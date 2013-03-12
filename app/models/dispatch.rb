class Dispatch < ActiveRecord::Base

  STATUSES = {:awaiting_payment => 0, :pending_shipment => 10, :shipped => 20, :canceled => -10}
  STATUSES_REV = STATUSES.invert
  COLUMNS_FOR_EXPORT = ['id', 'prize', 'username', 'email', 'address','mobile_number','phone_number',
      'status_as_text', 'payment_type', 'payment_amount', 'payment_number', 'payment_received_on']
  belongs_to :prize
  belongs_to :user
  belongs_to :short_listed_winner

  # when status == awaiting_payment
  validates_confirmation_of :paypal_account_id, :if => Proc.new {|dispatch| dispatch.paypal_account_id_required?}
  validates_presence_of :paypal_account_id, :ssn, :if => Proc.new {|dispatch| dispatch.paypal_account_id_required?}
  validates_presence_of :address_line_1, :city, :pin_code, :state, :country, :mobile_number
  validates_size_of :address_line_1, :address_line_2, :city, :pin_code, :state, :country, :mobile_number,
      :phone_number, :cancelation_reason, :maximum => 255, :allow_nil => true

  # when status == pending_shipment
  validates_presence_of :payment_type, :if => Proc.new { |dispatch| dispatch.status >= STATUSES[:pending_shipment] }
  validates_presence_of :payment_amount, :payment_number,
      :if => Proc.new { |dispatch| dispatch.status >= STATUSES[:pending_shipment] && dispatch.payment_type == 'DD' }
  validates_numericality_of :payment_amount, :allow_nil => true
  validates_date :payment_received_on,
      :if => Proc.new { |dispatch| dispatch.status >= STATUSES[:pending_shipment] && dispatch.payment_type == 'DD' }

  # when status == shipped
  validates_date :actioned_on, :if => Proc.new { |dispatch| dispatch.status == STATUSES[:shipped] }
  def validate
    if status == STATUSES[:shipped]
      errors.add_to_base("Dispatched on cannot be before the Payment Received date!") if actioned_on && payment_received_on && actioned_on.to_date < payment_received_on.to_date
    end  
  end  

  # when status == canceled
  validates_presence_of :cancelation_reason, :if => Proc.new { |dispatch| dispatch.status == STATUSES[:canceled] }

  def status_as_text
    text = STATUSES_REV[status].to_s.humanize
    text << " on #{actioned_on.strftime('%d %b %Y')}" unless actioned_on.nil?
    text
  end

  def address
    a = address_line_1
    a << " #{address_line_2}" unless address_line_2.empty?
    a << "\n#{city} - #{pin_code}\n#{state} #{country}"
  end

  def payment_details_present?
    not payment_type.nil?
  end

  def status_advance
    self.status += 10
  end

  def status_retreat
    self.status -= 10
  end

  def to_csv
   Dispatch::COLUMNS_FOR_EXPORT.collect {|c| send(c).to_s} 
  end

  def contest
    @contest ||= begin
      if short_listed_winner_id
        short_listed_winner.contest_prize.contest
      else
        nil
      end
    end    
  end

  def paypal_account_id_required?
    prize && prize.cash? && !prize.region.india?
  end

  private
  def username() user.username; end
  def email() user.email; end
  def pending?
    status > 0 && status < 20
  end

end
