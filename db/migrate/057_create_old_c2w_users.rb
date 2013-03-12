class CreateOldC2wUsers < ActiveRecord::Migration
  def self.up
    create_table :old_c2w_users do |t|
      t.column "first_name",             :string
      t.column "last_name",             :string
      t.column "day_counter",             :string
      t.column "address",             :string
      t.column "city",             :string
      t.column "state",             :string
      t.column "country",             :string
      t.column "pin_code",             :string
      t.column "contact_number",             :string
      t.column "gender",             :string
      t.column "date_of_birth",             :date
      t.column "email",             :string
      t.column "date_of_registration",             :date
      t.column "fmail",             :string
      t.column "points",             :integer
      t.column "modified_on",             :date
      t.column "reg_site",             :string
      t.column "mobile_number",             :string
      t.column "points_2",             :integer
      t.column "migrated_on",             :datetime
      t.column "new_user_id",             :integer
    end
    add_index :old_c2w_users, :migrated_on
  end

  def self.down
    drop_table :old_c2w_users
  end
end
