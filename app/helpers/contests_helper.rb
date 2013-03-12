module ContestsHelper
  def link_to_contest(contest, length = 18)
    link_to h(truncate(contest.title, length)), contest_path(contest.url_attributes(:action => :play)), :title => (h(contest.title) if contest.title.length > length)
  end

  def swf_url(contest, host = request.host_with_port)
    if RAILS_ENV != 'development'
      if contest.is_a?(PersonalityTest)
        url = "http://#{host}/PT-#{contest.id}"
      else
        url = "http://#{host}/#{contest[:type].first}-#{contest.id}"
      end
    else
      url = "http://#{host}/flvplayer/container.swf?curl=http://#{host}/#{contest[:type].tableize}/#{contest.id}/x/"
    end  
  end

  def render_flash_for_contest(contest, external = false, host = request.host_with_port)
    url = swf_url(contest, host)
    if external && !contest.is_a?(Crossword)
      width, height = 425, 386
      swf_params = "<embed src='#{url}' type='application/x-shockwave-flash' allowScriptAccess='always' width='#{width}' height='#{height}'></embed>"
    else
      width, height = 550, 500
      swf_params = "<param name='wmode' value='transparent'/><embed src='#{url}' wmode='transparent' allowScriptAccess='always' type='application/x-shockwave-flash' width='#{width}' height='#{height}'></embed>"
    end  
    back_link = "View more <a href='http://#{host}'>Contests</a> from <a href='http://#{host}/users/#{contest.username}'>#{contest.username}</a>"
    return "<object type='application/x-shockwave-flash' data='#{url}' width='#{width}' height='#{height}' id='c2w_game'><param name='allowScriptAccess' value='always'/><param name='movie' value='#{url}'/>#{swf_params}</object><br/><small>#{back_link}</small>"
  end

  def image_tag_for_contest(contest, options = {})
    if q = contest.question_with_image
      case q.content_type
      when Contest::CONTENT_TYPE_IMAGE
        # image_tag(url_for_file_column(q, :image, 'thumb'), :alt => contest.title)
         image_tag('/images/li_img3.jpg',:width => '151',:height => '151',:alt => "img")
      when Contest::CONTENT_TYPE_VIDEO
        image_tag(url_for_file_column(q.video, :image, 'thumb'),:width => '151',:height => '151', :alt => contest.title) if q.video && q.video.converted?
      when Contest::CONTENT_TYPE_YT_VIDEO
        "<span class='video_still'><span class='play'>Play</span>#{image_tag q.external_video_img_url,:width => '151',:height => '151', :alt => contest.title, :title => '' }</span>"
      end
    else
      if contest.skin && contest.skin.image
        # image_tag(url_for_file_column(contest.skin, :image), :alt => contest.title)
        image_tag('/images/li_img3.jpg',:width => '151',:height => '151',:alt => "img")
      else
        image_tag('/images/li_img3.jpg',:width => '151',:height => '151',:alt => "img")
      end
    end
  end

end
