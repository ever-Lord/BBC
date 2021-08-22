local Public = {}
local BiterRaffle = require "maps.biter_battles_v2.biter_raffle"
local Functions = require "maps.biter_battles_v2.functions"
local bb_config = require "maps.biter_battles_v2.config"
local fifo = require "maps.biter_battles_v2.fifo"
local math_random = math.random
local math_abs = math.abs
local enemy_team_of = {["north"] = "south", ["south"] = "north"}
--[[ EVL REMOVED VECTORS
local vector_radius = 512
local attack_vectors = {}
attack_vectors.north = {}
attack_vectors.south = {}
--awesomepatrol's pathing  updates
for p = 0.3, 0.71, 0.1 do
	local a = math.pi * p
	local x = vector_radius * math.cos(a)
	local y = vector_radius * math.sin(a)
	attack_vectors.north[#attack_vectors.north + 1] = {x, y * -1}
	attack_vectors.south[#attack_vectors.south + 1] = {x, y}
end
local size_of_vectors = #attack_vectors.north
]]--

--EVL REPLACE VECTORS BY WAYPOINTS
local way_point_radius = 512
local way_points = {}
way_points.north = {}
way_points.south = {}
local p=0.49
local _step=0.05
--EVL the waypoints are p=0.49 0.44 0.38 0.31 0.23 0.14 0.04
-- (more chance to come vertically than horizontally)
while p>0 do
	local a = math.pi * p
	local x = math.floor(way_point_radius * math.cos(a))
	local y = math.floor(way_point_radius * math.sin(a))
	way_points.north[#way_points.north + 1] = {x, y * -1}
	way_points.south[#way_points.south + 1] = {x, y}
	p=p-_step
	_step=_step+0.01
end
--ADD one vertical waypoint at p=0.47
if true then
	p=0.47
	local a = math.pi * p
	local x = math.floor(way_point_radius * math.cos(a))
	local y = math.floor(way_point_radius * math.sin(a))
	way_points.north[#way_points.north + 1] = {x, y * -1}
	way_points.south[#way_points.south + 1] = {x, y}
end


local size_of_way_points = #way_points.north

local unit_type_raffle = {"biter", "mixed", "mixed", "spitter", "spitter"}
local size_of_unit_type_raffle = #unit_type_raffle

local threat_values = {
	["small-spitter"] = 1.5,
	["small-biter"] = 1.5,
	["medium-spitter"] = 4.5,
	["medium-biter"] = 4.5,
	["big-spitter"] = 13,
	["big-biter"] = 13,
	["behemoth-spitter"] = 38.5,
	["behemoth-biter"] = 38.5,
	["small-worm-turret"] = 8,
	["medium-worm-turret"] = 16,
	["big-worm-turret"] = 24,
	["behemoth-worm-turret"] = 32,
	["biter-spawner"] = 32,
	["spitter-spawner"] = 32
}

local function get_active_biter_count(biter_force_name)
	local count = 0
	for _, _ in pairs(global.active_biters[biter_force_name]) do
		count = count + 1
	end
	return count
end

local function get_target_entity(force_name)
	local force_index = game.forces[force_name].index
	local target_entity = Functions.get_random_target_entity(force_index)
	if not target_entity then print("Unable to get target entity for " .. force_name .. " (in get_target_entity).") return end
	for _ = 1, 2, 1 do
		local e = Functions.get_random_target_entity(force_index)
		if math_abs(e.position.x) < math_abs(target_entity.position.x) then
			target_entity = e
		end
	end
	if not target_entity then 
		if global.bb_biters_debug then game.print("No side target found for " .. force_name .. " (in get_target_entity).") end
		return 
	end
	--print("Target entity for " .. force_name .. ": " .. target_entity.name .. " at x=" .. target_entity.position.x .. " y=" .. target_entity.position.y)
	return target_entity
end
--EVL GET THE RATIO between threats, return 0 if threat<0 (will be tweak see pre_main_attack)
local function get_threat_ratio(biter_force_name)
	if global.bb_threat[biter_force_name] <= 0 then return 0 end
	local t1 = global.bb_threat["north_biters"]
	local t2 = global.bb_threat["south_biters"]
	if t1 == 0 and t2 == 0 then return 0.5 end
	if t1 < 0 then t1 = 0 end
	if t2 < 0 then t2 = 0 end
	local total_threat = t1 + t2
	if total_threat == 0 then total_threat = 1 end --EVL I PREFER TO CHECK !DIV0 ?
	local ratio = global.bb_threat[biter_force_name] / total_threat
	return ratio
end

local function is_biter_inactive(biter, unit_number, biter_force_name)
	if not biter.entity then
		if global.bb_biters_debug then print("Debug: BiterBattles: active unit " .. unit_number .. " removed, possibly died.") end
		return true
	end
	if not biter.entity.valid then
		if global.bb_biters_debug then print("Debug: BiterBattles: active unit " .. unit_number .. " removed, biter invalid.") end
		return true
	end
	if not biter.entity.unit_group then
		if global.bb_biters_debug then print("Debug: BiterBattles: active unit " .. unit_number .. "  at x" .. biter.entity.position.x .. " y" .. biter.entity.position.y .. " removed, had no unit group.") end
		return true
	end
	if not biter.entity.unit_group.valid then
		if global.bb_biters_debug then print("Debug: BiterBattles: active unit " .. unit_number .. " removed, unit group invalid.") end
		return true
	end
	if game.tick - biter.active_since > bb_config.biter_timeout then
		if global.bb_biters_debug then print("Debug: BiterBattles: " .. biter_force_name .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since .. ".") end
		biter.entity.destroy()
		return true
	end
end

local function set_active_biters(group)
	if not group.valid then return end
	local active_biters = global.active_biters[group.force.name]

	for _, unit in pairs(group.members) do
		if not active_biters[unit.unit_number] then
			active_biters[unit.unit_number] = {entity = unit, active_since = game.tick}
		end
	end
end

Public.destroy_inactive_biters = function()
	local biter_force_name = global.next_attack .. "_biters"

	for _, group in pairs(global.unit_groups) do
		set_active_biters(group)
	end
	msg="" --EVL DEBUG/TEST/UNDERSTAND?
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		if is_biter_inactive(biter, unit_number, biter_force_name) then
			msg=msg..unit_number.." | "
			global.active_biters[biter_force_name][unit_number] = nil
		end
	end
	if global.bb_biters_debug and msg~="" then game.print("DEBUGS : Destroyed inactive biters > "..msg, {r = 77, g = 77, b = 177}) end --EVL find biter position, make a flytext
end

Public.send_near_biters_to_silo = function()
	if game.tick < 108000 then return end
	if not global.rocket_silo["north"] then return end
	if not global.rocket_silo["south"] then return end

	game.surfaces[global.bb_surface_name].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["north"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "north_biters",
		unit_search_distance = 64
		})

	game.surfaces[global.bb_surface_name].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "south_biters",
		unit_search_distance = 64
		})
end

local function get_random_spawner(biter_force_name)
	local spawners = global.unit_spawners[biter_force_name]
	local size_of_spawners = #spawners

	for _ = 1, 256, 1 do
		if size_of_spawners == 0 then return end
		local index = math_random(1, size_of_spawners)
		local spawner = spawners[index]
		if spawner and spawner.valid then
			return spawner
		else
			table.remove(spawners, index)
			size_of_spawners = size_of_spawners - 1
		end
	end
end

local function select_units_around_spawner(spawner, force_name, side_target)
	local biter_force_name = spawner.force.name

	local valid_biters = {}
	local i = 0

	local threat = global.bb_threat[biter_force_name] * math_random(8, 32) * 0.01

	--[[ EVL removed for BBC (dont even know what that means)
	--threat modifier for outposts
	local m = math_abs(side_target.position.x) - 512
	if m < 0 then m = 0 end
	m = 1 - m * 0.001
	if m < 0.5 then m = 0.5 end
	threat = threat * m
	]]--
	
	local unit_count = 0
	local max_unit_count = math.floor(global.bb_threat[biter_force_name] * 0.25) + math_random(6,12)
	if max_unit_count > bb_config.max_group_size then max_unit_count = bb_config.max_group_size end

	--Collect biters around spawners
	if math_random(1, 2) == 1 then
		local biters = spawner.surface.find_enemy_units(spawner.position, 160, force_name)
		if biters[1] then
			for _, biter in pairs(biters) do
				if unit_count >= max_unit_count then break end
				if biter.force.name == biter_force_name and global.active_biters[biter.force.name][biter.unit_number] == nil then
					i = i + 1
					valid_biters[i] = biter
					global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
					unit_count = unit_count + 1
					threat = threat - threat_values[biter.name]
				end
				if threat < 0 then break end
			end
		end
	end

	--Manual spawning of units
	local roll_type = unit_type_raffle[math_random(1, size_of_unit_type_raffle)]
	for _ = 1, max_unit_count - unit_count, 1 do
		if threat < 0 then break end
		local unit_name = BiterRaffle.roll(roll_type, global.bb_evolution[biter_force_name])
		local position = spawner.surface.find_non_colliding_position(unit_name, spawner.position, 128, 2)
		if not position then 
			if global.bb_biters_debug then game.print("DEBUGS: No room for spawning a biter (in select_units_around_spawner)",{200, 20, 20}) end 
			break 
		end
		local biter = spawner.surface.create_entity({name = unit_name, force = biter_force_name, position = position})
		threat = threat - threat_values[biter.name]
		i = i + 1
		valid_biters[i] = biter
		global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
		--Announce New Spawn
		if(global.biter_spawn_unseen[force_name][unit_name]) then
			game.print("A " .. unit_name:gsub("-", " ") .. " was spotted far away on team " .. force_name .. "...",{200, 20, 20})
			global.biter_spawn_unseen[force_name][unit_name] = false
		end
	end

	--if global.bb_biters_debug then game.print("DEBUGS: "..get_active_biter_count(biter_force_name) .. " active units for " .. biter_force_name,{20, 20, 20}) end --CODING--

	return valid_biters
end


--EVL DEBUG : Content of global.way_points_table -> game.print
local function show_way_points_table(_wp)
	if global.bb_biters_debug and not _wp then game.print("    No table for show_way_points_table !", {r = 177, g = 77, b = 77}) return end
	for force,wp in pairs(_wp) do
		local msg="  WayPoints ["..force.."] >"
		if table_size(wp)>0 then
			for index,position in pairs (wp) do
				msg=msg.."  ("..position[1]..","..position[2]..")"
			end
			if global.bb_biters_debug then game.print(msg,{r = 127, g = 97, b = 97}) end
		end
	end
end

local function send_group(unit_group, force_name, side_target, group_numero)
	local target
	if side_target then
		target = side_target
	else
		target = get_target_entity(force_name)
	end
	if not group_numero then group_numero="xx" end
	if not target then 
		if global.bb_biters_debug then game.print("  DEBUGS: No target for " .. force_name .. " biters (in send-group)  skipping group #"..group_numero..".", {r = 177, g = 77, b = 77})  end
		return 
	end

	target = target.position

	local commands = {}
--[[ EVL VECTORS REMOVED 
	local vector = attack_vectors[force_name][math_random(1, size_of_vectors)]
	local distance_modifier = math_random(25, 100) * 0.01
	local position = {target.x + (vector[1] * distance_modifier), target.y + (vector[2] * distance_modifier)}
	position = unit_group.surface.find_non_colliding_position("stone-furnace", position, 96, 1)
	if position then
		if math.abs(position.y) < math.abs(unit_group.position.y) then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = position,
				radius = 16,
				distraction = defines.distraction.by_enemy
			}
		end
	end
]]--
	
	--EVL TRYING TO EXPLAIN :
	-- 												set global.bb_biters_debug=true in init.lua for verbose
	--Each group goes to a waypoint randomly choosed in a ring around the spawn, then they aim a target (not changed) then they aim the silo
	--BUG? Some groups vanishes right after they find the path to waypoint, why ?
	--BUG? Sometime a group is assigned (or reassigned?) and is sent (again?) search for "waking up" below
	--BUG? Biters (or groups?) are destroyed, i dont get it search for "destroy_inactive_biters"
	--global.way_points stores previous waypoints to re-use them for opponent team, though it is limited to global.way_points_max entries
	--we always check the possibility to reach waypoints
	--so 2 chances out of 3 to re-use a waypoint (if enough are already stored)
	-- 1 out of 3 to set a new waypoint that will be stored in global.way_points[force]
	-- if position (waypoint) is not valid, we skip the first command (the one aiming the waypoint)
	
	--Initialisation for new WAYPOINTS -tobe moved to if not _position then
	local _way_point = way_points[force_name][math.random(1,size_of_way_points)] --EVL WE CHOOSE A RANDOM WAYPOINT ON THE QUARTER RING
	local distance_modifier = math_random(50, 100) * 0.01	--EVL  (circles of way_point_radius 256 to 512)
	local _posX=math.floor(_way_point[1]*distance_modifier)
	local _posY=math.floor(_way_point[2]*distance_modifier)
	
	--Initialisation for WAYPOINTS (either new or re-used)
	local _position = nil
	local _position_is_new=false
	local _reverse = ""
	
	if math.random(1,3)<3 then --2 out of 3 times, we try to get one previous waypoint that was sent to opponent team
		
		local force_opponent=enemy_team_of[force_name]
		local _nb_way_points_opp=table_size(global.way_points_table[force_opponent])
		--game.print("opponent "..force_opponent.." has ".._nb_way_points_opp.." waypoints")
		if _nb_way_points_opp > 2 then --we have 3 or more waypoints to choose from --CODING--Change to 4 or 5 ?
			local _index=math.random(1,_nb_way_points_opp)
			_position=global.way_points_table[force_opponent][_index]
			table.remove(global.way_points_table[force_opponent],_index)
			if global.bb_biters_debug then game.print("          Taking waypoint from "..force_opponent.." (".._position[1]..",".._position[2]..").", {r = 97, g = 97, b = 127}) end
			_position[2]=-_position[2] --EVL switch side of _position
			--EVL TODO? : send the group to the same side of the target  OR send it to the same side as it was sent to opponents ?
		end
	end
	
	if not _position then
		if math_random(1,10)>2 then
			--EVL SEND GROUP ON THE SAME SIDE (X-axis) OF THE MAP THAN THE TARGET
			if target.x <0 then
				_position = {-_posX, _posY}
			else
				_position = { _posX, _posY}
			end
			_position_is_new=true
		else
		-- So you build all your base on the same side of X-axis ? and never get attacked on your back ?
		-- Nope, and this is the patch, 20% chance of reverse attack xd
			if target.x <0 then
				_position = { _posX, _posY}
			else
				_position = {-_posX, _posY}
			end
			_reverse = "(reversed)"
			_position_is_new=true
			
		end
	end
	--
	-- Is there a place to be there (could be a lake)
	
	position = unit_group.surface.find_non_colliding_position("stone-furnace", _position, 96, 1)
	
	if position then
		if math.abs(position.y) >= math.abs(unit_group.position.y) then --EVL TEST/DEBUG/UNDERSTAND
			if global.bb_biters_debug then game.print("  DEBUGS: I dont know what happened here (send_group in ai.lua)  group #"..group_numero..".", {r = 255, g = 77, b = 77}) end
		end 
		--if math.abs(position.y) < math.abs(unit_group.position.y) then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = position,
				radius = 16,
				distraction = defines.distraction.by_enemy
			}
		--end 
		--Everything went fine, we store the _position (and not the position) > we want to always test surface.find_non_colliding_position
		if _position_is_new then 
			if table_size(global.way_points_table[force_name]) < global.way_points_max then --EVL we dont remember infinity of waypoints (we prefer to use old ones than new ones, for equity/balance)
				table.insert(global.way_points_table[force_name],_position)
				if global.bb_biters_debug then game.print("          Inserting new waypoint for "..force_name.." (".._position[1]..",".._position[2]..")", {r = 97, g = 127, b = 97}) end
			else
				if global.bb_biters_debug then game.print("          Forgetting new waypoint for "..force_name.." (".._position[1]..",".._position[2]..")", {r = 97, g = 127, b = 97}) end
			end
		end
	else
		if global.bb_biters_debug then game.print("  DEBUGS: failed to get position (in send_group) skipping waypoint command for group #"..group_numero..".", {r = 255, g = 77, b = 77}) end
		--no return here, we just skip way_point command
	end
	-- THEN WE SEND TO TARGET
	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = target,
		radius = 32,
		distraction = defines.distraction.by_enemy
	}
	-- THEN WE SEND TO SILO
	commands[#commands + 1] = {
		type = defines.command.attack,
		target = global.rocket_silo[force_name],
		distraction = defines.distraction.by_enemy
	}

	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.logical_and,
		commands = commands
	})
	if global.bb_biters_debug then game.print("          Debugs : target="..target.x..","..target.y.."   waypoint="..position.x..","..position.y.."  [color=#FFFFFF]sent[/color] ".._reverse.." ! ["..force_name.."]  group #"..group_numero, {r = 150, g = 150, b = 150}) end
	return true
end

local function get_unit_group_position(spawner)
	local p
	if spawner.force.name == "north_biters" then
		p = {x = spawner.position.x, y = spawner.position.y + 4}
	else
		p = {x = spawner.position.x, y = spawner.position.y - 4}
	end
	p = spawner.surface.find_non_colliding_position("electric-furnace", p, 512, 1)
	if not p then
		if global.bb_biters_debug then game.print("Debug: No unit_group_position found for team " .. spawner.force.name) end
		return
	end
	return p
end

local function get_active_threat(biter_force_name)
	local active_threat = 0
	for _, biter in pairs(global.active_biters[biter_force_name]) do
		if biter.entity then
			if biter.entity.valid then
				active_threat = active_threat + threat_values[biter.entity.name]
			end
		end
	end
	return active_threat
end

local function get_nearby_biter_nest(target_entity)
	local center = target_entity.position
	local biter_force_name = target_entity.force.name .. "_biters"
	local spawner = get_random_spawner(biter_force_name)
	if not spawner then return end
	local best_distance = (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2

	for _ = 1, 16, 1 do
		local new_spawner = get_random_spawner(biter_force_name)
		local new_distance = (center.x - new_spawner.position.x) ^ 2 + (center.y - new_spawner.position.y) ^ 2
		if new_distance < best_distance then
			spawner = new_spawner
			best_distance = new_distance
		end
	end

	if not spawner then return end
	--print("Nearby biter nest found at x=" .. spawner.position.x .. " y=" .. spawner.position.y .. ".")
	return spawner
end

local function create_attack_group(surface, force_name, biter_force_name, group_numero)
	
	if global.freeze_players then game.print("  DEBUGS: create_attack_group called while freezed") return end --EVL not supposed to happen
	local threat = global.bb_threat[biter_force_name]
	if get_active_threat(biter_force_name) > threat * 1.20 then 
		if global.bb_biters_debug then game.print("  DEBUGS: Enough threat ("..get_active_threat(biter_force_name)..") on " .. force_name .." side > Skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return
	end
	if threat <= 0 then 
		if global.bb_biters_debug then game.print("  DEBUGS: Threat is negative > Skipping ..["..force_name.."] skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return false 
	end
	if bb_config.max_active_biters - get_active_biter_count(biter_force_name) < bb_config.max_group_size then
		if global.bb_biters_debug then game.print("  DEBUGS: Not enough slots for biters for team " .. force_name .. ". Available slots: " .. bb_config.max_active_biters - get_active_biter_count(biter_force_name).." skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return false
	end
	local side_target = get_target_entity(force_name)
	if not side_target then
		if global.bb_biters_debug then game.print("  DEBUGS: No side target found for " .. force_name .. " (in create_attack_group) skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return
	end
	local spawner = get_nearby_biter_nest(side_target)
	if not spawner then
		if global.bb_biters_debug then game.print("  DEBUGS: No spawner found for " .. force_name .. " (in create_attack_group) skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return
	end
	local unit_group_position = get_unit_group_position(spawner)
	if not unit_group_position then 
		if global.bb_biters_debug then game.print("  DEBUGS: failed to get unit_group_position for " .. force_name .. " (in create_attack_group) skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return 
	end
	local units = select_units_around_spawner(spawner, force_name, side_target)
	if not units then 
		if global.bb_biters_debug then game.print("  DEBUGS: failed to get units for " .. force_name .. " (in create_attack_group) skipping group #"..group_numero, {r = 99, g = 99, b = 99}) end
		return 
	end
	local unit_group = surface.create_unit_group({position = unit_group_position, force = biter_force_name})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
	--EVL Now we send group
	send_group(unit_group, force_name, side_target,group_numero)
	global.unit_groups[unit_group.group_number] = unit_group
end

Public.pre_main_attack = function()
	local surface = game.surfaces[global.bb_surface_name]
	local force_name = global.next_attack
	if global.main_attack_wave_amount > 0 then --EVL we still have waves to send
		if global.bb_biters_debug then game.print("DEBUGS: pre_main_attack called while amount>O (groups still have to be sent, this alert caused by freeze/unfreeze at ~bad~ timings", {r = 192, g = 77, b = 77}) end --EVL
		return 
	end 
	if not global.training_mode or (global.training_mode and #game.forces[force_name].connected_players > 0) then
		local biter_force_name = force_name .. "_biters"
		global.main_attack_wave_amount = math.ceil(get_threat_ratio(biter_force_name) * 7)
		if global.main_attack_wave_amount < 3 then global.main_attack_wave_amount=3 end --EVL even if one team is far ahead, we want at least 3 waves : so waves are 0 (if threat<0) or in 3..7 interval
		--CHANGE THIS TO SHOW ADMINS ONLY ? (probably no)
		if global.bb_biters_debug then game.print("DEBUGS: UP TO "..global.main_attack_wave_amount .. " unit groups designated for " .. force_name .. " biters.", {r = 192, g = 77, b = 77}) end --EVL
	else
		global.main_attack_wave_amount = 0
	end
	
end


Public.perform_main_attack = function()
	--game.print("start of main_attack #"..global.main_attack_wave_amount)
	if global.freeze_players then return end -- EVL we dont send groups while freezed
	local number = (game.tick % 900)/60 --#call from tick functions (main.lua)
	
	--if global.bb_biters_debug then game.print("DEBUGS: "..number.." group#"..global.main_attack_wave_amount, {r = 127, g = 127, b = 127}) end --CODING--
	if number==1 and global.bb_biters_debug then show_way_points_table(global.way_points_table) end --show the table at the beginning of the main attacks
	if global.main_attack_wave_amount > 0 then
		--if global.bb_biters_debug then game.print("--------START OF SENDING GROUP#"..global.main_attack_wave_amount.."------", {r = 99, g = 99, b = 99}) end
		local surface = game.surfaces[global.bb_surface_name]
		local force_name = global.next_attack
		local biter_force_name = force_name .. "_biters"
		create_attack_group(surface, force_name, biter_force_name, global.main_attack_wave_amount)
		--if global.bb_biters_debug then game.print("--------END OF SENDING GROUP#"..global.main_attack_wave_amount.."------", {r = 99, g = 99, b = 99}) end --CODING--
		global.main_attack_wave_amount = global.main_attack_wave_amount - 1
		if global.main_attack_wave_amount==0 and global.bb_biters_debug then  --show the table at the end of the main attacks
			show_way_points_table(global.way_points_table) 
			game.print("‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒‒", {r = 50, g = 50, b = 50})
		end
	end

end

Public.post_main_attack = function()
	global.main_attack_wave_amount = 0
	if global.next_attack == "north" then
		global.next_attack = "south"
	else
		global.next_attack = "north"
	end
end

Public.wake_up_sleepy_groups = function()
	local force_name = global.next_attack
	local biter_force_name = force_name .. "_biters"
	local entity
	local unit_group
	for _, biter in pairs(global.active_biters[biter_force_name]) do
		entity = biter.entity
		if entity then
			if entity.valid then
				unit_group = entity.unit_group
				if unit_group then
					if unit_group.valid then
						if unit_group.state == defines.group_state.finished then
							--game.print("  DEBUGS : Waking up")
							
							if global.bb_biters_debug then game.print("  DEBUGS : Waking up "..force_name.." Unit Group at (" .. unit_group.position.x .. "," .. unit_group.position.y .. ").", {r = 127, g = 77, b = 77}) end
							send_group(unit_group, force_name)
							return
						end
					end
				end
			end
		end
	end
end

--By Maksiu1000 skip the last two tech
Public.unlock_satellite = function(event)
    -- Skip unrelated events
    if event.research.name ~= 'speed-module-3' then
        return
    end
    local force = event.research.force
    if not force.technologies['rocket-silo'].researched then
        force.technologies['rocket-silo'].researched=true
        force.technologies['space-science-pack'].researched=true
    end
end

Public.raise_evo = function()
	--game.print("public.raise_evo ") --EVL debug
	if global.freeze_players then --EVL evo of evo if also frozen
		return 
	end
	--EVL LINE BELOW TO UNCOMMENT AFTER TESTING --CODING--
	--if not global.training_mode and (#game.forces.north.connected_players == 0 or #game.forces.south.connected_players == 0) then return end


	--[[ EVL we are not babies, no more pity timer
	if game.ticks_played < 7200 then return end
	if global.difficulty_vote_index == 1 then
		local x = game.ticks_played/3600 -- current length of the match in minutes
		global.difficulty_vote_value = ((x / 470) ^ 3.7) + 0.25
	end
	]]--
	local amount = math.ceil(global.evo_raise_counter * 0.75)

	if not global.total_passive_feed_redpotion then global.total_passive_feed_redpotion = 0 end
	global.total_passive_feed_redpotion = global.total_passive_feed_redpotion + amount

	local biter_teams = {["north_biters"] = "north", ["south_biters"] = "south"}
	local a_team_has_players = false
	for bf, pf in pairs(biter_teams) do
		--EVL LINE BELOW TO UNCOMMENT AFTER TESTING  --CODING--
		--if #game.forces[pf].connected_players > 0 then --CODING--
			set_evo_and_threat(amount, "automation-science-pack", bf)
			a_team_has_players = true
			global.bb_evolution[bf] = global.bb_evolution[bf] + global.evo_boost_values[bf] --EVL we boost EVO (but not threat)
			--game.print("evo "..bf.."="..global.bb_evolution[bf]) --EVL debug
		--end --CODING--
	end
	if not a_team_has_players then return end
	global.evo_raise_counter = global.evo_raise_counter + (1 * 0.50)
end

Public.reset_evo = function()
	local amount = global.total_passive_feed_redpotion
	if amount < 1 then return end
	global.total_passive_feed_redpotion = 0

	local biter_teams = {["north_biters"] = "north", ["south_biters"] = "south"}
	for bf, _ in pairs(biter_teams) do
		global.bb_evolution[bf] = 0
		set_evo_and_threat(amount, "automation-science-pack", bf)
	end
end

--Biter Threat Value Subtraction
function Public.subtract_threat(entity)
	if not threat_values[entity.name] then return end
	if entity.type == "unit" then
		global.active_biters[entity.force.name][entity.unit_number] = nil
	end

	global.bb_threat[entity.force.name] = global.bb_threat[entity.force.name] - threat_values[entity.name]

	return true
end

local UNIT_NAMES = {
	'small-biter',
	'small-spitter',
	'medium-biter',
	'medium-spitter',
	'big-biter',
	'big-spitter',
	'behemoth-biter',
	'behemoth-spitter',
}
local UNIT_NAMES_LEN = #UNIT_NAMES

local function likely_biter_name(force_name)
	-- Get most likely biter name based on current evolution.
	local idx = UNIT_NAMES_LEN
	local evo = global.bb_evolution[force_name]
	-- Bother calculating threshold only for evolution less than 90.
	if evo < 0.9 then
		-- Map evolution onto array indicies.
		idx = math.ceil((evo + 0.1) * UNIT_NAMES_LEN)
	end

	-- Randomly choose between pair and respect array boundaries.
	if idx > 1 then
		idx = math.random(idx - 1, idx)
	end

	return UNIT_NAMES[idx]
end

local CORPSE_NAMES = {
	'behemoth-biter-corpse',
	'big-biter-corpse',
	'medium-biter-corpse',
	'small-biter-corpse',
	'behemoth-spitter-corpse',
	'big-spitter-corpse',
	'medium-spitter-corpse',
	'small-spitter-corpse',
}

local function reanimate_unit(id)
	local position = fifo.pop(id)

	-- Find corpse to spawn unit on top of.
	local surface = game.surfaces[global.bb_surface_name]
	local corpse = surface.find_entities_filtered {
		type = 'corpse',
		name = CORPSE_NAMES,
		position = position,
		radius = 1,
		limit = 1,
	}[1]

	local force = 'south_biters'
	if position.y < 0 then
		force = 'north_biters'
	end

	local direction = nil
	local name = nil
	if corpse == nil then
		-- No corpse data, choose unit based on evolution %.
		name = likely_biter_name(force)
	else
		-- Extract name by cutting of '-corpse' part.
		name = string.sub(corpse.name, 0, -8)
		position = corpse.position
		direction = corpse.direction
		corpse.destroy()
	end

	surface.create_entity {
		name = name,
		position = position,
		force = force,
		direction = direction,
	}
end

local function _reanimate_units(id, cycles)
	repeat
		-- Reanimate unit and reassign current fifo state
		reanimate_unit(id)
		cycles = cycles - 1
	until cycles == 0
end

function Public.reanimate_units()
	-- This FIFOs can be accessed by force indices.
	for force, id in pairs(global.dead_units) do
		-- Check for each side if there are any biters to reanimate.
		if fifo.empty(id) then
			goto reanim_units_cont
		end

		-- Balance amount of unit creation requests to get rid off
		-- excess stored in memory.
		local cycles = fifo.length(id) / global.reanim_balancer
		cycles = math.floor(cycles) + 1
		_reanimate_units(id, cycles)

		::reanim_units_cont::
	end
end

Public.schedule_reanimate = function(event)
	-- This event is to be fired from on_post_entity_died. Standard version
	-- of this event is racing with current reanimation logic. Corpse
	-- takes few ticks to spawn, there is also a short dying animation. This
	-- combined makes renimation to miss corpses on the battle field
	-- sometimes.
	
	-- If rocket silo was blown up - disable reanimate logic.
	if global.server_restart_timer ~= nil then
		return
	end

	-- There is no entity within this event and so we have to guess
	-- force based on y axis.
	local force = game.forces['south_biters']
	local position = event.position
	if position.y < 0 then
		force = game.forces['north_biters']
	end

	local idx = force.index
	local chance = global.reanim_chance[idx]
	if chance <= 0 then
		return
	end

	local reanimate = math.random(1, 100) <= chance
	if not reanimate then
		return
	end

	-- Store only position, that is enough to guess force and type of biter.
	fifo.push(global.dead_units[idx], position)
end

function Public.empty_reanim_scheduler()
	for force, id in pairs(global.dead_units) do
		-- Check for each side if there are any biters to reanimate.
		if not fifo.empty(id) then
			return false
		end
	end

	return true
end

return Public
