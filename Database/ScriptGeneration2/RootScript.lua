--[[ The Operation Flashpoint Dragon Rising Mission Editor Expansion by tvig0r0us
       ___         ___                     ___          ___          ___          ___          ___          ___     
      /\  \       /\__\         ___       /\  \        /\  \        /\  \        /\  \        /\__\        /\  \    
      \:\  \     /:/  /        /\  \     /::\  \      /::\  \      /::\  \      /::\  \      /:/  /       /::\  \   
       \:\  \   /:/  /         \:\  \   /:/\:\  \    /:/\:\  \    /:/\:\  \    /:/\:\  \    /:/  /       /:/\ \  \  
       /::\  \ /:/__/  ___     /::\__\ /:/  \:\  \  /:/  \:\  \  /::\~\:\  \  /:/  \:\  \  /:/  /  ___  _\:\~\ \  \ 
      /:/\:\__\|:|  | /\__\ __/:/\/__//:/__/_\:\__\/:/__/ \:\__\/:/\:\ \:\__\/:/__/ \:\__\/:/__/  /\__\/\ \:\ \ \__\
     /:/  \/__/|:|  |/:/  //\/:/  /   \:\  /\ \/__/\:\  \ /:/  /\/_|::\/:/  /\:\  \ /:/  /\:\  \ /:/  /\:\ \:\ \/__/
    /:/  /     |:|__/:/  / \::/__/     \:\ \:\__\   \:\  /:/  /    |:|::/  /  \:\  /:/  /  \:\  /:/  /  \:\ \:\__\  
    \/__/       \::::/__/   \:\__\      \:\/:/  /    \:\/:/  /     |:|\/__/    \:\/:/  /    \:\/:/  /    \:\/:/  /  
                 ~~~~        \/__/       \::/  /      \::/  /      |:|  |       \::/  /      \::/  /      \::/  /   
                                          \/__/        \/__/        \|__|        \/__/        \/__/        \/__/    
]]
VERSION = "20141117"

EDX = {__nopersist__ = true}

function onCreate()
	gameInit = true;
--Set debugger from level script
	if scripts.mission.level and scripts.mission.level.DEBUG then DEBUG = true end
	if scripts.mission.level and scripts.mission.level.DISPLAY then DISPLAY = true end
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		v.diagLog = function (message)
			if (scriptName == "waypoints" and scripts.mission.level and scripts.mission.level.logEdexToFile)
			or v.LOG_TO_FILE then
			local logFile = io.open(missionPath..scriptName.." Log.txt", "a+")
				if message ~= nil then
					logFile:write(os.date() .. ": " .. message .. "\n")
				else
					logFile:write(os.date() .. ": (nil)\n")
				end
				logFile:close()
			end
		end
	end
	
--Initialize table to store user variables with setVar/getVar/deleteVar functions
	if not VAR then VAR = {} end
	if not missionPath then missionPath = "./" end
	if not deadID then deadID = {} end
	
	if not playerEntities then
		playerEchelon = ""
		primaryPlayer = ""
		playerEntities = {}
		playerAI = {}
		playerBearing = {}
		coop = false
	end
	
	if not lights then
		lights = {}
	else
		for unit, status in pairs(lights) do
			lights[unit] = false
		end
	end
	
--Reroute functions to waypoints script for EDX distribution
	routeToEDX("onEnterRVPoint")
	routeToEDX("onFiring")
	routeToEDX("updateFrame")
	routeToEDX("onObjectiveCompleted")
	routeToEDX("onObjectiveFailed")
	routeToEDX("onObjectiveVisible")
	
--The following code
--Records what scripts contain what functions.  Functions not found on any script will be disabled.
	if not pointers then
		diagLog("analyzing pointers")
		local EVENTS = {
			"onArriveAtWaypoint", "onCmdCompleted", "onAllPlayersDead", "onDeath", "onIncap", "onEnter", "onTimer",
			"onEnterRVPoint", "onLeave", "onFirepowerKill",  "onOffboardSupp", "onHit", "onIdentified", "updateFrame",
			"onLand", "onMobilityKill", "onMount", "onDismount", "onMultiplayerMissionLoaded", "onPVPMissionEnd",
			"onNoAmmo", "onNoAmmoAll", "onObjectiveCompleted", "onObjectiveFailed", "onObjectiveVisible",
			"onObjectDamage", "onPlaceableKill", "onPlayDone", "onPlayEnter", "onPlayFailed", "onUnderfire",
			"onPlayInvalid", "onDespawnEntity", "onDespawnEntitySet", "onRespawn", "onSmartSpawned", "onFiring",
			"onSpawnedReady", "onSpeechEnd", "onPinned", "onSuppressed", "onUnsuppressed", "onSuspected","onMissionStart",
		}
		local EDX_EVENTS = {
			"onKeyPress", "numpad0", "numpad1", "numpad2", "numpad3", "numpad4", "numpad5", "numpad6", "numpad7", "numpad8",
			"numpad9", "numpadDiv", "numpadMult", "numpadMinus", "numpadPlus", "numpadClear", "numpadPgUp", "numpadPgDn",
			"numpadEnd", "numpadHome", "numpadIns", "numpadDel", "numpadDecimal", "numpadUp", "numpadDn", "numpadLt", "numpadRt",
			"onLoadCheckpoint","onTimeChange",
		}
		pointers = {}
		for i,name in ipairs(EVENTS) do
			pointers[name] = {}
			for si, sv in pairs(scripts.mission) do
				local scriptName = si
				if scriptName ~= "help"
				and scriptName ~= "config"
				and scriptName ~= "level"
				and scriptName ~= "waypoints" then
					for fi, fv in pairs(sv) do
						if fi == name or EDX:startsWith(fi, name) then
							if name == "onEnter" then
								if fi ~= "onEnterRVPoint" and not EDX:startsWith(fi, "onEnterRVPoint") then
									pointers[name][#pointers[name]+1] = scriptName
									diagLog(name.." saved for script "..scriptName)
								end
							elseif name == "onDespawnEntity" then
								if fi ~= "onDespawnEntitySet" and not EDX:startsWith(fi, "onDespawnEntitySet") then
									pointers[name][#pointers[name]+1] = scriptName
									diagLog(name.." saved for script "..scriptName)
								end
								
							else
								pointers[name][#pointers[name]+1] = scriptName
								diagLog(name.." saved for script "..scriptName)
							end
							break
						end
					end
				end
			end
			if #pointers[name] == 0 then
				pointers[name] = nil
				diagLog(name.." doesn't exist on any script")
				if scripts.mission.level then
					if not scripts.mission.level[name] then
						OFP:disableEvent(name)
						diagLog(name.." disabled")
					end
				else
					OFP:disableEvent(name)
					diagLog(name.." disabled")
				end
			end
		end
		for i,name in ipairs(EDX_EVENTS) do
			pointers[name] = {}
			for si, sv in pairs(scripts.mission) do
				local scriptName = tostring(si)
				if scriptName ~= "help"
				and scriptName ~= "config"
				and scriptName ~= "waypoints" then
					if sv[name] then
						pointers[name][#pointers[name]+1] = scriptName
						diagLog(name.." saved for script "..scriptName)
					end
				end
			end
			if #pointers[name] == 0 then
				pointers[name] = nil
				diagLog(name.." doesn't exist on any script")
			end
		end
		diagLog("script pointers created")
	end
	
--initialize the edex functions on all user scripts and read script info to display at mission start
	diagLog("initializing Edx")
	INFO = {}
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "help"
		and scriptName ~= "config" 
		and scriptName ~= "waypoints" then
			v.EDX = scripts.mission.waypoints.EDX
			if v.INFO then
				table.insert(INFO, v.INFO)
			end
			diagLog("Edx initialized to script "..scriptName)
		end
	end
	
--Initialize timer table and serial timer ID sequence.  Also reset hotkey file at mission start to prevent orphaned keystrokes from registering at mission start
	diagLog("initializing timers")
	resetKeyFile()
	if not timerTable then timerTable = {} end
	if not ID then ID = 0 end
	simpleFunc("onEDXInitialized",true)
	EDX:simpleTimer("initComplete",1000);
	if lcp then
		fireEH("onLoadCheckpoint");
		diagLog("mission load from checkpoint")
	else
		lcp = true;
		diagLog("new mission start")
	end
	diagLog("init completed")
end

function initComplete()
	EDX:deleteTimer("initComplete");
	gameInit = false;
end

function routeToEDX(functionName)
	if scripts.mission.level then
		scripts.mission.level[functionName] = scripts.mission.waypoints[functionName]
	end
end

--This function fires event handlers on all secondary scripts recorded to pointers
function fireEH(funcName, ...)
	--diagLog("fireEH "..funcName)
	local EH = false
	if pointers[funcName] then
		local scpts = pointers[funcName]
		for i,v in ipairs(scpts) do
			local scr = scripts.mission[v]
			if not scr.disableScript  then
				debugInfo = "function "..funcName.." on script "..v
				if scr[funcName] then
					scr[funcName](...)
					debugInfo = nil
					EH = true
				else
					local str, _str = "", ""
					local vars = {...}
					for vi, vv in ipairs(vars) do
						str = str..vv
						_str = _str.."_"..vv
						if scr[funcName..vv] then
							scr[funcName..vv](...)
							debugInfo = nil
							EH = true
							break
						elseif scr[funcName.."_"..vv] then
							scr[funcName.."_"..vv](...)
							debugInfo = nil
							EH = true
							break
						elseif scr[funcName..str] then
							scr[funcName..str](...)
							debugInfo = nil
							EH = true
							break
						elseif scr[funcName.._str] then
							scr[funcName.._str](...)
							debugInfo = nil
							EH = true
							break
						end
					end
				end
			end
		end
	end
	--debugInfo = nil
	return EH
end

function fireSimpleEH(funcName, ...)
	--diagLog("fireEH "..funcName)
	local EH = false
	if pointers[funcName] then
		local scpts = pointers[funcName]
		for i,v in ipairs(scpts) do
			local scr = scripts.mission[v]
			if not scr.disableScript and scr[funcName] then
				debugInfo = "function "..funcName.." on script "..v
				scr[funcName](...)
				EH = true
				debugInfo = nil
			end
		end
	end
	--debugInfo = nil
	return EH
end

function EDX:registerEventHandler(n)
	if not pointers[n] then
		pointers[n] = {}
		for si, sv in pairs(scripts.mission) do
			local scriptName = si;
			if scriptName ~= "help"
			and scriptName ~= "config"
			and scriptName ~= "level"
			and (((n == "openMenu" or n == "closeMenu") and scriptName == "waypoints") or scriptName ~= "waypoints") then
				for fi, fv in pairs(sv) do
					if fi == n then
						pointers[n][#pointers[n]+1] = scriptName;
						diagLog(n.." saved for script "..scriptName);
						break;
					end
				end
			end
		end
	end
end

function EDX:fireEventHandler(funcName, ...)
	fireSimpleEH(funcName, ...);
end

--Initializes an entire script to all user scripts in project.  (not recommended)
function initScript(scriptName, prefix)
	debugInfo = "initializing script "..scriptName
	local _prefix = scriptName
	if prefix then _prefix = prefix end
	for i,v in pairs(scripts.mission) do
		local scr = tostring(i)
		debugInfo = _prefix.." initializing on "..scr
		if scr ~= "config"
		and scr ~= "help"
		and scr ~= "waypoints"
		and scr ~= scriptName then
			v[_prefix] = scripts.mission[scriptName]
		end
	end
	--debugInfo = nil
end

--returns given script if it exists
function scriptPointer(scriptName)
	local script = scripts.mission[scriptName]
	if script then
		return script
	end
	return nil
end

--registers a function in the edex functions table and makes it available to all script in the project
function registerFunction(funcName)
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config" then
			if v[funcName] and not v.disableScript then
				debugInfo = "register function "..funcName.." on script "..scriptName
				scripts.mission.waypoints.EDX[funcName] = v[funcName]
			end
		end
	end
	debugInfo = nil
end

-- distributes given function and variables to all scripts 
function fireFunc(funcName, ...)
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config"
		and scriptName ~= "level" then
			if v[funcName] and not v.disableScript then
				debugInfo = "function "..funcName.." on script "..scriptName
				if ... then
					v[funcName](...)
					debugInfo = nil
				else
					v[funcName]()
					debugInfo = nil
				end
			end
		end
	end
	--debugInfo = nil
end

-- distributes given function and variables to all scripts and forces function on force flag even if disableScript is true
function simpleFunc(funcName,force)
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config"
		and scriptName ~= "level" then
			if v[funcName] and (force or not v.disableScript) then
				debugInfo = "function "..funcName.." on script "..scriptName
				v[funcName]()
				debugInfo = nil
			end
		end
	end
	--debugInfo = nil
end

-- distributes given function and variables to all scripts including the level script(not recommended for native event handlers)
function doFunc(funcName, ...)
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config" then
			if v[funcName] and not v.disableScript then
				debugInfo = "function "..funcName.." on script "..scriptName
				if ... then
					v[funcName](...)
					debugInfo = nil
				else
					v[funcName]()
					debugInfo = nil
				end
			end
		end
	end
	--debugInfo = nil
end

function onMissionStart()
	-- Set environment settings
	OFP:setTimeOfDay($[Hours], $[Minutes], $[Seconds])
	OFP:setWeatherCurrent($[WeatherTypeIndex])
	diagLog("Time set to $[Hours]:$[Minutes]:$[Seconds] and weather set to $[WeatherTypeIndex]")
	edxHours = $[Hours]
	edxMinutes = $[Minutes]
	edxSeconds = $[Seconds]
	lastMissionTime = 0
	edxWeatherType = $[WeatherTypeIndex]
	edxFogDensity = 0
	
	-- Set offboard support
	if $[OffboardSupportEnabled] then
		OFP:enableArtilleryStrike(0, "Mortar", "HE", true)
		OFP:setArtilleryStrikeCount(0, "Mortar", $[OffboardSupportMortarCount])
		OFP:enableArtilleryStrike(0, "HeavyMortar", "HE", true)
		OFP:setArtilleryStrikeCount(0, "HeavyMortar", $[OffboardSupportHeavyMortarCount])
		OFP:enableArtilleryStrike(0, "Howitzer", "HE", true)
		OFP:setArtilleryStrikeCount(0, "Howitzer", $[OffboardSupportHowitzerCount])
		OFP:enableAirStrike(0, "Small", true)
		OFP:setAirStrikeCount(0, "Small", $[OffboardSupportSmallAirStrikeCount])
		OFP:enableAirStrike(0, "Large", true)
		OFP:setAirStrikeCount(0, "Large", $[OffboardSupportLargeAirStrikeCount])
		OFP:enableAirStrike(0, "JDAM", true)
		OFP:setAirStrikeCount(0, "JDAM", $[OffboardSupportJDAMAirStrikeCount])
	end
	
	-- Add initial timing mechanism timer and garbage removal timer
	OFP:addTimer("timingMechanism", 500)
	timingMechanism = true
	OFP:addTimer("garbageRemoval", 10000)
	garbageRemoval = true
	
	-- Sets the buffer for dead ID's to be removed from the game by EDX
	DEAD_ID_BUFFER = 10;
	
	--Sets the threashold to check for player bearing changes
	BEARING_DIST = 1;
	
	--Fires on mission start on all scripts and displays script info
	fireSimpleEH("onMissionStart")
	for i,v in ipairs(INFO) do
		OFP:displaySystemMessage(v)
	end
	INFO = nil
	OFP:displaySystemMessage("Created with the OFDR EDX version "..VERSION)
	diagLog("onMissionStart completed")
end

function onTimer(delay, timerName)
	if DEBUG then
		for i,v in pairs(scripts.mission) do
			local scriptName = tostring(i)
			if v.debugInfo then
				debugger("DEBUG ["..scriptName.."]: "..v.debugInfo)
				v.debugInfo = nil
			end
		end
	end
	playerCheck(); --added to remove players from playerEntities table when they drop out of a game
	if timerName == "timingMechanism" then
		if scripts.mission.level and scripts.mission.level.disableEdexTimer then
			OFP:removeTimer("timingMechanism")
			return
		end
		OFP:setTimer("timingMechanism", 100)
		local missionTime = OFP:getMissionTime()
		timeTicker(missionTime)
		return
	elseif timerName == "garbageRemoval" then
		OFP:setTimer("garbageRemoval", 10000)
		local br = 0;
		while #deadID > DEAD_ID_BUFFER and br < 100 do
			br = br + 1;
			OFP:destroyEntitySet(deadID[1]);
			table.remove(deadID,1);
		end
		collectGarbage();
		return
	else
		if not fireEH("onTimer", timerName) then
			doFunc(timerName)
		end
		return
	end
	debugInfo = nil
end

function collectGarbage()
	local mem_used=collectgarbage("count")
	collectgarbage("collect")
	local mem_cleaned=collectgarbage("count")
	diagLog("Garbage collected. Memory before : "..mem_used.."  Memory after : "..mem_cleaned)
	diagLog("memory recovered:"..mem_used-mem_cleaned)
end

function updateFrame(currentTime, frameNo)
	fireSimpleEH("updateFrame", currentTime, frameNo)
end

function onFiring(firingSoldierName, weaponComponentName, magazineComponentName, fireMode)
	fireEH("onFiring", firingSoldierName, weaponComponentName, magazineComponentName, fireMode)
end

function onArriveAtWaypoint(entityName, waypointName)
	fireEH("onArriveAtWaypoint", entityName, waypointName)
end

function onCmdCompleted(commandID,commandName, unitorechelonName, isSuccessful)
	fireEH("onCmdCompleted", commandID, commandName, unitorechelonName, isSuccessful)
end

function onAllPlayersDead()
	fireSimpleEH("onAllPlayersDead")
end

function onDeath(victim, killer, method)
	fireEH("onDeath", victim, killer, method)
end

function onIncap(victim, killer, method)
	fireEH("onIncap", victim, killer, method)
end

function onEnter(zoneName, unitName)
	fireEH("onEnter", zoneName, unitName)
end

function onEnterRVPoint(entityName, index) 
	fireEH("onEnterRVPoint", entityName, index) 
end

function onLeave(zoneName, unitName)
	fireEH("onLeave", zoneName, unitName)
end

function onFirepowerKill(vehicle)
	fireEH("onFirepowerKill", vehicle)
end

function onOffboardSupp(firingSoldierName, supportType)
	fireEH("onOffboardSupp", firingSoldierName, supportType)
end

function onHit(victim, attacker, method)
	fireEH("onHit", victim, attacker, method)
end

function onIdentified(identifiedID, identifierID)
	fireEH("onIdentified", identifiedID, identifierID)
end

function onLand(HelicopterName)
	fireEH("onLand", HelicopterName)
end

function onMobilityKill(vehicle)
	fireEH("onMobilityKill", vehicle)
end

function onDismount(vehicleName, unitName, echelonName)
	fireEH("onDismount", vehicleName, unitName, echelonName)
end

function onMount(vehicleName, unitName, echelonName)
	fireEH("onMount", vehicleName, unitName, echelonName)
end

function onMultiplayerMissionLoaded()
	fireEH("onMultiplayerMissionLoaded")
end

function onPVPMissionEnd()
	fireSimpleEH("onPVPMissionEnd")
end

function onNoAmmo(ownerEntity)
	fireEH("onNoAmmo", ownerEntity)
end

function onNoAmmoAll(unit)
	fireEH("onNoAmmoAll", unit)
end

function onObjectiveCompleted(objectiveName)
	fireEH("onObjectiveCompleted", objectiveName)
end

function onObjectiveFailed(objectiveName)
	fireEH("onObjectiveFailed", objectiveName)
end

function onObjectiveVisible(objectiveName)
	fireEH("onObjectiveVisible", objectiveName)
end

function onObjectDamage(guid)
	fireEH("onObjectDamage", guid)
end

function onPlaceableKill(placeable, attacker)
	fireEH("onPlaceableKill", placeable, attacker)
end

function onPlayDone(echelon, play, layer)
	fireEH("onPlayDone", echelon, play, layer)
end

function onPlayEnter(echelon, play, layer)
	fireEH("onPlayEnter", echelon, play, layer)
end

function onPlayFailed(echelon, play, layer)
	fireEH("onPlayFailed", echelon, play, layer)
end

function onPlayInvalid(echelon, play, layer)
	fireEH("onPlayInvalid", echelon, play, layer)
end

function onDespawnEntity( entityName )
	fireEH("onDespawnEntity", entityName)
end

function onDespawnEntitySet( setID )
	fireEH("onDespawnEntitySet", setID)
end

function onRespawn(entityName)
	if EDX:isInTable(entityName,playerEntities) then
		EDX:setAutoLights(entityName)
	end
	fireEH("onRespawn", entityName)
end

function onSpawnedReady( setName, setID, tableOfEntities, errorCode )
	if errorCode > 0 then
		debugInfo = "onSpawnedReady "..setName.." "..setID.." "..#tableOfEntities.." "..errorCode;
	end
	fireSimpleEH("onSpawnedReady", setName, setID, tableOfEntities, errorCode )
end

function onSpeechEnd(soldier, sentence, handle)
	fireEH("onSpeechEnd", soldier, sentence, handle)
end

function onUnderfire(underfireID, shooterID, method)
	fireEH("onUnderfire", underfireID, shooterID, method)
end

function onPinned(entityID)
	fireEH("onPinned", entityID)
end

function onSuppressed(entityID)
	fireEH("onSuppressed", entityID)
end

function onUnsuppressed(entityID)
	fireEH("onUnsuppressed", entityID)
end

function onSuspected(victim, suspector)
	fireEH("onSuspected", victim, suspector)
end

function timeTicker(missionTime)
	fireTimer(missionTime)
	readHotKey()
end

function fireTimer(missionTime)
	if not timerTable then
		debugInfo = "timerTable not present"
		return
	end
	for i,v in pairs(timerTable) do
		if v.set and v.time <= missionTime then
			debugInfo = "ID = "..v.ID.." fnc = "..v.func
			local temp = v
			temp.set = nil
			timerTable[i] = temp
			local args = {v.ID}
			if v.args then
				args = {unpack(v.args)}
				args[#args + 1] = v.ID
			end
			for key,script in ipairs(v.pointers) do
				if not script.disableScript then
					debugInfo = "timerID = "..v.ID.." fnc = "..v.func.." script = "..script
					local f = scripts.mission[script][v.func]
					if f then
						f(unpack(args))
					end
				end
			end
		end
	end
	debugInfo = nil
end

function readHotKey()
	local keyfile = io.open("./hotkeys.data","r")
	if not keyfile then
		return
	else
		local input = keyfile:read("*line")
		if input then
			keyfile:close()
			resetKeyFile()
			menu(input)
			return true
		end
	end
end

function resetKeyFile()
	local keyfile = io.open("./hotkeys.data","w")
	if keyfile then
		keyfile:close()
		os.remove("./hotkeys.data")
	end
end

function menu(key)
	debugInfo = "Firing menu function for key "..key
	local stopKey = false
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config"
		and scriptName ~= "help"
		and not v.disableScript then
			debugInfo = "onKeyPress function "..key.." on "..scriptName
			if v.onKeyPress then
				local _stop = v.onKeyPress(key)
				if _stop then stopKey = true end
			end
		end
	end
	if not stopKey then
		debugInfo = "numpad function "..key
		if key == "Numpad0" then
			fireEH("numpad0")
		elseif key == "Numpad1" then
			fireEH("numpad1")
		elseif key == "Numpad2" then
			fireEH("numpad2")
		elseif key == "Numpad3" then
			fireEH("numpad3")
		elseif key == "Numpad4" then
			fireEH("numpad4")
		elseif key == "Numpad5" then
			fireEH("numpad5")
		elseif key == "Numpad6" then
			fireEH("numpad6")
		elseif key == "Numpad7" then
			fireEH("numpad7")
		elseif key == "Numpad8" then
			fireEH("numpad8")
		elseif key == "Numpad9" then
			fireEH("numpad9")
		elseif key == "Numpad/" then
			fireEH("numpadDiv")
		elseif key == "Numpad*" then
			fireEH("numpadMult")
		elseif key == "Numpad-" then
			fireEH("numpadMinus")
		elseif key == "Numpad+" then
			fireEH("numpadPlus")
		elseif key == "NumpadClear" then
			fireEH("numpadClear")
		elseif key == "NumpadPgUp" then
			fireEH("numpadPgUp")
		elseif key == "NumpadPgDn" then
			fireEH("numpadPgDn")
		elseif key == "NumpadHome" then
			fireEH("numpadHome")
		elseif key == "NumpadEnd" then
			fireEH("numpadEnd")
		elseif key == "NumpadIns" then
			fireEH("numpadIns")
		elseif key == "NumpadDel" then
			fireEH("numpadDel")
		elseif key == "Numpad." then
			fireEH("numpadDecimal")
		elseif key == "NumpadUp" then
			fireEH("numpadUp")
		elseif key == "NumpadDown" then
			fireEH("numpadDn")
		elseif key == "NumpadLeft" then
			fireEH("numpadLt")
		elseif key == "NumpadRight" then
			fireEH("numpadRt")
		end
	end
	debugInfo = nil
	return true
end

function EDX:distributeFunction(funcName, ...)
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "waypoints"
		and scriptName ~= "config" then
			if v[funcName] and not v.disableScript then
				debugInfo = "function "..funcName.." on script "..scriptName
				if ... then
					v[funcName](...)
					debugInfo = nil
				else
					v[funcName]()
					debugInfo = nil
				end
			end
		end
	end
end

function EDX:setActiveScript(scriptName)
	for i,v in pairs(scripts.mission) do
		if tostring(i) ~= "help"
		and scriptName ~= "config"
		and tostring(i) ~= "waypoints" then
			if tostring(i) == scriptName then
				scripts.mission.v.disableScript = nil
			else
				scripts.mission.v.disableScript = true
			end
		end
	end
end
	
function EDX:setVar(name, value)
	VAR[name] = value
end

function EDX:getVar(name)
	if VAR[name] then
		return VAR[name]
	end
end

function EDX:deleteVar(name)
	VAR[name] = nil
end

function EDX:setDeadID(setID)
	if setID and type(setID) == "number" then deadID[#deadID+1] = setID else debugInfo = "setDeadID: invalid setID" end
end

function EDX:setDeadIDBuffer(num)
	if num and type(num) == "number" and num > 0 then DEAD_ID_BUFFER = num else debugInfo = "setDeadIDBuffer: invalid input" end
end

---------------------------------------------------------------------------------FSM functions

function EDX:simpleTimer(timerName, delay, ...)
	debugInfo = "simpleTimer "..timerName.." "..delay
	local temp = {};
	temp.func = timerName
	temp.pointers = {}
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "help" 
		and scriptName ~= "config" then
			if v[timerName]and not v.disableScript then
				table.insert(temp.pointers,scriptName)
			end
		end
	end
	if #temp.pointers == 0 then
		debugInfo = "Function does not exist.  Simple timer not created. "..timerName.." "..delay
		return
	end
	temp.time = OFP:getMissionTime() + delay
	if delay ~= -1 then
		temp.set = true
	end
	temp.ID = ID
	if ... then
		temp.args = {...}
	end
	timerTable[timerName] = temp
	ID = ID + 1
	debugInfo = nil
	return temp.ID
end

function EDX:serialTimer(timerName,delay,...)
	debugInfo = "serialTimer "..timerName.." "..delay
	local temp = {};
	temp.func = timerName
	temp.pointers = {}
	for i,v in pairs(scripts.mission) do
		local scriptName = tostring(i)
		if scriptName ~= "help"
		and scriptName ~= "config" then
			if v[timerName]and not v.disableScript then
				table.insert(temp.pointers,scriptName)
			end
		end
	end
	if #temp.pointers == 0 then
		debugInfo = "Function does not exist.  Serial timer not created. "..timerName.." "..delay
		return
	end
	temp.time = OFP:getMissionTime() + delay
	if delay ~= -1 then
		temp.set = true
	end
	if ... then
		temp.args = {...}
	end
	temp.ID = ID
	timerTable[ID] = temp
	ID = ID + 1
	debugInfo = nil
	return temp.ID
end

function EDX:setTimer( timerID, delay,...)
	debugInfo = "resetting timer "..timerID.." "..delay
	local temp = timerTable[timerID]
	if not temp then
		return -1
	else
		temp.time = OFP:getMissionTime() + delay
		if delay ~= -1 then
			temp.set = true
		end
		if ... then
			temp.args = {...}
		end
		timerTable[timerID] = temp
		debugInfo = nil
		return timerID
	end
end

function EDX:triggerTimer(timerID)
	debugInfo = "triggerTimer "..timerID
	if timerTable[timerID] then
		local _timer = timerTable[timerID]
		_timer.set = nil
		timerTable[timerID] = _timer
		for _,script in pairs(_timer.pointers) do
			local f = scripts.mission[script][_timer.func]
			if f then
				if _timer.args then
						local argTable = _timer.args
						argTable[#argTable + 1] = _timer.ID
						f(unpack(argTable))
				else
					f(_timer.ID)
				end
			end
		end
	end
end

function EDX:serializeTimer(timerID)
	debugInfo = "serializeTimer "..timerID
	if timerTable[timerID]  and timerTable[timerID].ID ~= timerID then
		local _timer = timerTable[timerID]
		timerTable[_timer.ID] = _timer
		timerTable[timerID] = nil
		return _timer.ID
	end
end

function EDX:disableTimer(timerID)
	debugInfo = "disableTimer "..timerID
	if timerTable[timerID] then
		timerTable[timerID].set = nil
	end
end

function EDX:deleteTimer(timerID)
	diagLog("deleteTimer "..timerID)
	timerTable[timerID] = nil
end

function EDX:setTimerVar(timerID,varName,value)
	debugInfo = "setVar "..timerID.." "..varName
	if timerTable[timerID] then
		timerTable[timerID][varName] = value
	end
	debugInfo = nil
end

function EDX:getTimerVar(timerID,varName)
	debugInfo = "getVar "..timerID.." "..varName
	if timerTable[timerID] and timerTable[timerID][varName] then
		debugInfo = nil
		return timerTable[timerID][varName]
	end
	debugInfo = nil
	return nil
end

function EDX:deleteTimerVar(timerID,varName)
	debugInfo = "deleteVar "..timerID.." "..varName
	if timerTable[timerID] and timerTable[timerID][varName] then
		timerTable[timerID][varName] = nil
	end
	debugInfo = nil
end

function EDX:isGameInit()
	return gameInit;
end

-----------------------------------------------------------------------------------Unit management functions

function EDX:setMissionFolder(folderName)
	if folderName then
		missionPath = "./data_win/missions/"..folderName.."/"
	end
end

function EDX:getMissionFolder()
	return missionPath
end

function EDX:registerPlayerEchelon(echelonName,removeAI)
	if lcp then return end
	if OFP:isEchelon(echelonName) then
		playerEchelon = echelonName;
		for i = 0,OFP:getEchelonSize(echelonName) - 1 do
			local un = OFP:getEchelonMember(echelonName,i);
			if OFP:isUnit(un) then
				if not EDX:registerPlayer(un) then
					EDX:registerPlayable(un,removeAI);
				end
			end
		end
	end
end

function EDX:getPlayerEchelon()
	return playerEchelon;
end

function EDX:registerPlayer(entityName)
	if lcp then return end
	if OFP:isPlayer(entityName) and not OFP:isSecondaryPlayer(entityName) and not EDX:isInTable(entityName, playerEntities) then
		table.insert(playerEntities, entityName)
		primaryPlayer = entityName
		if playerEchelon == "" then playerEchelon = OFP:getParentEchelon(entityName) end
		playerBearing[entityName] = {0, {OFP:getPosition(entityName)}}
		EDX:serialTimer("calcPlayerBearing", 1000, entityName)
		return true;
	end
end

function EDX:registerPlayable(entityName, boolRemove)
	if lcp then return end
	if OFP:isSecondaryPlayer(entityName) and not EDX:isInTable(entityName, playerEntities) then
		coop = true
		table.insert(playerEntities, entityName)
		playerBearing[entityName] = {0, {OFP:getPosition(entityName)}}
		EDX:serialTimer("calcPlayerBearing", 1000, entityName)
		return true;
	else
		if boolRemove then
			OFP:despawnEntity(entityName)
		else
			EDX:setAutoLights(entityName)
			playerAI[#playerAI+1] = entityName;
		end
	end
end

function EDX:isCoop()
	return coop
end

function EDX:getPrimaryPlayer()
	return primaryPlayer
end

function EDX:getPlayerLeader()
	for i,v in ipairs(playerEntities) do
		if OFP:isPlayer(v) or OFP:isSecondaryPlayer(v) then
			if OFP:isAlive(v) then
				return v;
			end
		end
	end
end

playerFail = {};

function playerCheck()
	local temp = {};
	for i,v in ipairs(playerEntities) do
		if OFP:isAlive(v) and not OFP:isPlayer(v) then
			if not playerFail[v] then
				playerFail[v] = 1;
				temp[#temp+1] = v;
			elseif playerFail[v] <= 10 then
				playerFail[v] = playerFail[v] + 1;
				temp[#temp+1] = v;
			else
				playerFail[v] = nil;
				EDX:setAutoLights(v);
				playerAI[#playerAI+1] = v;
			end
		else
			if playerFail[v] then playerFail[v] = nil end
			temp[#temp+1] = v;
		end
	end
	if #temp ~= #playerEntities then
		playerEntities = temp;
	end
end

function EDX:getPlayers()
	return playerEntities
end

function EDX:getPlayerBearing(playerEntityName)
	local entityName = playerEntityName or primaryPlayer
	if playerBearing[entityName] then
		return playerBearing[entityName][1]
	end
end

function EDX:setBearingDist(dist)
	BEARING_DIST = dist;
end
function calcPlayerBearing(entityName, timerID)
	if not OFP:isPlayer(entityName) and not OFP:isSecondaryPlayer(entityName) then
		playerBearing[entityName] = nil;
		EDX:deleteTimer(timerID);
		return;
	end
	if OFP:isAlive(entityName) then
		local temp = playerBearing[entityName]
		local newPos = {OFP:getPosition(entityName)}
		local oldPos = temp[2]
		if EDX:get2dDistance(newPos[1], newPos[3], oldPos[1], oldPos[3]) > BEARING_DIST then
			temp[1] = math.floor(EDX:getBearing(oldPos[1], oldPos[3], newPos[1], newPos[3]))
			temp[2] = newPos
			playerBearing[entityName] = temp
		end
	end
	EDX:setTimer(timerID, 1000)
end

function EDX:setAutoLights(unitGroupOrEchelonName)
	if OFP:isGroup(unitGroupOrEchelonName) or OFP:isEchelon(unitGroupOrEchelonName) then
		local units = EDX:grpToTable(unitGroupOrEchelonName)
		for i, unit in ipairs(units) do
			if OFP:isUnit(unit) and lights[unit] == nil and not EDX:isInTable(unit, playerEntities) then
				lights[unit] = false
			elseif OFP:isEchelon(unit) then
				EDX:setAutoLights(unit)
			end
		end
	elseif OFP:isUnit(unitGroupOrEchelonName) then
		lights[unitGroupOrEchelonName] = false
	end
	if not lightTimer then
		lightTimer = EDX:simpleTimer("autoLightsMaintenance", 1000)
	end
end

function EDX:setAutoLightsHours(onHour, offHour)
	lightOnHour = onHour
	lightOffHour = offHour
end

function EDX:disableAutoLights()
	if lightTimer then
		EDX:deleteTimer("autoLightsMaintenance")
		lightTimer = nil
	end
	lights = {}
end

function autoLightsMaintenance()
	debugInfo = "start autoLightsMaintenance"
	EDX:setTimer("autoLightsMaintenance", 1000)
	local h, m, s = EDX:getTimeOfDay()
	local turnOnHour = lightOnHour or 20
	local turnOffHour = lightOffHour or 5
	for unit, lightOn in pairs(lights) do
		if OFP:isAlive(unit) then
			if h >= turnOnHour or h < turnOffHour then
				if EDX:isSoldier(unit) then
					debugInfo = "checking lights for soldier"
					local morale = OFP:getMorale(unit)
					local ROE = OFP:getROE(unit)
					if lightOn then
						debugInfo = "checking lights soldier light on"
						if ROE == "eHoldFire"
						or ROE == "eReturnFire"
						or ROE == "eFireOnMyLead"
						or morale == "EBreaking"
						or morale == "EBroken" then
							lights[unit] = false
							OFP:setLights(unit, false)
						end
					else
						debugInfo = "checking lights soldier light off"
						if  ROE ~= "eHoldFire"
						and ROE ~= "eReturnFire"
						and ROE ~= "eFireOnMyLead"
						and morale ~= "EBreaking"
						and morale ~= "EBroken" then
							lights[unit] = true
							OFP:setLights(unit, true)
						end
					end
				else
					debugInfo = "checking lights for vehicle"
					local vehicleLeader = OFP:getVehicleLeaderSoldier(unit)
					if vehicleLeader == "" then
						if lightOn then
							lights[unit] = false
							OFP:setLights(unit, false)
						end
					else
						local morale = OFP:getMorale(vehicleLeader)
						local ROE = OFP:getROE(vehicleLeader)
						if lightOn then
							debugInfo = "checking lights vehicle light on"
							if ROE == "eHoldFire"
							or ROE == "eReturnFire"
							or ROE == "eFireOnMyLead"
							or morale == "EBreaking"
							or morale == "EBroken" then
								lights[unit] = false
								OFP:setLights(unit, false)
							end
						else
							debugInfo = "checking lights vehicle light off"
							if  ROE ~= "eHoldFire"
							and ROE ~= "eReturnFire"
							and ROE ~= "eFireOnMyLead"
							and morale ~= "EBreaking"
							and morale ~= "EBroken" then
								lights[unit] = true
								OFP:setLights(unit, true)
							end
						end
					end
				end
			else
				if lightOn then
					lights[unit] = false
					OFP:setLights(unit, false)
				end
			end
		else
			if not EDX:isInTable(unit,playerAI) then
				lights[unit] = nil;
			else
				lights[unit] = false;
			end
		end
	end
end

function EDX:canSeeAny(entityName,groupName)
	local size = OFP:getGroupSize(groupName)
	for i=0,size-1 do
		if debug:canSee(entityName,OFP:getGroupMember(groupName,i)) then
			return true
		end
	end
	return false
end

function EDX:getSquadEchelons( squadEchelonName)
	local squadEchelons = {}
	if not OFP:isEchelon(OFP:getLeaderOfEchelon(squadEchelonName)) then
		return
	end
	local index = 0
	local echelon = OFP:getEchelonMember(squadEchelonName,index)
	while echelon do
		table.insert(squadEchelons,echelon)
		index = index + 1
		echelon = OFP:getEchelonMember(squadEchelonName,index)
	end
	for i,ech in ipairs(squadEchelons) do
		local temp = {}
		index = 0
		local member = OFP:getEchelonMember(ech,index)
		while member do
			table.insert(temp,member)
			index = index + 1
			member = OFP:getEchelonMember(ech,index)
		end
		temp.leader = OFP:getLeaderOfEchelon(ech)
		squadEchelons[ech] = temp
	end
	return squadEchelons	
end

function EDX:fireTeamRecruiter( ftName,groupName,attachDist,ftMaxSize,squadEchelon)
	local leader = OFP:getLeaderOfEchelon(ftName);
	if squadEchelon then
		local leadEch = OFP:getLeaderOfEchelon(squadEchelon);
		leader = OFP:getLeaderOfEchelon(leadEch);
	end
	if not OFP:isPlayer(leader) and not OFP:isSecondaryPlayer(leader) then
		return
	end
	local playerAdjust = 0
	if coop then
		for i,v in ipairs(playerEntities) do
			if not OFP:isAlive(v) then
				playerAdjust = playerAdjust + 1
			end
		end
	end
	local group_size = OFP:getGroupSize(groupName);
	if OFP:getEchelonSize(ftName) + playerAdjust < ftMaxSize then
		local tempDist = 0
		local nearestDist = 999999;
		local nearest,ech
		for i=0,group_size-1 do
			local member = OFP:getGroupMember(groupName,i);
			local echelon = OFP:getParentEchelon(member);
			tempDist = OFP:getDistance(leader,member)
			if echelon ~= squadEchelon
			and echelon ~= ftName
			and tempDist < nearestDist
			and tempDist <= attachDist then
				nearestDist = tempDist
				nearest = member
				ech = echelon
			end
		end
		if nearest then
			if not playerTeam then playerTeam = {} end
			local player_team = playerTeam[ech]
			if player_team then
				if player_team.unit then
					table.insert(player_team.unit,nearest)
				else
					player_team.unit = {nearest}
				end
			else
				player_team = {}
				player_team.echelon = ech
				player_team.unit = {}
				table.insert(player_team.unit,nearest)
			end
			playerTeam[ech] = player_team
			OFP:detach(ech,nearest);
			OFP:attach(ftName,nearest);
		end
	end
end

function EDX:squadRecruiter( squadEchelon,groupName,attachDist,detachDist,maxSquadSize)
	local leadEch = OFP:getLeaderOfEchelon(squadEchelon);
	local leader = OFP:getLeaderOfEchelon(leadEch);
	if not OFP:isPlayer(leader) and not OFP:isSecondaryPlayer(leader) then
		return
	end
	local squad_size = OFP:getEchelonSize(squadEchelon);
	debug_squad_size = squad_size;
	local group_size = OFP:getGroupSize(groupName);
	local numberEchelons = 0;
	if squadech_table == nil then
		squadech_table = {};
		local i = 0
		local ech = OFP:getEchelonMember(squadEchelon,i);
		while ech do
			table.insert(squadech_table,ech);
			i = i + 1
			ech = OFP:getEchelonMember(squadEchelon,i);
		end
	else
		if group_size > 0 then
			if #squadech_table < maxSquadSize then
				for i=0,group_size - 1 do
					local member = OFP:getGroupMember(groupName,i);
					local echelon = OFP:getParentEchelon(member);
					if echelon ~= squadEchelon then
						local ech_dist = OFP:getDistance(leader,echelon);
						if ech_dist <= attachDist and not OFP:isAnyMounted(echelon) then
							OFP:clearCommandQueue(echelon);
							OFP:attach(squadEchelon,echelon);
							resetOrders(echelon);
							table.insert(squadech_table,echelon)
							return
						end
					end
				end
			end
		end
		local temp_table = {};
		for i,v in ipairs(squadech_table) do
			local member = v;
			if OFP:isAlive(member) then
				local canDetach = true;
				for ii=0, OFP:getEchelonSize(member) - 1 do
					local echMember = OFP:getEchelonMember(member,ii);
					if OFP:getDistance(leader,echMember) <= detachDist then
						canDetach = false;
					end
				end
				if canDetach then
					OFP:detach(squadEchelon,member);
					OFP:clearCommandQueue(member);
					table.insert(temp_table,v);
				end
			else
				OFP:detach(squadEchelon,member);
				table.insert(temp_table,v);
			end
		end
		for i,v in ipairs(temp_table) do
			EDX:removeArrayElements(squadech_table,v);
		end
	end
end

function EDX:condenseSquad( squadName, maxSize)
	local echTable = {}
	local isSquad = false
	if OFP:isEchelon(OFP:getLeaderOfEchelon(squadName)) then
		isSquad = true
		local index = 0
		local echelon = OFP:getEchelonMember(squadName,index)
		while echelon do
			echTable[echelon] = {}
			local unitIndex = 0
			local unit = OFP:getEchelonMember(echelon,unitIndex)
			while unit do
				table.insert(echTable[echelon],unit)
				unitIndex = unitIndex + 1
				unit = OFP:getEchelonMember(echelon,unitIndex)
			end
			index = index + 1
			echelon = OFP:getEchelonMember(squadName,index)
		end
	end
	if isSquad then
		local leadEch = OFP:getLeaderOfEchelon(squadName)
		if #echTable[leadEch] < maxSize then
			for ech,units in pairs(echTable) do
				if ech ~= leadEch then
					if #echTable[ech] > 0 then
						while #echTable[leadEch] < maxSize and #echTable[ech] > 0 do
							OFP:detach(ech,units[1])
							OFP:attach(leadEch,units[1])
							table.insert(echTable[leadEch],units[1])
							table.remove(echTable[ech],1)
						end
					end
				end
			end
		end
		for ech,units in pairs(echTable) do
			if ech ~= leadEch then
				if #echTable[ech] < maxSize then
					for e,u in pairs(echTable) do
						if e ~= leadEch and e ~= ech then
							while #echTable[e] > 0 and #echTable[e] < maxSize and #echTable[ech] < maxSize do
								OFP:detach(e,u[1])
								OFP:attach(ech,u[1])
								table.insert(echTable[ech],u[1])
								table.remove(echTable[e],1)
							end
						end
					end
				end
			end
		end
		for ech,units in pairs(echTable) do
			if OFP:getEchelonSize(ech) == 0 then
				OFP:detach(squadName,ech)
			else
				if ech ~= OFP:getParentEchelon(squadName) then
					OFP:setIsControlledByParent(ech,true)
				end
			end
		end
	end
end

function EDX:getCurrentWeapon(unitName)
	if not OFP:isUnit(unitName) or OFP:getBroadUnitCategory(unitName) ~= "BROAD_UNIT_SOLDIER" then
		return ""
	else
		local index = debug:getCurrentWeaponIndex(unitName)
		local weaponCur = debug:getWeaponName(unitName,index)
		return weaponCur,index
	end
end

function EDX:isGround( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	local cat = OFP:getBroadUnitCategory(entity)
	if cat == "BROAD_UNIT_VEHICLE" or cat == "BROAD_UNIT_ARMOUR" then
		return true
	end
	return false
end

function EDX:isArmored( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	local cat = OFP:getBroadUnitCategory(entity)
	if  cat == "BROAD_UNIT_ARMOUR" then
		return true
	end
	return false
end

function EDX:isAir( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	local cat = OFP:getBroadUnitCategory(entity)
	if cat == "BROAD_UNIT_AIRCRAFT" then
		return true
	end
	return false
end

function EDX:isStatic( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	local cat = OFP:getBroadUnitCategory(entity)
	if cat == "BROAD_UNIT_STATIC" then
		return true
	end
	return false
end

function EDX:isSoldier( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	local cat = OFP:getBroadUnitCategory(entity)
	if cat == "BROAD_UNIT_SOLDIER" then
		return true
	end
	return false
end

function EDX:isVehicle( entity)
	if OFP:isEchelon(entity) then
		return false
	end
	return EDX:isAir(entity) or EDX:isGround(entity);
end

-----------------------------------------------------------------------------------Data management functions

function EDX:getNearest(entityNameOrPosition,tableGroupOrEchelonName,minDist,maxDist)
	local nearest = "";
	local nearest_dist = 99999;
	if not entityNameOrPosition or not tableGroupOrEchelonName then
		return "",-1
	end
	local list = tableGroupOrEchelonName
	if type(list) == "table" then
	elseif OFP:isEchelon(tableGroupOrEchelonName)
	or OFP:isGroup(tableGroupOrEchelonName) then
		list = EDX:grpToTable(tableGroupOrEchelonName)
	else
		return "",-1
	end
	local min_dist = minDist
	if not min_dist then
		min_dist = 0
	end
	local max_dist = maxDist
	if not max_dist then
		max_dist = 99999
	end
	local x, y, z
	if type(entityNameOrPosition) == "table" then
		x, y, z = entityNameOrPosition[1], entityNameOrPosition[2], entityNameOrPosition[3]
	else
		x, y, z = OFP:getPosition(entityNameOrPosition)
	end
	for i,v in ipairs(list) do
		if i ~= "__nopersist__" and type(v) == "string" then
			local member = v;
			local mx, my, mz
			if type(member) == "table" then
				mx, my, mz = member[1], member[2], member[3]
			else
				mx, my, mz = OFP:getPosition(member)
			end
			local temp_dist = EDX:get3dDistance( x, y, z, mx, my, mz)
			if entityName ~= member
			and temp_dist ~= -1
			and temp_dist < nearest_dist
			and temp_dist > min_dist
			and temp_dist < max_dist then
				nearest = member
				nearest_dist = temp_dist
			end
		end
	end
	if nearest == "" then
		nearest_dist = -1
	end
	return nearest,nearest_dist
end

function EDX:getFurthest(entityNameOrPosition,tableGroupOrEchelonName,minDist,maxDist)
	local furthest = "";
	local furthest_dist = 0;
	if not entityNameOrPosition or not tableGroupOrEchelonName then
		return "",-1
	end
	local list = tableGroupOrEchelonName
	if type(list) == "table" then
	elseif OFP:isEchelon(tableGroupOrEchelonName)
	or OFP:isGroup(tableGroupOrEchelonName) then
		list = EDX:grpToTable(tableGroupOrEchelonName)
	else
		return "",-1
	end
	local min_dist = minDist
	if not min_dist then
		min_dist = 0
	end
	local max_dist = maxDist
	if not max_dist then
		max_dist = 99999
	end
	local x, y, z
	if type(entityNameOrPosition) == "table" then
		x, y, z = entityNameOrPosition[1], entityNameOrPosition[2], entityNameOrPosition[3]
	else
		x, y, z = OFP:getPosition(entityNameOrPosition)
	end
	for i,v in ipairs(list) do
		if i ~= "__nopersist__" and type(v) == "string" then
			local member = v;
			local mx, my, mz
			if type(member) == "table" then
				mx, my, mz = member[1], member[2], member[3]
			else
				mx, my, mz = OFP:getPosition(member)
			end
			local temp_dist =  EDX:get3dDistance( x, y, z, mx, my, mz)
			if temp_dist > furthest_dist
			and temp_dist ~= -1
			and temp_dist > min_dist
			and temp_dist < max_dist then
				furthest = member;
				furthest_dist = temp_dist;
			end
		end
	end
	if furthest == "" then
		furthest_dist = -1
	end
	return furthest,furthest_dist
end

function EDX:get4Nearest( entityNameOrPosition,tableGroupOrEchelonName,minDist,maxDist)
	local nearest = {};
	local n1,n2,n3,n4 = "","","",""
	local d1,d2,d3,d4 = 99999,99999,99999,99999;
	if not entityNameOrPosition or not tableGroupOrEchelonName then
		return "",-1
	end
	local list = tableGroupOrEchelonName
	if type(list) == "table" then
	elseif OFP:isEchelon(tableGroupOrEchelonName)
	or OFP:isGroup(tableGroupOrEchelonName) then
		list = EDX:grpToTable(tableGroupOrEchelonName)
	else
		return "",-1
	end
	local min_dist = minDist
	if not min_dist then
		min_dist = 0
	end
	local max_dist = maxDist
	if not max_dist then
		max_dist = 99999
	end
	local x, y, z
	if type(entityNameOrPosition) == "table" then
		x, y, z = entityNameOrPosition[1], entityNameOrPosition[2], entityNameOrPosition[3]
	else
		x, y, z = OFP:getPosition(entityNameOrPosition)
	end
	for i,v in ipairs(list) do
		local member = v;
		local mx, my, mz
		if type(member) == "table" then
			mx, my, mz = member[1], member[2], member[3]
		else
			mx, my, mz = OFP:getPosition(member)
		end
		local temp_dist =  EDX:get3dDistance( x, y, z, mx, my, mz)
		if entityName ~= member
		and temp_dist ~= -1
		and temp_dist > min_dist
		and temp_dist < max_dist then
			if temp_dist < d1 then
				d4, n4 = d3, n3
				d3, n3 = d2, n2
				d2, n2 = d1, n1
				d1,n1 = temp_dist,member
			elseif temp_dist < d2 then
				d4, n4 = d3, n3
				d3, n3 = d2, n2
				d2,n2 = temp_dist,member
			elseif temp_dist < d3 then
				d4,n4 = d3,n3
				d3,n3 = temp_dist,member
			elseif temp_dist < d4 then
				d4,n4 = temp_dist,member
			end
		end
	end
	return n1,n2,n3,n4
end

function EDX:getNearestGroupMember(entity,group)
	local dist = -1;
	local index = OFP:getNearestGroupMemberIndex(entity,group) - 1;
	local nearest = OFP:getGroupMember(group,index);
	if nearest ~= entity and nearest ~= "" then
		dist = OFP:getDistance(entity,nearest);
	end
	return nearest,dist,index;
end

function EDX:isAnyInRange( entityName,tableGroupOrEchelonName,distance)
	local list = tableGroupOrEchelonName
	if not list then
		return false
	elseif OFP:isGroup(list) then
		list = EDX:grpToTable(tableGroupOrEchelonName)
	elseif OFP:isEchelon(list) then
		list = EDX:grpToTable(tableGroupOrEchelonName)
	end
	if type(list) == "string" then
		local dist = OFP:getDistance(entityName,list)
		if dist <= distance and dist ~= -1 then
			return true
		end
	elseif type(list) == "table" then
		for i,v in ipairs(list) do
			local dist = OFP:getDistance(entityName,v)
			if dist ~= -1
			and dist <= distance then
				return true
			end
		end
	end
	return false
end

function EDX:isAllInRange( entityName,tableEntityGroupOrEchelonName,distance)
	local list = tableEntityGroupOrEchelonName
	if not entityName or not list or not distance then
		return false
	elseif OFP:isGroup(list) then
		list = EDX:grpToTable(tableEntityGroupOrEchelonName)
	elseif OFP:isEchelon(list) then
		list = EDX:grpToTable(tableEntityGroupOrEchelonName)
	end
	if type(list) == "string" then
		local dist = OFP:getDistance(entityName,list)
		if dist > distance or dist == -1 then
			return false
		end
	elseif type(list) == "table" then
		local allDead = true
		for i,v in ipairs(list) do
			local dist = OFP:getDistance(entityName,v)
			if dist ~= -1 then
				if dist > distance then
					return false
				else
					allDead = nil
				end
			end
		end
	end
	if allDead then
		return false
	end
	return true
end

function EDX:grpToTable(groupOrEchelonName)
	local newTbl = {}
	local grpName = groupOrEchelonName
	if not grpName then
		return newTbl;
	elseif OFP:isEchelon(grpName) then
		local size = OFP:getEchelonSize(grpName)
		for i=0,size-1 do
			local grpMember = OFP:getEchelonMember(grpName,i)
			table.insert(newTbl,grpMember)
		end
		return newTbl
	elseif OFP:isGroup(grpName) then
		local size = OFP:getGroupSize(grpName)
		for i=0,size-1 do
			local grpMember = OFP:getGroupMember(grpName,i)
			table.insert(newTbl,grpMember)
		end
		return newTbl
	else
		return newTbl
	end
end

function EDX:isInTable( entity,tableName)
	if entity == nil or tableName == nil then
		return false;
	end
	for i,v in pairs(tableName) do
		if type(v) == "string" and string.lower(entity) == string.lower(v) then
			return i
		end
	end
	return false
end

function EDX:getRandom(tableGroupOrEchelonName,entityNameOrPosition,minDist,maxDist)
	if not tableGroupOrEchelonName then
		return false;
	end
	local index;
	local get_random = "";
	local list = tableGroupOrEchelonName;
	local min_dist = minDist
	local max_dist = maxDist
	if not minDist then
		min_dist = 0
	end
	if not maxDist then
		max_dist = 99999
	end
	if type(list) == "table" then
		local size = #list;
		if size > 0 then
			index = math.random(1,size)
		else
			return "",-1
		end
		if entityNameOrPosition then
			local x, y, z
			if type(entity) == "table" then
				x, y, z = entityNameOrPosition[1], entityNameOrPosition[2], entityNameOrPosition[3]
			else
				x, y, z = OFP:getPosition(entityNameOrPosition)
			end
			if minDist or maxDist then
				local indexList = {}
				for i=1,size do
					local member = list[i]
					local mx, my, mz
					if type(member) == "table" then
						mx, my, mz = member[1], member[2], member[3]
					else
						mx, my, mz = OFP:getPosition(member)
					end
					local dist =  EDX:get3dDistance( x, y, z, mx, my, mz)
					if dist >= min_dist and dist <= max_dist then
						table.insert(indexList,i)
					end
				end
				if #indexList > 0 then
					index = EDX:getRandom(indexList)
				else
					return "",-1
				end
			end
		end	
		get_random = list[index];
	elseif OFP:isEchelon(list) then
		local size = OFP:getEchelonSize(list) - 1;
		if size > 0 then
			index = math.random(0,size);
		else
			return "",-1
		end
		if entityNameOrPosition then
			if minDist or maxDist then
				local indexList = {}
				for i=0,size - 1 do
					local member = OFP:getEchelonMember(list,i)
					local mx, my, mz
					if type(member) == "table" then
						mx, my, mz = member[1], member[2], member[3]
					else
						mx, my, mz = OFP:getPosition(member)
					end
					local dist =  EDX:get3dDistance( x, y, z, mx, my, mz)
					if dist >= min_dist and dist <= max_dist then
						table.insert(indexList,i)
					end
					if dist >= min_dist and dist <= max_dist then
						table.insert(indexList,i)
					end
				end
				if #indexList > 0 then
					index = EDX:getRandom(indexList)
				else
					return "",-1
				end
			end
		end	
		get_random = OFP:getEchelonMember(list,index);
	elseif OFP:isGroup(list) then
		local size = OFP:getGroupSize(list) - 1;
		if size > 0 then
			index = math.random(0,size);
		else
			return "",-1
		end
		if entityNameOrPosition then
			if minDist or maxDist then
				local indexList = {}
				for i=0,size - 1 do
					local member = OFP:getGroupMember(list,i)
					local mx, my, mz
					if type(member) == "table" then
						mx, my, mz = member[1], member[2], member[3]
					else
						mx, my, mz = OFP:getPosition(member)
					end
					local dist =  EDX:get3dDistance( x, y, z, mx, my, mz)
					if dist >= min_dist and dist <= max_dist then
						table.insert(indexList,i)
					end
					if dist >= min_dist and dist <= max_dist then
						table.insert(indexList,i)
					end
				end
				if #indexList > 0 then
					index = EDX:getRandom(indexList)
				else
					return "",-1
				end
			end
		end	
		get_random = OFP:getGroupMember(list,index);
	end
	return get_random,index
end

function EDX:randomChance( percentage)
	if not percentage then
		return false
	else
		local chance = (math.random(0,1000) / 10)
		if chance <= percentage then
			return true
		else
			return false
		end
	end
end

------------------------------------------------------------------Edex Time Management functions

function EDX:getTimeOfDay(boolDisplay)
	local ms_start = OFP:convertTimeToMilliSeconds(edxHours, edxMinutes, edxSeconds)
	local ms_current = OFP:getMissionTime()
	local ms_passed = (ms_current - lastMissionTime) * 3
	local ms_total = ms_start + ms_passed
	local hrs,mins,secs = OFP:convertTimeToHMS(ms_total)
	while hrs > 23 do
		hrs = hrs - 24
	end
	display = string.format(" %02d:%02d:%02d", hrs, mins, secs)
	if boolDisplay then
		OFP:displaySystemMessage(display)
	end
	return hrs, mins, secs, display
end

function EDX:setTimeOfDay( h, m, s)
	edxHours, edxMinutes, edxSeconds = h,m,s
	lastMissionTime = OFP:getMissionTime()
	OFP:setTimeOfDay(h, m, s)
	fireSimpleEH("onTimeChange",h,m,s)
end

function EDX:advanceTime()
	local h,m,s = EDX:getTimeOfDay()
	h = h + 1
	while h > 23 do
		h = h - 24
	end
	lastMissionTime = OFP:getMissionTime()
	EDX:setTimeOfDay(h,m,s)
	fireSimpleEH("onTimeChange",h,m,s)
end

function EDX:setRandomTime()
	local h = math.random(0, 23)
	local m = math.random(0, 59)
	lastMissionTime = OFP:getMissionTime()
	EDX:setTimeOfDay(h, m, 0)
	fireSimpleEH("onTimeChange",h,m,0)
end

---------------------------------------------------------------Edex weather management functions

WEATHERTYPES = {
	__nopersist__ = true,
	[0] = "clear",
	[1] = "foggy",
	[2] = "cloudy",
	[3] = "overcast",
	[4] = "stormy",
	["clear"] = 0,
	["foggy"] = 1,
	["cloudy"] = 2,
	["overcast"] = 3,
	["stormy"] = 4,
}

function EDX:setFogTarget(fog, transitionTime)
	local delay = transitionTime * 60000
	local h, m, s = EDX:getTimeOfDay()
	local ms = OFP:convertTimeToMilliSeconds(h, m, s)
	local changeTime = ms + (delay * 3)
	h, m, s = OFP:convertTimeToHMS(changeTime)
	while h > 24 do
		h = h -24
	end
	OFP:setFogTarget(fog, h, m, s)
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return fog
end

function EDX:setWeatherTarget(weatherType, transitionTime)
	local delay = transitionTime * 60000
	local newWeather = weatherType
	if type(weatherType) == "string" then
		newWeather = WEATHERTYPES[weatherType]
	end
	local h, m, s = EDX:getTimeOfDay()
	local ms = OFP:convertTimeToMilliSeconds(h, m, s)
	local changeTime = ms + (delay * 3)
	h, m, s = OFP:convertTimeToHMS(changeTime)
	while h > 24 do
		h = h -24
	end
	OFP:setWeatherTarget(newWeather, h, m, s)
	edxWeatherType = newWeather
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return WEATHERTYPES[newWeather]
end

function EDX:randomizeWeather( changeDelay)
	local delay = changeDelay * 60000
	if not weatherTimer then
		weatherTimer = EDX:simpleTimer( "randomizeWeather", delay, changeDelay)
		diagLog("Weather timer initialized with delay of "..delay)
	else
		local h, m, s = EDX:getTimeOfDay()
		local ms = OFP:convertTimeToMilliSeconds(h, m, s)
		local changeTime = ms + delay
		h, m, s = OFP:convertTimeToHMS(changeTime)
		while h > 24 do
			h = h -24
		end
		local wt = math.random(0, 4)
		local fd = math.random(0, 100)
		OFP:setWeatherTarget(wt, h, m, s)
		OFP:setFogTarget(wt, h, m, s)
		edxWeatherType = wt
		edxFogDensity = fd
		EDX:setTimer( "randomizeWeather", delay, changeDelay)
		diagLog("New Weather type is "..wt.." and fog density is "..fd)
	end
end

--private random weather to handle timer calls
function randomizeWeather( changeDelay)
	local delay = changeDelay * 60000
	if not weatherTimer then
		weatherTimer = EDX:simpleTimer( "randomizeWeather", delay, changeDelay)
		diagLog("Weather timer initialized with delay of "..delay)
	else
		local h, m, s = EDX:getTimeOfDay()
		local ms = OFP:convertTimeToMilliSeconds(h, m, s)
		local changeTime = ms + delay
		h, m, s = OFP:convertTimeToHMS(changeTime)
		while h > 24 do
			h = h -24
		end
		local wt = math.random(0, 4)
		local fd = math.random(0, 100)
		OFP:setWeatherTarget(wt, h, m, s)
		OFP:setFogTarget(wt, h, m, s)
		edxWeatherType = wt
		edxFogDensity = fd
		EDX:setTimer( "randomizeWeather", delay, changeDelay)
		diagLog("New Weather type is "..wt.." and fog density is "..fd)
	end
end

function EDX:stopRandomizedWeather()
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
end

function EDX:setRandomWeather()
	local wt = math.random(0, 4)
	local fd = math.random(0, 100)
	OFP:setWeatherCurrent(wt)
	OFP:setFogCurrent(wt)
	edxWeatherType = wt
	edxFogDensity = fd
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	diagLog("New Weather type is "..wt.." and fog density is "..fd)
	return WEATHERTYPES[wt], fd
end

function EDX:setRandomWeatherTarget(transitionTime)
--Transition time in minutes
	local delay = transitionTime * 60000
	local h, m, s = EDX:getTimeOfDay()
	local ms = OFP:convertTimeToMilliSeconds(h, m, s)
	local changeTime = ms + (delay * 3)
	h, m, s = OFP:convertTimeToHMS(changeTime)
	while h > 24 do
		h = h -24
	end
	local wt = math.random(0, 4)
	local fd = math.random(0, 100)
	OFP:setWeatherTarget(wt, h, m, s)
	OFP:setFogTarget(wt, h, m, s)
	edxWeatherType = wt
	edxFogDensity = fd
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	diagLog("New Weather type is "..wt.." and fog density is "..fd)
	return WEATHERTYPES[wt], fd
end

function EDX:setFogCurrent(fog)
	OFP:setFogCurrent(fog)
	edxFogDensity = fog
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return fog
end

function EDX:setWeatherCurrent(weatherType)
	local newWeather = weatherType
	if type(weatherType) == "string" then
		newWeather = WEATHERTYPES[weatherType]
	end
	OFP:setWeatherCurrent(newWeather)
	edxWeatherType = newWeather
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return WEATHERTYPES[newWeather]
end

function EDX:cycleWeatherType()
	edxWeatherType = edxWeatherType + 1
	if edxWeatherType > 4 then
		edxWeatherType = 0
	end
	OFP:setWeatherCurrent(edxWeatherType)
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return WEATHERTYPES[edxWeatherType]
end

function EDX:cycleFogDensity()
	edxFogDensity = edxFogDensity + 20
	if edxFogDensity > 100 then
		edxFogDensity = 0
	end
	OFP:setFogCurrent(edxFogDensity)
	if weatherTimer then
		EDX:deleteTimer("randomizeWeather")
		weatherTimer = nil
	end
	return edxFogDensity
end

function EDX:getWeatherType()
	return WEATHERTYPES[edxWeatherType]
end

function EDX:getFogDensity()
	return edxFogDensity
end

------------------------------------------------------------Edex spatial relationship functions
function EDX:get3dDistance( x1,y1,z1,x2,y2,z2)
	local dist = -1
	if x1 and y1 and z1 and x2 and y2 and z2 then
		dist = math.sqrt(math.pow(x1-x2,2)+math.pow(y1-y2,2)+math.pow(z1-z2,2));
		return dist;
	else
		return dist;
	end
end

function EDX:getEntity3dDistance( entity,x2,y2,z2)
	local x1,y1,z1 = OFP:getPosition(entity)
	local dist = -1
	if x1 and y1 and z1 and x2 and y2 and z2 then
		dist = math.sqrt(math.pow(x1-x2,2)+math.pow(y1-y2,2)+math.pow(z1-z2,2));
		return dist;
	else
		return dist;
	end
end

function EDX:get2dDistance( x1,z1,x2,z2)
	local dist = -1
	if x1 and z1 and x2 and z2 then
		dist = math.sqrt(math.pow(x1-x2,2)+math.pow(z1-z2,2));
		return dist;
	else
		return dist;
	end
end

function EDX:getEntity2dDistance( entity,x2,z2)
	local x1,y1,z1 = OFP:getPosition(entity)
	local dist = -1
	if x1 and z1 and x2 and z2 then
		dist = math.sqrt(math.pow(x1-x2,2)+math.pow(z1-z2,2));
		return dist;
	else
		return dist;
	end
end

function EDX:getEntities2dDistance( entity1,entity2)
	local x1,y1,z1 = OFP:getPosition(entity1)
	local x2,y2,z2 = OFP:getPosition(entity2)
	local dist = -1
	if x1 and z1 and x2 and z2 then
		dist = math.sqrt(math.pow(x1-x2,2)+math.pow(z1-z2,2));
		return dist;
	else
		return dist;
	end
end

function EDX:getHeading( entity1,entity2,boolDisplay,targetName)
	local tar;
	local direction;
	local dist = math.floor(OFP:getDistance(entity1,entity2) + .5);
	local x1,y1,z1 = OFP:getPosition(entity1);
	local x2,y2,z2 = OFP:getPosition(entity2);
	local bearing = math.floor(EDX:getBearing(x1, z1, x2, z2))
	heading = EDX:bearing2heading(bearing)
	local target
	if targetName then
		target = targetName.." "
	else
		target = ""
	end
	local display = target..dist.." meters "..heading.." heading "..bearing.." degrees";
	if boolDisplay then
		OFP:displaySystemMessage(display);
	end
	return heading, bearing, dist, display
end

function EDX:canSpawn( spawnPoint,fDist,eDist,side)
	local can_spawn = true;
	local fnearest = OFP:getNearestFriend(spawnPoint,side);
	local enearest = OFP:getNearestEnemy(spawnPoint,side,false);
	if fnearest ~= "" then
		if OFP:getDistance(spawnPoint,fnearest) <= fDist then
			can_spawn = false;
		end
	end
	if enearest ~= "" then
		if OFP:getDistance(spawnPoint,enearest) <= eDist then
			can_spawn = false;
		end
	end
	return can_spawn;
end

function EDX:isGroundLevel( centerPos,radius,maxDif,offset)
	local x,y,z
	if type(centerPos) == "table" then
		x,y,z = unpack(centerPos)
	else
		x,y,z = OFP:getPosition(centerPos)
	end
	local _offset = 0
	if offset then
		_offset = offset
	end
	local testDist = 1
	local br = 0;
	while testDist <= radius and br < 100 do
		br = br + 1;
		local x1,x2,z1,z2 = x-testDist,x+testDist,z-testDist,z+testDist
		local testHeights = {
			OFP:getTerrainHeight(x1,z),OFP:getTerrainHeight(x2,z),OFP:getTerrainHeight(x,z1),OFP:getTerrainHeight(x,z2),
			OFP:getTerrainHeight(x1,z1),OFP:getTerrainHeight(x2,z1),OFP:getTerrainHeight(x2,z1),OFP:getTerrainHeight(x2,z2)
		}
		for i,v in ipairs(testHeights) do
			if math.abs(y+_offset-v) > maxDif then
				return false
			end
		end
		testDist = testDist + 1
	end
	return true
end

function EDX:isInLOS(entity1,entity2,precision)
	local x,y,z,a,b,c,_precision;
	if precision then _precision = precision else _precision = 10 end
	if type(entity1) == "table" then
		x,y,z = unpack(entity1);
	elseif type(entity1) == "string" then
		x,y,z = OFP:getPosition(entity1);
	end
	if type(entity2) == "table" then
		a,b,c = unpack(entity2);
	elseif type(entity2) == "string" then
		a,b,c = OFP:getPosition(entity2);
	end
	local dist = EDX:get2dDistance(x,z,a,c);
	local de = EDX:getBearing(x,z,a,c);
	local hdif = b-y;
	local ci = dist/_precision;
	local cdist = ci;
	local br = 0;
	while cdist < dist and br < 100 do
		br = br + 1;
		local ratio = cdist/dist;
		local nx,ny,nz = EDX:get360Coordinates({x,y,z},de,0,cdist);
		if ny > y + (hdif*ratio) then
			return false;
		end
		cdist = cdist + ci;
	end
	return true;
end

ALPHA = {"P","O","N","M","L","K","J","I","H","G","F","E","D","C","B","A"};

function EDX:getGlobalGridPosition(x,y,z)
	local gx = math.floor(x*.001);
	local gz = ALPHA[(math.floor(math.abs(z)*.001))+1];
	return gx..gz
end

function EDX:getLocalGridPosition(x,y,z)
	local gx = math.floor((x-(math.floor(x*.001)*1000))*.01);
	local gy = math.floor((1000-(math.floor(math.abs(z)-((math.floor(math.abs(z)*.001))*1000))))*.01);
	return "X"..gx.."Y"..gy
end

function EDX:getGridPosition(x,y,z)
	if not x or not z then return "ERROR: Invalid parameters passed to function" end
	return EDX:getGlobalGridPosition(x,y,z).." "..EDX:getLocalGridPosition(x,y,z)
end

function EDX:getBearing( x1, z1, x2, z2)
	local tempa = x1 - x2;
	local tempb = z1 - z2;
	local dir = math.atan2(tempa,tempb);
	dir = math.deg(dir);
	dir = 360 - dir
	while dir < 0 or dir >= 360 do
		if dir < 0 then
			dir = 360 + dir;
		elseif dir >= 360 then
			dir = dir - 360;
		end
	end
	return dir
end

function EDX:getDirOffset(dir1,dir2)
	local dif = math.abs(dir1-dir2);
	if dif > 180 then
		dif = math.abs(dif - 360)
	end
	return dif
end

function EDX:getBearing2( entity1, entity2 )
	local x1, y1, z1 = OFP:getPosition(entity1)
	local x2, y2, z2 = OFP:getPosition(entity2)
	local tempa = x1 - x2;
	local tempb = z1 - z2;
	local dir = math.atan2(tempa,tempb);
	dir = math.deg(dir);
	if dir < 0 then
		dir = 360 + dir;
	end
	dir = 360 - dir;
	if dir < 0 then
		dir = dir + 360;
	end
	return dir
end

function EDX:bearing2heading(nbearing)
	local testval = -1
	if nbearing then
		testval = math.floor(nbearing)
	else
		return "ERR"
	end
	if testval < 0 or testval > 359 then
		return "ERR"
	end
	if testval >= 348.75 or testval < 11.25 then
		return "N"
	elseif testval >= 11.25 and testval < 33.75 then
		return "NNE"   
	elseif testval >= 33.75 and testval < 56.25 then
		return "NE"
	elseif testval >= 56.25 and testval < 78.75 then
		return "ENE"
	elseif testval >= 78.75 and testval < 101.25 then
		return "E"
	elseif testval >= 101.25 and testval < 123.75 then
		return "ESE"
	elseif testval >= 123.75 and testval < 146.75 then
		return "SE"
	elseif testval >= 146.25 and testval < 168.75 then
		return "SSE"
	elseif testval >= 168.75 and testval < 191.25 then
		return "S"
	elseif testval >= 191.25 and testval < 213.75 then
		return "SSW"
	elseif testval >= 213.75 and testval < 236.25 then
		return "SW"
	elseif testval >= 236.25 and testval < 258.75 then
		return "WSW"
	elseif testval >= 258.75 and testval < 281.25 then
		return "W"
	elseif testval >= 281.25 and testval < 303.75 then
		return "WNW"
	elseif testval >= 303.75 and testval < 326.25 then
		return "NW"
	elseif testval >= 326.25 and testval < 348.75 then
		return "NNW"
	end
end

function EDX:getOffset( x1, y1, z1, x2, y2, z2)
	local x, y, z = x2 - x1, y2 - y1, z2 - z1
	return x, y, z
end

function EDX:get360Coordinates( centerPoint, degrees, angle, minDistance, maxDistance)
	local x,y,z
	if type(centerPoint) == "table" then
		x,y,z = unpack(centerPoint)
	else
		x,y,z = OFP:getPosition(centerPoint)
	end
	local _degrees
	if degrees < 360
	and degrees >= 0 then
		_degrees = degrees
		if angle > 0 then
			local ang = angle/ 2
			_degrees = math.random(_degrees - ang,  _degrees + ang)
		end
	else
		_degrees = math.random(0,359)
	end
	local _radius = minDistance
	if maxDistance then
		_radius = math.random(minDistance, maxDistance)
	end
	local radians = math.rad(_degrees - 90);
	local x2 = (_radius * math.cos(radians)) + x   -- plot the new x position
	local z2 = (_radius * math.sin(radians)) + z   -- plot the new z position
	local y2 = OFP:getTerrainHeight(x2,z2); --get height of terrain at spawn location
	return x2, y2, z2
end

function EDX:playersInTrigger(zoneName)
	for i,v in ipairs(playerEntities) do
		if OFP:isInTrigger(v,zoneName) then
			return true;
		end
	end
	return false;
end

--Returns true if given 3d coordinate is within the game world
function EDX:isInWorld( x, y, z)
	if x > 0
	and x < 32000
	and z < 0
	and z > -16000
	and y > 0
	and y < 700 then
		return true
	end
	return false
end

function EDX:isOcean(x, z)
	if OFP:getTerrainHeight(x, z) <= 40 then
		return {x, 40, z}
	end
	return false
end

--Returns a lake position as a table if the given coordinate is in a lake.  The y coordinate will be the surface of the water.
function EDX:isLake(x, z)
	local lakes = {
		{{2780, 144, -126245}, 17},	{{2773, 144, -12590}, 27},	{{2769, 144, -12559}, 35},	{{2764, 144, -12502}, 43},	{{2787, 144, -12425}, 82},	{{2773, 144, -12323}, 111},	{{2785, 144, -12218}, 79},
		{{2808, 144, -12162}, 80},	{{2842, 144, -12083}, 55},	{{4349, 158, -11726}, 109},	{{4273, 158, -11677}, 128},	{{4182, 158, -11614}, 142},	{{4097, 158, -11531}, 138},	{{4036, 158, -11402}, 123},
		{{11636, 84, -11050}, 56},	{{11558, 84, -11017}, 88},	{{11463, 84, -10996}, 93},	{{11366, 84, -10951}, 49},	{{11328, 84, -10921}, 48},	{{11277, 84, -10899}, 60},	{{11224, 84, -10865}, 81},
		{{11158, 84, -10823}, 54},	{{11126, 84, -10791}, 51},	{{13990, 96, -10824}, 132},	{{14133, 96, -10821}, 89},	{{14151, 96, -10765}, 100},	{{14246, 96, -10721}, 30},	{{14279, 96, -10701}, 32},
		{{14347, 96, -10672}, 55},	{{14383, 96, -10653}, 66},	{{14453, 96, -10596}, 70},	{{14524, 96, -10592}, 43},	{{14576, 96, -10585}, 29},	{{13753, 96, -10689}, 79},	{{13906, 96, -10699}, 125},
		{{14086, 96, -10646}, 103},	{{13657, 96, -10487}, 188},	{{13496, 96, -10424}, 115},	{{13925, 96, -10385}, 129},	{{14028, 96, -10409}, 120},	{{14026, 96, -10499}, 119},	{{14159, 96, -10443}, 90},
		{{14195, 96, -10485}, 107},	{{14259, 96, -10499}, 82},	{{17307, 96, -10533}, 79},	{{14371, 96, -10535}, 54},	{{14417, 96, -10544}, 40},	{{13969, 96, -10303}, 76},	{{13975, 96, -10225}, 44},
		{{13970, 96, -10185}, 30},	{{13966, 96, -10160}, 30},	{{13967, 96, -10129}, 30},	{{13966, 96, -10095}, 30},	{{13963, 96, -10062}, 36},	{{13959, 96, -10030}, 42},	{{13956, 96, -9986}, 52},
		{{13966, 96, -9865}, 117},	{{13966, 96, -9436}, 439},	{{13617, 96, -9613}, 110},	{{13545, 96, -9423}, 186},	{{16552,103, -5600}, 168},	{{16569, 103, -5412}, 131},	{{19683, 83, -9774}, 8},
		{{19685, 83, -9763}, 10},	{{19690, 83, -9752}, 12},	{{19695, 83, -9736}, 17},	{{19704, 83, -9714}, 26},	{{19712, 83, -9688}, 34},	{{19722, 83, -9661}, 35},	{{19729, 83, -9637}, 35},
		{{19725, 83, -9608}, 25},	{{19722, 83, -9587}, 23},	{{19722, 83, -9571}, 25},	{{19725, 83, -9550}, 27},	{{19724, 83, -9528}, 28},	{{19725, 83, -9502}, 28},	{{19730, 83, -9470}, 28},
		{{19737, 83, -9436}, 39},	{{19739, 83, -9405}, 37},	{{19736, 83, -9367}, 29},	{{19731, 83, -9340}, 26},	{{19724, 83, -9309}, 29},	{{19713, 83, -9275}, 27},	{{19706, 83, -9239}, 30},
		{{19695, 83, -9209}, 36},	{{19693, 83, -9175}, 42},	{{19692, 83, -9147}, 44},	{{19702, 83, -9099}, 29},	{{19771, 80, -8996}, 22},	{{19795, 80, -8967}, 27},	{{19817, 80, -8922}, 38},
		{{19867, 80, -8898}, 49},	{{23733, 49, -13164}, 56},	{{23778, 49, -12516}, 30},	{{23842, 49, -12407}, 42},	{{24477, 49, -12872}, 103},	{{24382, 49, -12729}, 127},	{{24363, 49, -12614}, 95},
		{{24735, 49, -12430}, 75},	{{24727, 49, -11939}, 77},	{{24818, 49, -11992}, 49},	{{24908, 49, -12017}, 56},	{{25004, 49, -12031}, 74},	{{25116, 49, -12015}, 84},	{{24489, 49, -11652}, 32},
		{{24568, 49, -11454}, 203},	{{24770, 49, -11531}, 80},	{{24817, 49, -13418}, 94},	{{25124, 49, -13613}, 74},	{{25225, 49, -13585}, 70},	{{25554, 49, -13261}, 49},	{{25864, 49, -12784}, 49},
		{{25904, 49, -12743}, 49},	{{25936, 49, -12687}, 61},	{{25939, 49, -12607}, 60},	{{25932, 49, -12525}, 68},	{{25977, 49, -12447}, 64},	{{26004, 49, -12393}, 80},	{{26009, 49, -12297}, 97},
		{{26073, 49, -12212}, 75},	{{26114, 49, -12158}, 74},	{{26156, 49, -12105}, 63},	{{26186, 49, -12065}, 54},	{{26203, 49, -12024}, 44},	{{26209, 49, -11991}, 32},	{{26212, 49, -11963}, 24},
		{{26216, 49, -11935}, 20},	{{26217, 49, -11914}, 23},	{{26219, 49, -11891}, 23},	{{26232, 49, -11857}, 19},	{{25745, 49, -12280}, 104},	{{25294, 49, -11754}, 146},	{{25439, 49, -11710}, 143},
		{{25580, 49, -11719}, 170},	{{25713, 49, -11774}, 164},
	}
	for i,v in ipairs(lakes) do
		local lx, ly, lz = unpack(v[1])
		local radius = v[2]
		if EDX:get2dDistance(x, z, lx, lz) <= radius then
			return v[1]
		end
	end
	return false
end

function EDX:getPath( vehicleOrEchelonName, destination, tableOfPathPoints, tableOfUsedPoints, currentPoint)
	local temp_dist = 0;
	local nearest_dist = 999999;
	local path_point = "none";
	local pathBuffer = 60;
	for i,v in ipairs(tableOfPathPoints) do
		local pathpt = v;
		local invalidPoint = false;
		if currentPoint ~= nil then
			if pathpt == currentPoint then
				invalidPoint = true;
			end
		end
		if tableOfUsedPoints ~= nil then
			if EDX:isInTable(pathpt,tableOfUsedPoints) then
				invalidPoint = true;
			end
		end
		if not invalidPoint then
			local target_dist = 0;
			if currentPoint ~= nil then
				target_dist = OFP:getDistance(currentPoint,destination);
			else
				target_dist = OFP:getDistance(vehicleOrEchelonName,destination);
			end
			local ptarget_dist = OFP:getDistance(pathpt,destination);
			if ptarget_dist < target_dist + pathBuffer then
				temp_dist = OFP:getDistance(vehicleOrEchelonName,pathpt);
				if temp_dist < nearest_dist then
					nearest_dist = temp_dist;
					path_point = v;
				end
			end
		end
	end
	return path_point;
end

-- returns the driver name of the given vehicle and the crew point index...
-- does not work for vu10m1025gl, vu09m1025mg, vp11type95
function EDX:getDriver( vehicleName)
	local unitName,index = "", -1
	local crewSize = debug:getNumberOfCrewPoints(vehicleName)
	for i=0,crewSize-1 do
		local crewPointName = debug:getCrewPointName(vehicleName, i)
			if crewPointName == "driver" or crewPointName == "pilot" then
				unitName = debug:getSoldierInCrewPoint(vehicleName,i)
				return unitName, i
			end
	end
end

-- returns a table of all gunners in the given vehicle
-- does not work for vu01m1a2
function EDX:getGunners( vehicleName)
	local gunners = {}
	local crewSize = debug:getNumberOfCrewPoints(vehicleName)
	for i=0,crewSize-1 do
		local crewPointName = debug:getCrewPointName(vehicleName, i)
			if crewPointName == "gunner"
			or crewPointName == "gunner2"
			or crewPointName == "gunner3"
			or crewPointName == "gunner_qjc88"
			or crewPointName == "gunner_up_m2hb"
			or crewPointName == "gunner_up_mk19" then
				unitName = debug:getSoldierInCrewPoint(vehicleName,i)
				gunners[#gunners + 1] = unitName
			end
	end
	return gunners
end

function EDX:removeDictionaryElements(dictionaryName, elementValue)
	local newTable = {}
	for i,v in pairs(dictionaryName) do
		if v~= elementValue then
			newTable[i] = v
		end
	end
	dictionaryName = newTable;
	return newTable
end

function EDX:removeArrayElements(arrayName, elementValue)
	local newTable = {}
	for i,v in ipairs(arrayName) do
		if v ~= elementValue then
			newTable[#newTable + 1] = v;
		end
	end
	arrayName = newTable;
	return newTable
end

--------------------------------------------------Save/Load table,file, Save/load file and file exists functions thanks to Haywood Slap
-- these functions were included in DROPP and soon were found to be essential functions when performing i/o operations in OFDR
-- I also believe these were included in the utils script from the SLAP Pack by HaywoodSlap...  all of the credit is his!!


-- Saves a table to the specified location.
function EDX:saveTable( theTable, tableName, location, indent)
	-- Check if this is a recursive call to table.save. If this
	-- is the first time save has been called we need to open
	-- the file specified by location, otherwise location is
	-- the file that was opened.
	if indent == nil then
		location = location or "save.lua"
		--tname = "__Save__"
		local file = io.open(location, "w")
		if tableName ~= nil then
			file:write(tableName.." = {\n")
		else
			file:write("__Save__ = {\n")
		end
		EDX:saveTable( theTable, tableName, file, "\t")
		file:write("}")
		io.close(file)
		return
	end

	-- Write the name/value pairs in the table to the file.
	for name,value in pairs(theTable) do
		local key = '["' .. name .. '"]'
--		local key = name
		if type(name) == "number" then
			key = '[' .. name .. ']'
		end
		-- If the value is a table we need to add the code to
		-- initialize the empty table and then call save recursively.
		if type(value) == "table" then
			location:write(indent .. key .. " = {\n")
			EDX:saveTable( value, tableName, location, indent .. "\t")
			location:write(indent .. "},\n")
		elseif type(value) == "string" then
			location:write(indent .. key .. " = " .. string.format("%q", value) .. ",\n")
		else
			location:write(indent .. key .. " = " .. tostring(value) .. ",\n")
		end
	end
end


function EDX:loadTable( filename, tableName)
	-- The "save" file is actually a Lua script, so all we need to do is
	-- load it and run it.  The Lua function "dofile" does both for us.
	dofile(filename)
	local result
	if tableName then
		result = tableName
		tableName = nil
	else
		result = __Save__
		__Save__ = nil
	end
	return result
end

-- Returns true if the specified file exists. Returns false otherwise.
function EDX:fileExists( filename)
	local f = io.open(filename, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

-- Reads a file and returns the contents in a Lua table. Returns nil
-- if the file could not be opened.
function EDX:loadFile( path)
	local file = io.open(path, "r+")
	if not file then
		return nil
	end
	local lines = {}
	local line = file:read()
	while line do
		table.insert(lines, line)
		line = file:read()
	end
	file:close()
	return lines
end

-- Save a Lua array to a file.
function EDX:saveFile( lines, path)
	local file = io.open(path, "w+")
	if file then
		for _,line in ipairs(lines) do
			file:write(line .. "\n")
		end
		file:close()
		return true
	end
	return false
end

-- Returns true if 'text' starts with the string 'prefix.
-- Returns false otherwise.
function EDX:startsWith( text, prefix)
	return string.sub(text, 1, string.len(prefix)) == prefix
end

-- Returns true if 'text' ends with the string 'prefix.
-- Returns false otherwise.
function EDX:endsWith( text, suffix)
	return string.sub(text, string.len(text), -string.len(suffix)) == suffix
end

-- Removes leading and trailing whitespace from the string.
function EDX:trim(text)
	return text:match("^%s*(.-)%s*$")
end

-- Splits the string 'str' on the first occurence of the
-- string 'sep' and returns the two parts. Returns nil, nil
-- if the 'sep' string does not appear in the input string 'str'.
-- For example, split("foo=bar", "=") returns "foo", "bar"
function EDX:split( str, sep)
	local n = 0
	local last = nil
	while n do
		last = n
		n = string.find(str, sep, n+1, true)
	end
	if last then
		return str:sub(1,last-1), str:sub(last+1)
	end
	return nil, nil
end

-- Returns the items from the table whose key's begin
-- with the specified prefix.
function EDX:filterTable(aTable, prefix)
	local result = {}
	for key,value in pairs(aTable) do
		if EDX:startsWith(key, prefix) then
			table.insert(result, key)
		end
	end
	return result
end

function EDX:round(n)
	return math.floor(n + 0.5)
end

function EDX:getImmediateParent(unit)
	local top = OFP:getParentEchelon(unit)
	if top == nil then
		return nil
	end
	return findImmediateParent(top, unit)
end

-- PRIVATE --
function findImmediateParent(parent, unit)
	local size = OFP:getEchelonSize(parent) - 1
	for i=0,size do
		local child = OFP:getEchelonMember(parent, i)
		if child == unit then
			return parent
		elseif OFP:isEchelon(child) then
			local found = findImmediateParent(child, unit)
			if found then
				return found
			end
		end
	end
	return nil
end

-- Returns the first echelon found in the table of entities.
function EDX:getEchelon(tableOfEntities)
	for _,entity in ipairs(tableOfEntities) do
		if OFP:isEchelon(entity) then
			return entity
		end
	end
	return nil
end

-- Returns the current OFP version number.
function EDX:getVersion()
	if OFP.getTerrainHeight then
		return "1.02"
	elseif OFP.setAIConfigPropertyValue then
		return "1.01"
	end
	return "1.00"
end

-- This is Druid's despawner function modified slightly to also
-- accept entity set IDs and allow an aribtrary number of parameters.
--
-- See http://community.codemasters.com/forum/operation-flashpoint-dragon-rising-mission-editing-modding-chat-zone-123/393095-despawner.html
-- for Druid's original script.
function EDX:despawner(...)
	for i,x in ipairs(arg) do
		if type(x) == "number" then
			-- Assume this is an entity set ID.
			OFP:destroyEntitySet(x)
		elseif OFP:isEchelon(x) then
			for y = 1, OFP:getEchelonFullSize(x) do
				OFP:despawnEntity( OFP:getEchelonMember(x, y-1) )
			end
		elseif OFP:isGroup(x) then
			for y = 1, OFP:getGroupSize(x) do
				OFP:despawnEntity( OFP:getGroupMember(x, y-1) )
			end
		else
			-- Not a number, group or echelon, so it must be an entity
			OFP:despawnEntity(x)
		end
	end
end


-- From http://lua-users.org/wiki/CopyTable
function EDX:deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--[[
The OWP sound player function requires the ofpdrWavePlayer coded by Dschonny.  This is a masterful piece of work that
allows you to play any wave file across the network in a multiplayer game in addition to adding the ability to create and use
custom sound files with ease.  Even things as simple as adding a musical sound track to intensify the experience are as simple
as adding the file to the owp/sounds folder and calling it from your script with the function below.  An ingenious contribution
from Dschonny.
]]--
function EDX:playOwpSound( soundFile)
    local owpCom = io.open("./owp/soundToPlay.owp", "w");
    owpCom:write(soundFile.."\n");
    owpCom:close();
end

----------------------------------------------------------------------------------------------------------------DEBUGGING FUNCTIONS

function debugger(message)
	local logFile = io.open("./EDX DEBUG.txt", "a+")
	if message then
		logFile:write(os.date() .. ": " .. message .. "\n")
		if DISPLAY then
			OFP:displaySystemMessage(message)
		end
	else
		logFile:write(os.date() .. ": (nil)\n")
	end
	logFile:close()
end
