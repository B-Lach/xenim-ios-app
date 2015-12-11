import json,httplib,plistlib

keys = plistlib.readPlist("Listen/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
parseRestAPIKey = keys["parseRestAPIKey"]

connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()
connection.request('POST', '/1/push', json.dumps({
       # if the notification can not be delivered to the user until this point in time
       # it will not be delivered at all. this should be 'now + event.duration'
       "expiration_time": "2018-03-19T22:05:08Z",
       "where": {
         "channels": "breitband",
         "localeIdentifier": "de-DE"
       },
       "data": {
         "alert": "Event XYZ is live now.",
         "event_id": "13wfdbvkb123",
         "badge": "1",
         "category": "EVENT_LIVE_NOW_CATEGORY",
         "sound": "ios_defaultsound.caf"
       }
     }), {
       "X-Parse-Application-Id": parseApplicationID,
       "X-Parse-REST-API-Key": parseRestAPIKey,
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print result


