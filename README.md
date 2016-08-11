This is an iOS application to listen to podcast livestreams from Xenim Streaming Network.

## URL schemes and universal links

Universal links should be preferred as they redirect to the webpage if the app is not installed. Url schemes fail if the app is not installed.

For universal links to work the json file `apple-app-site-association` is required on the web server. The file needs to be accessible via HTTPS—without any redirects—at `https://<domain>/apple-app-site-association` or `https://<domain>/.well-known/apple-app-site-association`.

### Just open the app

* url scheme: `xenim://`
* universal link: none

### Start streaming a specific running event

* url scheme: `xenim://event/skejdcm3l45fj`
* universal link: `https://streams.xenim.de/event/skejdcm3l45fj`

### Show a podcast detail page

* url scheme: `xenim://podcast/slksdfjh234wd`
* universal link: `https://streams.xenim.de/podcast/slksdfjh234wd`