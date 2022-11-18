# Web Requestor Edge Driver

Issue HTTP Requests (POST/GET/PUT) SmartThings mobile app or automations.  Requests can be any valid http request string and can include a body and specified headers.

There are three ways this driver can be used:

* Pre-configure up to 50 different POST/GET/PUT requests, which can then be individually triggered through Automations/Rules or via a button in the mobile app.
* Issue custom URL POST/GET commands from within a Rule
* Issue custom URL POST/GET commands via the SmartThings RESTful API

### Limitations

The Edge platform limits communication to IP addresses on your local LAN only.  However I have a bridge server application that can be run on any always-on computer (Windows/Linux/Mac/Raspberry Pi) on your LAN that can overcome this.  See https://github.com/toddaustin07/edgebridge for more details.

## Instructions

Access my [shared channel](https://api.smartthings.com/invitation-web/accept?id=cc2197b9-2dce-4d88-b6a1-2d198a0dfdef) invitation, enroll your hub, and select the ‘Web Requestor Multi V1.2’ driver.


When the driver gets installed onto your hub, you can do an *Add device / Scan for nearby devices* and a new device called ‘Web Req Multi Master’ will be created in your ‘No room assigned’ room.

### Setting up pre-configured web requests

Go to the device Controls screen of Web Requestor and go into device Settings by tapping the 3 vertical dots in the upper right corner of the screen. Here you can configure up to 50 web requests. The format **MUST** be:
```
GET:http://<ip:port/path> --OR-- POST:http://<ip:port/path> --OR-- PUT:http://<ip:port/path>
  -- OR --
GET:https://<ip:port/path> --OR-- POST:https://<ip:port/path> --OR-- PUT:https://<ip:port/path>
```
#### Notes regarding URL string

* You must include a valid IP *and* port number; if you don't specify a port number, then port 80 will be used by default
* If your URL string contains any spaces, they will be automatically replaced with ‘%20’
* Each request ‘slot’ has a default example string you can modify; note that any slot can be GET, POST, or PUT regardless of the preloaded example 
* URL strings can include any valid HTTP URL string, including parameters in the form of '?parm1=xxx'

#### Request Body (optional)

If you need to include a body with your http request, the first 5 configurable slots allow you to include this.  This is typically going to be provided as a valid JSON or XML string, however no syntax or formatting validation is done on this field.  If the needed body exceeds the limitations of this field, a second body field is provided which will be contatenated to the first when the request is sent.

#### Headers (optional)

Also included with the first 5 configurable slots is a Settings field to specify any needed HTTP headers.  They should be provided in a comma-delimited list in the form of \<*headerkey*\>=\<*value*\>.  For example:
```
Content-Type=text/html, Authorization=mytoken12345
```
- Note the use of the '**=**' character between headerkey and value; *not* ':'
- Note this precludes the use of any additional comma characters in the header values themselves.
- Spaces are allowed in the value (although not in the headerkey).  For example: 'Authorization=Bearer mytokenabcd1234'

If a body is included in the request, then a Content-Type header should be specified.  A Content-Length header is automatically included by the driver, so does not need to be explicitly provided.

Note that all requests are sent with an Accept: \*/\* by default.  This can be over-ridden by providing your own Accept header.

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

To make it possible for Rules to act on the returned data, there is a Settings option that allows you to specify a key for a single expected value in JSON or XML response data.  If this Settings option is configured, the key will be used to extract the corresponding value, which will be displayed in the field labeled 'Extracted key value' on the device Controls screen.

##### Key format
The format of the key is dot-notation and can include indexes where arrays may be present in the response data.

Examples:
```
temperature
temperature.value
temperatures[2].probe.celcius
```
Note that an array index of 0 indicates the first element.

### Creating multiple SmartThings Web Requestor Devices
Multiple SmartThings devices can be created to facilitate building automations/rules around an individual SmartThings device’s HTTP request(s). A button is included in the **Master** device’s Controls screen to create a new device. Each additional device created can be configured with up to 50 web requests, and includes all the same Settings options as the Master device.

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

A request *body* can also be included in the argument string.  The characters **{{^}}** in the GET or POST command argument will serve as a delimiter between the request URL and request body.  For example:

```
POST:http//192.168.1.75:4444/api?cmd=setvalue{{^}}{"value": "16.3"}
```
Where *{"value": "16.3"}* is the body data.

Custom headers to be used for 'on-the-fly' requests can be configured in the device Settings field labled 'Automation-generated Request Headers'.  Follow the same format as that specified above for pre-configured requests (comma-delimited string of \<*headerkey*\>=\<*value*\> pairs).

### Using custom HTTP requests from the RESTful API
The SmartThings RESTful API has an endpoint that allows you to send commands to devices.  This can be used in this case to have a webrequestor device send an HTTP GET or POST request.  The URL request string, body, and headers are provided as individual arguments in the API call to the *partyvoice23922.apiwebrequest* capability contained in the webrequestor device.

Here is an example:
```
POST https://api.smartthings.com/v1/devices/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/commands

with body:
{
  "commands": [
    {
      "component": "main",
      "capability": "partyvoice23922.apiwebrequest",
      "command": "GET",
      "arguments": [
        "http://192.168.1.140:6666/path?parm=some supercool parameter",
        "this is some body data",
        "Content-Type=text/html"
      ]
    }
  ]
}
```
Where:
* xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx would be the SmartThings deviceId of the target webrequestor device
* RESTful API request body JSON contains:
  * *component* and *capability* must be exactly as shown
  * *command* must be GET or POST
  * *arguments* array must include, **in order**, the URL string, optional body, and optional headers (headers follow required format explained above)

These RESTful API calls must of course also include an Authorization header with the user's Personal Access Token.

### Diagnosing problems
A windows application is included in this package called simpleserv.exe.  It can be run on a Windows 10 computer and will display http requests received on port 6666.  You can redirect your web requests temporarily to your Windows computer IP and port 6666 to make sure they are being sent as you expect.  The app always returns an HTTP 200 OK response for a properly formatted HTTP request.
