local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables"
local string_sub = string.sub
local math_random = math.random
local math_round = math.round
local math_abs = math.abs
local math_min = math.min
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local string_find = string.find

--EVL Publicity for hosts --CODING--
--local MDiscord="the French Discord Community https://discord.gg/kwZCMfa"
--local MDiscord="the FreeBB Discord Community https://discord.gg/yBGYCg5J"
local MDiscord="the Red Circuit Community https://discord.red-circuit.org/"
--local MDiscord="YOURSELF :-)"

-- Only add upgrade research balancing logic in this section
-- All values should be in tables.lua
local function proj_buff(current_value,force_name)
	if not global.combat_balance[force_name].bullet then global.combat_balance[force_name].bullet = get_ammo_modifier("bullet") end
	global.combat_balance[force_name].bullet = global.combat_balance[force_name].bullet + current_value
	game.forces[force_name].set_ammo_damage_modifier("bullet", global.combat_balance[force_name].bullet)
end
local function laser_buff(current_value,force_name)
		if not global.combat_balance[force_name].laser_damage then global.combat_balance[force_name].laser_damage = get_turret_attack_modifier("laser-turret") end
		global.combat_balance[force_name].laser_damage = global.combat_balance[force_name].laser_damage + current_value - get_upgrade_modifier("laser-turret")
		game.forces[force_name].set_turret_attack_modifier("laser-turret", current_value)	
end
local function flamer_buff(current_value_ammo,current_value_turret,force_name)
		if not global.combat_balance[force_name].flame_damage then global.combat_balance[force_name].flame_damage = get_ammo_modifier("flamethrower") end
		global.combat_balance[force_name].flame_damage = global.combat_balance[force_name].flame_damage + current_value_ammo - get_upgrade_modifier("flamethrower")
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.combat_balance[force_name].flame_damage)
		
		if not global.combat_balance[force_name].flamethrower_damage then global.combat_balance[force_name].flamethrower_damage = get_turret_attack_modifier("flamethrower-turret") end
		global.combat_balance[force_name].flamethrower_damage = global.combat_balance[force_name].flamethrower_damage +current_value_turret - get_upgrade_modifier("flamethrower-turret")
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.combat_balance[force_name].flamethrower_damage)	
end
local balance_functions = {
	["refined-flammables"] = function(force_name)
		flamer_buff(get_upgrade_modifier("flamethrower")*2,get_upgrade_modifier("flamethrower-turret")*2,force_name)
	end,
	["refined-flammables-1"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-2"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-3"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-4"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-5"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-6"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["refined-flammables-7"] = function(force_name)
		flamer_buff(0.06,0.06,force_name)
	end,
	["energy-weapons-damage"] = function(force_name)
		laser_buff(get_upgrade_modifier("laser-turret")*2,force_name)
	end,
	["energy-weapons-damage-1"] = function(force_name)
		laser_buff(0.2,force_name)
	end,
	["energy-weapons-damage-2"] = function(force_name)
		laser_buff(0.2,force_name)
	end,
	["energy-weapons-damage-3"] = function(force_name)
		laser_buff(0.4,force_name)
	end,
	["energy-weapons-damage-4"] = function(force_name)
		laser_buff(0.4,force_name)
	end,
	["energy-weapons-damage-5"] = function(force_name)
		laser_buff(0.4,force_name)
	end,
	["energy-weapons-damage-6"] = function(force_name)
		laser_buff(0.5,force_name)
	end,
	["energy-weapons-damage-7"] = function(force_name)
		laser_buff(0.5,force_name)
	end,
	["stronger-explosives"] = function(force_name)
		if not global.combat_balance[force_name].grenade_damage then global.combat_balance[force_name].grenade_damage = get_ammo_modifier("grenade") end			
		global.combat_balance[force_name].grenade_damage = global.combat_balance[force_name].grenade_damage + get_upgrade_modifier("grenade")
		game.forces[force_name].set_ammo_damage_modifier("grenade", global.combat_balance[force_name].grenade_damage)

		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = get_ammo_modifier("landmine") end
		global.combat_balance[force_name].land_mine = global.combat_balance[force_name].land_mine + get_upgrade_modifier("landmine")								
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["stronger-explosives-1"] = function(force_name)
		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = get_ammo_modifier("landmine") end
		global.combat_balance[force_name].land_mine = global.combat_balance[force_name].land_mine - get_upgrade_modifier("landmine")								
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["physical-projectile-damage"] = function(force_name)
		if not global.combat_balance[force_name].shotgun then global.combat_balance[force_name].shotgun = get_ammo_modifier("shotgun-shell") end
		global.combat_balance[force_name].shotgun = global.combat_balance[force_name].shotgun + get_upgrade_modifier("shotgun-shell")	
		game.forces[force_name].set_ammo_damage_modifier("shotgun-shell", global.combat_balance[force_name].shotgun)
		game.forces[force_name].set_turret_attack_modifier("gun-turret",0)
	end,
	["physical-projectile-damage-1"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-2"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-3"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-4"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-5"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-6"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
	["physical-projectile-damage-7"] = function(force_name)
		proj_buff(0.3,force_name)
	end,
}

local no_turret_blacklist = {
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true
}

local landfill_biters_vectors = {{0,0}, {1,0}, {0,1}, {-1,0}, {0,-1}}
local landfill_biters = {
	["big-biter"] = true,
	["big-spitter"] = true,
	["behemoth-biter"] = true,	
	["behemoth-spitter"] = true,
}

local target_entity_types = {
	["assembling-machine"] = true,
	["boiler"] = true,
	["furnace"] = true,
	["generator"] = true,
	["lab"] = true,
	["mining-drill"] = true,
	["radar"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["beacon"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true,
}

local spawn_positions = {}
local spawn_r = 7
local spawn_r_square = spawn_r ^ 2
for x = spawn_r * -1, spawn_r, 0.5 do
	for y = spawn_r * -1, spawn_r, 0.5 do
		if x ^ 2 + y ^ 2 < spawn_r_square then
			table.insert(spawn_positions, {x, y})
		end
	end
end
local size_of_spawn_positions = #spawn_positions

local Public = {}

function Public.add_target_entity(entity)
	if not entity then return end
	if not entity.valid then return end
	if not target_entity_types[entity.type] then return end
	table_insert(global.target_entities[entity.force.index], entity)
end

function Public.get_random_target_entity(force_index)
	local target_entities = global.target_entities[force_index]
	local size_of_target_entities = #target_entities
	if size_of_target_entities == 0 then return end
	for _ = 1, size_of_target_entities, 1 do
		local i = math_random(1, size_of_target_entities)
		local entity = target_entities[i]
		if entity and entity.valid then
			return entity
		else
			table_remove(target_entities, i)
			size_of_target_entities = size_of_target_entities - 1
			if size_of_target_entities == 0 then return end
		end
	end
end

function Public.biters_landfill(entity)
	if not landfill_biters[entity.name] then return end	
	local position = entity.position
	if math_abs(position.y) < 8 then return true end --EVL to avoid connection between north and south
	--but won't avoid direct PvP when river is landfilled :/
	local surface = entity.surface
	for _, vector in pairs(landfill_biters_vectors) do
		local tile = surface.get_tile({position.x + vector[1], position.y + vector[2]})
		if tile.collides_with("resource-layer") then
			surface.set_tiles({{name = "landfill", position = tile.position}})
			local particle_pos = {tile.position.x + 0.5, tile.position.y + 0.5}
			for _ = 1, 50, 1 do
				surface.create_particle({
					name = "stone-particle",
					position = particle_pos,
					frame_speed = 0.1,
					vertical_speed = 0.12,
					height = 0.01,
					movement = {-0.05 + math_random(0, 100) * 0.001, -0.05 + math_random(0, 100) * 0.001}
				})
			end
		end
	end
	return true
end

function Public.combat_balance(event)
	local research_name = event.research.name
	local force_name = event.research.force.name		
	local key
	for b = 1, string.len(research_name), 1 do
		key = string_sub(research_name, 0, b)
		if balance_functions[key] then
			if not global.combat_balance[force_name] then global.combat_balance[force_name] = {} end
			balance_functions[key](force_name)
		end
	end
end

function Public.init_player(player)
	if not player.connected then
		if player.force.index ~= 1 then
			player.force = game.forces.player
		end
		return
	end	
		
	if player.character and player.character.valid then
		player.character.destroy()
		player.set_controller({type = defines.controllers.god})
		player.create_character()	
	end
	player.clear_items_inside()
	player.spectator = true
	player.force = game.forces.spectator
	
	local surface = game.surfaces[global.bb_surface_name]
	local p = spawn_positions[math_random(1, size_of_spawn_positions)]
	if surface.is_chunk_generated({0,0}) then
		player.teleport(surface.find_non_colliding_position("character", p, 4, 0.5), surface)
	else
		player.teleport(p, surface)
	end
	if player.character and player.character.valid then player.character.destructible = false end
	game.permissions.get_group("spectator").add_player(player)
end

function Public.no_turret_creep(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if not no_turret_blacklist[event.created_entity.type] then return end
	local surface = event.created_entity.surface
	local spawners = surface.find_entities_filtered({type = "unit-spawner", area = {{entity.position.x - 70, entity.position.y - 70}, {entity.position.x + 70, entity.position.y + 70}}})
	if #spawners == 0 then return end
	
	local allowed_to_build = true
	
	for _, e in pairs(spawners) do
		if (e.position.x - entity.position.x)^2 + (e.position.y - entity.position.y)^2 < 4096 then --(EVL 64 tiles)^2
			allowed_to_build = false
			break
		end			
	end
	
	if allowed_to_build then return end
	
	if event.player_index then
		local turret={name=entity.name,count=1,health=entity.get_health_ratio()}
		game.players[event.player_index].insert(turret)--{name = entity.name, count = 1})
		game.players[event.player_index].play_sound{path = "utility/wire_connect_pole", volume_modifier = 0.5}
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		local turret={name=entity.name,count=1,health=entity.get_health_ratio()}
		inventory.insert(turret)													
	end
	
	surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Turret too close to spawner!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

--EVL Share chat between spectator/god/manager/forces
function Public.share_chat(event)
	if not event.message then return end
	if not event.player_index then return end


	local player = game.players[event.player_index]
	if not(player.tag) then tag = "" else tag = player.tag end
	local color = player.chat_color
	local msg = player.name .. tag .. " (" .. player.force.name .. "): ".. event.message
	--Note : BBChampions is always on tournamment mode
	-- So EVL rewrote the function
	--EVL Who are we sending message to ?
	local msg_spec=false
	local msg_god=false
	local msg_north=false
	local msg_south=false

	local _print=""
	if player.force.name == "north" then 
		_print="NORTH"
		msg_spec=true
		msg_god=true
		--msg_north=true -- done by game
	elseif player.force.name == "south" then 
		_print="SOUTH"
		msg_spec=true
		msg_god=true
		--msg_south=true -- done by game
	elseif player.force.name == "spectator" then
		--msg_spec=true  -- done by game
		msg_god=true
		if player.name==global.manager_table["north"] then --north manager to team north
			msg_north=true
			msg = player.name .. tag .. " (north manager): ".. event.message
			_print="MANAGER NORTH"
		elseif player.name==global.manager_table["south"] then --south manager to team south
			msg_south=true
			msg = player.name .. tag .. " (south manager): ".. event.message
			_print="MANAGER SOUTH"
		else 
			_print="SPEC"
		end
	elseif game.forces["spec_god"] and player.force.name == "spec_god" then
		_print="GOD"
		msg_spec=true
		--msg_god=true -- done by game
	elseif player.force.name == "player" then
		_print=">>>> SPAWN? (Bug: force.name=<<player>> in Public.share_chat(event)."
		msg_spec=true
		msg_god=true
	end
	--EVL Print to whom it has to be
	msg_debug="" --EVL debug
	if msg_north then 
		game.forces.north.print(msg, color)
		game.forces.north.play_sound{path = "utility/console_message", volume_modifier = 0.8}
		msg_debug=msg_debug.."(north) "
	end
	if msg_south then
		game.forces.south.print(msg, color)
		game.forces.south.play_sound{path = "utility/console_message", volume_modifier = 0.8}
		msg_debug=msg_debug.."(south) "
	end
	if msg_spec then
		game.forces.spectator.print(msg, color)
		game.forces.spectator.play_sound{path = "utility/console_message", volume_modifier = 0.8}
		msg_debug=msg_debug.."(spec) "
	end
	if msg_god and game.forces["spec_god"] then
		game.forces.spec_god.print(msg, color)
		game.forces.spec_god.play_sound{path = "utility/console_message", volume_modifier = 0.8}
		msg_debug=msg_debug.."(god) "
	end
	
	--local _ping, b = string_find(event.message, "gps=", 1, false)
	--EVL : cant print anything : it will override pings
	--if _ping then return end
	--EVL but if no ping can we debug ???
	--if msg_debug=="" then game.print(_print.."      Debug: NO MORE PRINT")
	--else game.print(_print.."      Debug: ADD PRINT TO "..msg_debug)
	--end
	
	
end

function Public.spy_fish(player, event)
	local button = event.button
	local shift = event.shift
	if not player.character then return end
	if event.control then return end
	local duration_per_unit = 2700
	local i2 = player.get_inventory(defines.inventory.character_main)
	if not i2 then return end
	local owned_fish = i2.get_item_count("raw-fish")
	local send_amount = 1
	if owned_fish == 0 then
		player.print("You have no fish in your inventory.",{ r=0.98, g=0.66, b=0.22})
	else
		if shift then
			if button == defines.mouse_button_type.left then
				send_amount = owned_fish
			elseif button == defines.mouse_button_type.right then
				send_amount = math_floor(owned_fish / 2)
			end
		else
			if button == defines.mouse_button_type.left then
				send_amount = 1
			elseif button == defines.mouse_button_type.right then
				send_amount = math_min(owned_fish, 5)
			end
		end

		local x = i2.remove({name="raw-fish", count=send_amount})
		if x == 0 then i2.remove({name="raw-fish", count=send_amount}) end
		local enemy_team = "south"
		if player.force.name == "south" then enemy_team = "north" end													 
		if global.spy_fish_timeout[player.force.name] - game.tick > 0 then 
			global.spy_fish_timeout[player.force.name] = global.spy_fish_timeout[player.force.name] + duration_per_unit * send_amount
			spy_time_seconds = math_floor((global.spy_fish_timeout[player.force.name] - game.tick) / 60)
			if spy_time_seconds > 60 then
				local minute_label = " minute and "
				if spy_time_seconds > 120 then
					minute_label = " minutes and "
				end
				player.print(math_floor(spy_time_seconds / 60) .. minute_label .. math_floor(spy_time_seconds % 60) .. " seconds of enemy vision left.", { r=0.98, g=0.66, b=0.22})
			else
				player.print(spy_time_seconds .. " seconds of enemy vision left.", { r=0.98, g=0.66, b=0.22})
			end
		else
			game.print(player.name .. " sent " .. send_amount .. " fish to spy on " .. enemy_team .. " team!", {r=0.98, g=0.66, b=0.22})
			global.spy_fish_timeout[player.force.name] = game.tick + duration_per_unit * send_amount
		end		
	end
end

function Public.create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r=0.5, g=0.3, b=0.99}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

--EVL Top Button for Packs listing (repair pack)  -> to be edited when pack is chosen
function Public.create_bbc_packs_button(player)
	if player.gui.top["bbc_packs_button"] then player.gui.top["bbc_packs_button"].destroy() end
	local b
	if not(global.pack_choosen) or global.pack_choosen=="" then
		b = player.gui.top.add({type = "sprite-button", caption = "[img=item.repair-pack]", name = "bbc_packs_button", tooltip = "Starter Packs Listing"})
		b.style.minimal_width = 38
	elseif Tables.packs_list[global.pack_choosen] then
		b = player.gui.top.add({type = "sprite-button", caption = "Pack: "..Tables.packs_list[global.pack_choosen].button, name = "bbc_packs_button", 
			tooltip = "Active Starter Pack: [font=default-large-bold]"..Tables.packs_list[global.pack_choosen].caption.."[/font]\n  [font=default-small][color=#999999]Click to view all packs.[/color][/font]"})
		b.style.minimal_width = 100
	else
		game.print("Bug : starter pack is wrong... (in functions/create_bbc_packs_button)")
	end
	b.style.font_color = {r=0.89, g=0.99, b=0.89}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

--EVL Remove all game_type buttons (after force-map-reset or starting-sequence) Not beautiful...
function Public.remove_all_pause_and_game_type_buttons()
	for _, player in pairs(game.connected_players) do
		if player.gui.top["bbc_game_type_button"] then player.gui.top["bbc_game_type_button"].destroy() end
		if player.gui.top["team_manager_pause_button"] then player.gui.top["team_manager_pause_button"].destroy() end
	end
end

--EVL Introduction Screen (always shown on player_joined)
function Public.show_intro(player)
	if player.gui.center["map_intro_frame"] then player.gui.center["map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	local frame = frame.add {type = "frame", direction = "vertical" }
		
	--TITLE
	local Mtitle=""
	Mtitle=Mtitle.."[font=default-large-bold][color=#FF5555]                                            "
	Mtitle=Mtitle.."--- WELCOME  TO  [/color][color=#5555FF]BITER[/color]  [color=#55FF55]BATTLES[/color]  [color=#FF5555]CHAMPIONSHIPS ![/color][/font]"
	Mtitle=Mtitle.."                      [color=#DDDDDD]https://bbchampions.org[/color]    "..global.version
	local title = frame.add {type = "label" , name = "biter_battles_map_title", caption = Mtitle} 
	title.style.single_line = false
	title.style.font = "default"
	title.style.font_color = {r=0.7, g=0.6, b=0.99}
	
	
	--LOGO AND FIRST PART
	local t= frame.add {type = "table", name = "biter_battles_map_top", column_count = 2}
	t.vertical_centering=false
	local t1 = t.add {type = "sprite", name = "biter_battles_map_left", sprite = "file/png/logo_300.png"}
	Mtop="\n"
	Mtop=Mtop.."[font=default-bold][color=#FF9740]A few words about Biter Battles : [/color][/font]\n\n"
	Mtop=Mtop.."        Your team defends your [item=rocket-silo]silo against waves of biters\n"
	Mtop=Mtop.."                                                    ... while defeating the other team's [item=rocket-silo]silo !\n\n"
	Mtop=Mtop.."        Feed your opponent's biters with [item=logistic-science-pack]science to increase their strength,\n\n"
	Mtop=Mtop.."        High tier [item=utility-science-pack]science juice will yield stronger mutagenic results.\n"
	Mtop=Mtop.."        Only feeding and [img=quantity-time]time increase the power of the biters and lead to one team's victory.\n\n"
	Mtop=Mtop.."        [font=default-bold]There is no direct pvp combat.[/font]\n"
	local t2 = t.add {type = "label" , name = "biter_battles_map_right", caption = Mtop} 
	t2.style.single_line = false
	t2.style.font = "default"
	t2.style.font_color = {r=0.7, g=0.6, b=0.99}
	
	--MAPINFO
	local Minfo=""
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Biter Battles Championships (BBC)[/color][/font] consist of [font=default-bold]2 leagues[/font] where teams fight for their global ranking and the final trophy !\n"
	Minfo=Minfo.."[font=default-bold][color=#5555FF]    [entity=big-biter] BITER[/color][/font] league is meant for ~casual~ players, with normal difficulty and where blueprints are allowed.\n"
	Minfo=Minfo.."[font=default-bold][color=#55FF55]    [entity=behemoth-biter] BEHEMOTH[/color][/font] league is meant for ~pro~ players, with hard difficulty and where blueprint library is disabled.\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Matches[/color][/font] are 3[font=default-small][color=#999999](+1)[/color][/font] vs 3[font=default-small][color=#999999](+1)[/color][/font], the [font=default-small-bold][color=#999999](+1)[/color][/font] "
	Minfo=Minfo.."meaning the manager (or coach/spy/substitute). One team is said [font=default-bold][color=#CCBBFF]ATHOME[/color][/font]\n"
	Minfo=Minfo.."                and has advantages against other team said [font=default-bold][color=#BBAAFF]AWAY[/color][/font] (visitors).\n"
	Minfo=Minfo.."     At the beginning, both teams get the same [item=repair-pack][font=default-bold][color=#CCBBFF]STARTER PACK[/color][/font][item=repair-pack] choosed among four, leading to a fast early game.\n"
	Minfo=Minfo.."     Team [font=default-bold][color=#CCBBFF]ATHOME[/color][/font] chooses : 1/ Their side 2/ To reroll map (up to twice, no rollback) 3/ The starter pack.\n"--DEBUG-- 4/ Is not attacked first.\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Be Careful : [/color][/font]Groups of biters will come from every side, there is no safe place !\n"
	Minfo=Minfo.."          And time is running... Once reached 2h of playtime, [img=quantity-time][font=default-bold][color=#CCBBFF]ARMAGEDDON[/color][/font][img=quantity-time] mode will be activated, expect Behemoths sooner than later !\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Streamers : [/color][/font]You can use [font=default-bold]~Spec~[/font] mode to have a larger view of the field.\n"
	Minfo=Minfo.."                      Clicking on the name of a player will show his crafting list and his inventory.\n"
	--Minfo=Minfo.."\n"
	local l = frame.add {type = "label", caption = Minfo, name = "biter_battles_map_intro"} 
	l.style.single_line = false
	l.style.font = "default"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}
	--BOTTOM
	local b= frame.add {type = "table", name = "biter_battles_map_bottom", column_count = 3}
	--b.vertical_centering=false
	local b1 = b.add {type = "label", name = "biter_battles_map_bleft", caption = "Thanks for reading - Have fun with the game !                     "} 
	--l.style.single_line = false
	b1.style.font = "default"
	b1.style.font_color = {r=0.7, g=0.6, b=0.99}
	local b2 = b.add ({type = "button",	name = "biter_battles_map_intro_next", caption = "Page 2     ►", tooltip = "Page 2 with more infos"}) 
	b2.style.font_color = {r=0.10, g=0.10, b=0.10}
	b2.style.font = "default-bold"
	b2.style.padding = -1
	--b2.style.width = 20

	local Mbottom=""
	Mbottom=Mbottom.."\n                        [font=default-small][color=#DDDDDD](c) Biter Battles was created by Mewmew from Comfy's servers[/color][/font]"
	Mbottom=Mbottom.."\n   [font=default-small][color=#AAFFAA]Server provided by "..MDiscord.."[/color][/font]"
	local b3 = b.add {type = "label", name = "biter_battles_map_bright", caption = Mbottom } 
	b3.style.single_line = false
	b3.style.font = "default"
	b3.style.font_color = {r=0.7, g=0.6, b=0.99}
	

	
end

--EVL SHOW NEXT PAGE (detailed info more optionnals)
function Public.show_intro_next(player)
	if player.gui.center["map_intro_frame"] then player.gui.center["map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	local frame = frame.add {type = "frame", direction = "vertical"}

	local Minfo=""
	Minfo=Minfo.."[font=default-large-bold][color=#FF5555]                                    --- WELCOME  TO  [/color][color=#5555FF]BITER[/color]  [color=#55FF55]BATTLES[/color]  [color=#FF5555]CHAMPIONSHIPS ---[/color][/font]"
	Minfo=Minfo.."                         [color=#DDDDDD]https://bbchampions.org[/color]    "..global.version.."\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Some more details about Biter Battles and BBC : [/color][/font]"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default][color=#FF9740]Restrictions : [/color][/font] Mines, Artillery, Atomic bomb are disabled. Robots can't build across the river which btw can't be landfilled.\n"
	Minfo=Minfo.."                    Pollution is not active. There is no cliff on the map. Killing (or dodging) worms will grant you rewards hidden in the scraps.\n"
	Minfo=Minfo.."                    [font=default-small][color=#999999]Note: Silo can't be destroyed by players, even with grenades, it will be left with 9 health.[/color][/font]\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default][color=#FF9740]BITERS[/color][/font] form groups. Each group first try to reach a ~waypoint~ then attack a random target then attack the silo.\n"
	Minfo=Minfo.."                [font=default-small][color=#999999]Groups will attack from all angles, and will repeat those attacks to other side (slightly randomized).[/color][/font]\n"
	Minfo=Minfo.."[font=default][color=#FF9740]EVO-lution[/color][/font] of the biters increases when they get fed, and can rise above 100% which unlocks endgame modifiers,\n"
	Minfo=Minfo.."                     granting biters increased damage and health. Tier of biters grows with evolution.\n"
	Minfo=Minfo.."[font=default][color=#FF9740]THREAT[/color][/font] causes biters to attack and reduces when biters are slain. Feeding gives permanent ~threat-income~, as well as\n"
	Minfo=Minfo.."                creating instant threat. A high threat value causes big attacks. Values of zero or below will cause no attacks.\n"
	Minfo=Minfo.."                [font=default-small][color=#999999]Note: if you have less threat than opponents, you'll get fewer groups of biters attacking your structures.[/color][/font]\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default][color=#FF9740]PAUSE : [/color][/font] teams can ask for a short pause once per hour, referee will freeze players and biters,\n"
	Minfo=Minfo.."                 then when players are ready, referee will unfreeze and trigger a short countdown.\n"
	Minfo=Minfo.."                [font=default-small][color=#999999]Note: referee can force unfreezing players after 180s (if players are not responding).[/color][/font]\n"	
	Minfo=Minfo.."[font=default][color=#FF9740]SPEED : [/color][/font] if both teams agree, referee can reduce the speed of the game with this chat command [color=#DDDDDD]/c game.speed=0.8[/color]\n"
	Minfo=Minfo.."                  [font=default-small][color=#999999](only in case some players can't keep up with the game and have jumps).[/color][/font]\n"
	Minfo=Minfo.."[font=default][color=#FF9740]CLEAR-CORPSES [/color][/font] is called every 15 min, clearing biter corpses and remnants.\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default][color=#FF9740]TIPS : [/color][/font] you need to be fast ! Biters are very aggressive, you need to find a good balance between 3 things :\n"
	Minfo=Minfo.."     [font=default-bold][color=#CCBBFF]Defense[/color][/font]    so you don't get overwhelmed,\n"
	Minfo=Minfo.."     [font=default-bold][color=#CCBBFF]Building[/color][/font]    so you can keep up with biter evolution,\n"
	Minfo=Minfo.."     [font=default-bold][color=#CCBBFF]Offensive[/color][/font]  so you boost opponent's biter evolution.\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."[font=default][color=#FF9740]CONTACT : [/color][/font][color=#DDDDDD]bbc.factorio@gmail.com     Twitter: @BiterBattles     Discord: everLord#4340[/color]\n"
	Minfo=Minfo.."\n"
	Minfo=Minfo.."Thanks for reading - Have fun with the game !"
	Minfo=Minfo.."                                                                                    "
	Minfo=Minfo.."[font=default-small][color=#DDDDDD](c) Biter Battles was created by Mewmew from Comfy's servers[/color][/font]"
	Minfo=Minfo.."\n                                                                                                                                                  "
	Minfo=Minfo.."[font=default-small][color=#AAFFAA]Server provided by "..MDiscord.."[/color][/font]"

	local l = frame.add {type = "label", caption = Minfo, name = "biter_battles_map_intro"}


	l.style.single_line = false
	l.style.font = "default"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}
end

--EVL SHOW LATEST & IMPORTANT RULES WHEN <</starting-sequence>>
function Public.show_rules(player)
	if player.gui.center["map_rules_frame"] then player.gui.center["map_rules_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "map_rules_frame", direction = "vertical"}
	local frame = frame.add {type = "frame", direction = "vertical" }
		
	--TITLE
	local Mtitle=""
	Mtitle=Mtitle.."[font=default-large-bold][color=#FF5555] REMEMBER THESE RULES ![/color][/font]"
	Mtitle=Mtitle.."                                   [color=#DDDDDD]https://bbchampions.org[/color]    "..global.version
	local title = frame.add {type = "label" , name = "biter_battles_rules_title", caption = Mtitle} 
	title.style.single_line = false
	title.style.font = "default"
	title.style.font_color = {r=0.7, g=0.6, b=0.99}	
	
	--RULES
	local Minfo="\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]You are not allowed to save map[/color][/font] [font=default-small][color=#AAAAAA](anti-cheat)[/color][/font].\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Debug mode (F4/F5) is mostly deactivated for players [/color][/font] [font=default-small][color=#AAAAAA](or should be)[/color][/font].\n\n"
	Minfo=Minfo.."[font=default-bold][color=#AAFFAA]If a pause is needed, please spam[/color] [color=#FFFFFF]'pause'[/color] or [color=#FFFFFF]'pp'[/color] [color=#88CC88]in chat.[/color][/font] "
	Minfo=Minfo.."[font=default-small][color=#AAAAAA](referees are slow)[/color][/font].\n\n"
	Minfo=Minfo.."[font=default-bold][color=#97DD40]Team ~AtHome~ can reroll map up to twice[/color][/font] [font=default-small][color=#AAAAAA](no roll back)[/color][/font].\n"
	Minfo=Minfo.."[font=default-bold][color=#97DD40]Once map is kept, Team ~AtHome~ announces\n    starter pack as soon as possible[/color][/font] [font=default-small][color=#AAAAAA](gentleman rule)[/color][/font].\n\n"
	Minfo=Minfo.."[font=default-bold][color=#40DDFF]Streamers are not supposed to reveal the map[/color][/font] [font=default-small][color=#AAAAAA](stream hack, use god mode wisely)[/color][/font].\n\n"
	Minfo=Minfo.."[font=default-bold][color=#BBBBBB]Notes and updates :[/color][/font]\n"
	Minfo=Minfo.."[font=default][color=#DDFFDD]          - Players can feel stucked after countdowns, just move in any direction or click[/color][/font].\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]          - Players can deconstruct fishes close to river border[/color][/font] [font=default-small][color=#AAAAAA](by 8 tiles ~ default range)[/color][/font].\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]          - Managers can see own team crafts and inventories[/color][/font] [font=default-small][color=#AAAAAA](but not researches)[/color][/font].\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]          - Managers send messages/pings to own team[/color][/font].\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]          - Manager speakers are only cosmetic, no interaction at all[/color][/font] [font=default-small][color=#AAAAAA](think of a megaphone)[/color][/font].\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]          - Clear-corpses every 15 min, players and managers can still use[/color][/font] [font=default-small][color=#AAAAAA]<</clear-corpses>>[/color][/font]\n"
	Minfo=Minfo.."[font=default][color=#DDDDDD]             from their position at any time[/color][/font] [font=default-small][color=#AAAAAA](no overlap to other side)[/color][/font].\n"
	--Minfo=Minfo.."[font=default][color=#AAAAAA]             ProTip: Command[/color] [color=#AAFFAA]/cc[/color] [color=#AAAAAA](same as <</clear-corpses>>) is faster to type ![/color][/font]\n"
	Minfo=Minfo.."[font=default-large-bold][color=#FFAAAA]             ProTip: Command[/color] [color=#AAFFAA]/ccc[/color] [color=#FFAAAA](same as <</clear-corpses>>) is faster to type ![/color][/font]\n"
	--Minfo=Minfo.."[font=default][color=#DDDDDD]          - god mode pings are not seen by players or specs,\n             spec (and manager) pings are not seen by players.[/color][/font].\n"

	Minfo=Minfo.."\n"
	local l = frame.add {type = "label", caption = Minfo, name = "biter_battles_rule_text"} 
	l.style.single_line = false
	l.style.font = "default"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}
	--BOTTOM
	local b= frame.add {type = "table", name = "biter_battles_rule_bottom", column_count = 2}
	--b.vertical_centering=false
	local b1 = b.add {type = "label", name = "biter_battles_rule_bleft", caption = "Thanks for reading - Have fun with the game !                            "} 
	--l.style.single_line = false
	b1.style.font = "default"
	b1.style.font_color = {r=0.7, g=0.6, b=0.99}
	local b2 = b.add ({type = "button",	name = "biter_battles_rule_close", caption = " READ & APPROVED !"}) 
	b2.style.font_color = {r=0.99, g=0.10, b=0.10}
	b2.style.font = "default-bold"
	b2.style.padding = -1	
end


--EVL Frame with Packs listing (repair pack)
function Public.show_bbc_packs(player)
	if player.gui.center["bbc_packs_frame"] then player.gui.center["bbc_packs_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "bbc_packs_frame", caption = "STARTER PACKS   (click to expand)", direction = "vertical"}
	local t = frame.add({type = "table", name = "bbc_packs_root_table", column_count = Tables.packs_total_nb})
	t.vertical_centering=false
	local _pack_score={} -- EVL the score of total items (sum of qtity * item_value)
		
	for _, pack_elem in pairs(Tables.packs_list) do
		local pack_name=pack_elem.name

		--EVL THE TITLE (button) & SEPARATOR
		local tt= t.add({type = "table", name = "bbc_c_"..pack_name, column_count = 2}) --bbc_c for column
		local button = tt.add({
			type = "button",
			name = "bbc_b_"..pack_name, -- bbc_b for button
			caption = pack_elem.caption,
			tooltip = pack_elem.tooltip
		})
		button.style.font = "heading-1" 
		if pack_name==global.bbc_pack_details then
			button.style.font_color = {r = 0, g = 0, b = 125}
		end
		if pack_name==global.pack_choosen then
			button.style.font_color = {r = 0, g = 125, b = 0}
			
		end

		tt.add({type = "label", caption = "  "}) 
		
		--EVL CONCAT THE CHESTS and get the score/value of the pack		
		local pack_tot_content = {}
		local chest_pos = {
			["left"] = "left",
			["center"] = "center",
			["right"] = "right"
		}
		_pack_score[pack_name]=0
		for _,_chest in pairs(chest_pos) do
			--game.print("pack:"..pack_name.." chest : ".._chest)
			for _item,_qty in pairs(Tables.packs_contents[pack_name][_chest]) do
				if not pack_tot_content[_item] then  
					pack_tot_content[_item] = _qty
				else
					pack_tot_content[_item] = pack_tot_content[_item] + _qty
				end
				--EVL Add the quantity*value of the item to total score of the pack
				if not Tables.packs_item_value[_item] then
					game.print("Debug: pack:"..pack_name.."  chest:".._chest.."  item : ".._item.." is unknown.")
				else
					_pack_score[pack_name]=_pack_score[pack_name] + _qty * Tables.packs_item_value[_item]
				end

			end
		end

		-- EVL SHOW THE SCORE/VALUE OF THE PACK
		local ttt= tt.add({type = "table", name = "bbc_c_"..pack_name, column_count = 2}) -- bbc_c for column
		ttt.style.minimal_width = 175 
		local i = ttt.add({type = "label", caption = "Score:"}) 
		i.style.font = "count-font"
		local q = ttt.add({type = "label", caption = math.floor(_pack_score[pack_name])}) 		
		q.style.font = "count-font"
		--THE LIST
		if global.bbc_pack_details==pack_name then --WE SHOW DETAILS
			for _item,_qty in pairs(pack_tot_content) do
				local img="[img=item.".._item.."]"
				local i = ttt.add({type = "label", caption = img}) 
				local d=_qty.." (" --d for details
				--game.print("left:"..Tables.packs_contents[pack_name]["left"][_item])
				if Tables.packs_contents[pack_name]["left"][_item] then
					d=d..Tables.packs_contents[pack_name]["left"][_item]
					--game.print("left:"..Tables.packs_contents[pack_name]["left"]._item)
				else
					d=d.."-"
				end
				d=d.." , "
				if Tables.packs_contents[pack_name]["center"][_item] then
					d=d..Tables.packs_contents[pack_name]["center"][_item]
				else
					d=d.."-"
				end
				d=d.." , "
				if Tables.packs_contents[pack_name]["right"][_item] then
					d=d..Tables.packs_contents[pack_name]["right"][_item]
				else
					d=d.."-"
				end
				d=d..")"
				local q = ttt.add({type = "label", caption = d})
			end
		else 
			for _item,_qty in pairs(pack_tot_content) do
				local img="[img=item.".._item.."]"
				local i = ttt.add({type = "label", caption = img}) 
				--local qty=_qty.."->".._qty * Tables.packs_item_value[_item]
				local q = ttt.add({type = "label", caption = _qty})
				
			end
		end
	end
	frame.add { type = "line", caption = "this line", direction = "horizontal" }	
	local ttttt= frame.add({type = "table", name = "bbc_bottom", column_count = 2})
	_info_caption="Items will be distributed into 3 chests (left,mid,right) according to details above.           \n"
	_info_caption=_info_caption.."[font=default-small][color=#999999]Note: Starter Pack ~ROBOTS~ will grant both teams 2 levels of Worker robot speed.[/color][/font]"
	local _info=ttttt.add({type = "label", caption = _info_caption}) 
	_info.style.single_line = false
	_info.style.font = "default"
	_info.style.font_color = {r=0.7, g=0.6, b=0.99}
	local button = ttttt.add({
			type = "button",
			name = "bbc_close_packs_frame",
			caption = "Close"
	})
	button.style.font = "heading-1"
	button.style.font_color = {r = 32, g = 32, b = 32}
end

function Public.map_intro_click(player, element)
	if element.name == "close_map_intro_frame" then player.gui.center["map_intro_frame"].destroy() return true end	
	if element.name == "biter_battles_map_left" then player.gui.center["map_intro_frame"].destroy() return true end	
	if element.name == "biter_battles_map_right" then player.gui.center["map_intro_frame"].destroy() return true end	
	if element.name == "biter_battles_map_intro" then player.gui.center["map_intro_frame"].destroy() return true end	
	--EVL PAGE 2
	if element.name == "biter_battles_map_intro_next" then 
		if player.gui.center["map_intro_frame"] then
			player.gui.center["map_intro_frame"].destroy()
			Public.show_intro_next(player)
			return true
		else
			Public.show_intro_next(player)
			return true
		end
	end
	
	--EVL PAGE 1
	if element.name == "map_intro_button" then
		if player.gui.center["map_intro_frame"] then
			player.gui.center["map_intro_frame"].destroy()
			return true
		else
			Public.show_intro(player)
			return true
		end
	end	
end

function Public.map_rules_close(player, element)
	if element.name == "biter_battles_rule_close" then
		if player.gui.center["map_rules_frame"] then
			player.gui.center["map_rules_frame"].destroy()
			return true
		end
	end	
	
end

--EVL Show/Hide Packs listing (repair pack button)
function Public.bbc_packs_click(player, element)
	local _elem = element.name
	if _elem == "bbc_close_packs_frame" then player.gui.center["bbc_packs_frame"].destroy() return true end
	--ACTIVE DETAILS FOR THIS PACK
	local _isPack=string.sub(_elem,7,13)
	for _,_pack in pairs(Tables.packs_list) do
		if _pack.name==_isPack then
			if global.bbc_pack_details==_isPack then 
				global.bbc_pack_details = ""
			else
				global.bbc_pack_details=_isPack
			end
			Public.show_bbc_packs(player)
			return true
		end
	end
	if _elem == "bbc_packs_button" then --EVL click on the repair pack
		if player.gui.center["bbc_packs_frame"] then
			player.gui.center["bbc_packs_frame"].destroy()
			return true
		else
			Public.show_bbc_packs(player)
			return true
		end
	end	

end


function get_ammo_modifier(ammo_category)
	local result = 0
	if Tables.base_ammo_modifiers[ammo_category] then
        result = Tables.base_ammo_modifiers[ammo_category]
	end
    return result
end
function get_turret_attack_modifier(turret_category)
	local result = 0
	if Tables.base_turret_attack_modifiers[turret_category] then
        result = Tables.base_turret_attack_modifiers[turret_category]
	end
    return result
end

function get_upgrade_modifier(ammo_category)
    result = 0
    if Tables.upgrade_modifiers[ammo_category] then
        result = Tables.upgrade_modifiers[ammo_category]
    end
    return result
end

--EVL Change number in kilos (840 -> 0.8k or 12345 -> 12.3k)
function Public.inkilos(value)
	if not value then return -9999 end
	local _value=tonumber(value)
	if _value > 9999 then --Too big, dont need comma
		_value=math.floor(_value/1000).."k"
	elseif _value > 800 then
		if 	_value%100<=50 then
			_value=math.floor(_value/1000).."."..math.floor((_value%1000)/100,0).."k"
		else
			local _decimal = math.floor((_value%1000)/100)
			if _decimal==9 then 
				_value=(math.floor(_value/1000)+1)..".0k"
			else
				_value=math.floor(_value/1000).."."..(_decimal+1).."k"
			end
		end
	end
	return _value
end
--EVL ticks into "h m s"
function Public.get_human_time(tick)
	local secondes = math.floor(tick / 60)
	secondes=secondes%60
	local minutes = tick % 216000
	local hours = tick - minutes
	minutes = math.floor(minutes / 3600)
	hours = math.floor(hours / 216000)
	local humantime = ""
	if hours > 0 then
		humantime = hours .. "h"
	end
	if secondes < 10 then secondes=" "..secondes end
	if minutes < 10 then minutes=" "..minutes end
	
	humantime = humantime .. minutes .."m" .. secondes .. "s"
	return humantime
end

function Public.get_nb_players(force)
	if not(force) or (force~="north" and force~="south") then
		game.print(">>>>>ERROR: in get_nb_players, param force is wrong.", {r=0.98, g=0.22, b=0.22})
		return false
	end
	local force_nb_players=#game.forces[force].connected_players
	--Adjust #players if manager is in team
	if global.managers_in_team and global.manager_table[force] and game.players[global.manager_table[force]] then
		force_nb_players=force_nb_players-1
	end
	if global.viewing_technology_gui[force]>0 then
		force_nb_players=force_nb_players-global.viewing_technology_gui[force]
		if global.bb_debug_gui then game.print(">>>>>INFO: in get_nb_players, removed "..global.viewing_technology_gui[force].." specs spying "..force.." tech tree.", {r=0.98, g=0.98, b=0.22}) end
	end
	if force_nb_players<0 then 
		if global.bb_debug_gui then game.print(">>>>>ERROR: in get_nb_players, result is negative (due to "..force.." manager not connected?) :/", {r=0.98, g=0.22, b=0.22}) end
		force_nb_players=0
		return false
	end
	return force_nb_players
end

return Public
