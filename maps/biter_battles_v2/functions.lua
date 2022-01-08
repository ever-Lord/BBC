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
local MDiscord="the French Discord Community https://discord.gg/kwZCMfa"
--local MDiscord="the FreeBB Discord Community https://discord.gg/yBGYCg5J"
--local MDiscord="the Red Circuit Community https://discord.red-circuit.org/"
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
	if math_abs(position.y) < 8 then return true end
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
		game.players[event.player_index].insert({name = entity.name, count = 1})
		game.players[event.player_index].play_sound{path = "utility/wire_connect_pole", volume_modifier = 0.5}
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
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
		_print=">>>> SPAWN? (Bug: force=player in Public.share_chat(event)."
		msg_spec=true
		msg_god=true
	end
	--EVL Print to whom it has to
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
		game.print("Bug : starter pack is wrong... (infunctions/create_bbc_packs_button)")
	end
	b.style.font_color = {r=0.89, g=0.99, b=0.89}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

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
	Mtitle=Mtitle.."                                [color=#DDDDDD]https://bbchampions.org[/color]    "..global.version
	local title = frame.add {type = "label" , name = "biter_battles_rules_title", caption = Mtitle} 
	title.style.single_line = false
	title.style.font = "default"
	title.style.font_color = {r=0.7, g=0.6, b=0.99}	
	
	--RULES
	local Minfo="\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]You are not allowed to save map[/color][/font] [font=default-small][color=#AAAAAA](anti-cheat)[/color][/font].\n"
	Minfo=Minfo.."[font=default-bold][color=#FF9740]Debug mode (F4/F5) is mostly deactivated for players [/color][/font] [font=default-small][color=#AAAAAA](or should be)[/color][/font].\n\n"
	Minfo=Minfo.."[font=default-bold][color=#AAFFAA]If a pause is needed, please spam[/color] [color=#FFFFFF]'pause'[/color] or [color=#FFFFFF]'pp'[/color] [color=#88CC88]in chat[/color][/font]"
	Minfo=Minfo.."[font=default-small][color=#AAAAAA] (referees are slow)[/color][/font].\n\n"
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
	Minfo=Minfo.."[font=default][color=#AAAAAA]             ProTip: Command[/color] [color=#AAFFAA]/zz[/color] [color=#AAAAAA](same as <</clear-corpses>>) is faster to type ![/color][/font]\n"
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
					game.print("Bug pack:"..pack_name.."  chest:".._chest.."  item : ".._item.." unknown")
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

--FUNCTION TO CHANGE NUMBER IN KILOS (840 -> 0.8k or 12345 -> 12.3k)
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


--[[
	Copyright 2019 Tyler Richard Hoyer
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
		http://www.apache.org/licenses/LICENSE-2.0
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]
--[[
local GF8x2 = {
[0]=0x00,0x02,0x04,0x06,0x08,0x0a,0x0c,0x0e,0x10,0x12,0x14,0x16,0x18,0x1a,0x1c,0x1e,
	0x20,0x22,0x24,0x26,0x28,0x2a,0x2c,0x2e,0x30,0x32,0x34,0x36,0x38,0x3a,0x3c,0x3e,
	0x40,0x42,0x44,0x46,0x48,0x4a,0x4c,0x4e,0x50,0x52,0x54,0x56,0x58,0x5a,0x5c,0x5e,
	0x60,0x62,0x64,0x66,0x68,0x6a,0x6c,0x6e,0x70,0x72,0x74,0x76,0x78,0x7a,0x7c,0x7e,
	0x80,0x82,0x84,0x86,0x88,0x8a,0x8c,0x8e,0x90,0x92,0x94,0x96,0x98,0x9a,0x9c,0x9e,
	0xa0,0xa2,0xa4,0xa6,0xa8,0xaa,0xac,0xae,0xb0,0xb2,0xb4,0xb6,0xb8,0xba,0xbc,0xbe,
	0xc0,0xc2,0xc4,0xc6,0xc8,0xca,0xcc,0xce,0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xdc,0xde,
	0xe0,0xe2,0xe4,0xe6,0xe8,0xea,0xec,0xee,0xf0,0xf2,0xf4,0xf6,0xf8,0xfa,0xfc,0xfe,
	0x1b,0x19,0x1f,0x1d,0x13,0x11,0x17,0x15,0x0b,0x09,0x0f,0x0d,0x03,0x01,0x07,0x05,
	0x3b,0x39,0x3f,0x3d,0x33,0x31,0x37,0x35,0x2b,0x29,0x2f,0x2d,0x23,0x21,0x27,0x25,
	0x5b,0x59,0x5f,0x5d,0x53,0x51,0x57,0x55,0x4b,0x49,0x4f,0x4d,0x43,0x41,0x47,0x45,
	0x7b,0x79,0x7f,0x7d,0x73,0x71,0x77,0x75,0x6b,0x69,0x6f,0x6d,0x63,0x61,0x67,0x65,
	0x9b,0x99,0x9f,0x9d,0x93,0x91,0x97,0x95,0x8b,0x89,0x8f,0x8d,0x83,0x81,0x87,0x85,
	0xbb,0xb9,0xbf,0xbd,0xb3,0xb1,0xb7,0xb5,0xab,0xa9,0xaf,0xad,0xa3,0xa1,0xa7,0xa5,
	0xdb,0xd9,0xdf,0xdd,0xd3,0xd1,0xd7,0xd5,0xcb,0xc9,0xcf,0xcd,0xc3,0xc1,0xc7,0xc5,
	0xfb,0xf9,0xff,0xfd,0xf3,0xf1,0xf7,0xf5,0xeb,0xe9,0xef,0xed,0xe3,0xe1,0xe7,0xe5
}

local GF8x3 = {
[0]=0x00,0x03,0x06,0x05,0x0c,0x0f,0x0a,0x09,0x18,0x1b,0x1e,0x1d,0x14,0x17,0x12,0x11,
	0x30,0x33,0x36,0x35,0x3c,0x3f,0x3a,0x39,0x28,0x2b,0x2e,0x2d,0x24,0x27,0x22,0x21,
	0x60,0x63,0x66,0x65,0x6c,0x6f,0x6a,0x69,0x78,0x7b,0x7e,0x7d,0x74,0x77,0x72,0x71,
	0x50,0x53,0x56,0x55,0x5c,0x5f,0x5a,0x59,0x48,0x4b,0x4e,0x4d,0x44,0x47,0x42,0x41,
	0xc0,0xc3,0xc6,0xc5,0xcc,0xcf,0xca,0xc9,0xd8,0xdb,0xde,0xdd,0xd4,0xd7,0xd2,0xd1,
	0xf0,0xf3,0xf6,0xf5,0xfc,0xff,0xfa,0xf9,0xe8,0xeb,0xee,0xed,0xe4,0xe7,0xe2,0xe1,
	0xa0,0xa3,0xa6,0xa5,0xac,0xaf,0xaa,0xa9,0xb8,0xbb,0xbe,0xbd,0xb4,0xb7,0xb2,0xb1,
	0x90,0x93,0x96,0x95,0x9c,0x9f,0x9a,0x99,0x88,0x8b,0x8e,0x8d,0x84,0x87,0x82,0x81,
	0x9b,0x98,0x9d,0x9e,0x97,0x94,0x91,0x92,0x83,0x80,0x85,0x86,0x8f,0x8c,0x89,0x8a,
	0xab,0xa8,0xad,0xae,0xa7,0xa4,0xa1,0xa2,0xb3,0xb0,0xb5,0xb6,0xbf,0xbc,0xb9,0xba,
	0xfb,0xf8,0xfd,0xfe,0xf7,0xf4,0xf1,0xf2,0xe3,0xe0,0xe5,0xe6,0xef,0xec,0xe9,0xea,
	0xcb,0xc8,0xcd,0xce,0xc7,0xc4,0xc1,0xc2,0xd3,0xd0,0xd5,0xd6,0xdf,0xdc,0xd9,0xda,
	0x5b,0x58,0x5d,0x5e,0x57,0x54,0x51,0x52,0x43,0x40,0x45,0x46,0x4f,0x4c,0x49,0x4a,
	0x6b,0x68,0x6d,0x6e,0x67,0x64,0x61,0x62,0x73,0x70,0x75,0x76,0x7f,0x7c,0x79,0x7a,
	0x3b,0x38,0x3d,0x3e,0x37,0x34,0x31,0x32,0x23,0x20,0x25,0x26,0x2f,0x2c,0x29,0x2a,
	0x0b,0x08,0x0d,0x0e,0x07,0x04,0x01,0x02,0x13,0x10,0x15,0x16,0x1f,0x1c,0x19,0x1a
}

local GF8x9 = {
[0]=0x00,0x09,0x12,0x1b,0x24,0x2d,0x36,0x3f,0x48,0x41,0x5a,0x53,0x6c,0x65,0x7e,0x77,
	0x90,0x99,0x82,0x8b,0xb4,0xbd,0xa6,0xaf,0xd8,0xd1,0xca,0xc3,0xfc,0xf5,0xee,0xe7,
	0x3b,0x32,0x29,0x20,0x1f,0x16,0x0d,0x04,0x73,0x7a,0x61,0x68,0x57,0x5e,0x45,0x4c,
	0xab,0xa2,0xb9,0xb0,0x8f,0x86,0x9d,0x94,0xe3,0xea,0xf1,0xf8,0xc7,0xce,0xd5,0xdc,
	0x76,0x7f,0x64,0x6d,0x52,0x5b,0x40,0x49,0x3e,0x37,0x2c,0x25,0x1a,0x13,0x08,0x01,
	0xe6,0xef,0xf4,0xfd,0xc2,0xcb,0xd0,0xd9,0xae,0xa7,0xbc,0xb5,0x8a,0x83,0x98,0x91,
	0x4d,0x44,0x5f,0x56,0x69,0x60,0x7b,0x72,0x05,0x0c,0x17,0x1e,0x21,0x28,0x33,0x3a,
	0xdd,0xd4,0xcf,0xc6,0xf9,0xf0,0xeb,0xe2,0x95,0x9c,0x87,0x8e,0xb1,0xb8,0xa3,0xaa,
	0xec,0xe5,0xfe,0xf7,0xc8,0xc1,0xda,0xd3,0xa4,0xad,0xb6,0xbf,0x80,0x89,0x92,0x9b,
	0x7c,0x75,0x6e,0x67,0x58,0x51,0x4a,0x43,0x34,0x3d,0x26,0x2f,0x10,0x19,0x02,0x0b,
	0xd7,0xde,0xc5,0xcc,0xf3,0xfa,0xe1,0xe8,0x9f,0x96,0x8d,0x84,0xbb,0xb2,0xa9,0xa0,
	0x47,0x4e,0x55,0x5c,0x63,0x6a,0x71,0x78,0x0f,0x06,0x1d,0x14,0x2b,0x22,0x39,0x30,
	0x9a,0x93,0x88,0x81,0xbe,0xb7,0xac,0xa5,0xd2,0xdb,0xc0,0xc9,0xf6,0xff,0xe4,0xed,
	0x0a,0x03,0x18,0x11,0x2e,0x27,0x3c,0x35,0x42,0x4b,0x50,0x59,0x66,0x6f,0x74,0x7d,
	0xa1,0xa8,0xb3,0xba,0x85,0x8c,0x97,0x9e,0xe9,0xe0,0xfb,0xf2,0xcd,0xc4,0xdf,0xd6,
	0x31,0x38,0x23,0x2a,0x15,0x1c,0x07,0x0e,0x79,0x70,0x6b,0x62,0x5d,0x54,0x4f,0x46
}

local GF8x11 = {
[0]=0x00,0x0b,0x16,0x1d,0x2c,0x27,0x3a,0x31,0x58,0x53,0x4e,0x45,0x74,0x7f,0x62,0x69,
	0xb0,0xbb,0xa6,0xad,0x9c,0x97,0x8a,0x81,0xe8,0xe3,0xfe,0xf5,0xc4,0xcf,0xd2,0xd9,
	0x7b,0x70,0x6d,0x66,0x57,0x5c,0x41,0x4a,0x23,0x28,0x35,0x3e,0x0f,0x04,0x19,0x12,
	0xcb,0xc0,0xdd,0xd6,0xe7,0xec,0xf1,0xfa,0x93,0x98,0x85,0x8e,0xbf,0xb4,0xa9,0xa2,
	0xf6,0xfd,0xe0,0xeb,0xda,0xd1,0xcc,0xc7,0xae,0xa5,0xb8,0xb3,0x82,0x89,0x94,0x9f,
	0x46,0x4d,0x50,0x5b,0x6a,0x61,0x7c,0x77,0x1e,0x15,0x08,0x03,0x32,0x39,0x24,0x2f,
	0x8d,0x86,0x9b,0x90,0xa1,0xaa,0xb7,0xbc,0xd5,0xde,0xc3,0xc8,0xf9,0xf2,0xef,0xe4,
	0x3d,0x36,0x2b,0x20,0x11,0x1a,0x07,0x0c,0x65,0x6e,0x73,0x78,0x49,0x42,0x5f,0x54,
	0xf7,0xfc,0xe1,0xea,0xdb,0xd0,0xcd,0xc6,0xaf,0xa4,0xb9,0xb2,0x83,0x88,0x95,0x9e,
	0x47,0x4c,0x51,0x5a,0x6b,0x60,0x7d,0x76,0x1f,0x14,0x09,0x02,0x33,0x38,0x25,0x2e,
	0x8c,0x87,0x9a,0x91,0xa0,0xab,0xb6,0xbd,0xd4,0xdf,0xc2,0xc9,0xf8,0xf3,0xee,0xe5,
	0x3c,0x37,0x2a,0x21,0x10,0x1b,0x06,0x0d,0x64,0x6f,0x72,0x79,0x48,0x43,0x5e,0x55,
	0x01,0x0a,0x17,0x1c,0x2d,0x26,0x3b,0x30,0x59,0x52,0x4f,0x44,0x75,0x7e,0x63,0x68,
	0xb1,0xba,0xa7,0xac,0x9d,0x96,0x8b,0x80,0xe9,0xe2,0xff,0xf4,0xc5,0xce,0xd3,0xd8,
	0x7a,0x71,0x6c,0x67,0x56,0x5d,0x40,0x4b,0x22,0x29,0x34,0x3f,0x0e,0x05,0x18,0x13,
	0xca,0xc1,0xdc,0xd7,0xe6,0xed,0xf0,0xfb,0x92,0x99,0x84,0x8f,0xbe,0xb5,0xa8,0xa3
}

local GF8x13 = {
[0]=0x00,0x0d,0x1a,0x17,0x34,0x39,0x2e,0x23,0x68,0x65,0x72,0x7f,0x5c,0x51,0x46,0x4b,
	0xd0,0xdd,0xca,0xc7,0xe4,0xe9,0xfe,0xf3,0xb8,0xb5,0xa2,0xaf,0x8c,0x81,0x96,0x9b,
	0xbb,0xb6,0xa1,0xac,0x8f,0x82,0x95,0x98,0xd3,0xde,0xc9,0xc4,0xe7,0xea,0xfd,0xf0,
	0x6b,0x66,0x71,0x7c,0x5f,0x52,0x45,0x48,0x03,0x0e,0x19,0x14,0x37,0x3a,0x2d,0x20,
	0x6d,0x60,0x77,0x7a,0x59,0x54,0x43,0x4e,0x05,0x08,0x1f,0x12,0x31,0x3c,0x2b,0x26,
	0xbd,0xb0,0xa7,0xaa,0x89,0x84,0x93,0x9e,0xd5,0xd8,0xcf,0xc2,0xe1,0xec,0xfb,0xf6,
	0xd6,0xdb,0xcc,0xc1,0xe2,0xef,0xf8,0xf5,0xbe,0xb3,0xa4,0xa9,0x8a,0x87,0x90,0x9d,
	0x06,0x0b,0x1c,0x11,0x32,0x3f,0x28,0x25,0x6e,0x63,0x74,0x79,0x5a,0x57,0x40,0x4d,
	0xda,0xd7,0xc0,0xcd,0xee,0xe3,0xf4,0xf9,0xb2,0xbf,0xa8,0xa5,0x86,0x8b,0x9c,0x91,
	0x0a,0x07,0x10,0x1d,0x3e,0x33,0x24,0x29,0x62,0x6f,0x78,0x75,0x56,0x5b,0x4c,0x41,
	0x61,0x6c,0x7b,0x76,0x55,0x58,0x4f,0x42,0x09,0x04,0x13,0x1e,0x3d,0x30,0x27,0x2a,
	0xb1,0xbc,0xab,0xa6,0x85,0x88,0x9f,0x92,0xd9,0xd4,0xc3,0xce,0xed,0xe0,0xf7,0xfa,
	0xb7,0xba,0xad,0xa0,0x83,0x8e,0x99,0x94,0xdf,0xd2,0xc5,0xc8,0xeb,0xe6,0xf1,0xfc,
	0x67,0x6a,0x7d,0x70,0x53,0x5e,0x49,0x44,0x0f,0x02,0x15,0x18,0x3b,0x36,0x21,0x2c,
	0x0c,0x01,0x16,0x1b,0x38,0x35,0x22,0x2f,0x64,0x69,0x7e,0x73,0x50,0x5d,0x4a,0x47,
	0xdc,0xd1,0xc6,0xcb,0xe8,0xe5,0xf2,0xff,0xb4,0xb9,0xae,0xa3,0x80,0x8d,0x9a,0x97
}

local GF8x14 = {
[0]=0x00,0x0e,0x1c,0x12,0x38,0x36,0x24,0x2a,0x70,0x7e,0x6c,0x62,0x48,0x46,0x54,0x5a,
	0xe0,0xee,0xfc,0xf2,0xd8,0xd6,0xc4,0xca,0x90,0x9e,0x8c,0x82,0xa8,0xa6,0xb4,0xba,
	0xdb,0xd5,0xc7,0xc9,0xe3,0xed,0xff,0xf1,0xab,0xa5,0xb7,0xb9,0x93,0x9d,0x8f,0x81,
	0x3b,0x35,0x27,0x29,0x03,0x0d,0x1f,0x11,0x4b,0x45,0x57,0x59,0x73,0x7d,0x6f,0x61,
	0xad,0xa3,0xb1,0xbf,0x95,0x9b,0x89,0x87,0xdd,0xd3,0xc1,0xcf,0xe5,0xeb,0xf9,0xf7,
	0x4d,0x43,0x51,0x5f,0x75,0x7b,0x69,0x67,0x3d,0x33,0x21,0x2f,0x05,0x0b,0x19,0x17,
	0x76,0x78,0x6a,0x64,0x4e,0x40,0x52,0x5c,0x06,0x08,0x1a,0x14,0x3e,0x30,0x22,0x2c,
	0x96,0x98,0x8a,0x84,0xae,0xa0,0xb2,0xbc,0xe6,0xe8,0xfa,0xf4,0xde,0xd0,0xc2,0xcc,
	0x41,0x4f,0x5d,0x53,0x79,0x77,0x65,0x6b,0x31,0x3f,0x2d,0x23,0x09,0x07,0x15,0x1b,
	0xa1,0xaf,0xbd,0xb3,0x99,0x97,0x85,0x8b,0xd1,0xdf,0xcd,0xc3,0xe9,0xe7,0xf5,0xfb,
	0x9a,0x94,0x86,0x88,0xa2,0xac,0xbe,0xb0,0xea,0xe4,0xf6,0xf8,0xd2,0xdc,0xce,0xc0,
	0x7a,0x74,0x66,0x68,0x42,0x4c,0x5e,0x50,0x0a,0x04,0x16,0x18,0x32,0x3c,0x2e,0x20,
	0xec,0xe2,0xf0,0xfe,0xd4,0xda,0xc8,0xc6,0x9c,0x92,0x80,0x8e,0xa4,0xaa,0xb8,0xb6,
	0x0c,0x02,0x10,0x1e,0x34,0x3a,0x28,0x26,0x7c,0x72,0x60,0x6e,0x44,0x4a,0x58,0x56,
	0x37,0x39,0x2b,0x25,0x0f,0x01,0x13,0x1d,0x47,0x49,0x5b,0x55,0x7f,0x71,0x63,0x6d,
	0xd7,0xd9,0xcb,0xc5,0xef,0xe1,0xf3,0xfd,0xa7,0xa9,0xbb,0xb5,0x9f,0x91,0x83,0x8d
}

local s = {
[0]=0x63,0x7C,0x77,0x7B,0xF2,0x6B,0x6F,0xC5,0x30,0x01,0x67,0x2B,0xFE,0xD7,0xAB,0x76,
	0xCA,0x82,0xC9,0x7D,0xFA,0x59,0x47,0xF0,0xAD,0xD4,0xA2,0xAF,0x9C,0xA4,0x72,0xC0,
	0xB7,0xFD,0x93,0x26,0x36,0x3F,0xF7,0xCC,0x34,0xA5,0xE5,0xF1,0x71,0xD8,0x31,0x15,
	0x04,0xC7,0x23,0xC3,0x18,0x96,0x05,0x9A,0x07,0x12,0x80,0xE2,0xEB,0x27,0xB2,0x75,
	0x09,0x83,0x2C,0x1A,0x1B,0x6E,0x5A,0xA0,0x52,0x3B,0xD6,0xB3,0x29,0xE3,0x2F,0x84,
	0x53,0xD1,0x00,0xED,0x20,0xFC,0xB1,0x5B,0x6A,0xCB,0xBE,0x39,0x4A,0x4C,0x58,0xCF,
	0xD0,0xEF,0xAA,0xFB,0x43,0x4D,0x33,0x85,0x45,0xF9,0x02,0x7F,0x50,0x3C,0x9F,0xA8,
	0x51,0xA3,0x40,0x8F,0x92,0x9D,0x38,0xF5,0xBC,0xB6,0xDA,0x21,0x10,0xFF,0xF3,0xD2,
	0xCD,0x0C,0x13,0xEC,0x5F,0x97,0x44,0x17,0xC4,0xA7,0x7E,0x3D,0x64,0x5D,0x19,0x73,
	0x60,0x81,0x4F,0xDC,0x22,0x2A,0x90,0x88,0x46,0xEE,0xB8,0x14,0xDE,0x5E,0x0B,0xDB,
	0xE0,0x32,0x3A,0x0A,0x49,0x06,0x24,0x5C,0xC2,0xD3,0xAC,0x62,0x91,0x95,0xE4,0x79,
	0xE7,0xC8,0x37,0x6D,0x8D,0xD5,0x4E,0xA9,0x6C,0x56,0xF4,0xEA,0x65,0x7A,0xAE,0x08,
	0xBA,0x78,0x25,0x2E,0x1C,0xA6,0xB4,0xC6,0xE8,0xDD,0x74,0x1F,0x4B,0xBD,0x8B,0x8A,
	0x70,0x3E,0xB5,0x66,0x48,0x03,0xF6,0x0E,0x61,0x35,0x57,0xB9,0x86,0xC1,0x1D,0x9E,
	0xE1,0xF8,0x98,0x11,0x69,0xD9,0x8E,0x94,0x9B,0x1E,0x87,0xE9,0xCE,0x55,0x28,0xDF,
	0x8C,0xA1,0x89,0x0D,0xBF,0xE6,0x42,0x68,0x41,0x99,0x2D,0x0F,0xB0,0x54,0xBB,0x16
}

local si = {
[0]=0x52,0x09,0x6A,0xD5,0x30,0x36,0xA5,0x38,0xBF,0x40,0xA3,0x9E,0x81,0xF3,0xD7,0xFB,
	0x7C,0xE3,0x39,0x82,0x9B,0x2F,0xFF,0x87,0x34,0x8E,0x43,0x44,0xC4,0xDE,0xE9,0xCB,
	0x54,0x7B,0x94,0x32,0xA6,0xC2,0x23,0x3D,0xEE,0x4C,0x95,0x0B,0x42,0xFA,0xC3,0x4E,
	0x08,0x2E,0xA1,0x66,0x28,0xD9,0x24,0xB2,0x76,0x5B,0xA2,0x49,0x6D,0x8B,0xD1,0x25,
	0x72,0xF8,0xF6,0x64,0x86,0x68,0x98,0x16,0xD4,0xA4,0x5C,0xCC,0x5D,0x65,0xB6,0x92,
	0x6C,0x70,0x48,0x50,0xFD,0xED,0xB9,0xDA,0x5E,0x15,0x46,0x57,0xA7,0x8D,0x9D,0x84,
	0x90,0xD8,0xAB,0x00,0x8C,0xBC,0xD3,0x0A,0xF7,0xE4,0x58,0x05,0xB8,0xB3,0x45,0x06,
	0xD0,0x2C,0x1E,0x8F,0xCA,0x3F,0x0F,0x02,0xC1,0xAF,0xBD,0x03,0x01,0x13,0x8A,0x6B,
	0x3A,0x91,0x11,0x41,0x4F,0x67,0xDC,0xEA,0x97,0xF2,0xCF,0xCE,0xF0,0xB4,0xE6,0x73,
	0x96,0xAC,0x74,0x22,0xE7,0xAD,0x35,0x85,0xE2,0xF9,0x37,0xE8,0x1C,0x75,0xDF,0x6E,
	0x47,0xF1,0x1A,0x71,0x1D,0x29,0xC5,0x89,0x6F,0xB7,0x62,0x0E,0xAA,0x18,0xBE,0x1B,
	0xFC,0x56,0x3E,0x4B,0xC6,0xD2,0x79,0x20,0x9A,0xDB,0xC0,0xFE,0x78,0xCD,0x5A,0xF4,
	0x1F,0xDD,0xA8,0x33,0x88,0x07,0xC7,0x31,0xB1,0x12,0x10,0x59,0x27,0x80,0xEC,0x5F,
	0x60,0x51,0x7F,0xA9,0x19,0xB5,0x4A,0x0D,0x2D,0xE5,0x7A,0x9F,0x93,0xC9,0x9C,0xEF,
	0xA0,0xE0,0x3B,0x4D,0xAE,0x2A,0xF5,0xB0,0xC8,0xEB,0xBB,0x3C,0x83,0x53,0x99,0x61,
	0x17,0x2B,0x04,0x7E,0xBA,0x77,0xD6,0x26,0xE1,0x69,0x14,0x63,0x55,0x21,0x0C,0x7D
}

local rcon = {
	0x8d,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36,0x6c,0xd8,0xab,0x4d,0x9a,
	0x2f,0x5e,0xbc,0x63,0xc6,0x97,0x35,0x6a,0xd4,0xb3,0x7d,0xfa,0xef,0xc5,0x91,0x39,
	0x72,0xe4,0xd3,0xbd,0x61,0xc2,0x9f,0x25,0x4a,0x94,0x33,0x66,0xcc,0x83,0x1d,0x3a,
	0x74,0xe8,0xcb,0x8d,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36,0x6c,0xd8,
	0xab,0x4d,0x9a,0x2f,0x5e,0xbc,0x63,0xc6,0x97,0x35,0x6a,0xd4,0xb3,0x7d,0xfa,0xef,
	0xc5,0x91,0x39,0x72,0xe4,0xd3,0xbd,0x61,0xc2,0x9f,0x25,0x4a,0x94,0x33,0x66,0xcc,
	0x83,0x1d,0x3a,0x74,0xe8,0xcb,0x8d,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,
	0x36,0x6c,0xd8,0xab,0x4d,0x9a,0x2f,0x5e,0xbc,0x63,0xc6,0x97,0x35,0x6a,0xd4,0xb3,
	0x7d,0xfa,0xef,0xc5,0x91,0x39,0x72,0xe4,0xd3,0xbd,0x61,0xc2,0x9f,0x25,0x4a,0x94,
	0x33,0x66,0xcc,0x83,0x1d,0x3a,0x74,0xe8,0xcb,0x8d,0x01,0x02,0x04,0x08,0x10,0x20,
	0x40,0x80,0x1b,0x36,0x6c,0xd8,0xab,0x4d,0x9a,0x2f,0x5e,0xbc,0x63,0xc6,0x97,0x35,
	0x6a,0xd4,0xb3,0x7d,0xfa,0xef,0xc5,0x91,0x39,0x72,0xe4,0xd3,0xbd,0x61,0xc2,0x9f,
	0x25,0x4a,0x94,0x33,0x66,0xcc,0x83,0x1d,0x3a,0x74,0xe8,0xcb,0x8d,0x01,0x02,0x04,
	0x08,0x10,0x20,0x40,0x80,0x1b,0x36,0x6c,0xd8,0xab,0x4d,0x9a,0x2f,0x5e,0xbc,0x63,
	0xc6,0x97,0x35,0x6a,0xd4,0xb3,0x7d,0xfa,0xef,0xc5,0x91,0x39,0x72,0xe4,0xd3,0xbd,
	0x61,0xc2,0x9f,0x25,0x4a,0x94,0x33,0x66,0xcc,0x83,0x1d,0x3a,0x74,0xe8,0xcb,0x8d
}

local xor4 = {
[0]=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
	1,0,3,2,5,4,7,6,9,8,11,10,13,12,15,14,
	2,3,0,1,6,7,4,5,10,11,8,9,14,15,12,13,
	3,2,1,0,7,6,5,4,11,10,9,8,15,14,13,12,
	4,5,6,7,0,1,2,3,12,13,14,15,8,9,10,11,
	5,4,7,6,1,0,3,2,13,12,15,14,9,8,11,10,
	6,7,4,5,2,3,0,1,14,15,12,13,10,11,8,9,
	7,6,5,4,3,2,1,0,15,14,13,12,11,10,9,8,
	8,9,10,11,12,13,14,15,0,1,2,3,4,5,6,7,
	9,8,11,10,13,12,15,14,1,0,3,2,5,4,7,6,
	10,11,8,9,14,15,12,13,2,3,0,1,6,7,4,5,
	11,10,9,8,15,14,13,12,3,2,1,0,7,6,5,4,
	12,13,14,15,8,9,10,11,4,5,6,7,0,1,2,3,
	13,12,15,14,9,8,11,10,5,4,7,6,1,0,3,2,
	14,15,12,13,10,11,8,9,6,7,4,5,2,3,0,1,
	15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,
}

local function xor8(a, b)
	local al = a % 16
	local bl = b % 16
	return 16 * xor4[a - al + (b - bl) / 16] + xor4[16 * al + bl]
end

local function addRoundKey(state, key)
	for i, byte in next, state do
		state[i] = xor8(byte, key[i])
	end
end

local function subBytes(state, s_box)
	for i, byte in next, state do
		state[i] = s_box[byte]
	end
end

local function shiftRows(state)
	state[5], state[6], state[7], state[8] =
	state[6], state[7], state[8], state[5]

	state[9], state[10], state[11], state[12] =
	state[11], state[12], state[9], state[10]

	state[13], state[14], state[15], state[16] =
	state[16], state[13], state[14], state[15]
end

local function inv_shiftRows(state)
	state[6], state[7], state[8], state[5] =
	state[5], state[6], state[7], state[8]

	state[11], state[12], state[9], state[10] =
	state[9], state[10], state[11], state[12]

	state[16], state[13], state[14], state[15] =
	state[13], state[14], state[15], state[16]
end

local function mixColumns(state)
	for cur = 1, 4 do
		local a, b, c, d = state[cur], state[cur + 4], state[cur + 8], state[cur + 12]
		state[cur +  0] = xor8(xor8(xor8(GF8x2[a], GF8x3[b]), c), d)
		state[cur +  4] = xor8(xor8(xor8(a, GF8x2[b]), GF8x3[c]), d)
		state[cur +  8] = xor8(xor8(xor8(a, b), GF8x2[c]), GF8x3[d])
		state[cur + 12] = xor8(xor8(xor8(GF8x3[a], b), c), GF8x2[d])
	end
end

local function inv_mixColumns(state)
	for cur = 1, 4 do
		local a, b, c, d = state[cur], state[cur + 4], state[cur + 8], state[cur + 12]
		state[cur +  0] = xor8(xor8(xor8(GF8x14[a], GF8x11[b]), GF8x13[c]), GF8x9[d])
		state[cur +  4] = xor8(xor8(xor8(GF8x9[a], GF8x14[b]), GF8x11[c]), GF8x13[d])
		state[cur +  8] = xor8(xor8(xor8(GF8x13[a], GF8x9[b]), GF8x14[c]), GF8x11[d])
		state[cur + 12] = xor8(xor8(xor8(GF8x11[a], GF8x13[b]), GF8x9[c]), GF8x14[d])
	end
end

-- 256-bit key constants
local n = 32 -- number of bytes in the 256-bit encryption key
local b = 240 -- number of bytes in 15 128-bit round keys
local function schedule256(key)
	local expanded = {}
	for c = 0, n do
		local byte = key % 256
		expanded[c] = byte
		key = (key - byte) / 256
	end

	local i = 1
	local c = n
	local t1 = expanded[1]
	local t2 = expanded[2]
	local t3 = expanded[3]
	local t4 = expanded[4]
	while c < b do
		t1, t2, t3, t4 = xor8(rcon[i], s[t2]), s[t3], s[t4], s[t1]
		i = i + 1

		for _ = 1, 4 do
			c = c + 1
			t1 = xor8(t1, expanded[c - n])
			expanded[c] = t1

			c = c + 1
			t2 = xor8(t2, expanded[c - n])
			expanded[c] = t2

			c = c + 1
			t3 = xor8(t3, expanded[c - n])
			expanded[c] = t3

			c = c + 1
			t4 = xor8(t4, expanded[c - n])
			expanded[c] = t4
		end

		t1 = s[t1]
		t2 = s[t2]
		t3 = s[t3]
		t4 = s[t4]

		for _ = 1, 4 do
			c = c + 1
			t1 = xor8(t1, expanded[c - n])
			expanded[c] = t1

			c = c + 1
			t2 = xor8(t2, expanded[c - n])
			expanded[c] = t2

			c = c + 1
			t3 = xor8(t3, expanded[c - n])
			expanded[c] = t3

			c = c + 1
			t4 = xor8(t4, expanded[c - n])
			expanded[c] = t4
		end
	end

	local roundKeys = {}
	for round = 0, 14 do
		local roundKey = {}
		for byte = 1, 16 do
			roundKey[byte] = expanded[round * 16 + byte]
		end
		roundKeys[round] = roundKey
	end
	return roundKeys
end

local function chunks(text, i)
	local first = i * 16 + 1
	if first > #text then
		return
	end
	i = i + 1

	local chunk = {text:byte(first, first + 15)}
	for j = #chunk + 1, 16 do
		chunk[j] = 0
	end

	return i, chunk
end

local function encrypt(state, roundKeys)
	addRoundKey(state, roundKeys[0])
	for round = 1, 13 do
		subBytes(state, s)
		shiftRows(state)
		mixColumns(state)
		addRoundKey(state, roundKeys[round])
	end
	subBytes(state, s)
	shiftRows(state)
	addRoundKey(state, roundKeys[14])
end

local function decrypt(state, roundKeys)
	addRoundKey(state, roundKeys[14])
	inv_shiftRows(state)
	subBytes(state, si)
	for round = 13, 1, -1 do
		addRoundKey(state, roundKeys[round])
		inv_mixColumns(state)
		inv_shiftRows(state)
		subBytes(state, si)
	end
	addRoundKey(state, roundKeys[0])
end

local function ECB_256(method, key, originaltext)
	local text = {}
	local roundKeys = schedule256(key)
	for chunk, state in chunks, originaltext, 0 do
		method(state, roundKeys)
		text[chunk] = string.char(unpack(state))
	end
	return table.concat(text)
end

--return {
--	encrypt = encrypt;
--	decrypt = decrypt;
--	ECB_256 = ECB_256;
--}

local key = 0x68C756C6C186436C9EC51C174C32AE81761389B5E5904E30BA57CCD911290ECC
local plaintext = 'mysecretmysecretmysecret'
--local cyphertext = ECB_256(encrypt, key, plaintext)
global.cyphertext = ECB_256(encrypt, key, plaintext)
--local newtext = ECB_256(decrypt, key, cyphertext)
global.newtext = ECB_256(decrypt, key, global.cyphertext)

--game.print(plaintext)
--game.print(#cyphertext, cyphertext)
--game.print(#newtext, newtext)
]]--
return Public
