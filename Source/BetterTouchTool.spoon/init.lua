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
--- Update a BTT trigger object.
---
--- Parameters:
---  * uuid - A string containing the UUID of the BTT object to update. Can be obtained from the BTT window by right-clicking on the object and choosing "Copy UUID"
---  * payload - A table containing the fields to pass. The fields are object-dependent, the easiest way to learn them is to right-click on an object of the desired type and choose "Copy JSON to clipboard"
function obj:update_trigger(uuid, payload)
  local json_str = hs.json.encode(payload):gsub([[\]], [[\\]]):gsub([["]], [[\"]])
  local code = [[tell application "BetterTouchTool" to update_trigger "]] .. uuid .. [[" json "]] .. json_str .. [["]]
  hs.osascript.applescript(code)
end

--- BetterTouchTool:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for BetterTouchTool
---
--- Parameters:
---  * mapping - A table containing hotkey objifier/key details for the following items:
---   * hello - Say Hello
function obj:bindHotkeys(mapping)
   if mapping["hello"] then
      if (self.key_hello) then
         self.key_hello:delete()
      end
      self.key_hello = hs.hotkey.bindSpec(mapping["hello"], function() self:sayHello() end)
   end
end

return obj
