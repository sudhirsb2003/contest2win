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
#client_id = sys.argv[4]

# Set headers
headers = SOAPpy.Types.headerType()
headers.developer_email = dev_email
headers.developer_password = dev_password
#headers.client_id = client_id

# Set service connection
service = SOAPpy.SOAPProxy(
  server + "/api/adsense/v3/AccountService",
  namespace="http://www.google.com/api/adsense/v3",
  header=headers)
service.config.debug = 0

dummy = SOAPpy.Types.untypedType(name="id", data="0")

response = service.getDeveloperSiteData(dummy)

#print response['value']
print response
