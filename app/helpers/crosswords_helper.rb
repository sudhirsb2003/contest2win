require 'digest/md5'
module CrosswordsHelper
  
  def draw_crossword(crossword)
    size = crossword.grid_size - 1
    html = "<table class='crossword_grid'>"
    (0..size).each {|r|
      html << "<tr>\n"
      (0..size).each {|c|
         html << "<td id='x#{r}_#{c}'></td>"
      }
      html << "\n</tr>"
    }
    html << '</table>'
    html << '<script>'
    crossword.clues.each do |clue|
      html << "$('x#{clue.row}_#{clue.col}').addClassName('crossword_cell');\n"
      html << "$('x#{clue.row}_#{clue.col}').addClassName('cell#{clue.question_id}');\n"
      html << "$('x#{clue.row}_#{clue.col}').innerHTML = '<span>#{clue.position}</span><a id=\"c#{clue.row}_#{clue.col}\" href=\"#\" onclick=\"return enter_answer(#{clue.question_id});\">&nbsp;</a>';\n"
      r, c = clue.row, clue.col
      (1..clue.length-1).each {
        clue.across ? c = c + 1 : r = r + 1
        html << "$('x#{r}_#{c}').addClassName('crossword_cell');\n"
        html << "$('x#{r}_#{c}').addClassName('cell#{clue.question_id}');\n"
        html << "$('x#{r}_#{c}').innerHTML = '<a id=\"c#{r}_#{c}\" href=\"#\" onclick=\"return enter_answer(#{clue.question_id});\">&nbsp;</a>';\n"
      }
    end
    html << '</script>'
    html
  end
  
  def md5(text)
    Digest::MD5.hexdigest(text)
  end

end
