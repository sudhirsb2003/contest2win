module C2W
  class Config
    mattr_accessor :safe_mode
  end

  class Error < RuntimeError
    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.error(self.to_s)
    end
  end

  class Authentication < Error; end
  class ActivationRequired < Error; end
end
