require 'abimporter/abimporter'

class ImportContactsController < ApplicationController
  layout 'popup'
  protect_from_forgery :except => [:fetch_contacts]

  CACHE = MemCache.new @@memcache_options
  CACHE.servers = @@memcache_servers
  def fetch_contacts
    begin
      raise 'Please enter your email id and password' if params[:email_id].blank? || params[:password].blank?
      contacts = ContactsImporter.import(params[:email_id], params[:password], params[:email_service])
      key = "#{params[:email_id]}/#{params[:email_service]}#{Time.now}".hash
      CACHE.set(key, contacts, 30.seconds)
      return redirect_to :action => :contacts, :key => key, :protocol => 'http'
    rescue Timeout::Error
      flash.now[:error] = "The service provider's server is taking too long to respond. Please try again after sometime."
    rescue Octazen::HttpError
      flash.now[:error] = 'Bad user name or password'
    rescue Octazen::CaptchaError
      flash.now[:error] = 'Bad user name or password'
    rescue
      flash.now[:error] = $!.to_s
      logger.error($!.to_s)
      logger.error($!.inspect)
    end
    render :action => :index
  end

  def contacts
    Octazen::Contact.new 'dummy','dummy'
    @contacts = CACHE.get(params[:key])
  end
end
