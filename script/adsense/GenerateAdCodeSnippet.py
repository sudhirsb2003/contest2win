#!/usr/bin/python
#
# Copyright 2006, Google Inc. All Rights Reserved.

#####################################################################
# Sample code to add a generate ad code snippet through Adsense API #
#####################################################################

import sys
import SOAPpy

dev_email = sys.argv[1]
dev_password = sys.argv[2]
server = sys.argv[3]
client_id = sys.argv[4]
banner_size = sys.argv[5]

# Set headers
headers = SOAPpy.Types.headerType()
headers.developer_email = dev_email
headers.developer_password = dev_password
headers.client_id = client_id

# Set service connection
service = SOAPpy.SOAPProxy(
  server + "/api/adsense/v3/AccountService",
  namespace="http://www.google.com/api/adsense/v3",
  header=headers)
# To view xml request/response set service.config.debug = 1
service.config.debug = 0

syn_service_type = SOAPpy.Types.structType(name="synServiceTypes")
syn_service_type._addItem(name="value",value="ContentAds")

# Get the Syndication ID
# Might throw a soap exception on user input or error upon trying to connect
response = service.getSyndicationService(syn_service_type)
syn_id = response["id"]
#print "syn id :", syn_id
#print

# Set another service connetion
service = SOAPpy.SOAPProxy(
  server + "/api/adsense/v3/AdSenseForContentService",
  namespace="http://www.google.com/api/adsense/v3",
  header=headers)
service.config.debug = 0

# Set up the ad style
ad_style_template = """
  <backgroundColor>%s</backgroundColor>
  <borderColor>%s</borderColor>
  <name>%s</name>
  <textColor>%s</textColor>
  <titleColor>%s</titleColor>
  <urlColor>%s</urlColor>
  """

ad_style = ad_style_template % ('#FFFFFF', '#000000', '',
                                '#000000', '#000000', '#FFFF00')
ad_style = SOAPpy.Types.untypedType(name="adStyle",data=ad_style)
#ad_style._setAttr(
#  'xmlns:impl', 
#  'http://www.google.com/api/adsense/v3')
#ad_style._setAttr('xsi:type', 'impl:AdStyle')

# Set up other parameters
syn_service_id = SOAPpy.Types.untypedType(name="synServiceId",data=syn_id)
ad_unit_type = SOAPpy.Types.structType(name="adUnitType")
ad_unit_type._addItem(name="value",value="TextOnly")
layout = SOAPpy.Types.structType(name="adLayout")
layout._addItem(name="value",value=banner_size)
#layout._addItem(name="value",value="300x250")
#alternate = SOAPpy.Types.untypedType(name="alternate",data="#FFFFFF")
alternate = SOAPpy.Types.untypedType(name="alternate",data="")
is_framed_page = SOAPpy.Types.untypedType(name="isFramedPage",data="False")
channel_name = SOAPpy.Types.untypedType(name="channelName",data="")
corner_styles = SOAPpy.Types.structType(name="cornerStyles")
corner_styles._addItem(name="value",value="DEFAULT")

# Generate ad code, might throw a soap exception
# on user input or error upon trying to connect
response = service.generateAdCode(syn_service_id, ad_style, ad_unit_type,
                                  layout, alternate, is_framed_page,
                                  channel_name,corner_styles)

print response
