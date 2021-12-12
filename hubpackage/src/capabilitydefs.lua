local select_cap = [[
{
    "id": "partyvoice23922.webrequestselect",
    "version": 1,
    "status": "proposed",
    "name": "webrequestselect",
    "attributes": {
        "selection": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string",
                        "maxLength": 16
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "setter": "setSelection",
            "enumCommands": []
        }
    },
    "commands": {
        "setSelection": {
            "name": "setSelection",
            "arguments": [
                {
                    "name": "value",
                    "optional": false,
                    "schema": {
                        "type": "string",
                        "maxLength": 16
                    }
                }
            ]
        }
    }
}
]]

local requestcmd_cap = [[
{
    "id": "partyvoice23922.webrequest",
    "version": 1,
    "status": "proposed",
    "name": "WebRequest",
    "attributes": {},
    "commands": {
        "POST": {
            "name": "POST",
            "arguments": [
                {
                    "name": "url",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        },
        "GET": {
            "name": "GET",
            "arguments": [
                {
                    "name": "url",
                    "optional": false,
                    "schema": {
                        "type": "string"
                    }
                }
            ]
        }
    }
}
]]

local httpcode_cap = [[
{
    "id": "partyvoice23922.httpcode",
    "version": 1,
    "status": "proposed",
    "name": "httpcode",
    "attributes": {
        "httpcode": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {}
}
]]


local response_cap = [[
{
    "id": "partyvoice23922.httpresponse",
    "version": 1,
    "status": "proposed",
    "name": "httpresponse",
    "attributes": {
        "response": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {}
}
]]

local keyvalue_cap = [[
{
    "id": "partyvoice23922.keyvalue",
    "version": 1,
    "status": "proposed",
    "name": "keyvalue",
    "attributes": {
        "keyvalue": {
            "schema": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "additionalProperties": false,
                "required": [
                    "value"
                ]
            },
            "enumCommands": []
        }
    },
    "commands": {}
}
]]

local createdev_cap = [[
{
    "id": "partyvoice23922.createanother",
    "version": 1,
    "status": "proposed",
    "name": "createanother",
    "attributes": {},
    "commands": {
        "push": {
            "name": "push",
            "arguments": []
        }
    }
}
]]

return {
		select_cap = select_cap,
        requestcmd_cap = requestcmd_cap,
        response_cap = response_cap,
        httpcode_cap = httpcode_cap,
        keyvalue_cap = keyvalue_cap,
        createdev_cap = createdev_cap,
}
