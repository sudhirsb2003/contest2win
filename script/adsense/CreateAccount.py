#!/usr/bin/python
#
# Copyright 2006, Google Inc. All Rights Reserved.
 
################################################################
# sample code to create an Adsense account through Adsense API #
################################################################

import sys
import SOAPpy

dev_email = sys.argv[1]
dev_password = sys.argv[2]
server = sys.argv[3]
loginEmail = sys.argv[4]
not_associated = sys.argv[5]
profile_url = sys.argv[6]
developerUrl = sys.argv[7]

# Set headers
headers = SOAPpy.Types.headerType()
headers.developer_email = dev_email
headers.developer_password = dev_password
if not_associated == "true":
  headers.client_id = "will be ignored"
  headers.debug_zip = "400057"
  headers.debug_phone = "47935"
  headers.debug_association_type = "NotAssociated"
  #headers.debug_association_type = "Active"
#else:
  #headers.debug_association_type = "Active"

# Set service connection
service = SOAPpy.SOAPProxy(
  server + "/api/adsense/v3/AccountService",
  namespace="http://www.google.com/api/adsense/v3",
  header=headers)
# To view xml request/response set service.config.debug = 1
service.config.debug = 0

# Set the parameters
login_email = SOAPpy.Types.untypedType(name="loginEmail", data=loginEmail)
entity_type = SOAPpy.structType(name="entityType")
entity_type._addItem("value","Individual")
website_url = SOAPpy.Types.untypedType(name="websiteUrl", data=profile_url)
website_locale = SOAPpy.Types.untypedType(name="websiteLocale", data="en")
users_preferred_locale = SOAPpy.Types.untypedType(name="usersPreferredLocale", data="en_US")
email_promotion_preferences = SOAPpy.Types.untypedType(name="emailPromotionsPreference", data="true")

syn_service_types0 = SOAPpy.structType(name="synServiceTypes")
syn_service_types0._addItem(name="value",value="ContentAds")
syn_service_types1 = SOAPpy.structType(name="synServiceTypes")
syn_service_types1._addItem(name="value",value="SearchAds")

developer_url = SOAPpy.Types.untypedType(name="developerUrl", data=developerUrl)

# Create an adsense account, might throw a soap exception
# on user input or error upon trying to connect
try:
  response = service.createAccount(
               login_email,
               entity_type,
               website_url,
               website_locale,
               users_preferred_locale,
               email_promotion_preferences,
               syn_service_types0,
               #syn_service_types1,
               developer_url
             )
except SOAPpy.Types.faultType, fault:
  print "Fail|"+fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['message']+"|"+fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['code']
  sys.exit(1)

# Print results
#print "Adsense account creation successful"
if type(response)==list:
  for i in response:
    print "account type :",i['type']['value']
    print "  syn id :",i['id']
else:
  #print "account type :",response['type']['value']
  #print "  syn id :",response['id']
  print "Success|"+response['id']
