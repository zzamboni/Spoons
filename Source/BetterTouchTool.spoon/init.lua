--- === BetterTouchTool ===
---
--- Interface with the BetterTouchTool API
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BetterTouchTool.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/BetterTouchTool.spoon.zip)

local obj={}
obj.__index = obj

-- Metadata
obj.name = "BetterTouchTool"
obj.version = "0.1"
obj.author = "Diego Zamboni <diego@zzamboni.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- BetterTouchTool.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('BetterTouchTool')

--- BetterTouchTool:update_trigger(uuid, payload)
--- Method
--- Raw wrapper around the BTT `update_trigger` API call to update any BTT trigger object.
---
--- Parameters:
---  * uuid - A string containing the UUID of the BTT object to update. Can be obtained from the BTT window by right-clicking on the object and choosing "Copy UUID"
---  * payload - A table containing the fields to pass. The fields are object-dependent, the easiest way to learn them is to right-click on an object of the desired type and choose "Copy JSON to clipboard"
---
--- Returns:
---  * The return values from [hs.osascript.applescript](http://www.hammerspoon.org/docs/hs.osascript.html#applescript) on the execution of the AppleScript code to the update_trigger BTT method.
function obj:update_trigger(uuid, payload)
  local json_str = hs.json.encode(payload):gsub([[\]], [[\\]]):gsub([["]], [[\"]])
  local code = [[tell application "BetterTouchTool" to update_trigger "]] .. uuid .. [[" json "]] .. json_str .. [["]]
  return hs.osascript.applescript(code)
end

--- BetterTouchTool:btticondata_from_hsimage(image)
--- Method
--- Return the base64-encoded version of an hs.image object.
---
--- Parameters:
---  * image - An [http://www.hammerspoon.org/docs/hs.image.html](hs.image) object.
---
--- Returns:
---  * A string containing the base64-encoded image.
function obj:btticondata_from_hsimage(img)
  return img:encodeAsURLString():gsub("^data:image/png;base64,", "")
end

--- Convert a color from 0.0-1.0 (used by Hammerspoon) to RGB's 0-255
function _1_255(num)
  return num*255.0
end

--- Convert a Hammerspoon hs.color object to a color string as used by BTT: "R, G, B, G" (each in 0-255 range, floating-point numbers)
function _hscolor_to_rgb(color)
  if type(color) == 'table' then
    local c = hs.drawing.color.asRGB(color)
    return string.format("%.6f, %.6f, %.6f, %.6f", _1_255(c.red), _1_255(c.green), _1_255(c.blue), _1_255(c.alpha))
  else
    return color
  end
end

--- BetterTouchTool:touchbar_button(uuid, spec)
--- Method
--- Update a BTT TouchBar button definition
---
--- Parameters:
---  * uuid - UUID of the BTT object to update. Can be obtained from the BTT window by right-clicking on the desired object and choosing "Copy UUID". Can be `nil` if `spec` contains a `uuid` field.
---  * spec - table containing the specification for the object. Can contain the following fields:
---    * uuid - UUID of the BTT object to update. Can also be passed in the first argument (takes precedence if specified in `spec`).
---    * name - string value for the `BTTTouchBarButtonName` field, which determines the string shown in the button. If set to an empty string, the button is hidden.
---    * icon - an `hs.image` object containing an icon to show in the button.
---    * color - an `hs.drawing.color` object specifying the background color for the button. Can also be a string already in BTT's "R, G, B, G" format.
---    * code - a string containing arbitrary Lua code to execute. The code will be executed using the `hs` command, so the whole Hammerspoon environment, loaded config, spoons, etc. are available.
---    * Any fields starting with "BTT" are passed unmodified to the underlying call to BTT's `update_trigger` API call.
---
--- Returns:
---  * The return values from [hs.osascript.applescript](http://www.hammerspoon.org/docs/hs.osascript.html#applescript) on the execution of the AppleScript code to the update_trigger BTT method.
function obj:touchbar_button(uuid, spec)
  local payload = {
    BTTTouchBarButtonName = "",
    BTTTriggerType = 629,
    BTTTriggerClass = "BTTTriggerTypeTouchBar",
    BTTPredefinedActionType = 206,
    BTTPredefinedActionName = "Execute Shell Script / Task",
    BTTShellTaskActionScript = "",
    BTTShellTaskActionConfig = string.format("/usr/local/bin/hs:::-c:::Hammerspoon-configured: %s", spec.name or ""),
    BTTTriggerConfig = {}
  }
  for k,v in pairs(spec) do
    if k == "uuid" then
      uuid = v
    elseif k == "name" then
      payload.BTTTouchBarButtonName = v
    elseif k == "icon" then
      payload.BTTIconData = obj:btticondata_from_hsimage(v)
    elseif k == "code" then
      payload.BTTShellTaskActionScript = v
    elseif k == "color" then
      payload.BTTTriggerConfig.BTTTouchBarButtonColor = _hscolor_to_rgb(v)
    elseif string.match(k, "^BTT") then
      payload[k] = v
    end
  end
  return obj:update_trigger(uuid, payload)
end

--- BetterTouchTool:bindSpoonActions(spoon, spec)
--- Method
--- Bind Spoon-provided actions to BTT triggers. Only TouchBar button triggers are supported for now.
---
--- Parameters:
---  * spoon - an object containing the loaded Spoon to which the actions will be bound. Must contain a valid Spoon (i.e. an element of the top-level `spoon.` namespace). The Spoon object must contain the following top-level metadata variables (e.g. `spoon.<SpoonName>.<variable>`):
---    * name - a string with the Spoon name. Must match the name by which the Spoon object can be accessed (`spoon.<name>`)
---    * spoon_action_mappings - a table containing a mapping from action names to functions to be called when the action is invoked. It's the same format expected by the `def` argument of the [`hs.spoons.bindHotkeysToSpec()](http://www.hammerspoon.org/docs/hs.spoons.html#bindHotkeysToSpec) function (ideally, the same object should be used for both, so that spoon actions can be bound to both hotkeys and BTT triggers).
---  * spec - a table containing the action name-to-BTT trigger mappings. Its keys must exist in the `spoon.spoon.action_mappings` table, and the value must be a table with the following fields:
---    * kind - a string containing the trigger type to bind. Must correspond to an existing method in this spoon. Currently only `touchbar_button` is supported, and uses `BetterTouchTool:touchbar_button` to configure the BTT trigger.
---    * Any fields supported by the underlying method call according to `kind`, e.g. `BetterTouchTool:touchbar_button`.
function obj:bindSpoonActions(spoon, spec)
  if spoon and spoon.spoon_action_mappings then
    local def = spoon.spoon_action_mappings
    for name,key in pairs(spec) do
      if def[name] then
        local code = "spoon."..spoon.name..".spoon_action_mappings['"..name.."']()"
        obj.logger.df("Generated code for BTT trigger for action %s: %s", name, code)
        spec[name].code = code
        if spec[name].kind == 'touchbar_button' then
          obj.logger.df("Binding TouchBar button according to this spec: %s", hs.inspect(spec[name]))
          obj:touchbar_button(spec[name].uuid, spec[name])
        end
      else
        obj.logger.ef("Error: BTT binding requested for undefined action '%s'", name)
      end
    end
  end
end

return obj
