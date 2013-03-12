class ContestsSweeper < ActionController::Caching::Sweeper
  observe Contest, Entry, Question

  def after_save(record)
    if record.is_a? Contest
      expire_contest(record)
    else # Entry | Question
      expire_contest record.contest if record.live?
    end  
  end

  def after_destroy(record)
    after_save(record)
  end

  private
  def expire_contest(record)
    cache_dir = ActionController::Base.page_cache_directory
    unless cache_dir == RAILS_ROOT+"/public"
      path = "#{cache_dir}/#{record.class.to_s.tableize}/#{record.id}"
      FileUtils.rm_rf "#{path}"
    end  
  end

end
