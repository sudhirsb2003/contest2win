# Methods added to this helper will be available to all templates in the application.
require 'redcloth'

module ApplicationHelper

  def short_datetime(datetime)
    datetime.strftime "%d %b %Y %I:%M %p" unless datetime.nil?
  end

  def short_date(date)
    date.strftime "%d %b %y" unless date.nil?
  end

  def textilize(text)
    RedCloth.new(text).to_html unless text.nil?
  end

  def windowed_pagination_links(pagingEnum, options)
    link_to_current_page = options[:link_to_current_page]
    always_show_anchors = options[:always_show_anchors]
    padding = options[:window_size]

    current_page = pagingEnum.page
    html = ''

    #Calculate the window start and end pages 
    padding = padding < 0 ? 0 : padding
    first = pagingEnum.page_exists?(current_page  - padding) ? current_page - padding : 1
    last = pagingEnum.page_exists?(current_page + padding) ? current_page + padding : pagingEnum.last_page

    # Print start page if anchors are enabled
    html << yield(1) if always_show_anchors and not first == 1

    # Print window pages
    first.upto(last) do |page|
      (current_page == page && !link_to_current_page) ? html << page : html << yield(page)
    end

    # Print end page if anchors are enabled
    html << yield(pagingEnum.last_page) if always_show_anchors and not last == pagingEnum.last_page
    html
  end

  # Displays a loading indicator inside the <tt>target</tt> DOM element.
  def ajax_loading_indicator(target, msg='Loading, Please wait...')
    "new Insertion.Bottom('#{target}', '<div class=\"loading\">#{msg}</div>');"
  end

  # Replaces the contents of the element with a loading indicator. 
  def loading_indicator_small(element_id)
    "$('#{element_id}').innerHTML = '#{image_tag('loading_wheel.gif')}'"
  end

  def get_my_latest_response(contest)
    if logged_in?
      my_response = Response.latest_by_contest_id_and_user_id(contest.id, current_user.id)
    elsif session[:uuid]
      my_response = Response.latest_by_contest_id_and_session_id(contest.id, session[:uuid])
    end  
    my_response
  end

  # Shows the question's image or the question's video's image if present. 
  def show_question_image(question, size = 'medium')
    if video = question.video
      if video.converted?
        image_tag(url_for_file_column(video, :image, size), :alt => question.question)
      else
        "#{image_tag(url_for_file_column(video, :image, size), :alt => question.question) if video.image}<div class='highlight'>Video stream not yet generated.</div>"
      end  
    elsif question.image
      image_tag(url_for_file_column(question, :image, size), :alt => question.question)
    elsif (skin = question.contest.skin) && question.contest.skin.image
      image_tag(url_for_file_column(skin, :image, size), :alt => question.question)
    end
  end

  # Shows the question's image or the question's video's image if present. 
  def show_question_thumb(question)
    if question.reuse_previous_media? && (prev_question = question.previous_question_with_reusable_media).present?
      question = prev_question
    end
    case question.content_type
    when Contest::CONTENT_TYPE_VIDEO
      if video = question.video
        if video.converted?
          link_to_remote image_tag(url_for_file_column(video, :image, 'thumb'), :alt => question.question),
              :url => "/videos/show_question/#{question.id}", :title => h(question.question)
        else
          "#{image_tag(url_for_file_column(video, :image, 'thumb'), :alt => question.question) if video.image}<div class='highlight'>Video stream not yet generated.</div>"
        end
      else
        'Video not found!'
      end
    when Contest::CONTENT_TYPE_IMAGE
      link_to image_tag(url_for_file_column(question, :image, 'thumb'), :alt => question.question),
            url_for_file_column(question, :image), :rel => "lightbox[#{question.contest_id}]", :title => h(question.question)
    when Contest::CONTENT_TYPE_YT_VIDEO
      	img_class_var = "<span class='video_still'><span class='play'>Play</span>#{image_tag question.external_video_img_url, :alt => question.question}</span>"
	      link_to_remote img_class_var,:url => "/videos/show_question_external_video/#{question.id}", :title => h(question.question),:html=>{:class=>"play"}
    end
  end

  def show_entry_thumb(entry)
    case entry.content_type
    when Contest::CONTENT_TYPE_VIDEO
      if video = entry.video
        if video.converted?
            link_to_remote image_tag(url_for_file_column(video, :image, 'thumb'), :alt => ''), :url => "/videos/show_entry/#{entry.id}?title=", :title => h(entry.title)
        else
          "#{image_tag(url_for_file_column(video, :image, 'thumb'), :alt => '') if video.image}<div class='highlight'>Video stream not yet generated.</div>"
        end  
      end
    when Contest::CONTENT_TYPE_IMAGE
      link_to image_tag(url_for_file_column(entry, :image, 'thumb'), :alt => ''),
            url_for_file_column(entry, :image), :rel => "lightbox[#{entry.contest_id}]", :title => h(entry.title)
    when Contest::CONTENT_TYPE_YT_VIDEO
      	img_class_var = "<span class='video_still'><span class='play'>Play</span>#{image_tag entry.external_video_img_url, :alt => ''}</span>"
	      link_to_remote img_class_var,:url => "/videos/show_entry_external_video/#{entry.id}", :title => h(entry.title),:html=>{:class=>"play"}
    end
  end

  def show_thumb(x)
    x.is_a?(Entry) ? show_entry_thumb(x) : show_question_thumb(x)
  end

  def reqd
    '<span class="reqd">*</span>'
  end

  def insert_note(text, heading = 'Note')
    ts = Time.now.to_i
    return <<-END
    <div class="note_container">
    <a href="#" style="float:left" onclick="Element.toggle('note#{ts}');return false;"><img src="/images/icons/info.png" alt=""/></a>
    <div class="note" id="note#{ts}" style="display:none">
      <h4>#{heading}</h4>
      #{text}
    </div>
    <br clear="left"/>
    </div>
    END
  end

  def check_box_collection(object_name, method, collection)
    content = '<ul class="checkboxes">'
    collection.each do |label, value|
      content << "<li><input type='checkbox' name='#{object_name}[#{method.singularize}_ids][]'"
      content << ' checked ' if eval("@#{object_name}.#{method.singularize}_ids.include?(#{value})")
      content << " value='#{value}' id='#{object_name}[#{method.singularize}_ids][#{value}]'/> <label for='#{object_name}[#{method.singularize}_ids][#{value}]'>#{label}</label></li>"
    end
    content << '</ul>'
    content
  end

  def tip(text)
    "<span class='tip'>#{text}</span>"
  end

  @@HYPERLINK_REGX = Regexp.new(/http:\/\/(blog|in|us|www)\.(contests2win|c2w).com[^( |<|\n)]*/i)
  def hyperlink_links(text)
    text.gsub(@@HYPERLINK_REGX, '<a href="\0" target="_blank">\0</a>')
  end

  def simple_paginate(collection, offset, size)
      offset = offset.to_i
      return <<-HTML
        <div class="pagination">
          <span>#{link_to_unless offset == 0, '&laquo; Newer', {:offset => offset - size}}</span>
          |
          <span>#{link_to_unless collection.size < size, 'Older &raquo;', {:offset => offset + size}}</span>
        </div>
      HTML
  end

  def cache_if(condition, cache_key, &block)
    condition ? send("cache", cache_key, &block) : yield
  end

  def cache_flush_if(condition, cache_key, &block)
    controller.expire_fragment(cache_key) if condition
    send("cache", cache_key, &block)
  end

  def number_as_pp(pp)
    number_with_delimiter(number_with_precision(pp, 2))
  end

  def yes_no(value)
    value ? 'yes' : 'no'
  end

  def link_to_tweet(msg, title = 'Tweet this...')
    "<a class='tweet_link' href='http://twitter.com/home?status=#{msg}' target='_blank' title='Post to twitter' onclick=\"track_external_click('twitter.com')\"'>#{title}</a> "
  end

  def safe_html(html)
    sanitize(html, :tags => %w(a em strong i b))
  end

  def options_for_category()
    options = []
    all_categories = Category.all
    all_categories.each do |category|
      options.push([category.name,category.id.to_s])
    end
    options
  end

  def options_for_sorting
    options = [["Most Recent","most_recent"],["Most Played","most_played"],["Top Rated","top_rated"],["Featured","featured"],["Prize Points","prize_points"]]
    options

  end
end
