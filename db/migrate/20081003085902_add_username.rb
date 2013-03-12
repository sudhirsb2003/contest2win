class AddUsername < ActiveRecord::Migration
  def self.up
    add_column :contests, :username, :string
    execute %{update contests set username = (select username from users where id = contests.user_id)}
    add_column :comments, :username, :string
    execute %{update comments set username = (select username from users where id = comments.user_id)}
    add_column :questions, :username, :string
    execute %{update questions set username = (select username from users where id = questions.user_id)}
    add_column :entries, :username, :string
    execute %{update entries set username = (select username from users where id = entries.user_id)}
  end

  def self.down
    remove_column :contests, :username
    remove_column :comments, :username
    remove_column :questions, :username
    remove_column :entries, :username
  end
end
