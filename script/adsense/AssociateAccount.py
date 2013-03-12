#!/usr/bin/python
#
# Copyright 2006, Google Inc. All Rights Reserved.
 
###################################################################
# sample code to associate an Adsense account through Adsense API #
###################################################################

import sys
import SOAPpy

dev_email = sys.argv[1]
dev_password = sys.argv[2]
server = sys.argv[3]
loginEmail = sys.argv[4]
postalCode = sys.argv[5]
phoneHint = sys.argv[6]
developerUrl = sys.argv[7]

#server = "https://sandbox.google.com"

#dev_email = "REPLACE WITH DEVELOPER EMAIL"
#dev_password = "REPLACE WITH DEVELOPER PASSWORD"

# Set headers
headers = SOAPpy.Types.headerType()
headers.developer_email = dev_email
headers.developer_password = dev_password
headers.client_id = "will be ignored"


# Set service connection
service = SOAPpy.SOAPProxy(
  server + "/api/adsense/v3/AccountService",
  namespace="http://www.google.com/api/adsense/v3",
  header=headers)
# To view xml request/response set service.config.debug = 1
service.config.debug = 0

# Set the parameters
login_email = SOAPpy.Types.untypedType(name="loginEmail",
                                      data=loginEmail)
postal_code = SOAPpy.Types.untypedType(name="postalCode",data=postalCode)
phone = SOAPpy.Types.untypedType(name="phone",data=phoneHint)
developer_url = SOAPpy.Types.untypedType(name="developerUrl",
                                        data=developerUrl)

try:
  response = service.associateAccount(
                login_email,
                postal_code,
                phone,
                developer_url
              )
except SOAPpy.Types.faultType, fault:
  #print "Fault!"
  #print "  trigger :",fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['trigger']
  #print "  message :",fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['message']
  #print "  code :",fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['code']
  print "Fail|"+fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['message']+"|"+fault['detail']['AdSenseApiExceptionFault']['AdSenseApiException']['code']
  exit(1)

# Print results
#print "Adsense account association successful"
if type(response)==list:
  for i in response:
    #print "account type :",i['type']['value']
    #print "  syn id :",i['id']
    if i['type']['value'] == 'ContentAds':
 	    print "Success|"+i['id']
else:
  #print "account type :",response['type']['value']
  #print "  syn id :",response['id']
  print "Success|"+response['id']
