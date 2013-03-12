class OldC2wUser < ActiveRecord::Base

  def self.find_old(username_or_email)
    username_or_email.downcase!
    unless rec = OldC2wUser.find(:first, :conditions => ['lower(email) = ?', username_or_email])
      rec = OldC2wUser.find(:first, :conditions => ['lower(userid) = ?', username_or_email])
    end
    rec
  end

  def self.find_by_email(email)
    OldC2wUser.find(:first, :conditions => ['lower(email) = ?', email.downcase])
  end

  def migrated?
    ! migrated_on.nil?
  end

  def to_user
    #user = User.new(attributes(:only => User.column_names))
    user = User.new(attributes.delete_if{|k,v| !User.column_names.include?(k)})
    user.username = userid
    user.gender = gender == 'F' ? 'Female' : 'Male'
    user.address_line_1 = address
    user.phone_number = contact_number
    user
  end

  def self.number_of_migrations
    count(:conditions => 'migrated_on is not null')
  end
end
