class AddSessionIdToResponses < ActiveRecord::Migration
  def self.up
    add_column :responses, :session_id, :string
    add_index :responses, :session_id

    execute %{alter table responses alter column user_id drop not null}
  end

  def self.down
    remove_column :responses, :session_id
  end
end
