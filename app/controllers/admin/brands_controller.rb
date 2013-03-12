class Admin::BrandsController < AdminController
  layout 'admin'

  def list
    @brands = Brand.all.paginate(:page => params[:page])
  end

  def new
    if request.post?
      @brand = Brand.new(params[:brand])
      if @brand.save
        flash[:notice] = "Brand - #{@brand.name} Created!" 
        redirect_to brands_management_url
      end  
    else
      @brand = Brand.new  
    end
  end

  def edit
    @brand = Brand.find(params[:id])
    if request.post?
      if @brand.update_attributes(params[:brand])
        flash[:notice] = "Brand - #{@brand.name} Updated!"  
        redirect_to brands_management_url
      end  
    end
  end

  def delete
    brand = Brand.find(params[:id])
    if brand.deletable?
      Brand.delete(params[:id])
      redirect_to brands_management_url
    else
      render :nothing => true, :status => :error
    end  
  end

end
