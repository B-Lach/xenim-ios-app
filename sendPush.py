import json,httplib,plistlib

podcast_name = "Lage der Nation"
podcast_id = "498a7c0e-9fe7-45f3-8ec0-373d815983ab"

# setup parse connection
keys = plistlib.readPlist("Xenim/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
# parseRestAPIKey = keys["parseRestAPIKey"]
parseMasterKey = keys["parseMasterKey"]
connection = httplib.HTTPSConnection('dev.push.xenim.de', 443)
connection.connect()

message = podcast_name + " sendet jetzt live."

connection.request('POST', '/parse/push', json.dumps({
       "where": {
         "channels": "podcast_" + podcast_id
       },
       "data": {
         "alert": message,
         "badge": 1,
         "sound": "ios_defaultsound.caf"
       }
     }), {
       "X-Parse-Application-Id": parseApplicationID,
       # "X-Parse-REST-API-Key": parseRestAPIKey,
       "X-Parse-Master-Key": parseMasterKey,
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print result


