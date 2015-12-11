import json,httplib,plistlib

keys = plistlib.readPlist("Listen/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
parseRestAPIKey = keys["parseRestAPIKey"]

connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()
connection.request('POST', '/1/push', json.dumps({
       #"expiration_time": "2015-03-19T22:05:08Z",
       "where": {
         "channels": "breitband",
         "localeIdentifier": "de-DE"
       },
       "data": {
         "alert": "Event XYZ is live now.",
         "badge": "1",
         "category": "EVENT_CATEGORY",
         "sound": "ios_defaultsound.caf",
         "event_id": "13wfdbvkb123"
       }
     }), {
       "X-Parse-Application-Id": parseApplicationID,
       "X-Parse-REST-API-Key": parseRestAPIKey,
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print result


