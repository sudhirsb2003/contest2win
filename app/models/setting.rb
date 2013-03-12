class Setting < ActiveRecord::Base
  
  def self.value(name)
    find_by_name(name.to_s).value rescue nil
  end
end
