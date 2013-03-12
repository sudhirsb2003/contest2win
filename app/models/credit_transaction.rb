class CreditTransaction < ActiveRecord::Base

  named_scope :non_loyalty, :conditions => ['loyalty_points = ? and amount != 0', false]

  def cr_db
    amount < 0 ? 'Db' : 'Cr'
  end

end
