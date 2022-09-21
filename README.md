# Web Requestor Edge Driver

Issue POST and GET HTTP Requests from the SmartThings mobile app.  Requests can be any valid http request string and can include a body and specified headers.

There are two ways this driver can be used:

* Configure up to 50 different POST/GET/PUT requests, which can then be individually triggered through Automations/Rules or via a button in the mobile app.
* Issue custom URL POST/GET commands from within a Rule

### Limitations

The Edge platform limits communication to IP addresses on your local LAN only.  However I have a bridge server program that can be run on any always-on computer (Windows/Linux/Mac/Raspberry Pi) on your LAN that can overcome this.  See https://github.com/toddaustin07/edgebridge for more details.

## Instructions

Access my [shared channel](https://api.smartthings.com/invitation-web/accept?id=cc2197b9-2dce-4d88-b6a1-2d198a0dfdef) invitation, enroll your hub, and select the ‘Web Requestor Multi V1.0’ driver.


When the driver gets installed onto your hub, you can do an *Add device / Scan for nearby devices* and a new device called ‘Web Req Multi Master’ will be created in your ‘No room assigned’ room.

### Setting up pre-configured web requests

Go to the device Controls screen of Web Requestor and go into device Settings by tapping the 3 vertical dots in the upper right corner of the screen. Here you can configure up to 50 web requests. The format **MUST** be:
```
GET:http://<ip:port/path> --OR-- POST:http://<ip:port/path> --OR-- PUT:http://<ip:port/path>
  -- OR --
GET:https://<ip:port/path> --OR-- POST:https://<ip:port/path> --OR-- PUT:https://<ip:port/path>
```
#### Notes regarding URL string

* You must include a valid IP *and* port number; if you wouldn’t specify a port number in other apps or a browser, then use ‘:80’
* If your URL contains any spaces, use ‘%20’
* Each request ‘slot’ has a default example string you can modify; note that any slot can be GET, POST, or PUT regardless of the preloaded example 
* URL strings can include any valid HTTP URL string, including parameters in the form of '?parm1=xxx'

#### Request Body (optional)

If you need to include a body with your http request, the first 5 configurable slots allow you to include this.  This is typically going to be provided as a valid JSON or XML string, however no syntax or formatting validation is done on this field.  If the needed body exceeds the limitations of this field, a second body field is provided which will be contatenated to the first when the request is sent.

#### Headers (optional)

Also included with the first 5 configurable slots is a Settings field to specify any required HTTP headers.  They should be provided in a comma-delimited list in the form of \<*headerkey*\>=\<*value*\>.  For example:
```
Content-Type=text/html, Authorization=mytoken12345
```
- Note the use of the '**=**' character between headerkey and value; *not* ':'
- Note this dis-allows the use of any additional comma characters in the header values themselves.
- Spaces are allowed in the value (although not in the headerkey).  For example: 'Authorization=Bearer mytokenabcd1234'

If a body is included in the request, then a Content-Type header should be specified.

Note that all requests are sent with an Accept: \*/\* by default.

#### Response Timeout
As a default, the driver will timeout if no response is received within 3 seconds.  However this can be changed in the *Response Timeout* Settings option.

### Executing your Requests

After you have saved some web requests, return to the device Controls screen and tap the button labeled ‘Select web request to execute’. Then select the corresponding request number and your web request will be sent.

If the web request number (1-50) you selected has not been configured with a valid URL string, a 'Not Configured' message will be briefly displayed.

Once the request has been sent, the HTTP response code will be displayed in the corresponding field (200, 401, etc)

**Non-HTTP errors** will also be displayed in the HTTP Response Code field, but will always be preceeded by '\*\*' (two asterisks).  Possible values are:
- \*\*Timeout: the URL used likely doesn't exist (the timeout duration can be chosen in device Settings as described above, but defaults to 3 seconds)
- \*\*No response: no acknowledgement from server; it didn’t recognize the request
- \*\*Refused: connection was refused (no application at given port)
- \*\*Failed: the request could not be executed for various other reasons, e.g. socket error, etc.

Response data returned from the HTTP request will be shown in the HTTP Response Data field.  If the HTTP response data is XML, JSON, or HTTP data, then the SmartThings mobile app will try to format it as such when it is displayed.

Note that a limitation of 1024 characters has been placed on displayed and stored response data.

#### Extracting a key value

To make it possible for Rules to act on the returned data, there is a Settings option that allows you to specify the XML or JSON key for a single expected value in the response data.  If this Settings option is configured, the key will be searched for in the returned HTTP data and if found, the corresponding value will be displayed in the field labeled 'Extracted key value' on the device details screen.

### Creating multiple SmartThings Web Requestor Devices
Multiple SmartThings devices can be created to facilitate building automations/rules around an individual SmartThings device’s HTTP request(s). A button is included in the Master device’s Controls screen to create a new device. Each additional device created can be configured with up to 50 web requests, and includes all the same Settings options as the Master device.

### Using custom HTTP requests from Automations or Rules

If you want to execute an 'on-the-fly' custom web request URL, this can be done with either Automations or Rules.  In Automations, in the mobile app simply select the desired Action of GET or POST, and provide the URL string in the blank field provided.

For Rules, here is an example of how this would be done:
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
                      "string": "http://192.168.1.104:1755/tts_SCPD.xml{{^}}some request body data can go here"
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
Issue a command of **GET** or **POST** to the **partyvoice23922.webrequest** capability of the web requestor device, and specify an argument string containing the URL.

A body can also be included in these argument strings.  The characters **{{^}}** in the GET or POST command argument will serve as a delimiter between the request head and request body.

Custom headers can be configured in the device Settings field labled 'Automation-generated Request Headers'.  Follow the same format as that specified above for pre-configured requests (comma-delimited string of \<*headerkey*\>=\<*value*\> pairs).
