class AddCountFieldsToQuestionAndOptions < ActiveRecord::Migration
  def self.up
    add_column :questions, :answers_count, :integer, :null => false, :default => 0
    execute %{UPDATE questions set answers_count = (select count(a.id) from answers a inner join questions q on q.id = a.question_id inner join contests on q.contest_id = contests.id where a.question_id = questions.id and a.created_on::date <= contests.ends_on::date and contests.type in ('Faceoff','Poll'))}

    add_column :question_options, :clicks, :integer, :null => false, :default => 0
    execute %{UPDATE question_options set clicks = (select count(a.id) from answers a inner join questions q on q.id = a.question_id inner join contests on q.contest_id = contests.id where a.question_id = question_options.question_id and a.question_option_id = question_options.id and a.created_on::date <= contests.ends_on::date and contests.type in ('Faceoff','Poll'))}
  end

  def self.down
    remove_column :questions, :answers_count
    remove_column :question_options, :clicks
  end
end
