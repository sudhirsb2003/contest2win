module Rake
  module TaskManager
    def redefine_task(task_class, args, &block)
      task_name, deps = resolve_args([args])
      task_name = task_class.scope_name(@scope, task_name)
      deps = [deps] unless deps.respond_to?(:to_ary)
      deps = deps.collect {|d| d.to_s }
      task = @tasks[task_name.to_s] = task_class.new(task_name, self)
      task.application = self
      task.add_description(@last_description)
      @last_description = nil
      task.enhance(deps, &block)
      task
    end
  end
  class Task
    class << self
      def redefine_task(args, &block)
        Rake.application.redefine_task(self, args, &block)
      end
    end
  end
end

def redefine_task(args, &block)
  Rake::Task.redefine_task(args, &block)
end

namespace :db do
  namespace :test do

    desc 'Prepare the test database and migrate schema'
    redefine_task :prepare => :environment do
      Rake::Task['db:test:migrate_schema'].invoke
    end

    desc 'Use the migrations to create the test database'
    task :migrate_schema => 'db:test:purge' do
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      ActiveRecord::Migrator.migrate("db/migrate/")
    end
  
  end
end

