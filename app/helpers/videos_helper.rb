module VideosHelper
  def show_video(video, autostart = false)
    if video.converted?
      preview_image = url_for_file_column(video, 'image')
      file = '/flvplayer/flvplayer.swf?clicktext=+&amp;file=' + url_for_file_column(video, 'stream_file')
      file += "&amp;image=#{preview_image}" if preview_image
      file += "&amp;autostart=true" if autostart
      return "<object type='application/x-shockwave-flash' width='240' height='200' wmode='transparent'
          data='#{file}'>
          <param name='movie' value='#{file}' />
          <param name='wmode' value='transparent' />
      </object>"
    else
      return "#{image_tag(url_for_file_column(video, :image, 'thumb'), :alt => '') if video.image}<div class='highlight video_stream_not_generated_msg'>Video stream not yet generated.
        Should be done in approximately #{video.time_to_conversion} minutes</div>"
    end  
  end

  def show_external_video(question)
    url = "http://www.youtube.com/v/#{question.external_video_id}&amp;hl=en&amp;fs=1&amp;showsearch=0"
    return "<object type='application/x-shockwave-flash' data='#{url}' width='300' height='200'><param name='movie' value='#{url}'/><param name='allowFullScreen' value='true'></param><param name='wmode' value='transparent'/></object>"
  end

end
