class VideosController < ApplicationController
  def show_entry
    entry = Entry.find(params[:id])
    render :update do |page|
      page.insert_html :bottom, "body", :partial => 'videos/show', :locals => {:video => entry.video, :title => entry.title, :external => false}
    end  
  end
  def show_question
    question = Question.find(params[:id])
    render :update do |page|
      page.insert_html :bottom, "body", :partial => 'videos/show', :locals => {:video => question.video, :title => question.question, :external => false}
    end  
  end

 def show_entry_external_video
    entry = Entry.find(params[:id])
    render :update do |page|
      page.insert_html :bottom, "body", :partial => 'videos/show', :locals => {:question => entry, :title => entry.title, :external => true}
    end  
 end

 def show_question_external_video
    question = Question.find(params[:id])
    render :update do |page|
      page.insert_html :bottom, "body", :partial => 'videos/show', :locals => {:question => question, :title => question.question, :external => true}
    end  
 end

end
