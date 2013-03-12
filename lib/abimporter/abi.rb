#********************************************************************************
#Copyright 2008 Octazen Solutions
#All Rights Reserved
#
#You may not reprint or redistribute this code without permission from Octazen Solutions.
#
#WWW: http://www.octazen.com
#Email: support@octazen.com
#********************************************************************************

$:.unshift(File.dirname(__FILE__))

# This is the entrypoint to the library

module Octazen
  #This will hold hash of domain name to importer class name
  DOMAIN_IMPORTERS = {}
end


require 'abiconfig'
require 'abimporter'


# Dynamically load available importers

def load_if_exist (path)
  begin
    require(path)
    Octazen::Logging.debug("Loaded #{path}")
  rescue LoadError
    #Library not present
  end
end

#Contacts Importer Bundle 1
load_if_exist('hotmail.rb')
load_if_exist('aol.rb')
load_if_exist('gmail.rb')
load_if_exist('yahoo.rb')
load_if_exist('linkedin.rb')

#Contacts Importer Bundle 3
load_if_exist('plaxo.rb')
