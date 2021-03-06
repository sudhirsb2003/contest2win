class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column "username",          :string,   :limit => 30,                       :null => false
      t.column "email",             :string,                                       :null => false
      t.column "password",          :string,                                       :null => false
      t.column "first_name",        :string,   :limit => 30
      t.column "last_name",         :string,   :limit => 30
      t.column "picture",           :string
      t.column "gender",            :string,   :limit => 10
      t.column "dob",               :date
      t.column "address_line_1",    :string
      t.column "address_line_2",    :string
      t.column "city",              :string
      t.column "pin_code",          :string
      t.column "state",             :string
      t.column "phone_number",      :string
      t.column "mobile_number",     :string
      t.column "favourite_topics",  :string
      t.column "favourite_prizes",  :string
      t.column "status",            :integer,   :limit => 10#, :default => User::STATUS_LIVE, :null => false
      t.column "level",              :integer,   :limit => 10#, :default => User::LEVEL_USER,   :null => false
      t.column "last_logged_in_on", :datetime
      t.column "created_on",        :datetime,                                     :null => false
      t.column "updated_on",        :datetime,                                     :null => false
    end
    add_index "users", ["email"], :unique => true
    add_index "users", ["username"], :unique => true
  end

  def self.down
    drop_table :users
  end
end
