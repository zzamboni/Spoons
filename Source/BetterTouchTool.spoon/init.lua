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

--- BetterTouchTool:hsimageToBTTIconData(image)
--- Method
--- Return the base64-encoded version of an hs.image object.
---
--- Parameters:
---  * image - An [http://www.hammerspoon.org/docs/hs.image.html](hs.image) object.
---
--- Returns:
---  * A string containing the base64-encoded image.
function obj:hsimageToBTTIconData(img)
  return img:encodeAsURLString():gsub("^data:image/png;base64,", "")
end

--- Convert a color from 0.0-1.0 (used by Hammerspoon) to RGB's 0-255
function _1_255(num)
  return num*255.0
end

--- Convert a Hammerspoon hs.color object to a color string as used by BTT: "R, G, B, G" (each in 0-255 range, floating-point numbers)
function obj:hscolorToBTTColor(color)
  if type(color) == 'table' then
    local c = hs.drawing.color.asRGB(color)
    return string.format("%.6f, %.6f, %.6f, %.6f", _1_255(c.red), _1_255(c.green), _1_255(c.blue), _1_255(c.alpha))
  else
    return color
  end
end

--- BetterTouchTool:touchbarButton(uuid, spec)
--- Method
--- Update a BTT TouchBar button definition
---
--- Parameters:
---  * uuid - UUID of the BTT object to update. Can be obtained from the BTT window by right-clicking on the desired object and choosing "Copy UUID". Can be `nil` if `spec` contains a `uuid` field.
---  * spec - table containing the specification for the object. Can contain the following fields:
---    * uuid - UUID of the BTT object to update. Can also be passed in the first argument (takes precedence if specified in `spec`).
---    * name - string value for the `BTTTouchBarButtonName` field, which determines the string shown in the button. If set to an empty string, the button is hidden.
---    * icon - an `hs.image` object containing an icon to show in the button.
---    * icon_size - an `hs.geometry` size object specifing the size to use for the icon.
---    * icon_only - a boolean to specify if only the icon should be shown.
---    * color - an `hs.drawing.color` object specifying the background color for the button. Can also be a string already in BTT's "R, G, B, G" format.
---    * code - a string containing arbitrary Lua code to execute. The code will be executed using the `hs` command, so the whole Hammerspoon environment, loaded config, spoons, etc. are available.
---    * Any fields starting with "BTT" are passed unmodified to the underlying call to BTT's `update_trigger` API call. If the value is a table, its contents is copied without further inspection (this can be used to populate the `BTTTriggerConfig` table common in some BTT widgets.
---
--- Returns:
---  * The return values from [hs.osascript.applescript](http://www.hammerspoon.org/docs/hs.osascript.html#applescript) on the execution of the AppleScript code to the update_trigger BTT method.
function obj:touchbarButton(uuid, spec)
  local payload = {
    BTTTouchBarButtonName = "",
    BTTTriggerType = 629,
    BTTTriggerClass = "BTTTriggerTypeTouchBar",
    BTTPredefinedActionType = 137,
    BTTPredefinedActionName = "Execute Terminal Command (Async, non-blocking)",
    BTTTerminalCommand = "",
    BTTTriggerConfig = {}
  }
  for k,v in pairs(spec) do
    if k == "uuid" then
      uuid = v
    elseif k == "name" then
      payload.BTTTouchBarButtonName = v
    elseif k == "icon" then
      payload.BTTIconData = obj:hsimageToBTTIconData(v)
    elseif k == "code" then
      payload.BTTTerminalCommand = string.format("/usr/local/bin/hs -c '%s'",v)
    elseif k == "color" then
      payload.BTTTriggerConfig.BTTTouchBarButtonColor = obj:hscolorToBTTColor(v)
    elseif k == "icon_only" then
      payload.BTTTriggerConfig.BTTTouchBarOnlyShowIcon = v
    elseif k == "icon_size" then
      payload.BTTTriggerConfig.BTTTouchBarItemIconWidth = v.w
      payload.BTTTriggerConfig.BTTTouchBarItemIconHeight = v.h
    elseif string.match(k, "^BTT") then
      if type(v) == "table" then
        if not payload[k] then
          payload[k] = {}
        end
        for k2,v2 in pairs(v) do
          payload[k][k2] = v2
        end
      else
        payload[k] = v
      end
    end
  end
  return obj:update_trigger(uuid, payload)
end

--- BetterTouchTool:touchbarWidget(uuid, spec)
--- Method
--- Update a BTT TouchBar widget definition. A widget has the ability to run a script and determine its icon, text and color from the output of the script. In addition, it can execute another script when touched.
---
--- Parameters:
---  * uuid - UUID of the BTT object to update. Can be obtained from the BTT window by right-clicking on the desired object and choosing "Copy UUID". Can be `nil` if `spec` contains a `uuid` field.
---  * spec - table containing the specification for the object. Can contain the following fields:
---    * uuid - UUID of the BTT object to update. Can also be passed in the first argument (takes precedence if specified in `spec`).
---    * name - string value for the `BTTWidgetName` fields, which determines the widget name.
---    * icon - an `hs.image` object containing the initial icon to show in the button. Can be updated by the widget script output.
---    * icon_size - an `hs.geometry` size object specifing the size to use for the icon.
---    * icon_only - a boolean to specify if only the icon should be shown.
---    * color - an `hs.drawing.color` object specifying the background color for the button. Can also be a string already in BTT's "R, G, B, G" format.
---    * code - a string containing arbitrary Lua code to execute when the widget is clicked. The code will be executed using the `hs` command, so the whole Hammerspoon environment, loaded config, spoons, etc. are available.
---    * widget_code - a string containing arbitrary Lua code to execute within the widget. The script you can either return a simple string which will then be shown on the widget (if it's an empty string, the widget is hidden), or you can return a JSON string containing any of the following fields (you can call `hs.json.encode` on a Lua table to produce this string):
---      * text: string to show on the widget (if set to an empty string, the widget is hidden)
---      * icon_data: a string containing a base64-encoded icon for the widget. You can use `BetterTouchTool:hsimageToBTTIconData` to produce this string from an `hs.image` object.
---      * icon_path: a string containing the path of an image to use as the widget icon. If both `icon_data` and `icon_path` are specified, `icon_data` takes precedence.
---      * background_color: a string in "R,G,B,Gamma" format specifying the background color for the widget. You can use `BetterTouchTool:hscolorToBTTColor` to produce this string from an `hs.drawing.color` object.
---      * font_color: a string containing the font color for the widget, in the same format as background_color.
---      * font_size: an integer specifying the font size for the widget text.
---    * widget_interval - how often the widget should be updated, in seconds.
---    * Any fields starting with "BTT" are passed unmodified to the underlying call to BTT's `update_trigger` API call. If the value is a table, its contents is copied without further inspection (this can be used to populate the `BTTTriggerConfig` table common in some BTT widgets.
---
--- Returns:
---  * The return values from [hs.osascript.applescript](http://www.hammerspoon.org/docs/hs.osascript.html#applescript) on the execution of the AppleScript code to the update_trigger BTT method.
function obj:touchbarWidget(uuid, spec)
  local payload = {
    BTTWidgetName = "",
    BTTTriggerType = 642,
    BTTTriggerTypeDescription = "Shell Script / Task Widget",
    BTTPredefinedActionType = 137,
    BTTPredefinedActionName = "Execute Terminal Command (Async, non-blocking)",
    BTTTriggerClass = "BTTTriggerTypeTouchBar",
    BTTTerminalCommand = "",
    BTTShellScriptWidgetGestureConfig = "/usr/local/bin/hs:::-c",
    BTTTriggerConfig = {
      BTTScriptType = 0,
      BTTTouchBarShellScriptString = "",
      BTTTouchBarScriptUpdateInterval = 30,
      BTTTouchBarButtonName = "",
      BTTTouchBarOnlyShowIcon = false,
    }
  }
  for k,v in pairs(spec) do
    if k == "uuid" then
      uuid = v
    elseif k == "name" then
      payload.BTTWidgetName = v
    elseif k == "icon" then
      payload.BTTIconData = obj:hsimageToBTTIconData(v)
    elseif k == "code" then
      payload.BTTTerminalCommand = string.format("/usr/local/bin/hs -c '%s'",v)
    elseif k == "widget_code" then
      payload.BTTTriggerConfig.BTTTouchBarShellScriptString = v
    elseif k == "widget_interval" then
      payload.BTTTriggerConfig.BTTTouchBarScriptUpdateInterval = v
    elseif k == "color" then
      payload.BTTTriggerConfig.BTTTouchBarButtonColor = obj:hscolorToBTTColor(v)
    elseif k == "icon_only" then
      payload.BTTTriggerConfig.BTTTouchBarOnlyShowIcon = v
    elseif k == "icon_size" then
      payload.BTTTriggerConfig.BTTTouchBarItemIconWidth = v.w
      payload.BTTTriggerConfig.BTTTouchBarItemIconHeight = v.h
    elseif string.match(k, "^BTT") then
      if type(v) == "table" then
        if not payload[k] then
          payload[k] = {}
        end
        for k2,v2 in pairs(v) do
          payload[k][k2] = v2
        end
      else
        payload[k] = v
      end
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
---    * kind - a string containing the trigger type to bind. Must correspond to an existing method in this spoon. Currently only `touchbarButton` is supported, and uses `BetterTouchTool:touchbarButton` to configure the BTT trigger.
---    * Any fields supported by the underlying method call according to `kind`, e.g. `BetterTouchTool:touchbarButton`.
function obj:bindSpoonActions(spoon, spec)
  local def = {}
  if spoon and spoon.spoon_action_mappings then
    def = spoon.spoon_action_mappings
  end
  for name,key in pairs(spec) do
    --- Auto-generate code if we have a definition in the spoon and no
    --- code field is explicitly given in the spec
    if def[name] and (not spec[name].code) then
      local code = "spoon."..spoon.name..".spoon_action_mappings[\""..name.."\"]()"
      obj.logger.df("Generated code for BTT trigger for action %s: %s", name, code)
      spec[name].code = code
    end
    if spec[name].kind == 'touchbarButton' then
      obj.logger.df("Binding TouchBar button according to this spec: %s", hs.inspect(spec[name]))
      obj:touchbarButton(spec[name].uuid, spec[name])
    elseif spec[name].kind == 'touchbarWidget' then
      obj.logger.df("Binding TouchBar widget according to this spec: %s", hs.inspect(spec[name]))
      obj:touchbarWidget(spec[name].uuid, spec[name])
    end
  end
end

return obj
