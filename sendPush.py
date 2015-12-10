import json,httplib
connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()
connection.request('POST', '/1/push', json.dumps({
       "channels": [
         "en",
         "wasmitmedien"
       ],
       "data": {
         "alert": "Live soon!"
       }
     }), {
       "X-Parse-Application-Id": "8MWfUM4grO3NqKBxXqgxZ61JblY6PtbgrcM0d4f2",
       "X-Parse-REST-API-Key": "OxbsDT5VJ2UTaSdTwInFmr0rfMmj8kXeWecRwlAs",
       "Content-Type": "application/json"
     })
result = json.loads(connection.getresponse().read())
print result