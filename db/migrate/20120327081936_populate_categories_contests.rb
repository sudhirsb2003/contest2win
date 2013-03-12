class PopulateCategoriesContests < ActiveRecord::Migration
  def self.up
    execute %Q{insert into categories_contests (category_id, contest_id) (select category_id, c.id from contests c inner join categories on categories.id = c.category_id)}
  end

  def self.down
  end
end
