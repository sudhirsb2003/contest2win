class Hangman < Contest
  has_many :responses, :foreign_key => 'contest_id', :class_name => 'HangmanResponse', :dependent => :delete_all do
    def valid(*args)
      with_scope(:find => { :conditions => 'user_id is not null and answers_count > 0'} ) do
        find(*args)
      end
    end
    # Recent unique responses
    def recent(*args)
      with_scope(:find => { :conditions => 'user_id is not null and old_response = false' }) do
        find(*args)
      end  
    end
    # Top responses
    def top(*args)
      with_scope(:find => { :conditions => 'user_id is not null' }) do
        find(*args)
      end  
    end
  end

end
