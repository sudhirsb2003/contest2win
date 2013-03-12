class DropCategoryDefaultFromContests < ActiveRecord::Migration
  def self.up
    execute %{alter table contests alter column category_id drop default}
  end

  def self.down
  end
end
