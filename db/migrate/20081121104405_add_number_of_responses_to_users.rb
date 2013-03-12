class AddNumberOfResponsesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :number_of_responses, :integer, :default => 0
    execute %{CREATE table tmp_response_counts as select user_id, count(id) from responses group by user_id;
    CREATE index tmp_response_count_user on tmp_response_counts (user_id);
    update users set number_of_responses = COALESCE(t.count, 0) from tmp_response_counts t where t.user_id = users.id;
    DROP table tmp_response_counts;
    }
  end

  def self.down
    remove_column :users, :number_of_responses
  end
end
