local Public = {}
local Server = require 'utils.server'

local bb_config = require "maps.biter_battles_v2.config"
local bb_diff = require "maps.biter_battles_v2.difficulty_vote"
local event = require 'utils.event'
local Functions = require "maps.biter_battles_v2.functions"
local feed_the_biters = require "maps.biter_battles_v2.feeding"
local Tables = require "maps.biter_battles_v2.tables"
local show_inventory = require 'modules.show_inventory_bbc'
local Where = require 'commands.where'
local Team_manager = require "maps.biter_battles_v2.team_manager" --EVL needed to redraw team managers when spec<->god
local wait_messages = Tables.wait_messages
local food_names = Tables.gui_foods

local math_random = math.random

require "maps.biter_battles_v2.spec_spy"

local gui_values = {
		["north"] = {force = "north", biter_force = "north_biters", c1 = bb_config.north_side_team_name, c2 = "JOIN ", n1 = "join_north_button",
		t1 = "Evolution of north side biters.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.55, g = 0.55, b = 0.99}, color2 = {r = 0.66, g = 0.66, b = 0.99},
		tech_spy = "spy-north-tech", prod_spy = "spy-north-prod"},
		["south"] = {force = "south", biter_force = "south_biters", c1 = bb_config.south_side_team_name, c2 = "JOIN ", n1 = "join_south_button",
		t1 = "Evolution of south side biters.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.99, g = 0.33, b = 0.33}, color2 = {r = 0.99, g = 0.44, b = 0.44},
		tech_spy = "spy-south-tech", prod_spy = "spy-south-prod"}
	}
	
local function create_sprite_button(player)
	if player.gui.top["bb_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "bb_toggle_button", sprite = "entity/big-biter"})
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.padding = -1
end

--[[ local function create_first_join_gui(player) -- EVL BBchampions always in tournament mode
	if not global.game_lobby_timeout then global.game_lobby_timeout = 5999940 end
	if global.game_lobby_timeout - game.tick < 0 then global.game_lobby_active = false end
	local frame = player.gui.left.add { type = "frame", name = "bb_main_gui", direction = "vertical" }
	local b = frame.add{ type = "label", caption = "Defend your Rocket Silo!" }
	b.style.font = "heading-1"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}
	local b = frame.add  { type = "label", caption = "Feed the enemy team's biters to gain advantage!" }
	b.style.font = "heading-2"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}

	frame.add  { type = "label", caption = "-----------------------------------------------------------"}

	for _, gui_value in pairs(gui_values) do
		local t = frame.add { type = "table", column_count = 3 }
		local c = gui_value.c1
		if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "heading-2"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		l.style.maximal_width = 290
		local l = t.add  { type = "label", caption = "  -  "}
		local l = t.add  { type = "label", caption = Functions.get_nb_players(gui_value.force).." Players "}
		l.style.font_color = { r=0.22, g=0.88, b=0.22}

		local c = gui_value.c2
		local font_color =  gui_value.color1
		if global.game_lobby_active then
			font_color = {r=0.7, g=0.7, b=0.7}
			c = c .. " (waiting for players...  "
			c = c .. math.ceil((global.game_lobby_timeout - game.tick)/60)
			c = c .. ")"
		end
		local t = frame.add  { type = "table", column_count = 4 }
		for _, p in pairs(game.forces[gui_value.force].connected_players) do
			local l = t.add({type = "label", caption = p.name})
			l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
			l.style.font = "heading-2"
		end
		local b = frame.add  { type = "sprite-button", name = gui_value.n1, caption = c }
		b.style.font = "default-large-bold"
		b.style.font_color = font_color
		b.style.minimal_width = 350
		frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	end
end
--]]

local function add_tech_button(elem, gui_value)
	local tech_button = elem.add {
		type = "sprite-button",
		name = gui_value.tech_spy,
		sprite = "item/space-science-pack"
	}
	tech_button.style.height = 25
	tech_button.style.width = 25
	tech_button.style.left_margin = 3
end

--[[ EVL local function add_prod_button(elem, gui_value) Not used for now

	local prod_button = elem.add {
		type = "sprite-button",
		name = gui_value.prod_spy,
		sprite = "item/assembling-machine-3"
	}
	prod_button.style.height = 25
	prod_button.style.width = 25
end
]]--

function Public.create_main_gui(player)
	local is_spec = (player.force.name == "spectator") or (player.force.name == "spec_god") --EVL we have 2 kinds of specs (see spectator_zoom.lua)
	-- EVL Little test 
	if  (player.force.name == "spec_god") and not (global.god_players[player.name]) then 
		if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") has incompatibility between his force and global.god_players") end
	end
	if player.gui.left["bb_main_gui"] then player.gui.left["bb_main_gui"].destroy() end

	if global.bb_game_won_by_team then return end
	
	--[[ EVL BBChampions always in tournament mode
	if not global.chosen_team[player.name] then 
		if not global.tournament_mode then
			create_first_join_gui(player)
			return
		end
	end
	]]--
	local frame = player.gui.left.add { type = "frame", name = "bb_main_gui", direction = "vertical" }
	
	--EVL Add a timer (with pause when frozen)
	local ttime = frame.add { type = "table", name = "biter_battle_time", column_count = 3 }

	local tttime = ttime.add {	type = "sprite", name = "tttime-editor", sprite = "quantity-time"}
	local time_played = game.ticks_played - global.freezed_time
	local htime_gui = "Game has not started "
	local htime_tooltip = "Game will enter in ARMAGEDDON mode after ".. math.floor(global.evo_boost_tick/3600) .." minutes !"
	if global.freezed_start == 999999999 then -- we are unfreezed
		if global.match_running then 
			 htime_gui = Functions.get_human_time(time_played).." "
		--else
		-- Match is not running -> 	 htime_gui = "Game has not started "
		end
	else --EVL we are freezed since tick=global.freezed_start
		time_paused = game.ticks_played - global.freezed_start
		local real_time_played = time_played - time_paused
		if global.match_running then 
			htime_gui = Functions.get_human_time(real_time_played) .. "   (pause ".. math.floor(time_paused/60) .."s) "
		--else
		-- Match is not running -> 	 htime_gui = "Game has not started "
		end
	end
	if global.bb_debug then htime_tooltip =  htime_tooltip .. "\n debug : global.freezed_time=" .. math.floor(global.freezed_time/60) .. "\n debug : global.freezed_start=" .. math.floor(global.freezed_start/60) end
	local tttime = ttime.add({type = "label", caption = htime_gui, tooltip = htime_tooltip } )
	tttime.style.font = "default-large-bold"
	tttime.style.font_color = {r = 192, g = 192, b = 255}
	local tttimee = ttime.add {type = "sprite", name = "tttimee-editor", sprite = "quantity-time"}

	--EVL line separator
	frame.add { type = "line", caption = "this line", direction = "horizontal" }
	--EVL FIN
	
	-- Science sending GUI
	if not is_spec then
		frame.add { type = "table", name = "biter_battle_table", column_count = 4 }
		local t = frame.biter_battle_table
		for food_name, tooltip in pairs(food_names) do
			local s = t.add { type = "sprite-button", name = food_name, sprite = "item/" .. food_name }
			s.tooltip = tooltip
			s.style.minimal_height = 41
			s.style.minimal_width = 41
			s.style.top_padding = 0
			s.style.left_padding = 0
			s.style.right_padding = 0
			s.style.bottom_padding = 0
		end
	end

	local first_team = true
	for _, gui_value in pairs(gui_values) do
		-- Line separator
		if not first_team then
			frame.add { type = "line", caption = "this line", direction = "horizontal" }
		else
			first_team = false
		end

		-- Team name & Player count
		local t = frame.add { type = "table", name="team_info_" .. gui_value.force, column_count = 5 }

		-- Team name
		local c = gui_value.c1
		local maxim_team="[font=default-small][color=#777777](missing maxim)[/color][/font]"
		if global.tm_custom_name[gui_value.force] then 
			c = global.tm_custom_name[gui_value.force] 
			if Tables.maxim_teams[c] and Tables.maxim_teams[c]~="" and Tables.maxim_teams[c]~="tbd" then
				maxim_team="[color=#AAAAAA]"..Tables.maxim_teams[c].."[/color]"
			end
		end
		local _tooltip=maxim_team.."\n[font=default-small][color=#77CC77]   Click to view info & craftings.[/color]\n[color=#CC7777]   Click again to close.\n   Click on <<¡>> to show inventories[/color][/font]"
		local l = t.add  { type = "label", name = "open_close_inv_"..gui_value.force, caption = c, tooltip=_tooltip}
		l.style.font = "default-bold"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		l.style.maximal_width = 102
		
		if global.viewing_inventories[player.name] and global.viewing_inventories[player.name][gui_value.force] and global.viewing_inventories[player.name][gui_value.force]["active"] then
			local inventory_mode="[color=#88EE88]¡[/color]"
			local inventory_tooltip="[color=#88EE88]Show inventories in team screen infos.[/color]"
			if global.viewing_inventories[player.name][gui_value.force]["inventory"] then 
				inventory_mode="[color=#CC7777]![/color]"
				inventory_tooltip="[color=#CC7777]Hide inventories in team screen infos.[/color]"
			end
			local toggle_inventory = t.add({type = "sprite-button", name = "team_inventory_toggle_"..gui_value.force, caption=inventory_mode, tooltip=inventory_tooltip})
			toggle_inventory.style.font = "heading-2"
			toggle_inventory.style.height = 18
			--toggle_inventory.style.vertical_align="center"
			toggle_inventory.style.width = 18
			toggle_inventory.style.padding = -6
		else
			--local toggle_inventory  = t.add{type = "label", name = "team_inventory_toggle_"..gui_value.force, caption = ""}
			local toggle_inventory = t.add({type = "sprite-button", name = "team_inventory_toggle_"..gui_value.force, caption="", tooltip=""})
			toggle_inventory.style.font = "heading-2"
			toggle_inventory.style.height = 1
			--toggle_inventory.style.vertical_align="center"
			toggle_inventory.style.width = 1
			toggle_inventory.style.padding = -6
		end



		-- Number of players
		local l = t.add  { type = "label", caption = " - "}
		local nb_players_force=Functions.get_nb_players(gui_value.force)
		local c = nb_players_force.." Player"
		if nb_players_force ~= 1 then c = c .. "s" end
		if nb_players_force == 0 then c = "No player" end --EVL 
		
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default"
		l.style.font_color = { r=0.22, g=0.88, b=0.22}
		
		-- Tech button EVL only if game has started and player is spec and player is admin (so no tech button for spy/coach/sub)
		if global.match_running and is_spec and player.admin then --Avoid Bug (switch player looking add science tree will give him all techs like mining productivity and all recipes)
			add_tech_button(t, gui_value)
			-- add_prod_button(t, gui_value)
		end

		-- Player list EVL Removed <<player list>> button, we always show the player list in BBchampions
		if true then
			local t = frame.add  { type = "table", column_count = 8 }
			for _, p in pairs(game.forces[gui_value.force].connected_players) do
				--game.print("index:"..p.index.."  name:"..p.name) --EVL DEBUG
				if (global.viewing_technology_gui_players[p.name])
					--Skip player (not really in the team, just viewing technology tree gui)
				or (global.managers_in_team and global.manager_table[gui_value.force] and p.name==global.manager_table[gui_value.force])
					--Skip player (not really in the team, just manager)
				then --EVL in this mode manager are set to team
					--Do nothing
				else
					local maxim_player="[font=default-small][color=#777777](missing maxim)[/color][/font]"
					if Tables.maxim_players[p.name] and Tables.maxim_players[p.name]~="" and Tables.maxim_players[p.name]~="tbd" then
						maxim_player="[color=#AAAAAA]"..Tables.maxim_players[p.name].."[/color]"
					end
					local _tooltip=maxim_player.."\n[font=default-small][color=#77CC77]Click to view inventory and crafts.[/color][/font]"
					local l_player = t.add  { type = "label", name="plist_"..p.index ,caption = p.name, tooltip=maxim_player} --EVL Add .index for inventory purpose
					l_player.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
					--local l_camera  = t.add  { type = "sprite", name="pcam_"..p.index ,sprite = "quantity-time", tooltip="click to view player's camera"} --slot-armor-white | select-icon-white | reassign | not-played-yet | expand
					local l_camera = t.add  { type = "label", name="pcam_"..p.index ,caption = "© ", tooltip="click to view player's camera"} --EVL Add .index for camera purpose
					l_camera.style.font_color = {r = 150, g = 150, b = 150}
				end
			end
		end

		-- Statistics
		local t = frame.add { type = "table", name = "stats_" .. gui_value.force, column_count = 5 }

		-- Evolution
		local l = t.add  { type = "label", caption = "Evo:"}
		local biter_force = game.forces[gui_value.biter_force]
		local evo = math.floor(1000 * global.bb_evolution[gui_value.biter_force]) * 0.1
		local evo_tooltip = gui_value.t1 .. "\n[color=#FF5555]Damage: " .. (biter_force.get_ammo_damage_modifier("melee") + 1) * 100 
							.. "%[/color]\n[color=#70FF70]Revive: " .. global.reanim_chance[biter_force.index] .. "%[/color]"
		local l = t.add  { type = "label", caption = evo.."%", tooltip = evo_tooltip}
		--l.style.minimal_width = 25
		l.style.minimal_width = 40
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"

		-- Threat
		local l = t.add  {type = "label", caption = "Threat: "}
		l.style.minimal_width = 25
		local l = t.add  {type = "label", name = "threat_" .. gui_value.force, 
			caption = math.floor(global.bb_threat[gui_value.biter_force]),
			tooltip="[color=#EE8888]Actual passive threat income =[/color] [color=#FFAAAA]"..(math.floor(global.bb_threat_income[gui_value.biter_force]*100)/100)
					.."[/color] [color=#EE8888]per second.[/color]\n[color=#888888]"..gui_value.t2.."[/color]"
		}
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"
		l.style.width = 50
	end
	--EVL ADD BUTTONS FOR SPEC_GOD MODE (Larger wiew of the map without revealing other forces)
	--ONLY if admin AND spectator (real & god modes)
	--ONLY if gama has started (so streamers dont reveal ie stream hack)
	if is_spec and player.admin and global.match_running and player.name~=global.manager_table["north"] and player.name~=global.manager_table["south"] then
		frame.add { type = "line", caption = "this line", direction = "horizontal" }
		local _spec_gui = frame.add { type = "table", column_count = 5 }
		--EVL Button SPEC (zoom=0.18)
		local b_spec = _spec_gui.add({type = "sprite-button", name = "spec_z_spec", caption = "Spec", tooltip = "[color=#999999]Only admins as spectators can fly over the map,[/color]\n Click to switch between REAL and GOD modes."})
		b_spec.style.font = "heading-2"
		b_spec.style.font_color = {112, 112, 255}
		b_spec.style.width = 50
		b_spec.style.maximal_height = 30
		b_spec.style.padding = -2
		_spec_gui.add({type = "label", caption="  "})
		--EVL Button + (zoom=0.12)
		local b_zoom1 = _spec_gui.add({type = "sprite-button", name = "spec_z_1", caption = "+", tooltip = "Large view"})
		b_zoom1.style.font = "default-large-bold"
		b_zoom1.style.font_color = {112, 212, 112}
		b_zoom1.style.width = 40
		b_zoom1.style.maximal_height = 30
		b_zoom1.style.padding = -2
		_spec_gui.add({type = "label", caption="   "})
		--EVL Button + (zoom=0.06)
		local b_zoom2 =_spec_gui.add({type = "sprite-button", name = "spec_z_2", caption = "++", tooltip = "Larger view"})
		b_zoom2.style.font = "default-large-bold"
		b_zoom2.style.font_color = {255, 112, 112}
		b_zoom2.style.width = 40
		b_zoom2.style.maximal_height = 30
		b_zoom2.style.padding = -2
	end
	-- Difficulty mutagen effectivness update
	if not global.match_running then --EVL Dont update difficulty vote button once match has started
		bb_diff.difficulty_gui() 
	end

end

function Public.refresh()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["bb_main_gui"] then
			Public.create_main_gui(player)
		end
	end
	global.gui_refresh_delay = game.tick + 20 --EVL was 5 (saving UPS)
end

--Refresh threat when a biter has died (min 31 ticks between refreshes)
function Public.refresh_threat()
	if global.gui_refresh_delay > game.tick then return end
	for _, player in pairs(game.connected_players) do
		if player.gui.left["bb_main_gui"] then
			if player.gui.left["bb_main_gui"].stats_north then
				player.gui.left["bb_main_gui"].stats_north.threat_north.caption = math.floor(global.bb_threat["north_biters"])
				player.gui.left["bb_main_gui"].stats_south.threat_south.caption = math.floor(global.bb_threat["south_biters"])
			end
		end
	end
	global.gui_refresh_delay = game.tick + 31 --EVL was 5 (saving UPS)
end

function join_team(player, force_name, forced_join)
	if not player.character then return end
	if not forced_join then
		if global.tournament_mode then
			player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
		end
	end
	if not force_name then return end
	local surface = player.surface

	local enemy_team = "south"
	if force_name == "south" then enemy_team = "north" end
	--[[ Not used in BBChampions
	if not global.training_mode and global.bb_settings.team_balancing then --EVL not used
		if not forced_join then
			if #game.forces[force_name].connected_players > #game.forces[enemy_team].connected_players then
				if not global.chosen_team[player.name] then
					player.print("Team " .. force_name .. " has too many players currently.", {r = 0.98, g = 0.66, b = 0.22})
					return
				end
			end
		end
	end
	]]--
	--[[ Not used in BBChampions
	if global.chosen_team[player.name] then --EVL not used
		if not forced_join then
			if game.tick - global.spectator_rejoin_delay[player.name] < 3600 then
				player.print(
					"Not ready to return to your team yet. Please wait " .. 60-(math.floor((game.tick - global.spectator_rejoin_delay[player.name])/60)) .. " seconds.",
					{r = 0.98, g = 0.66, b = 0.22}
				)
				return
			end
		end
		local p = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 16, 0.5)
		if not p then
			game.print("No spawn position found for " .. player.name .. "!", {255, 0, 0})
			return 
		end
		player.teleport(p, surface)
		player.force = game.forces[force_name]
		player.character.destructible = true
		Public.refresh()
		game.permissions.get_group("Default").add_player(player)
		local msg = table.concat({"Team ", player.force.name, " player ", player.name, " is no longer spectating."})
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(msg)
		global.spectator_rejoin_delay[player.name] = game.tick
		player.spectator = false
		return
	end
	]]
	local pos = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 1)
	if not pos then pos = game.forces[force_name].get_spawn_position(surface) end
	player.teleport(pos)
	player.force = game.forces[force_name]
	
	player.character.destructible = true
	game.permissions.get_group("Default").add_player(player)
	if not forced_join then
		local c = player.force.name
		if global.tm_custom_name[player.force.name] then c = global.tm_custom_name[player.force.name] end
		local message = table.concat({player.name, " has joined team ", c, "!"})
		game.print(message, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(message)
	end
	local i = player.get_inventory(defines.inventory.character_main)
	i.clear()
	--[[ EVL WE GO ON FIELD EMPTY, WITH USE STARTER PACKS
	player.insert {name = 'pistol', count = 1}
	player.insert {name = 'raw-fish', count = 3}
	player.insert {name = 'firearm-magazine', count = 32}
	player.insert {name = 'iron-gear-wheel', count = 8}
	player.insert {name = 'iron-plate', count = 16}
	player.insert {name = 'burner-mining-drill', count = 10}
	player.insert {name = 'wood', count = 2}
	]]--
	global.chosen_team[player.name] = force_name
	global.spectator_rejoin_delay[player.name] = game.tick
	player.spectator = false
	Public.refresh()
end

function spectate(player, old_force, forced_join)
	--if not force_joined then force_joined=false end

	if not player.character then 
		if global.bb_debug_gui then game.print("Debug : "..player.name.." is not a character (in gui/spectate.lua). That is  probably normal.", {r = 0.98, g = 0.22, b = 0.22}) end
	end
	if not(old_force=="north" or old_force=="south") then 
		if global.tournament_mode then game.print("Debug: in spectate() "..player.name.." is not in a team, can't move to spectators (in gui.lua/spectate).", {r = 0.98, g = 0.66, b = 0.22}) end
		return 
	end
	if not forced_join then
		if global.tournament_mode then player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) return end
	end


	player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
	--EVL remove corpse if empty (probably wrong player move)
	local corpses = player.surface.find_entities_filtered{type="character-corpse"}
	for _,corpse in pairs(corpses) do
		local this_player = game.get_player(corpse.character_corpse_player_index)
		if this_player.name==player.name then
			local this_inventory=corpse.get_inventory(defines.inventory.character_corpse).get_contents()
			if table_size(this_inventory)==0 then
				if global.bb_debug_gui then game.print("Debug: in spectate() Destroy empty corpse for dead "..player.name..". Saving force ("..old_force..").", {r = 0.98, g = 0.66, b = 0.22}) end
				global.corpses_force[player.name]=old_force --DEBUG-- Are we sure ?
				corpse.destroy()
			else
				--EVL In case of ... 
				--(should not happen unless a referee moves a player with inventory not empty)
				--well... could be for a substitution "from" player connected (but he should have emptied his inventory before)
				if global.bb_debug_gui then game.print("Debug: in spectate() Saving force:"..old_force.." for dead "..player.name.." (corpse not empty).", {r = 0.98, g = 0.66, b = 0.22}) end
				global.corpses_force[player.name]=old_force
			end
		end
	end
	player.force = game.forces.spectator --already done a priori
	if player.character then
		player.character.destructible = false --DEBUG-- when disco player is moved to island, then back to team it will put his corpse on island
	else
		if global.bb_debug_gui then game.print("Debug : "..player.name.." is not a character (in gui/spectate.lua). Is that OK ???", {r = 0.98, g = 0.66, b = 0.22}) end
	end
	if not forced_join then
		local msg = player.name .. " is spectating."
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(msg)
	end
	game.permissions.get_group("spectator").add_player(player)
	global.spectator_rejoin_delay[player.name] = game.tick
	Public.create_main_gui(player)
	player.spectator = true

end
--[[ local function join_gui_click(name, player) --Not
	local team = {
		["join_north_button"] = "north",
		["join_south_button"] = "south"
	}

	if not team[name] then return end

	if global.game_lobby_active then --EVL not used
		if player.admin then
			join_team(player, team[name])
			game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
			global.game_lobby_active = false
			return
		end
		player.print("Waiting for more players, " .. wait_messages[math_random(1, #wait_messages)], { r=0.98, g=0.66, b=0.22})
		return
	end
	join_team(player, team[name])
end
]]
local spy_forces = {{"north", "south"},{"south", "north"}}
function Public.spy_fish()
	for _, f in pairs(spy_forces) do
		if global.spy_fish_timeout[f[1]] - game.tick > 0 then
			local r = 96
			local surface = game.surfaces[global.bb_surface_name]
			for _, player in pairs(game.forces[f[2]].connected_players) do
				game.forces[f[1]].chart(surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})
			end
		else
			global.spy_fish_timeout[f[1]] = 0
		end
	end
end

--EVL Show opposite side to teams (depends on player positions and radars, triggereg if global.managers_in_team==true in main.lua --EVL in this mode manager are set to team)
function Public.spy_forces(force,target)
	local surface = game.surfaces[global.bb_surface_name]
	local mid_river=bb_config["border_river_width"]/2 --44/2
	local spawn_vision=62 -- other possible value = 65+32? (ie one more chunk left_x and right_x, vertical stays same)
	--command to test spawn_chart: /c r=40 game.forces["north"].chart(game.player.surface,{{-r, 24}, {r, r+24}})
	--Note : the command witrh r=40 is equivalent to r=62or63, but the chart works not the same in the code below... why ?
	local player_vision=79 -- may be reduced by 32 or 31
	---command to test player_chart: /c r=96 pos_x=math.floor(game.player.position.x/32)*32+16 pos_y=math.floor(game.player.position.y/32)*32+16 game.forces["north"].chart(game.player.surface,{{pos_x-r,pos_y-r}, {pos_x+r,pos_y+r}})	
	local radar_vision=111 -- may be reduced by 32 or 31
	--command to test radar_chart: /c r=111 radar=game.player.surface.find_entities_filtered{force="north",name = "radar"}[1] pos_x=math.floor(radar.position.x/32)*32+16 pos_y=math.floor(radar.position.y/32)*32+16 game.forces["north"].chart(game.player.surface,{{pos_x-r,pos_y-r}, {pos_x+r,pos_y+r}})
	if not(force and (force=="north" or force=="south")) then 
		if global.bb_debug or global.bb_debug_gui then game.print(">>>>> Wrong force "..tostring(force).." in Gui.spy_forces.", {r = 0.88, g = 0.22, b = 0.22}) end
		return 
	end
	
	local chart_force="south"
	if force=="south" then chart_force="north" end
	-------------------------------------------
	--Show <<force>> side to <<chart_force>> --
	-------------------------------------------

	if target=="spawn" then
		--Default : spawn free chart even if no players (for both teams)
		local chart_y_min=-spawn_vision-mid_river
		local chart_y_max=-mid_river
		if force=="south" then
			chart_y_min=mid_river
			chart_y_max=spawn_vision+mid_river
		end
		--Reveal to both sides
		game.forces[chart_force].chart(surface,{{-spawn_vision, chart_y_min},{spawn_vision, chart_y_max}})
		game.forces[force].chart(surface,{{-spawn_vision, chart_y_min},{spawn_vision, chart_y_max}})

	elseif target=="players" then
		--Players
		for _, player in pairs(game.forces[force].connected_players) do
			if global.viewing_technology_gui_players[player.name] or (global.manager_table[force] and player.name==global.manager_table[force]) then
				--Do nothing
			else
				local pos_x=math.floor(player.position.x/32)*32+16
				local pos_y=math.floor(player.position.y/32)*32+16
				--if force=="south" then --limit chart to mid river--DEBUG--
				--	if (pos_y+player_vision)>-mid_river then pos_y=-mid_river-player_vision end
				--else
				--	if (pos_y-player_vision)<mid_river then pos_y=mid_river+player_vision end
				--end
				
				game.forces[chart_force].chart(surface,{{pos_x-player_vision, pos_y-player_vision}, {pos_x+player_vision, pos_y+player_vision}})
			end
		end
	elseif target=="radars" then
		--/c r=224 radar=surface.find_entities_filtered{force=force,name = "radar"}[1] pos_x=math.floor(radar.position.x/32)*32+16 pos_y=math.floor(radar.position.y/32)*32+16 game.forces["north"].chart(game.player.surface,{{pos_x-r,pos_y-r}, {pos_x+r,pos_y+r}})
		
		--Radars
		local radars=surface.find_entities_filtered{force=force,name = "radar"}
		for _,radar in pairs(radars) do
			if radar.energy>860 then --EVL max energy=5333,with one solar panel nrj=861
				local radar_x=math.floor(radar.position.x/32)*32+16
				local radar_y=math.floor(radar.position.y/32)*32+16
				--if force=="south" then --limit chart to mid river--DEBUG--
				--	if (radar_y+radar_vision)>-mid_river then radar_y=-mid_river-radar_vision end
				--else
				--	if (radar_y-radar_vision)<mid_river then radar_y=mid_river+radar_vision end
				--end
				--game.print("Radar north ("..radar_x..","..radar_y..") nrj="..radar.energy)
				game.forces[chart_force].chart(surface,{{radar_x-radar_vision, radar_y-radar_vision}, {radar_x+radar_vision, radar_y+radar_vision}})
			end
		end
	else
		if global.bb_debug or global.bb_debug_gui then game.print(">>>>> Wrong target "..tostring(target).." in Gui.spy_forces.", {r = 0.88, g = 0.22, b = 0.22}) end
	end
end

--for _,radar in pairs(radars) do game.print("Radar #"..tonumber(_).." ("..radar.posision.x..","..radar.posision.y..") nrj="..radar.energy) end
local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	--if global.bb_debug_gui then game.print("DEBUGUI Init ok >>>>> on_gui_click: "..name.." by "..player.name..".",{r = 100, g = 100, b = 100}) end
	
	-- Close/Refresh inventory WITHIN Gui of player (not working if big latency)
	if name == "inventory_close" then
		if global.bb_debug_gui then game.print("DEBUGUI calling close_inventory ("..player.name..",target).") end
		show_inventory.close_inventory(player,"target")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	end
	if name == "inventory_refresh" then
		show_inventory.refresh_inventory(player,"target")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	end
	-- Close/Refresh inventory WITHIN Gui of teams (not working if big latency)
	if name == "team_inventory_close_north" then
		if global.bb_debug_gui then game.print("DEBUGUI calling close_inventory ("..player.name..",north).") end
		show_inventory.close_inventory(player,"north")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	elseif name == "team_inventory_close_south" then
		if global.bb_debug_gui then game.print("DEBUGUI calling close_inventory ("..player.name..",south).") end
		show_inventory.close_inventory(player,"south")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	end
	if name == "team_inventory_refresh_north" then
		if global.bb_debug_gui then game.print("DEBUGUI calling refresh_inventory ("..player.name..",north).") end
		show_inventory.refresh_inventory(player,"north")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	elseif name == "team_inventory_refresh_south" then
		if global.bb_debug_gui then game.print("DEBUGUI calling refresh_inventory ("..player.name..",south).") end
		show_inventory.refresh_inventory(player,"south")
		player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		return
	end
	--Toggle inventories in GUI of teams
	if name == "team_inventory_toggle_north" then
		--Update gui with inventory toggle button
		if global.viewing_inventories[player.name] and global.viewing_inventories[player.name]["north"] and global.viewing_inventories[player.name]["north"]["active"] then
			local inventory_mode="NIL"
			local inventory_tooltip="NIL"
			if global.viewing_inventories[player.name]["north"]["inventory"] then
				global.viewing_inventories[player.name]["north"]["inventory"]=false
				inventory_mode="[color=#88EE88]¡[/color]"
				inventory_tooltip="[color=#88EE88]Show inventories in team screen infos.[/color]"
			else
				global.viewing_inventories[player.name]["north"]["inventory"]=true
				inventory_mode="[color=#CC7777]![/color]"
				inventory_tooltip="[color=#CC7777]Hide inventories in team screen infos.[/color]"
			end
			show_inventory.refresh_inventory(player,"north")
			if player.gui.left["bb_main_gui"] then
				local toggle_inventory  = player.gui.left["bb_main_gui"].team_info_north.team_inventory_toggle_north
				toggle_inventory.caption=inventory_mode
				toggle_inventory.tooltip=inventory_tooltip
			end	
			player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		end
		return
	elseif name == "team_inventory_toggle_south" then
		--Update gui with inventory toggle button
		if global.viewing_inventories[player.name] and global.viewing_inventories[player.name]["south"] and global.viewing_inventories[player.name]["south"]["active"] then
			local inventory_mode="NIL"
			local inventory_tooltip="NIL"
			if global.viewing_inventories[player.name]["south"]["inventory"] then
				global.viewing_inventories[player.name]["south"]["inventory"]=false
				inventory_mode="[color=#88EE88]¡[/color]"
				inventory_tooltip="[color=#88EE88]Show inventories in team screen infos.[/color]"
			else
				global.viewing_inventories[player.name]["south"]["inventory"]=true
				inventory_mode="[color=#CC7777]![/color]"
				inventory_tooltip="[color=#CC7777]Hide inventories in team screen infos.[/color]"
			end
			show_inventory.refresh_inventory(player,"south")
			if player.gui.left["bb_main_gui"] then
				local toggle_inventory  = player.gui.left["bb_main_gui"].team_info_south.team_inventory_toggle_south
				toggle_inventory.caption=inventory_mode
				toggle_inventory.tooltip=inventory_tooltip
			end	
			player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		end
		return
	end


	
	if name == "bb_toggle_button" then
		if player.gui.left["bb_main_gui"] then
			player.gui.left["bb_main_gui"].destroy()
		else
			Public.create_main_gui(player)
		end
		return
	end
	--[[ EVL Removed, we always show the player list, no possibility to "join_team_button"
	if name == "join_north_button" then join_gui_click(name, player) return end
	if name == "join_south_button" then join_gui_click(name, player) return end
	]]--
	if name == "raw-fish" then Functions.spy_fish(player, event) return end

	if food_names[name] then feed_the_biters(player, name, 0, "regular") return end --EVL add 2 parameters (for training mode see team_manager>training and command in feeding.lua)
	
	--EVL SHOW INVENTORY & CRAFTING LIST
	--EVL Click on player from LeftGUI.playerlist
	--EVL only available for admins that are spectating	and managers of same side
	local _name=string.sub(name,0,6)
	if _name=="plist_" then
		local _target_name = event.element.caption
		if not game.players[_target_name] then
			if global.bb_debug then game.print("Debug: Player (".._target_name..") does not exist (in gui.lua/playerlist). Can't show inventory") end
			return
		end
		
		
		--Check if conditions are fulfilled
		if (player.admin and (player.force.name == "spectator" or player.force.name == "spec_god")) --admin and (spec or god)
			or (global.manager_table["north"] and player.name==global.manager_table["north"] and game.players[_target_name].force.name=="north") --manager north and target north
			or (global.manager_table["south"] and player.name==global.manager_table["south"] and game.players[_target_name].force.name=="south")  then --manager south and target south
		--if player.admin then   --CODING--
		--if true then   --CODING--
			show_inventory.open_inventory(player, game.players[_target_name]) --EVL player=source, _target=target
		else
			player.print(">>>>> Only admins as spectators (and managers) can view inventory and crafting-queue.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return
	end
	--EVL SHOW INVENTORY & CRAFTING LIST of TEAMS
	--EVL Click on team name from LeftGUI
	--EVL only available for admins that are spectating	and managers of same side
	if name=="open_close_inv_north" then
		--Check if conditions are fulfilled
		if (player.admin and (player.force.name == "spectator" or player.force.name == "spec_god")) --admin and (spec or god)
			or (global.manager_table["north"] and player.name==global.manager_table["north"]) then --manager north and target team north
		--if player.admin then   --CODING--
		--if true then   --CODING--
			show_inventory.open_inventory(player, "north") --EVL player=source, _target=team north
			--Update gui with inventory toggle button
			if global.viewing_inventories[player.name] and global.viewing_inventories[player.name]["north"] and global.viewing_inventories[player.name]["north"]["active"] then
				local inventory_mode="NIL"
				local inventory_tooltip="NIL"
				if global.viewing_inventories[player.name]["north"]["inventory"] then
					inventory_mode="[color=#CC7777]![/color]"
					inventory_tooltip="[color=#CC7777]Hide inventories in team screen infos.[/color]"
				else
					inventory_mode="[color=#88EE88]¡[/color]"
					inventory_tooltip="[color=#88EE88]Show inventories in team screen infos.[/color]"
				end
				show_inventory.refresh_inventory(player,"north")
				if player.gui.left["bb_main_gui"] then
					local toggle_inventory  = player.gui.left["bb_main_gui"].team_info_north.team_inventory_toggle_north
					toggle_inventory.caption=inventory_mode
					toggle_inventory.tooltip=inventory_tooltip
					toggle_inventory.style.height = 18
					toggle_inventory.style.width = 18
				end	
			end
			player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		else
			player.print(">>>>> Only admins as spectators (and north manager) can view inventory and crafting-queue of north team.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return
	elseif name=="open_close_inv_south" then
		--Check if conditions are fulfilled
		if (player.admin and (player.force.name == "spectator" or player.force.name == "spec_god")) --admin and (spec or god)
			or (global.manager_table["south"] and player.name==global.manager_table["south"]) then --manager south and target team south
		--if player.admin then   --CODING--	
		--if true then  --CODING--
			show_inventory.open_inventory(player, "south") --EVL player=source, _target=team south
			--Update gui with inventory toggle button
			if global.viewing_inventories[player.name] and global.viewing_inventories[player.name]["south"] and global.viewing_inventories[player.name]["south"]["active"] then
				local inventory_mode="NIL"
				local inventory_tooltip="NIL"
				if global.viewing_inventories[player.name]["south"]["inventory"] then
					inventory_mode="[color=#CC7777]![/color]"
					inventory_tooltip="[color=#CC7777]Hide inventories in team screen infos.[/color]"
				else
					inventory_mode="[color=#88EE88]¡[/color]"
					inventory_tooltip="[color=#88EE88]Show inventories in team screen infos.[/color]"
				end
				show_inventory.refresh_inventory(player,"south")
				if player.gui.left["bb_main_gui"] then
					local toggle_inventory  = player.gui.left["bb_main_gui"].team_info_south.team_inventory_toggle_south
					toggle_inventory.caption=inventory_mode
					toggle_inventory.tooltip=inventory_tooltip
					toggle_inventory.style.height = 18
					toggle_inventory.style.width = 18					
				end	
			end
			player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		else
			player.print(">>>>> Only admins as spectators (and south manager) can view inventory and crafting-queue of south team.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return
	end
	--EVL SHOW MINI CAMERA OF PLAYER
	--EVL Click on © from LeftGUI.playerlist
	--EVL only available for admins that are spectating	and managers of same side
	_name=string.sub(name,0,5)
	if _name=="pcam_" then
		local _target_index = tonumber(string.sub(name,6))
		if not(_target_index) or (_target_index<1) or not (game.players[_target_index]) then
			if global.bb_debug then game.print("Debug: Player (#".._target_index..") does not exist (in gui.lua/playerlist) cant show minicam") end
			return
		end
		local _target=game.players[_target_index]
		--Check if conditions are fulfilled
		if (player.admin and (player.force.name == "spectator" or player.force.name == "spec_god")) --admin and (spec or god)
			or (global.manager_table["north"] and player.name==global.manager_table["north"] and _target.force.name=="north") --manager north and target north
			or (global.manager_table["south"] and player.name==global.manager_table["south"] and _target.force.name=="south")  then --manager south and target south
				Where.create_mini_camera_gui(player, _target.name, _target.position, _target.surface.index)
				game.play_sound{path = global.sound_low_bip, volume_modifier = 1}
				return
		else
				player.print(">>>>> Only admins as spectators (and managers) can view mini-camera of player.", {r = 175, g = 0, b = 0})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
		end
	end	
	--
	--EVL BUTTONS FOR SPEC_GOD MODE (Larger wiew of the map without revealing other forces)
	--
	if name=="spec_z_spec" then --Spec_God_Mode switch
		--First we create the new force
		if not game.forces["spec_god"] then 
			game.create_force("spec_god")
			local f = game.forces["spec_god"]
			--f.set_spawn_position({0,0},surface)
			f.technologies["toolbelt"].researched = true
			f.set_cease_fire("north_biters", true)
			f.set_cease_fire("south_biters", true)
			f.set_friend("north", false)
			f.set_friend("south", false)
			f.set_cease_fire("player", true)
			f.share_chart = true
		end
		
		if player.admin then
			if player.force.name == "spectator" then -- GO TO SPEC GOD MODE
				player.close_map() -- EVL trying to close map view before
				player.force = game.forces["spec_god"]
				if player.character then player.character.destroy() end
				player.character = nil
				player.zoom=0.18
				player.show_on_map=false -- EVL remove red dots on map view for players and spectators (new in 1.1.47)
				global.god_players[player.name] = true
				Team_manager.redraw_all_team_manager_guis()
				game.forces["spectator"].print(">>>>> Admin: " ..  player.name .. " has gone into Spec/God mode view.", {r = 75, g = 75, b = 75})
				game.forces["spec_god"].print(">>>>> Admin: " ..  player.name .. " has gone into Spec/God mode view.", {r = 75, g = 75, b = 75})
				player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
				if global.bb_debug then game.print("Debug: player: " ..  player.name .." ("..player.force.name..") switches to God mode") end
			
			elseif player.force.name == "spec_god" then -- GO TO SPEC REAL MODE
				player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
				player.create_character()
				player.force = game.forces["spectator"]
				player.zoom=0.30
				player.show_on_map=true  -- EVL restore dots on map view for players and spectators (new in 1.1.47)
				player.character.destructible = false --EVL give back the property to the spec
				global.god_players[player.name] = false
				Team_manager.redraw_all_team_manager_guis()
				game.forces["spectator"].print(">>>>> Admin: " ..  player.name .." ("..player.force.name..") switches back to Real mode.", {r = 75, g = 75, b = 75})
				game.forces["spec_god"].print(">>>>> Admin: " ..  player.name .." ("..player.force.name..") switches back to Real mode.", {r = 75, g = 75, b = 75})
				player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
				
			else
				player.print(">>>>> Only spectators are allowed to use ~SPEC~ view.", {r = 175, g = 0, b = 0})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			end
			return
		else
			player.print(">>>>> Only admins are allowed to use ~SPEC~ view.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
	end
	
	if name == "spec_z_1" then --EVL Asking for large view {112, 112, 255}
		if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") asks for Large view") end
		if player.admin then
			if player.force.name == "spec_god" then --EVL admin must be in spec_god mode too
				player.zoom=0.12 -- EVL WRITE ONLY :-(
				player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
			else
				player.print(">>>>> You must click on [color=#7070FF]~SPEC~[/color] button first.", {r = 175, g = 0, b = 0})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			end
		else 
			player.print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return
	end
	if name == "spec_z_2" then --EVL Asking for larger view
		if global.bb_debug then game.print("Debug: player :" ..  player.name .." ("..player.force.name.. ") asks for LargeR view") end
		if game.players[event.player_index].admin then
			if player.force.name == "spec_god" then --EVL admin must be in spec_god mode too
				player.zoom=0.06 -- EVL WRITE ONLY :-(
				player.play_sound{path = global.sound_low_bip, volume_modifier = 1}
			else
				player.print(">>>>> You must click on [color=#7070FF]~SPEC~[/color] button first.", {r = 175, g = 0, b = 0})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			end
		else
			player.print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return
	end	
	
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.chosen_team then global.chosen_team = {} end

	if #game.connected_players > 1 then
		global.game_lobby_timeout = math.ceil(36000 / #game.connected_players)
	else
		global.game_lobby_timeout = 599940
	end

	--EVL Restore that disconnected player has rejoined (team manager)
	if global.disconnected[player.name] then 
		global.disconnected[player.name]=nil 
	end


	--if not global.chosen_team[player.name] then
	--	if global.tournament_mode then
	--		player.force = game.forces.spectator
	--	else
	--		player.force = game.forces.player
	--	end
	--end

	create_sprite_button(player)
	Public.create_main_gui(player)
end

--Moved to show_inventory_bbc.lua
--local function on_pre_player_left_game(event)
--end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
--event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)  --Moved to show_inventory_bbc.lua
return Public
