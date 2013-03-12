class UserMailer < ActionMailer::Base

  def activation_mail(controller, user)
    recipients user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Activate your c2w.com account."

    content_type "text/html"
    body :user => user, :controller => controller
  end

  def welcome_mail(controller, user)
    recipients user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Welcome to c2w.com!"

    content_type "text/html"
    body :user => user, :controller => controller
  end

  def password_regeneration_instructions(controller, user, token)
    recipients user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - Your New Password!"

    content_type "text/html"
    body :user => user, :token => token, :controller => controller
  end

  def old_password(controller, old_user)
    recipients old_user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Contests2win.com - Your Old Password"

    content_type "text/html"
    body :old_user => old_user, :controller => controller
  end

  def new_message_notification(controller, message)
    recipients message.receiver.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - #{message.sender.username} has sent you a message."

    content_type "text/html"
    body :message => message, :controller => controller
  end

  def friend_request_notification(controller, sender, receiver)
    recipients receiver.email
    from        "#{sender.name} <#{AppConfig.notification_email_id}>"
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - #{sender.username} has added you as a friend."

    content_type "text/html"
    body :sender => sender, :receiver => receiver, :controller => controller
  end

end
