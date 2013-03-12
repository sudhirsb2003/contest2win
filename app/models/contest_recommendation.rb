class ContestRecommendation < ActiveRecord::Base
  
  belongs_to :contest

  validates_presence_of :from_name, :from_email_address, :message, :to_email_addresses
  validates_format_of :from_email_address,
      :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i
  validates_each :to_email_addresses do |rec, name, value|
    email_arr = split_email_addresses(value)
    #valid_email_arr = email_arr.select {|e| e if e =~ /^([^@]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/i }
    valid_email_arr = email_arr.select {|e| e if e =~ %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i }
    rec.errors.add name, ' are invalid' if valid_email_arr.size != email_arr.size
  end

  def self.split_email_addresses(email_addresses)
    email_addresses.split(/[\s,;\n]+/)
  end

end
