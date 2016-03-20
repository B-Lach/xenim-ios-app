import json,httplib,plistlib

podcast_name = "Funkenstrahlen"
podcast_id = "c4123648-b697-4093-bbcd-d79d1ff6b558"
event_id = "0edbb110-c1c4-46fb-a0a4-4741f07f7b13"

# setup parse connection
keys = plistlib.readPlist("Xenim/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
parseRestAPIKey = keys["parseRestAPIKey"]
parseMasterKey = keys["parseMasterKey"]
connection = httplib.HTTPSConnection('dev.push.xenim.de', 443)
connection.connect()

supported_locales = ["de-DE"]
message = podcast_name + " is live now."

for locale in supported_locales:
  # set message depending on locale
  # english is default
  if locale == "de-DE":
    message = podcast_name + " sendet jetzt live."
     
  connection.request('POST', '/parse/push', json.dumps({
         # if the notification can not be delivered to the user until this point in time
         # it will not be delivered at all. this should be 'now + event.duration'
         "expiration_time": "2018-03-19T22:05:08Z",
         "where": {
           "deviceType": {
              "$in": ["ios"]
            },
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
         "X-Parse-Master-Key": parseMasterKey,
         "Content-Type": "application/json"
       })
  result = json.loads(connection.getresponse().read())
  print "send push to " + locale
  print result

# also send a message to users with unsupported locales. use default message (english)
connection.request('POST', '/parse/push', json.dumps({
       # if the notification can not be delivered to the user until this point in time
       # it will not be delivered at all. this should be 'now + event.duration'
       "expiration_time": "2018-03-19T22:05:08Z",
       "where": {
         "deviceType": {
            "$in": ["ios"]
          },
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
       "X-Parse-Master-Key": parseMasterKey,
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print "send push to all other locales"
print result


