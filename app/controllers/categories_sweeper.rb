class CategoriesSweeper < ActionController::Caching::Sweeper
  observe Category

  def after_save(record)
    expire_categories
  end

  def after_destroy(record)
    expire_categories
  end

  private
  def expire_categories
    Region.all.each{|r| expire_fragment("#{r.id}/home/_categories")}
  end

end
