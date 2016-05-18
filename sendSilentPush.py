import json,httplib,plistlib

# setup parse connection
keys = plistlib.readPlist("Xenim/Keys.plist")
parseApplicationID = keys["parseApplicationID"]
# parseRestAPIKey = keys["parseRestAPIKey"]
parseMasterKey = keys["parseMasterKey"]
connection = httplib.HTTPSConnection('push.xenim.de', 443)
connection.connect()

connection.request('POST', '/parse/push', json.dumps({
       "where": {

       },
       "data": {

       }
     }), {
       "X-Parse-Application-Id": parseApplicationID,
       # "X-Parse-REST-API-Key": parseRestAPIKey,
       "X-Parse-Master-Key": parseMasterKey,
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print result


