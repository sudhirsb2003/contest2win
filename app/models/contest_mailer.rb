class ContestMailer < ActionMailer::Base

  def comment_added_notification(comment, controller)
    contest = comment.contest
    commentor = comment.user
    contest_creator = contest.user

    recipients contest_creator.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "#{commentor.username} has commented on your game"

    content_type "text/html"
    body :contest_creator => contest_creator, :contest => contest, :commentor => commentor, :controller => controller
  end

  def contest_added_notification(contest, controller)
    recipients contest.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w.com - Your #{contest.class} has been approved and is live."
    content_type "text/html"
    body :user => contest.user, :contest => contest, :controller => controller
  end

  def contest_rejected_notification(contest, controller)
    recipients contest.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "c2w - Your #{contest.class} was not approved."

    content_type "text/html"
    body :user => contest.user, :contest => contest, :controller => controller
  end

  def recommendation(recommendation, controller)
    from        AppConfig.notification_email_address
    recipients recommendation.from_email_address
    bcc recommendation.to_email_addresses
    headers 'reply-to' => recommendation.from_email_address
    subject "#{recommendation.from_name} wants you to play this game."

    content_type "text/html"
    body :recommendation => recommendation, :contest => recommendation.contest, :controller => controller
  end
  
  def contest_featured_notification(contest, controller)
    recipients contest.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Awesome! Your #{contest.class} has been featured."

    content_type "text/html"
    body :user => contest.user, :contest => contest, :controller => controller
  end
  
  def contest_prize_added_notification(contest_prize, controller)
    contest = contest_prize.contest
    prize = contest_prize.prize
    recipients contest.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Your game has a prize now."

    content_type "text/html"
    body :user => contest.user, :contest_prize => contest_prize, :prize => prize, :controller => controller
  end
  
  def contest_loyalty_enabled_notification(contest_region, controller)
    contest = contest_region.contest
    recipients contest.user.email
    from        AppConfig.notification_email_address
    bcc AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject "Your game on c2w has prize points now."

    content_type "text/html"
    body :user => contest.user, :contest_region => contest_region, :controller => controller
  end

  def copyright_violation(copyright_violation,controller)
    recipients  'copyright-issues@c2w.com'    
    from        copyright_violation.from_email_address
    bcc         AppConfig.default_bcc_address if AppConfig.default_bcc_address
    subject     "Copyright violation from #{copyright_violation.from_name}"
    content_type "text/html"
    body        :copyright_violation => copyright_violation, :contest => copyright_violation.contest, :controller => controller
  end
	
end
