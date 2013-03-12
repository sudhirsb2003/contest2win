class SmsAlert < ActiveRecord::Base
  require 'uri'
  require 'net/http'
  require 'net/https'

  validates_presence_of :user_id
  validates_presence_of :msisdn

  STATUS_PENDING = 0
  STATUS_SENT = 1
  STATUS_FAILED = -1
  MESSAGE = URI.escape('Congratulations! You have won a prize on Contests2win.com. Please check your email for further details.')

  def self.send_pending_smses
    find(:all, :conditions => "status = #{STATUS_PENDING}").each {|alert|
      alert.send_message
      alert.save
    }
  end

  def send_message
	sms_url =  "https://www.bsmart.in/smart/SmartSendSMS.jsp?usr=#{AppConfig.sms_service_username}&pass=#{AppConfig.sms_service_password}&msisdn=#{normalized_msisdn}"
	sms_url += "&msg=#{MESSAGE}&sid=C2W&fl=0&mt=0"
    uri = URI.parse(sms_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    self.attempts = self.attempts + 1
    sms_response = http.get(uri.request_uri)
    if sms_response.code == '200'
      transaction_id = sms_response.body.strip.to_i
      if transaction_id.to_i > 0
        self.status = STATUS_SENT
        self.sent_on = Time.now
        self.transaction_id = transaction_id
      end  
    end  
    self.status = attempts > AppConfig.sms_attempts ? STATUS_FAILED : STATUS_PENDING unless self.status == STATUS_SENT
  end

  def normalized_msisdn
    temp_msisdn = msisdn.gsub(/\D/, '')
    temp_msisdn = '91' + temp_msisdn unless temp_msisdn.starts_with? '91'
    temp_msisdn
  end
end
