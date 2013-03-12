class Admin::SkinsController < AdminController
  layout 'admin'

  def list
    @skins = Skin.all.paginate(:page => params[:page])
  end

  def new
    if request.post?
      @skin = Skin.new(params[:skin])
      if @skin.save
        flash[:notice] = "Skin - #{@skin.name} Created!" 
        redirect_to skins_management_url
      end  
    else
      @skin = Skin.new  
    end
  end

  def edit
    @skin = Skin.find(params[:id])
    if request.post?
      if @skin.update_attributes(params[:skin])
        flash[:notice] = "Skin - #{@skin.name} Updated!"  
        redirect_to skins_management_url
      end  
    end
  end

  def delete
    skin = Skin.find(params[:id])
    if skin.deletable?
      Skin.delete(params[:id])
      render :nothing => true
    else
      render :nothing => true, :status => :error
    end  
  end

end
