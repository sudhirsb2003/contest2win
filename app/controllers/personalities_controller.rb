class PersonalitiesController < ApplicationController
  layout 'popup'

  def badge
    @personality = Personality.find(params[:id])
    return render(:template => 'shared/access_denied', :status => :unauthorized) unless @personality.contest.live?
    respond_to do |format|
      format.html {}
      format.xml {render :xml => @personality.to_xml(:base_url => request.host_with_port)}
    end
  end
end
