module PersonalitiesHelper
  def flash_embed_code(personality)
    #url = "http://#{request.host_with_port}/flvplayer/badge.swf?curl=#{personalities_url(personality)}/"
    url = RAILS_ENV == 'development' ? "http://#{request.host_with_port}/flvplayer/badge.swf?curl=#{personalities_url(personality)}/" : "http://#{request.host_with_port}/pbadge-#{personality.id}"
    width, height = 200, 200
    return "<object type='application/x-shockwave-flash' data='#{url}' width='#{width}' height='#{height}'> <param name='movie' value='#{url}'/><param name='allowScriptAccess' value='always'/><embed src='#{url}'  type='application/x-shockwave-flash' allowScriptAccess='always' type='application/x-shockwave-flash' width='#{width}' height='#{height}'></embed></object>"

  end

end
