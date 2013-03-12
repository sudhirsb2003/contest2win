class Category < ActiveRecord::Base
  has_and_belongs_to_many :contests
  #has_and_belongs_to_many :regions

  named_scope :all, :order => 'name'

  # filters
  before_create :generate_slug

  def generate_slug
    write_attribute(:slug, name.downcase.gsub(/\W+/,'-')[0..99].gsub(/^-|-$/,''))
  end

  def before_destroy
    raise "This category has contests and hence can't be deleted!" if contests.first.present?
  end
end
