# Web Requestor Edge Driver

Issue POST and GET HTTP Requests from the SmartThings mobile app

There are two ways this driver can be used:

* Configure up to 50 different POST/GET requests, which can then be individually triggered through Automations/Rules or via a button in the mobile app.
* Issue custom URL POST/GET commands from within a Rule

### Limitations

The Edge platform limits communication to IP addresses on your local LAN only.  However I have a bridge server program that can be run on any always-on computer (Windows/Linux/Mac) on your LAN that can overcome this.  See xxxxx for more details.

## Instructions

Use the link below to access my shared channel, enroll your hub, and select the ‘Web Requestor Multi V1.0’ driver.
https://api.smartthings.com/invitation-web/accept?id=cc2197b9-2dce-4d88-b6a1-2d198a0dfdef

When the driver gets installed onto your hub (up to 12 hours), you can do an Add device / Scan nearby and a new device called ‘Web Req Multi Master’ will be created in your ‘No room assigned’ room.

### Setting up pre-configured web requests

Go to the device details screen of Web Requestor and go into device Settings by tapping the 3 vertical dots in the upper right corner of the screen. Here you can configure up to 50 web requests. The format **MUST** be:
```
POST:http://<ip:port/path> --OR-- GET:http://<ip:port/path>
  -- OR --
POST:https://<ip:port/path> --OR-- GET:https://<ip:port/path>
```
#### Notes regarding URL string

* You must include a valid IP and port number; if you normally don’t include port number in other apps or a browser, use ‘:80’
* If your URL contains any spaces, use ‘%20’
* Each request ‘slot’ has a default example string you can modify; note that any slot can be either POST or GET regardless of the preloaded example 
* URL strings can include any valid HTTP URL string, including parameters in the form of '?parm1=xxx'

After you have saved some web requests, return to the device details screen and tap the button labeled ‘Select web request to execute’. Then select the corresponding request number and your web request will be sent.

If the web request number (1-50) you selected has not been configured with a valid URL string, a 'Not Configured' message will be briefly displayed.

Once the request has been sent, the HTTP response code will be displayed in the corresponding field (200, 401, etc)

**Non-HTTP errors** will also be displayed in the HTTP Response Code field, but will always bed preceeded by '\*\*' (two asterisks).  Possible values are:
- \*\*Timeout: the URL used likely doesn't exist; there is a 3-second timeout for all HTTP requests
- \*\*No response: no acknowledgement from server; it didn’t recognize the request
- \*\*Refused: connection was refused (no application at give port)
- \*\*Failed: the request could not be executed for various other reasons, e.g. socket error, etc.

Response data returned from the HTTP request will be shown in the HTTP Response Data field.  If the HTTP response data is XML, JSON, or HTTP data, then SmartThings will try to format it as such when it is displayed.

#### Extracting a key value

To make it possible for Rules to act on the returned data, there is a Settings option that allows you to specify the XML or JSON key for a single expected value in the response data.  If this Settings option is configured, the key will be searched for in the returned HTTP data and if found, the corresponding value will be displayed in the field labeled 'Extracted key value' on the device details screen.

### Creating multiple Web Requestor Devices
Multiple web requestor devices can be created to facilitate building automations/rules around an individual device’s web request(s). A button is included in each device’s details screen to create a new device. Each device can be configured with up to 50 web requests, and includes the option to specify a key for JSON and XML value extraction.

### Creating Rules with custom HTTP requests

If you want to specify an 'on-the-fly' custom web request URL in a Rule, here is an example of how that would be done:
```
{
  "name": "Test Web Requestor",
  "actions": [
    {
      "if": {
        "equals": {
          "left": {
            "device": {
              "devices": [
                "4c4f0e69-2542-4a05-83bf-1dfa0f0ccaad"
              ],
              "component": "main",
              "capability": "presenceSensor",
              "attribute": "presence"
            }
          },
          "right": {
            "string": "present"
          }
        },
        "then": [
          {
            "command": {
              "devices": [
                "3b70d48d-d458-472e-befd-e18afd173382"
              ],
              "commands": [
                {
                  "component": "main",
                  "capability": "partyvoice23922.webrequest",
                  "command": "GET",
                  "arguments": [
                    {
                      "string": "http://192.168.1.104:1755/tts_SCPD.xml"
                    }
                  ]
                }
              ]
            }
          }
        ]
      }
    }
  ]
}
```
