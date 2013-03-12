class CopyrightViolation < ActiveRecord::BaseWithoutTable

  belongs_to :contest

  column :contest_id, :integer
  column :from_name, :string
  column :from_email_address, :string
  column :contact, :string
  column :message, :string

  validates_presence_of :from_name, :from_email_address, :contact, :message
  validates_size_of :from_name, :from_email_address, :maximum => 255
  validates_size_of :message, :maximum => 500
  validates_format_of :from_email_address, :with => %r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i, :allow_blank => true

end
