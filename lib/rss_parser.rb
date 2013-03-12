class RSSParser
  require 'rexml/document'
  require 'timeout'
  def self.run(url, timeout = 5)
    begin
      xml = nil
      Timeout::timeout(timeout) do
        xml = REXML::Document.new Net::HTTP.get(URI.parse(url))
      end
      data = {
      :title    => xml.root.elements['channel/title'].text,
      :home_url => xml.root.elements['channel/link'].text,
      :rss_url  => url,
      :items    => []
      }
      xml.elements.each '//item' do |item|
      new_items = {} and item.elements.each do |e| 
          new_items[e.name.gsub(/^dc:(\w)/,"\1").to_sym] = e.text
      end
      data[:items] << new_items
      end
      data
    rescue Timeout::Error
        return {}
    rescue
        return {}
    end
  end
end
