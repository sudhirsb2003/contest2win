module BannersHelper
  def show_banner(location, placement, classname = nil)
    unless AppConfig.disable_ads
      <<-AD
      <div id='#{placement}' #{"class='"+classname+"'" if classname}>
      <script type='text/javascript'>GA_googleFillSlot("#{BANNERS[location.to_sym]}");</script>
      </div>
      AD
    else
      return "<div id='#{placement}'>Ads Disabled</div>"
    end
  end

  def show_contest_banner(contest)
    return "<div id='contest_banner'>Ads Disabled</div>" if AppConfig.disable_ads
    show_banner('contest_rectangle', 'contest_banner')
  end

#  def show_banner_inline(location, placement, classname = nil)
#    unless AppConfig.disable_ads
#      banner = Banner.find_by_location(location)
#      return "<div id='#{placement}' #{"class='"+classname+"'" if classname}>#{banner ? banner.code : ""}</div>"
#    else
#      return "<div id='#{placement}'>Ads Disabled</div>"
#    end
#  end
 
  def show_contest_top_banner(contest)
    return "<div id='top_banner'>Ads Disabled</div>" if AppConfig.disable_ads
    show_banner('contest_top', 'top_banner')
  end

end
