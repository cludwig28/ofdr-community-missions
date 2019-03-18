--[[				Missile mod v001 by
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

--Below are examples of all of the event handlers fired by the missileMod script. You can use these on any script!

function onEnterRadarRange(radarID,targetName)
	OFP:displaySystemMessage("Helicopter "..targetName.." has entered the range of radar "..radarID);
end

function onRadarLock(radarID,targetName)
	OFP:displaySystemMessage("Radar "..radarID.." has locked on to "..targetName);
end

function onRadarDestroyed(radarEntity,attacker)
	OFP:displaySystemMessage("Radar entity "..radarEntity.." has been destroyed by "..attacker);
end

function onEnterSAMRange(samID,targetName)
	OFP:displaySystemMessage("Helicopter "..targetName.." has entered the range of SAM "..samID);
end

function onSAMLock(samID,targetName)
	OFP:displaySystemMessage("SAM "..samID.." has locked on to "..targetName);
end

function onSAMFiring(samID,targetName,missileID)
	OFP:displaySystemMessage("SAM "..samID.." has fired on "..targetName.." with missile "..missileID);
end

function onSAMOutOfAmmo(samID)
	OFP:displaySystemMessage("SAM "..samID.." has run out of missiles!");
end

function onSAMDestroyed(samEntity,attacker)
	OFP:displaySystemMessage("SAM missile entity "..samEntity.." has been destroyed by "..attacker);
end

function onMissileHitGround(x,y,z)
	OFP:displaySystemMessage("Missile has hit the ground at "..x..", "..y..", "..z);
end

function onMissileHitTarget(targetName)
	OFP:displaySystemMessage("Missile has hit "..targetName);
	if OFP:isAlive(targetName) then
		--[[
		--This is an alternative that allows the helicopter to take a couple of shots with lesser damage
		if not OFP:isTailRotorDestroyed(targetName) then
			OFP:damageVehicle(targetName,"tailrotor");
			OFP:damageVehicle(targetName,"firepower");
		elseif not OFP:isMainRotorDestroyed(targetName) then
			OFP:damageVehicle(targetName,"mainrotor");
		else
			OFP:destroyVehicle(targetName);
		end
		]]
		OFP:destroyVehicle(targetName); --default action when a missile hits its target
	end
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

--GLOBAL SCRIPT PARAMETERS
LOCK_TIME = 8; --Time required for SAM's to get an initial lock on a target
FIRE_DELAY = 5; --Delay from lock to actual fire time

--[[***************************************************************************************************
----------------------------------DO NOT EDIT BELOW THIS POINT!!!!-------------------------------------
*****************************************************************************************************]]

INFO = "Missile Mod v001 by tvig0r0us";

function onCreate()
----------------------------------reinitialize functions on mission checkpoint load
	if missiles then
		for i,v in pairs(missiles) do
			v.move = move;
		end
	end
	if sams then
		for i,v in pairs(sams) do
			v.fire = fire;
		end
	end
end

function onEDXInitialized()
	-------------------------------FUNCTIONS AVAILABLE TO OTHER SCRIPTS VIA EDX:functionCall()----------
	
	--Fires a missile from entity or position named
	--Params: missileName- An entity name, table of x,y,z coordinates or samID to fire a missile from
	--		target- the name of a target for a missile to track
	--		reqLOS- whether or not to require line of sight to fire missile (true/false)
	function EDX:fireSAM(missileName,target,reqLOS)
		local _samName = missileName;
		if type(_samName) == "number" then
			if sams[_samName] then
				_samName = sams[_samName];
			else
				debugInfo = "ERROR[fireSAM]: Invalid missileName";
				return debugInfo;
			end
		end
		if reqLOS and EDX:isInLOS(_samName,target) then
			return fireMissile("X_IMPT_EXPL_Master1_Small",_samName,target,150);
		elseif not reqLOS then
			return fireMissile("X_IMPT_EXPL_Master1_Small",_samName,target,150);
		end
	end
	
	--Will detonate a missile in flight 
	--Params: missileID- ID from event handler or fireSAM function
	function EDX:detonateMissile(missileID)
		if not missiles[missileID] then
			debugInfo = "ERROR[detonateMissile]: Invalid missileID";
			return debugInfo;
		else
			missiles[missileID].ground = true;
			return true;
		end
	end
	
	--Creates a new lua object for the radarName passed
	--Params: radarName- can be any object
	--		samArray- an array of samID's for the radar to assume fire control
	--		targetSide- The side to set the automated targeting system 0=US 1=PLA
	function EDX:newRadar(radarName,samArray,targetSide)
		return newRadar(radarName,samArray,targetSide);
	end
	
	--Returns a lua object containing the data for a script created radar by radarID
	--Params: radarID- the radarID retuned by newRadar and several script event handlers
	function EDX:getRadarObject(radarID)
		if not radars[radarID] then
			debugInfo = "ERROR[getRadarObject]: Invalid radarID";
			return debugInfo;
		else
			return radars[radarID];
		end
	end
	
	--Removes a radar script object from the game (not the entity it was assigned to)
	--Params: radarID- the radarID retuned by newRadar and several script event handlers
	function EDX:deleteRadar(radarID)
		if not radars[radarID] then
			debugInfo = "ERROR[deleteRadar]: Invalid radarID";
			return debugInfo;
		else
			OFP:destroyEntitySet(radars[radarID].trigID);
			radarTrigs[radars[radarID].trig] = nil;
			radars[radarID] = nil;
			return true;
		end
	end
	
	--Returns a lua object containing the data for a script created SAM by samID
	--Params: samID- the samID retuned by newSam and several script event handlers
	function EDX:getSAMObject(samID)
		if not sams[samID] then
			debugInfo = "ERROR[getSAMObject]: Invalid samID";
			return debugInfo;
		else
			return sams[samID];
		end
	end
	
	--Creates a new lua object for the samName passed
	--Params: samName- can be any object
	--		targetSide- The side to set the automated targeting system 0=US 1=PLA
	function EDX:newSAM(samName,targetSide)
		return newSAM(samName,targetSide);
	end
	
	--Sets the side for a sam missile to target
	--Params: samID- the samID retuned by newSam and several script event handlers
	--		targetSide- The side to set the automated targeting system 0=US 1=PLA
	function EDX:setSAMEnemySide(samID,targetSide)
		if not sams[samID] then
			debugInfo = "ERROR[setSAMEnemySide]: Invalid samID";
			return debugInfo;
		else
			sams[samID].ts = targetSide;
			return true;
		end
	end
	
	--Sets a sam's active targeting
	--Params: samID- the samID retuned by newSam and several script event handlers
	--		active- true or false  default is true
	function EDX:setSAMActive(samID,active)
		local _act = active;
		if _act == nil then _act = true end 
		if not sams[samID] then
			debugInfo = "ERROR[setSAMActive]: Invalid samID";
			return debugInfo;
		else
			sams[samID].active = _act;
			return true;
		end
	end
	
	--Sets the total number of missiles a sam can fire
	--Params: samID- the samID retuned by newSam and several script event handlers
	--		ammoCount- the number of missiles  default = -1(unlimited)
	function EDX:setSAMAmmo(samID,ammoCount)
		if not sams[samID] then
			debugInfo = "ERROR[setSAMAmmo]: Invalid samID";
			return debugInfo;
		else
			sams[samID].ammo = ammoCount;
			return true;
		end
	end
	
	--Removes a sam missile script object from the game (not the entity it was assigned to)
	--Params: samID- the samID retuned by newSam and several script event handlers
	function EDX:deleteSAM(samID)
		if not sams[samID] then
			debugInfo = "ERROR[deleteSAM]: Invalid samID";
			return debugInfo;
		else
			OFP:destroyEntitySet(sams[samID].trigID);
			samTrigs[sams[samID].trig] = nil;
			sams[samID] = nil;
			return true;
		end
	end
	
	--Creates a new missile array with radars
	--Params: samNames- an array of SAM missile names, radarNames- an array of radars, targetSide- the side to target
	function EDX:newSAMArray(samNames,radarNames,targetSide)
		local ns = {};
		local nr = {};
		for i,v in ipairs(samNames)do
			ns[#ns+1]=newSAM(v,targetSide);
		end
		for i,v in ipairs(radarNames)do
			nr[#nr+1]=newRadar(v,ns,targetSide)
		end
		return ns,nr
	end
end

function onMissionStart()
	spawned = {};
	missiles = {};
	sams = {};
	samTrigs = {};
	radars = {};
	radarTrigs = {};
	tt = OFP:getMissionTime() + 1000;
	fc = 0;
	lf = 0;
	fps = 60;
	ID = 0;
end

function getNewID()
	ID = ID+1;
	return ID;
end

function updateFrame(currentTime, frameNo)
	fc = fc + 1
	if currentTime >= tt and fc > lf then
		fps = fc - lf
		lf = fc
		tt = currentTime + 1000
	end
	for _,fx in pairs(missiles) do
		fx:move();
	end
end

function fireMissile(effectName,startPos,target,speed)
	missile = {};
	missile.fx = effectName;
	missile.spd = speed;
	missile.tar = target;
	missile.ey = ey;
	missile.ez = ez;
	if type(startPos) == "table" then
		missile.pos = startPos;
		missile.start = startPos;
	elseif type(startPos) == "string" and OFP:getDistance(startPos,startPos) ~= -1 then
		local sx,sy,sz = OFP:getPosition(startPos);
		if debug:getTemplateName(startPos) == "ev12sama" then
			sy = sy + 2.5;
		end
		missile.pos = {sx,sy,sz};
		missile.start = {sx,sy,sz};
	end
	missile.ID = getNewID();
	missile.sets = {};
	OFP:playOneShotSound ("flashpoint2", "WpnFX", "BY_ATM", missile.pos[1],missile.pos[2],missile.pos[3]);
	missile.move = move;
	missiles[missile.ID] = missile;
	return missile.ID;
end
	
function move(self)
	local travelDist = self.spd/fps;
	local x,y,z = unpack(self.pos);
	local sx,sy,sz = unpack(self.start);
	local tx, ty, tz;
	local nx, ny, nz;
	if type(self.tar) == "table" then
		tx, ty, tz = unpack(self.tar)
	elseif type(self.tar) == "string" then
		tx, ty, tz = OFP:getPosition(self.tar)
	end
	if EDX:get3dDistance(x, y, z, tx, ty, tz) <= travelDist and not self.hit then
		self.hit = true
	elseif self.hit then
		if #self.sets == 0 then
			EDX:distributeFunction("onMissileHitTarget",self.tar);
			missiles[self.ID] = nil;
			--OFP:displaySystemMessage("Target reached!!")
		end
	elseif self.ground then
		if #self.sets == 0 then
			EDX:distributeFunction("onMissileHitGround",x,y,z);
			missiles[self.ID] = nil;
			--OFP:displaySystemMessage("Missile collided with ground!!")
		end
	else
		local da = EDX:get3dDistance(x, y, z, tx, ty, tz)
		local db = EDX:get2dDistance(x, z, tx, tz)
		local dc = ty - y
		local tb = EDX:getBearing(x, z, tx, tz)
		local ratio = travelDist/da
		local dxz = db * ratio
		local dy = dc * ratio
		nx, ny, nz = EDX:get360Coordinates({x, y, z},tb,0,dxz)
		ny = y + dy
		local terrainHeight = OFP:getTerrainHeight(nx, nz)
		local sDist = EDX:get3dDistance(x, y, z, sx, sy, sz)
		if  sDist <= 10 then
			ny = y + .4;
		elseif ny <= terrainHeight then
			self.ground = true;
			ny = terrainHeight - 1;
		end
		
		self.pos = {nx,ny,nz};
		if EDX:getEntity3dDistance(EDX:getPlayerLeader(),nx,ny,nz) <= 2000 then
			local sid = OFP:spawnEntitySetAtLocation("ssamfxwp",nx,ny-1,nz);
			self.sets[#self.sets+1] = sid;
			spawned[sid] = self.ID;
		end
	end
end

function newSAM(samName,targetSide)
	local samObj = {};
	samObj.nm = samName;
	samObj.ts = targetSide;
	samObj.ammo = -1;--default to unlimited ammo count on creation of sam object
	samObj.active = true;
	samObj.tar = {};
	samObj.ID = getNewID();
	local x,y,z = OFP:getPosition(samName);
	local sid = OFP:spawnEntitySetAtLocation("ssamtrig",x,y,z);
	samObj.trigID = sid;
	spawned[sid] = samObj.ID;
	sams[samObj.ID] = samObj;
	return samObj.ID;
end

function newRadar(radarName,samArray,targetSide)
	local radObj = {};
	radObj.nm = radarName;
	radObj.sams = samArray;
	radObj.ts = targetSide;
	radObj.active = true;
	radObj.tar = {};
	radObj.ID = getNewID();
	local x,y,z = OFP:getPosition(radarName);
	local sid = OFP:spawnEntitySetAtLocation("sradtrig",x,y,z);
	radObj.trigID = sid;
	spawned[sid] = radObj.ID;
	radars[radObj.ID] = radObj;
	return radObj.ID
end

function samLock(samID,targetName,timerID)
	if sams[samID] then
		local sam = sams[samID];
		local tar = sam.tar[targetName];
		if not sam.active or sam.ammo == 0 then
			EDX:setTimer(timerID,1000);
			tar.lock = 0;
			return;
		end
		if OFP:isAlive(targetName) and OFP:isInTrigger(targetName,sam.trig) then
			if OFP:getSide(targetName) == sam.ts then
				tar.lock = tar.lock + 1;
				if tar.lock < LOCK_TIME and not EDX:isInLOS(sam.nm,targetName) then
					tar.lock = 0;
				end
				if tar.lock > LOCK_TIME + FIRE_DELAY then
					local mis = fireMissile("X_IMPT_EXPL_Master1_Small",sam.nm,targetName,150);
					EDX:distributeFunction("onSAMFiring",samID,targetName,mis);
					if sam.ammo > 0 then
						sam.ammo = sam.ammo - 1;
						if sam.ammo == 0 then
							EDX:distributeFunction("onSAMOutOfAmmo",sam.ID)
						end
					end
					if EDX:isInLOS(sam.nm,targetName) then
						tar.lock = LOCK_TIME;
					else
						tar.lock = 0;
					end
				elseif tar.lock == LOCK_TIME then
					EDX:distributeFunction("onSAMLock",samID,targetName);
				end
			else
				tar.lock = 0;
			end
		else
			sam.tar[targetName] = nil;
			EDX:deleteTimer(timerID);
			return;
		end
	else
		EDX:deleteTimer(timerID);
		return;
	end
	EDX:setTimer(timerID,1000);
end

function radarLock(radarID,targetName,timerID)
	if radars[radarID] then
		local radar = radars[radarID];
		local tar = radar.tar[targetName];
		if not radar.active then
			EDX:setTimer(timerID,1000);
			tar.lock = 0;
			return;
		end
		if OFP:isAlive(targetName)
		and OFP:isInTrigger(targetName,radar.trig) then
			if OFP:getSide(targetName) == radar.ts then
				tar.lock = tar.lock + 1;
				if tar.lock < LOCK_TIME and not EDX:isInLOS(radar.nm,targetName) then
					tar.lock = 0;
				end
				if tar.lock > LOCK_TIME + FIRE_DELAY then
					local minDist = 99999;
					local sam;
					for i,v in ipairs(radar.sams) do
						if sams[v] then
							local td = OFP:getDistance(targetName,sams[v].nm);
							if td < minDist and sams[v].ammo ~= 0 then
								if EDX:isInLOS(sams[v].nm,targetName) then
									minDist = td;
									sam = sams[v];
								end
							end
						end
					end
					if sam then
						local mis = fireMissile("X_IMPT_EXPL_Master1_Small",sam.nm,targetName,150);
						EDX:distributeFunction("onSAMFiring",sam.ID,targetName,mis);
						if sam.ammo > 0 then
							sam.ammo = sam.ammo - 1;
							if sam.ammo == 0 then
								EDX:distributeFunction("onSAMOutOfAmmo",sam.ID)
							end
						end
						if EDX:isInLOS(radar.nm,targetName) then
							tar.lock = LOCK_TIME;
						else
							tar.lock = 0;
						end
					elseif not EDX:isInLOS(radar.nm,targetName) then
						tar.lock = 0;
					else
						tar.lock = LOCK_TIME + FIRE_DELAY;
					end
				elseif tar.lock == LOCK_TIME then
					EDX:distributeFunction("onRadarLock",radarID,targetName);
				end
			else
				tar.lock = 0;
			end
		else
			radar.tar[targetName] = nil;
			EDX:deleteTimer(timerID);
			return;
		end
	else
		EDX:deleteTimer(timerID);
		return;
	end
	EDX:setTimer(timerID,1000);
end

function newTarget(samObject,targetName)
	local tar = {};
	tar.lock = 0;
	tar.timer = EDX:serialTimer("samLock",1000,samObject.ID,targetName);
	samObject.tar[targetName] = tar;
end

function newRadarTarget(radarObject,targetName)
	local tar = {};
	tar.lock = 0;
	tar.timer = EDX:serialTimer("radarLock",1000,radarObject.ID,targetName);
	radarObject.tar[targetName] = tar;
end

function onEnter(zoneName, unitName)
	if samTrigs[zoneName] and OFP:getBroadUnitCategory(unitName) == "BROAD_UNIT_AIRCRAFT" then
		local sam = sams[samTrigs[zoneName]];
		if OFP:getSide(unitName) == sam.ts then
			newTarget(sam,unitName);
			EDX:distributeFunction("onEnterSAMRange",sam.ID,unitName);
		end
	elseif radarTrigs[zoneName] and OFP:getBroadUnitCategory(unitName) == "BROAD_UNIT_AIRCRAFT" then
		local radar = radars[radarTrigs[zoneName]];
		if OFP:getSide(unitName) == radar.ts then
			newRadarTarget(radar,unitName);
			EDX:distributeFunction("onEnterRadarRange",radar.ID,unitName);
		end
	end
end

function onMount(vehicleName, unitName, echelonName)
	if OFP:getBroadUnitCategory(vehicleName) == "BROAD_UNIT_AIRCRAFT" then
		for i,v in pairs(sams) do
			if OFP:isInTrigger(vehicleName,v.trig)
			and not v.tar[vehicleName] then
				newTarget(v,vehicleName);
				EDX:distributeFunction("onEnterSAMRange",v.ID,vehicleName);
				return;
			end
		end
		for i,v in pairs(radars) do
			if OFP:isInTrigger(vehicleName,v.trig)
			and not v.tar[vehicleName] then
				newTarget(v,vehicleName);
				EDX:distributeFunction("onEnterRadarRange",v.ID,vehicleName);
				return;
			end
		end
	end
end

function onPlaceableKill(placeable, attacker)
	for i,v in pairs(sams) do
		if v.nm == placeable then
			samTrigs[v.trig] = nil;
			OFP:destroyEntitySet(v.trigID);
			sams[i] = nil;
			EDX:distributeFunction("onSAMDestroyed",placeable,attacker);
			return;
		end
	end
	for i,v in pairs(radars) do
		if v.nm == placeable then
			radarTrigs[v.trig] = nil;
			OFP:destroyEntitySet(v.trigID);
			radars[i] = nil;
			EDX:distributeFunction("onRadarDestroyed",placeable,attacker);
			return;
		end
	end
end

function onSpawnedReady(setName, setID, tableOfEntities, errorCode)
	if not spawned[setID] then return end
	if setName == "ssamfxwp" then
		local mis = missiles[spawned[setID]];
		local x,y,z = OFP:getPosition(tableOfEntities[1]);
		if mis.ground or mis.hit then
			OFP:doParticleEffect("X_EXPL_MISS_Master1_Med",tableOfEntities[1]);
			OFP:playOneShotSound ("flashpoint2", "EXP", "explosion", mis.pos[1],mis.pos[2],mis.pos[3]);
		else
			OFP:doParticleEffect(mis.fx,tableOfEntities[1]);
		end
		OFP:destroyEntitySet(mis.sets[1]);
		table.remove(mis.sets,1);
	elseif setName == "ssamtrig" then
		local sam = sams[spawned[setID]];
		sam.trig = tableOfEntities[1];
		samTrigs[sam.trig] = sam.ID;
	elseif setName == "sradtrig" then
		local radar = radars[spawned[setID]];
		radar.trig = tableOfEntities[1];
		radarTrigs[radar.trig] = radar.ID;
	end
	spawned[setID] = nil;
end

function onKeyPress(key)
	if key == "!F9" then
		EDX:saveTable(scripts.mission.missileMod,nil,"missileModScriptSave.lua")
	end
end