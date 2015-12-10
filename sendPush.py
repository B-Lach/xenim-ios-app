import json,httplib,plistlib

keys = plistlib.readPlist("Listen/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
parseRestAPIKey = keys["parseRestAPIKey"]

connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()
connection.request('POST', '/1/push', json.dumps({
       "where": {
         "channels": "wasmitmedien",
         "localeIdentifier": "de-DE"
       },
       "data": {
         "alert": "Live soon!"
       }
     }), {
       "X-Parse-Application-Id": parseApplicationID,
       "X-Parse-REST-API-Key": parseRestAPIKey,
       "Content-Type": "application/json"
     })
print connection.request
result = json.loads(connection.getresponse().read())
print result


