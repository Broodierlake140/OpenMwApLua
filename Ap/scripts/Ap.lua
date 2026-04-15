
local UI = require("openmw.ui")
local util = require('openmw.util')
local core = require('openmw.core')
local async = require('openmw.async')


---@type APClient
local AP = requireAP()
  
local gameName = "OpenMw"
local itemsHandling = 7 -- binary b111 - we want everything
local messageFormat = AP.RenderFormat.TEXT
local min = 1
local time = 0


---@type APClient | nil
local apConnection = nil
--Simply add quests in the format of {1, "questid", 2, "questid"}
local quests = {}
--Add the quest stages in the form of {1, "quest stage", 2, "queststage"). 
--Please note that they will have to be in the same id location, say we have a quest where the finishing id is one and it's the first one.
--It should be quests = {1, "quest"} quest_stage = {1, "1"}
--When these locations are sent the id's will be added to 3000 for simplicity
local quest_stage = {}

--This helps save the received list across instances
Received = Received or {}



Blue = util.color.rgb(0,0,255)

local function showMsg(msg)
    UI.showMessage(tostring(msg), { showInDialog = false })
end

local Address = nil
local Slot = nil
local Pass = nil
local stage = 0


local version = { major = 0, minor = 6, build = 6 }
EnableItems = {}

local errorcount = 0



function add_locations(locations, pos)
  table.insert(locations,pos,value)
end

locations = {}

local function connect(server, slot, password)
    if apConnection ~= nil then
        apConnection = nil
        collectgarbage("collect")
    end

    local function on_socket_connected()
        print("Connected")
        UI.printToConsole("Connected", Blue)
        
    end

    local function on_socket_error(msg)
        print("Socket error: " .. msg)
        if errorcount == 3 then
          apConnection = nil
          end
        errorcount = errorcount + 1
    end

    local function on_socket_disconnected()
        print("Socket disconnected")
        UI.printToConsole("Socked disconnected", Blue)
    end

    local function on_room_info()
        if apConnection == nil then return end
        print("Room info")
        UI.printToConsole("Room info", Blue)
        Version = {major=0, minor=6, build=6}
        apConnection:ConnectSlot(slot, password, itemsHandling, { "Lua-APClientPP" }, Version)
    end

    local function on_slot_connected(slot_data)
        if apConnection == nil then return end
        showMsg("Slot connected")
        print(slot_data)
        print("missing locations: " .. table.concat(apConnection.missing_locations, ", "))
        print("checked locations: " .. table.concat(apConnection.checked_locations, ", "))
        apConnection:Say("Hello World!")
        apConnection:Bounce({ name = "test" }, { gameName })
        local extra = { nonce = 123 } -- optional extra data will be in the server reply
        apConnection:Get({ "counter" }, extra)
        apConnection:Set("counter", 0, true, { { "add", 1 } }, extra)
        apConnection:Set("empty_array", nil, true, { { "replace", AP.EMPTY_ARRAY } })
        apConnection:ConnectUpdate(nil, { "Lua-APClientPP", "DeathLink" })
        apConnection:LocationChecks({})
        print("Players:")
        local players = apConnection:get_players()
        for _, player in ipairs(players) do
            print("  " .. tostring(player.slot) .. ": " .. player.name ..
                " playing " .. apConnection:get_player_game(player.slot))
            UI.printToConsole("  " .. tostring(player.slot) .. ": " .. player.name ..
                " playing " .. apConnection:get_player_game(player.slot), Blue)
        end
    end

    local function on_slot_refused(reasons)
        showMsg("Slot refused: " .. table.concat(reasons, ", "))
        apConnection = nil
    end

    local function on_items_received(items)
        for _, item in ipairs(items) do

            local found = false 
            for _, v in pairs(Received) do
              if v == item.item then
                found = true
              end
            end
            if found == false then
              showMsg("Items received :" .. tostring(item.item))
              print(tostring(item.item))
              core.sendGlobalEvent("Give",item.item)
              table.insert(Received,item.item)
            end
        end
    end

    local function on_location_info(items)
        print("Locations scouted:")
        for _, item in ipairs(items) do
            print(item.item)
        end
    end

    local function on_location_checked(locations)
        if apConnection == nil then return end
        print("Locations checked:" .. table.concat(locations, ", "))
        print("Checked locations: " .. table.concat(apConnection.checked_locations, ", "))
    end

    local function on_data_package_changed(data_package)
        print("Data package changed:")
        print(data_package)
    end

    local function on_print(msg)
        print(msg)
        
    end

    local function on_print_json(msg, extra)
        if apConnection == nil then return end
        print(apConnection:render_json(msg, messageFormat))
        UI.printToConsole(apConnection:render_json(msg, messageFormat), Blue)
        
        for key, value in pairs(extra) do
            -- print("  " .. key .. ": " .. tostring(value))
            -- UI.printToConsole("  " .. key .. ": " .. tostring(value), Blue)
        end
    end

    local function on_bounced(bounce)
        print("Bounced:")
        print(bounce)
    end

    local function on_retrieved(map, keys, extra)
        print("Retrieved:")
        -- since lua tables won't contain nil values, we can use keys array
        -- relevant string.char(97) and string.byte("example")
        for _, key in ipairs(keys) do
            print("  " .. key .. ": " .. tostring(map[key]))
        end
        -- extra will include extra fields from Get
        print("Extra:")
        for key, value in pairs(extra) do
            print("  " .. key .. ": " .. tostring(value))
        end
        -- both keys and extra are optional
    end

    local function on_set_reply(message)
        print("Set Reply:")
        for key, value in pairs(message) do
            print("  " .. key .. ": " .. tostring(value))
            if key == "value" and type(value) == "table" then
                for subkey, subvalue in pairs(value) do
                    print("    " .. subkey .. ": " .. tostring(subvalue))
                end
            end
        end
    end

    local uuid = ""
    apConnection = AP(uuid, gameName, server, version);

    apConnection:set_socket_connected_handler(on_socket_connected)
    apConnection:set_socket_error_handler(on_socket_error)
    apConnection:set_socket_disconnected_handler(on_socket_disconnected)
    apConnection:set_room_info_handler(on_room_info)
    apConnection:set_slot_connected_handler(on_slot_connected)
    apConnection:set_slot_refused_handler(on_slot_refused)
    apConnection:set_items_received_handler(on_items_received)
    apConnection:set_location_info_handler(on_location_info)
    apConnection:set_location_checked_handler(on_location_checked)
    apConnection:set_data_package_changed_handler(on_data_package_changed)
    apConnection:set_print_handler(on_print)
    apConnection:set_print_json_handler(on_print_json)
    apConnection:set_bounced_handler(on_bounced)
    apConnection:set_retrieved_handler(on_retrieved)
    apConnection:set_set_reply_handler(on_set_reply)
end

local function disconnect()
    if apConnection == nil then
        return false
    end
    if apConnection:get_state() == APClient.State.DISCONNECTED then
        apConnection = nil
        collectgarbage("collect")
        return false
    end
    apConnection = nil
    collectgarbage("collect")
    return true
end

local function isConnected()
    if apConnection == nil then
        return false
    end
    if apConnection:get_state() == APClient.State.DISCONNECTED then
        return false
    end
    return true
end

local function getConnection()
    return apConnection
end






stage = 0


if apConnection == nil then
  UI.printToConsole("Enter Your Archipelago Address and port Example: archipelago.gg:xxxxx", Blue)
  stage = 1
  print("Connecting")
  end


function onConsole(mode, command, selectedObject)
  --This catches what is sent in the archipelago console. It replaces the normal console.
  --You can type <exit> in it to leave the archipelago console until you reopen it, it may disconnect you. Needs checking.
  --If you're connected anything else sent is passed onto the server.
  --If you aren't it will prompt you to enter your id  
  if command == "Exit" or command == "exit" then
    UI.setConsoleMode("")
   elseif command == "Wipe Received" or command == "wipe received" or comamnd == "Wipe received" or command == "wipe Received" then
    Received = {}
  elseif command == "/help" or command == "help" then
    UI.printToConsole("exit: This Command Sets The Console Back Into The Default Console Until You Reopen It",Blue)
    UI.printToConsole("Wipe Received: This Command Resets The List Of What Item's You've Received Giving Them To You Again",Blue)
  elseif apConnection ~= nil then
    apConnection:Say(command)
  else
   if stage == 0 then 
    UI.printToConsole("Enter Your Archipelago Address and port Example: archipelago.gg:xxxxx", Blue)
    stage = stage + 1
   elseif stage == 1 then
    Address = command
    UI.printToConsole("Enter your slot name", Blue)
    stage = 2
   elseif stage == 2 then
    Slot = command
    stage = 3
    UI.printToConsole("Enter your password if you have one else press enter Else, press space then enter", Blue)
   elseif stage == 3 then
    Pass = command
    if Pass == " " then
     Pass = ""
     print(Address)
     UI.printToConsole("Address : " .. Address,Blue)
     print(Slot)
     UI.printToConsole("Slot : " .. Slot,Blue)
     print(Pass)
     UI.printToConsole("Pass : " .. Pass,Blue)
     print("Stage 0")
     stage = 0
     connect(Address, Slot, Pass)
    else  
      print(Address)
      UI.printToConsole("Address : " .. Address,Blue)
      print(Slot)
      UI.printToConsole("Slot : " .. Slot,Blue)
      print(Pass)
      UI.printToConsole("Pass : " .. Pass,Blue)
      print("Stage 1")
      stage = 1
      connect(Address, Slot, Pass)
    end 
    end
    end
end

Key = function(key)
  if key.symbol == "`" then
    UI.setConsoleMode("Archipelago")
   end
end

SendLocation = function(location)
  --This is an event received from Global.lua except for quests
  --Quests will have 3000 added to their archipelago id for simplicity in dealing with ids
  apConnection:LocationChecks({location})
end




Load = function(savedData)
  --On Loading a save it replaces Received with either {} or the saved List
  Received = savedData or Received
end

Save = function()
  return Received
end

OnQuest = function(questId, stage)
  for i in pairs(quests) do
    if tostring(questId) == quests[i] then
      if tostring(stage) == quest_stage[i] then
        SendLocation(i + 3000)
      end
    end
   end
end

return {
    interfaceName = "Archipelago",
    interface = {
        connect = connect,
        disconnect = disconnect,
        isConnected = isConnected,
        getConnection = getConnection
    },
    engineHandlers = {
        onConsoleCommand = onConsole,
        onKeyPress = Key,
        onQuestUpdate = onQuest,
        onLoad = Load,
        onSave = Save,
  
  
        onUpdate = function()
            if apConnection ~= nil then
                apConnection:poll()
                --Every 120 frames it sends the event Remove to Global.lua.
                --To change the amount of frames simply change time == 60.
                --Min starts at 0 incrementing by 10 every 120 frames right now.
                --Change the min <= 100 to be 10 less than the highest id ap_<item> id that was added to morrowind.
                --For example, if you had ap_115 you would have to change min <= 100 to min <= 105.
                if time == 120 then 
                  time = 0 
                  core.sendGlobalEvent("Remove", min)
                  if min <= 100 then 
                    min = min + 10
                  else 
                    min = 1
                  end               
                else 
                  time = time + 1
                end
            end
        end
     },
     eventHandlers = {
      SendLocation = SendLocation
     }
}
