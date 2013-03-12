class CategoriesController < ApplicationController

  def show
    @category = Category.find_by_slug(params[:slug])
    redirect_to contests_url(:controller => :contests, :action => 'most_recent', :catid => @category.id)
  end
end
