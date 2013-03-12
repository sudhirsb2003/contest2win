require File.dirname(__FILE__) + '/../test_helper'

class SmsAlertTest < Test::Unit::TestCase
  fixtures :sms_alerts 
  def test_normalize_msisdn
    assert_equal "919987547935", SmsAlert.new(:msisdn => "919987547935").normalized_msisdn
    assert_equal "919987547935", SmsAlert.new(:msisdn => "(+91) 9987547935").normalized_msisdn
    assert_equal "919987547935", SmsAlert.new(:msisdn => "91 99875 47935").normalized_msisdn
    assert_equal "919987547935", SmsAlert.new(:msisdn => "(mob) 99875 47935").normalized_msisdn
  end

  def test_send_sms
    alert = SmsAlert.new(:msisdn => '9987547935')
    alert.send_message
    assert_equal SmsAlert::STATUS_SENT, alert.status
    assert_equal 1, alert.attempts
    assert_not_nil alert.transaction_id
  end

end
