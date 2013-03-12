class Email < ActiveRecord::BaseWithoutTable
end

class Email::ContactUs < Email
  column :name, :string
  column :c2wID, :string  
  column :email_address, :string
  column :message, :string

  validates_presence_of :name, :email_address, :message
  validates_size_of :name, :email_address, :maximum => 255
  validates_size_of :message, :maximum => 500
  validates_format_of :email_address, :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i, :allow_blank => true

end

class Email::Referral < Email
  column :to_email_addresses, :string
  column :message, :string
  column :from_user_id

  belongs_to :from_user, :foreign_key => :from_user_id, :class_name => 'User'

  validates_presence_of :to_email_addresses, :message
  validates_size_of :message, :maximum => 500
  validates_each :to_email_addresses do |rec, name, value|
    email_arr = split_email_addresses(value)
    valid_email_arr = email_arr.select {|e| e if e =~ %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i }
    rec.errors.add name, ' are invalid' if valid_email_arr.size != email_arr.size
  end

  def self.split_email_addresses(email_addresses)
    email_addresses.split(/[\s,;\n]+/)
  end


end
