module AccountHelper
  def account_link(options)
    account_path(options)
  end

  def sign_up_link(label = 'Sign-up', referer = nil)
    link_to 'Sign-up', account_path(:action => :register, :ref => request.url)
  end

end
