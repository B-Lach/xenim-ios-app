import json,httplib,plistlib

podcast_name = "Breitband"
podcast_id = "breitband"
event_id = "13wfdbvkb123"

# setup parse connection
keys = plistlib.readPlist("Listen/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
parseRestAPIKey = keys["parseRestAPIKey"]
connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()

supported_locales = ["de-DE"]
message = podcast_name + " is live now."

for locale in supported_locales:
  # set message depending on locale
  # english is default
  if locale == "de-DE":
    message = podcast_name + " sendet jetzt live."
     
  connection.request('POST', '/1/push', json.dumps({
         # if the notification can not be delivered to the user until this point in time
         # it will not be delivered at all. this should be 'now + event.duration'
         "expiration_time": "2018-03-19T22:05:08Z",
         "where": {
           "channels": "podcast_" + podcast_id,
           "localeIdentifier": locale
         },
         "data": {
           "alert": message,
           "event_id": event_id,
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
  print "send push to " + locale
  print result

# also send a message to users with unsupported locales. use default message (english)
connection.request('POST', '/1/push', json.dumps({
       # if the notification can not be delivered to the user until this point in time
       # it will not be delivered at all. this should be 'now + event.duration'
       "expiration_time": "2018-03-19T22:05:08Z",
       "where": {
         "channels": "podcast_" + podcast_id,
         "localeIdentifier": {
           "$nin": supported_locales
         }
       },
       "data": {
         "alert": message,
         "event_id": event_id,
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
print "send push to all other locales"
print result


