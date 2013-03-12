class RankedEntry < ActiveRecord::Base
  belongs_to :entry
  named_scope :sorted, :conditions => ['sorted = ?', true]
  named_scope :unsorted, :conditions => ['sorted = ?', false]

  def middle
    (upper_bound + lower_bound)/2
  end

  def mark_as_sorted
    sorted = true
    transaction do
      connection.execute <<-SQL, 'Updating points of entries'
        UPDATE entries set total_points = total_points + 1 from ranked_entries WHERE entries.id = ranked_entries.entry_id
          and response_id = #{response_id} and ranked_entries.points >= #{points} and sorted = true and entries.id != #{entry_id};
        UPDATE entries set total_points = total_points + #{points} where id = #{entry_id};
        UPDATE ranked_entries set points = points + 1 WHERE response_id = #{response_id} and points >= #{points} and sorted = true;
        UPDATE ranked_entries set sorted = true WHERE id = #{id};
      SQL
    end  
    
  end
end
