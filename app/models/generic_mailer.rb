class GenericMailer < ActionMailer::Base
  
  def contact_us_mail(contact_us)
    recipients  AppConfig.crm_email_address
    from        "#{contact_us.name} <#{AppConfig.notification_email_id}>"
    reply_to    contact_us.email_address
    bcc         AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject     "Message from #{contact_us.name}"
    content_type 'text/plain'
    body        :contact_us => contact_us
  end

  def referral_mail(referral_mail, referral_link)
    from        "#{referral_mail.from_user.name} <#{AppConfig.notification_email_id}>"
    reply_to    referral_mail.from_user.email
    bcc  referral_mail.to_email_addresses
    subject     "Join me on C2W!"
    content_type 'text/html'
    body        :referral_mail => referral_mail, :referral_link => referral_link
  end
end

