#-- $Id: quiz.rb 304 2007-08-27 19:24:56Z ngupte $
#++
# A Crossword is a type of <tt>Contest</tt> which has questions that fit into a 20x20 grid.
class Crossword < Contest

  has_many :all_questions, :foreign_key => 'contest_id', :class_name => 'CrosswordQuestion', :dependent => :destroy, :conditions => "questions.status != #{STATUS_DELETED}"
  has_many :draft_questions, :foreign_key => 'contest_id', :class_name => 'Question', :dependent => :delete_all, :conditions => "questions.status = #{STATUS_DRAFT}"

  def add_question(question, answer)
    q = CrosswordQuestion.new(:question => question, :answer => answer)
    all_questions << q
    return q
  end

  def generate
    Crossword.uncached do
      self.all_questions.reload
      word_file = write_word_file
      grid = generate_grid(word_file)
      rows = parse_grid(grid)
      generate_clues(rows)
    end
    #File.delete temp_file 
  end

  def write_word_file
    File.open(temp_file, 'w') do |handle|
      all_questions.sort{|x,y| x.answer <=> y.answer}.each {|q| handle.puts q.answer }
    end
    temp_file
  end

  def generate_grid(word_file_name)
    output = `#{AppConfig.crossword_generator_prog} #{word_file_name}`
  end

  def parse_grid(grid)
    rows = []
    grid.split("\n").each {|line| rows << Array.new(line.split(//)) }
    return rows
  end

  def generate_clues(rows)
    clues.each {|c| c.destroy}
    cols = rows.transpose
    all_questions.each {|q, i|
      row, col = find_answer(rows, q.answer, true)
      if col.nil?
        col, row = find_answer(cols, q.answer, false)
        across = false
      else
        across = true
      end
      unless row.nil? || col.nil?
        q.create_clue(:row => row, :col => col, :across => across, :length => q.answer.length)
        q.update_attribute(:status, Question::STATUS_APPROVAL_PENDING)
      end 
    }
    calculate_clue_positions
  end

  def find_answer(rows, answer, across)
    rows.each_with_index {|line, row|
      col = line.to_s.index(answer)
      if col
        if col == 0 || line[col - 1] == '-' # check to see if it's the beginning of a word
          if across
            r,c = row, col
          else
            r,c = col, row
          end  
          return row, col if id.nil? || clues("row = #{r} and col = #{c} and across = #{across}").empty?
        end
      end  
    }
    return nil, nil
  end

  def clues(conditions = nil)
    _conditions = "questions.contest_id = #{id}"
    _conditions << ' and ' + conditions if conditions
    CrosswordClue.find(:all, :select => 'crossword_clues.*',
        :joins => 'inner join questions on questions.id = question_id', :conditions => _conditions,
        :order => 'row, col')
  end

  def calculate_clue_positions
    connection.execute <<-SQL, 'Calculating clue positions'
      CREATE TEMP SEQUENCE rownum;
      CREATE TEMP TABLE temp_clues AS SELECT cc.row, cc.col, nextval('rownum') AS rownum FROM crossword_clues cc INNER JOIN questions q ON q.id = cc.question_id AND q.contest_id = #{id} GROUP BY cc.row, cc.col ORDER BY cc.row, cc.col;
      UPDATE crossword_clues SET position = rownum FROM temp_clues, questions q WHERE q.id = crossword_clues.question_id AND q.contest_id = #{id} AND temp_clues.row = crossword_clues.row AND temp_clues.col = crossword_clues.col;
      DROP SEQUENCE rownum;
      DROP TABLE temp_clues;
    SQL
  end

  def questions_addable?(user)
    return user && !id.nil? && status == Contest::STATUS_DRAFT
  end

  def show_others_can_add_option?
    return false
  end

  def solution_viewable?(by_user)  
    ended? || user == by_user || (by_user && by_user.moderator?)
  end  

  # Returns a temporary file for writing the answers to
  # This is needed as the input to the crossword generator program.
  def temp_file
    "#{AppConfig.tmp_dir}/crossword-#{id}.txt"
  end

  def finished_creating
    draft_questions.delete_all
    super
  end

  def grid_size
    case version_number
      when '2.13' then 20
      else 15
    end
  end

  def questions_editable?(by_user)
    (user == by_user && draft?) || (by_user && by_user.moderator? && approval_pending?)
  end

end
