

local core = require("openmw.core")
local world = require("openmw.world")
local  player = world.players[1]
local types = require("openmw.types")   
local inventory = types.Actor.inventory(player)
local util = require("openmw.util")
---ap_items should be in the format of {1, "morrowind id", 2, "other morrowind id"}. 
---This is solely for conviniece but if you wish to just use the morrowind ids by themself just remove the * 2 from the give function else statement.
local ap_items = {}


---@type APClient

---@type APClient | nil

Give = function(id)
      count = 1
      if id >= 1000 and id <= 2000 then
        --if the archipelago item id is between 1000 and 2000 it subtracts 1000 and gives it as gold
        itemid = "Gold_001"
        count = id - 1000
        Item = world.createObject(itemid, count)
        Item:moveInto(types.Actor.inventory(player))
      elseif id == 2005 then 
        --if the archipelago item id is 2005 it gives 5 restore health small potions
        itemid = "p_restore_health_s"
        count = 5
        Item = world.createObject(itemid, count)
        Item:moveInto(types.Actor.inventory(player))
      else
        --This gives the player an item in the list ap_items with a number twice that of the archipelago id 
        itemid = ap_items[id * 2]
        Item = world.createObject(itemid, count)
        Item:moveInto(types.Actor.inventory(player))
    end
  end
  
  
  
  
  
  
  
  


Remove = function(min, max)
     for i = min, min + 10 do
       checkinvitem = inventory:find("ap_" .. tostring(i))
       print("ap_" .. i)
          if checkinvitem ~= nil then
            checkinvitem:remove(1)
            player:sendEvent("SendLocation",i)
            
          end
        end
       end


return{
  eventHandlers = {
    Give = Give,
    Remove = Remove
  }

}
