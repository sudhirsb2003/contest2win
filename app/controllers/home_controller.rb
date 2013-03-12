class HomeController < ApplicationController

  def index
    #@title = "Welcome to Contests2win"
    #return render :text => 'Live and kicking...' if request.host == 'localhost' # monit pings
    per_page = 4

    unless request.xhr?
      #@home_contest_cache_key = "/home/_contest#{Time.now.to_i/5.minutes.to_i}" # cache for 5 minutes
      unless read_fragment(@home_contest_cache_key)
        if @question = Question.find_with_image(:first, :conditions => ['contests.featured = true and contests.type != ?', 'Crossword'], :order => 'random()')
          @contest = @question.contest
        end  
      end
      running_contests = Contest.live.running
      @featured_quizzes = running_contests.featured.find(:all,:include => [:favourites],:limit => 5) 
      puts "-"*100
      puts "FQ : #{@featured_quizzes.size}"
      puts "-"*100
      @featured_contests = running_contests.featured.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
      @popular_contests = running_contests.most_played.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
      @recent_contests = running_contests.recent.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
    else
      @quize_type =  params[:quize_type]
      case @quize_type
      when "e"
        @contests = Contest.live.running.featured.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
        @update_div = "editorial_quizzes"
        @heading = "Editorial Picks - Quizzes"
        @action_name = "featured"
      when "p"  
        @contests = Contest.live.running.most_played.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
        @update_div = "popular_quizzes"
        @heading = "Popular Quizzes"
        @action_name = "most_played"
      when "r"        
        @contests = Contest.live.running.recent.paginate(:all,:include => [:favourites],:page => params[:page], :per_page => per_page) 
        @update_div = "recent_quizzes"
        @heading = "Recent Quizzes"
        @action_name = "most_recent"
      end



      render :update do |page|
         page.replace_html "#{@update_div}", :partial => '/contests/contests',:locals => {:contests => @contests,:heading => @heading,:quiz_type => @quize_type,:action_name => action_name}
      end
    end
  end

  def contests
    case params[:tab]
    when 'most_played'

      contests = Contest.live.running.most_played.find(:all, :conditions => ["starts_on >= now()::date - interval '7 days'"], :limit => 12)
      @description = "The most Played Contests this week. Play and win Points!"
    when 'contests_with_prizes'
      contests = Contest.live.running.with_prizes.find(:all, :conditions => ["starts_on >= now()::date - interval '7 days'"], :limit => 12)
      @description = "Play these contests and get a chance to win cool prizes! Participate Now!"
    end
    render :update do |page|
      page.replace_html "#{params['tab']}_body", :partial => 'contests', :locals => {:contests => contests}
    end
  end

  def search
    @results = ThinkingSphinx::Search.search(params[:query], :page => params[:page], :per_page => 10) unless params[:query].blank?
    render :layout => 'application'
  end


  def contact_us
    @title = "Contact Us"
    if request.post?
      @contact_us = Email::ContactUs.new params[:contact_us]
      if @contact_us.valid?
        GenericMailer.deliver_contact_us_mail(@contact_us)
        render :template => 'home/contact_us_sent'
      end 
    else
      if current_user?(user)
        @contact_us = Email::ContactUs.new({:email_address => user.email, :c2wID => user.username, :name => user.full_name})
      end  
    end     
  end

end
