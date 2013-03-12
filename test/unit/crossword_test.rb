require File.dirname(__FILE__) + '/../test_helper'

class CrosswordTest < Test::Unit::TestCase
  
  fixtures :users, :contests

  #CROSSWORD_DIR = File.dirname(__FILE__) + '/../../../misc/crossword' 
  CROSSWORD_DIR = "#{RAILS_ROOT}/misc/crossword"

  def test_write_word_file
    c = Crossword.new
    c.add_question("Best Browser in the world", "Firefox")
    c.add_question("Linus created", "Linux")
    c.add_question("Open source Servlet container", "tomcat")
    file = c.write_word_file
    assert File.exists?(file)
    File.delete(file)
  end

  def test_generate_grid
    c = Crossword.new
    output = c.generate_grid(CROSSWORD_DIR + '/words.txt')
    original = `cat #{CROSSWORD_DIR + '/grid.txt'}`
    assert_equal original, output
  end

  def test_generate_grid_error
    c = Crossword.new
    output = c.generate_grid(CROSSWORD_DIR + '/words_err.txt')
  end

  def test_parse_grid
    c = Crossword.new
    rows = c.parse_grid(`cat #{CROSSWORD_DIR}/grid.txt`)
    assert 20, rows.length
    assert 20, rows[0].length
  end

  def test_find_answer
    c = Crossword.new
    rows = c.parse_grid(`cat #{CROSSWORD_DIR}/grid.txt`)
    row,col = c.find_answer(rows, 'FIREFOX', true)
    assert_equal 6, row
    assert_equal 13, col

    row,col = c.find_answer(rows, 'FOX', true)
    assert_nil row
    assert_nil col

    col,row = c.find_answer(rows.transpose, 'FOX', false)
    assert_equal 15, row
    assert_equal 10, col

  end

  def test_generate
    c = Crossword.new(:title => 'test x word', :tag_list => 'test', :ends_on => Date.today + 10.days, :category_id => 1, :description => '')
    c.user_id = users(:a_user).id
    c.save!
    assert_not_nil c.version_number

    q = CrosswordQuestion.new(:question => "Best Browser in the world", :answer => "Firefox")
    q.user_id = users(:a_user).id
    c.all_questions << q

    q = CrosswordQuestion.new(:question => "2nd Best Browser in the world", :answer => "Opera")
    q.user_id = users(:a_user).id
    c.all_questions << q

    q1 = CrosswordQuestion.new(:question => "Worst Browser in the world", :answer => "safari")
    q1.user_id = users(:a_user).id
    c.all_questions << q1

    q2 = CrosswordQuestion.new(:question => "Worst Browser in the world (DUPLICATE)", :answer => "safari")
    q2.user_id = users(:a_user).id
    c.all_questions << q2

    c.generate
    c1, c2 = CrosswordClue.find_by_question_id(q1), CrosswordClue.find_by_question_id(q2)
    assert_not_equal "#{c1.row}-#{c1.col}-#{c1.across}", "#{c2.row}-#{c2.col}-#{c2.across}"
    c.all_questions.each {|q| assert_not_nil q.clue.id }
  end

  def test_generate_intense
    c = Crossword.new(:title => 'test x word', :tag_list => 'test', :ends_on => Date.today + 10.days, :category_id => 1, :description => '')
    c.user_id = users(:a_user).id
    c.save!

    30.times { 
      q = CrosswordQuestion.new(:question => "test", :answer => random_word)
      q.user_id = users(:a_user).id
      c.all_questions << q
    }
    file = c.write_word_file
    c.generate
    #c.all_questions.each {|q| assert_not_nil q.clue.id }
  end

  def test_solution_viewable
    c = Crossword.new(:ends_on => (Time.now + 10.days).to_date)
    c.user = users(:a_user)
    c.status = Contest::STATUS_LIVE
    assert c.solution_viewable?(users(:a_user))
    assert c.solution_viewable?(users(:a_moderator))
    assert !c.solution_viewable?(users(:another_user))
    assert !c.solution_viewable?(nil)

    c.ends_on = (Time.now - 10.days).to_date
    assert c.solution_viewable?(users(:a_user))
    assert c.solution_viewable?(users(:a_moderator))
    assert c.solution_viewable?(users(:another_user))
    assert c.solution_viewable?(nil)
  end

  def random_word
    chars = ("a".."z").to_a + ("A".."Z").to_a
    newpass = ""
    2.upto(rand(12) + 3) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

end
