class PrizeMailer < ActionMailer::Base

  def winner_short_listed_notification_no_tds(winner, controller)
    recipients winner.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - You have won a #{winner.contest_prize.prize.title}!"

    content_type "text/html"
    body :winner => winner, :controller => controller
  end

  def redemption_notification(dispatch, controller)
    prize = dispatch.prize
    recipients dispatch.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Contests2win.com - Congratulations! You have redeemed a #{prize.title}!"

    content_type "text/html"
    body :user => dispatch.user, :prize => prize, :controller => controller
  end

  def winner_short_listed_notification_to_us_user_for_cash_prize(winner, controller)
    recipients winner.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - You have won #{winner.contest_prize.prize.title}."

    content_type "text/html"
    body :winner => winner, :controller => controller
  end

  def winner_short_listed_notification_to_us_user_for_non_cash_prize(winner, controller)
    recipients winner.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - You have won a #{winner.contest_prize.prize.title}."

    content_type "text/html"
    body :winner => winner, :controller => controller
  end

  def winner_short_listed_notification_with_tds(winner, controller)
    recipients winner.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - You have won a #{winner.contest_prize.prize.title}!"

    content_type "text/html"
    body :winner => winner, :controller => controller
  end

  def winner_notification(winner, controller)
    recipients winner.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Congratulations #{winner.user.username}! You have won #{winner.contest_prize.prize.title}"

    content_type "text/html"
    body :winner => winner, :controller => controller
  end

  def prize_confirmed_notification(dispatch, controller)
    recipients AppConfig.prizes_email_address
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "#{dispatch.user.username} claimed prize #{dispatch.prize.title}"

    content_type "text/html"
    body :dispatch => dispatch, :controller => controller
  end

end
