#! /bin/bash
curl -X POST \
  -H "X-Parse-Application-Id: oogha5shae9eisie7vagoo7thoo6eequ4via6ash9Eis5Wah9u" \
  -H "X-Parse-Master-Key: ish5aic1ohtah2aeg6ohPiacieshiec0Chau0laiSh4taipae4" \
  -H "Content-Type: application/json" \
  -d '{
        "where": {
          "deviceType": {
            "$in": [
              "ios"
            ]
          }
        },
        "data": {
          "title": "The Shining",
          "alert": "All work and no play makes Jack a dull boy."
        }
      }'\   https://dev.push.xenim.de/parse/push