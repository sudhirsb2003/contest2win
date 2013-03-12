# --$Id: response.rb 2798 2009-01-07 05:55:09Z ngupte $--
#
# A response is what a user submits to a Contest.
# Responses contain one or more <tt>Answer</tt>s.
#
class Response < ActiveRecord::Base
  # view levels control who is allowed to view this response. 
  VIEW_LEVEL_ALL = 100
  VIEW_LEVEL_SELF = 0
  after_create :mark_old_responses

  attr_protected :score, :answers_count, :correct_answers_count, :old_response, :finished_on, :created_on

  has_many :answers, :order => 'answers.id'
  has_one :latest_answer, :class_name => 'Answer', :order => 'id desc'
  belongs_to :contest, :counter_cache => 'played'
  belongs_to :user, :counter_cache => 'number_of_responses'
  has_many :bets

  named_scope :online, :joins => :contest, :conditions => "contests.status >= #{Contest::STATUS_LIVE}" 
  named_scope :latest, :conditions => ['old_response = ?', false]
  named_scope :top_scores, :conditions => ['user_id is not null'], :order => 'score desc, id desc'
  named_scope :recent_plays, :conditions => ['user_id is not null'], :order => 'updated_on desc'
  
  def find_un_answered_questions
    question = contest.questions.find(:all, :conditions => ["questions.id not in (select question_id from answers where response_id = #{id})"])
  end

  def find_un_answered_question(order = 'questions.id')
    question = contest.questions.find(:first,
      :conditions => ["questions.id not in (select question_id from answers where response_id = #{id})"],
      :order => order)
  end

  def self.latest_by_contest_id_and_user_id(contest_id, user_id)
      find_by_contest_id_and_user_id(contest_id, user_id, :order => 'responses.id desc', :limit => 1)
  end

  def self.latest_by_contest_id_and_session_id(contest_id, session_id)
      find_by_contest_id_and_session_id(contest_id, session_id, :order => 'responses.id desc', :limit => 1)
  end

  def players_name
    if user
      user.username
    else
      'Unknown'
    end  
  end

  def completed?
    !new_record? and contest.questions.count <= answers_count
  end
  alias completed completed?

  def questions_remaining
    @questions_remaining ||= contest.questions.count - answers_count
  end

  # Gets the percentage of right answers to the total number of questions.
  def success
    (correct_answers_count*100.0/answers_count).round.to_i if answers_count > 0
  end

  def to_xml(options = {})
    super(options.merge( {:root => 'response', :only => [:score, :points, :correct, :id], :skip_types => true,
        :include => [:latest_answer],
        } )) do |xml|
      xml.completed completed?
      xml.tag! 'questions-answered', answers_count
      xml.tag! 'questions-remaining', questions_remaining
      xml.tag! 'correct-count', correct_answers_count
      xml.success success
      if contest.is_a?(PersonalityTest) && completed? && personality
        xml.personality do |xml|
          xml.title personality.title
          xml.description personality.description
          xml.tag! 'similar-users', (personality.similar_users rescue 'N/A')
          if personality.image
            host = personality.image_in_s3? ? FileColumn::S3FileColumnExtension::Config.s3_distribution_url : "http://#{options[:base_url]}"
            xml.image "#{host}/#{personality.image_web_path()}"
          end
          xml.tag! 'embed-page-url', "http://#{options[:base_url]}/personalities/#{personality.id}" if user && user.admin?
        end
      end
      if contest.is_a? Crossword
        xml.answers do
          answers.each do |answer|
            xml.answer do
              xml.question_id answer.question_id
              xml.answer answer.question.answer
              xml.correct answer.correct
           end
          end
        end
      end
    end    
  end

  #def similar_users
    #((personality.number_of_users/contest.played.to_f)*100.0).round(2) if contest.is_a?(PersonalityTest)
  #end

  def add_answer(ans_attr)
    return nil if answers.find_by_question_id(ans_attr[:question_id])
    ans = answers.build(ans_attr)
    if ans.question_option_id && option = ans.question.options.find(ans.question_option_id)
      ans.points = option.points_to_award
      ans.correct = option.correct?
      ans.entry_id = option.entry_id
    end  
    ans.save
    reload
    ans
  end

  def mark_old_responses
    if user_id
      connection.update <<-SQL, 'Marking old responses'
        UPDATE responses set old_response = true where contest_id = #{contest_id} and user_id = #{user_id} and id < #{id} and old_response != true
      SQL
    end  
  end

  def before_create
    self.finished_on = Time.now
  end

  def self.delete_old_by_unknown_users
    self.delete_all "user_id is null and updated_on < now() - interval '1 day'"
  end
  
  def personality
    @personality ||= begin
      if contest.is_a?(PersonalityTest)
        contest.personality_for_score(score)
      else
        nil
      end
    end
  end

  def total_bet
    @total_bet ||= bets.sum(:wager)
  end

  def bets_for(option_id)
    bets.sum(:wager, :conditions => ['option_id = ?', option_id])
  end

  def payout_for(option_id)
    bets.find(:all, :conditions => ['option_id = ?', option_id]).sum(&:payout)
  end

  def recently_completed?
    completed? && (Time.now - updated_on) < 1.minute
  end
end
