local Public = {}
local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Terrain = require "maps.biter_battles_v2.terrain" --EVL (none)

local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}

local function get_player_array(force_name)
	local a = {}	
	for _, p in pairs(game.forces[force_name].connected_players) do a[#a + 1] = p.name end
	return a
end

function Public.freeze_players() --EVL Needed to start game already frozen
	game.print("start of function freeze players")
	if not global.freeze_players then --EVL global.freeze_players is not managed here
		if global.bb_debug then game.print("Debug: Freeze_players called without global.freeze_players set to true.") end
		return 
	end 
	global.team_manager_default_permissions = {}
	local p = game.permissions.get_group("Default")	
	for action_name, _ in pairs(defines.input_action) do
		global.team_manager_default_permissions[action_name] = p.allows_action(defines.input_action[action_name])
		p.set_allows_action(defines.input_action[action_name], false)
	end	
	local defs = {
		defines.input_action.write_to_console,
		defines.input_action.gui_click,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_checked_state_changed	,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		defines.input_action.edit_permission_group,
	}	
	for _, d in pairs(defs) do p.set_allows_action(d, true) end
	--EVL Save tick (time when players have been frozen)
	if global.freezed_start ~= 999999999  then game.print("Debug: global.freezed_start <> 999999999(="..global.freezed_start..") in freeze_players") end --useless
	global.freezed_start=game.ticks_played --EVL save the tick when freeze started to substract freezed time from played_time when unfreezing happens
	--EVL FREEZE BITERS
	if not game.surfaces[global.bb_surface_name] then return end
	local surface = game.surfaces[global.bb_surface_name] 
	for _, e in pairs(surface.find_entities_filtered({force = "north_biters"})) do
        e.active = false
    end
    for _, e in pairs(surface.find_entities_filtered({force = "south_biters"})) do
        e.active = false
    end
	if global.bb_debug then game.print("Debug: Players and Biters are frozen (Team_manager).") end
	--game.print("end of function : freezing players at ".. global.freezed_start .." ticks", {r = 111, g = 111, b = 255}) --EVL DEBUG
end

local function unfreeze_players()
	game.print("start of function unfreeze players")
	if global.freeze_players then --EVL global.freeze_players is not managed here
		if global.bb_debug then game.print("Debug: Unfreeze_players called without global.freeze_players set to false.") end
		return 
	end 
	local p = game.permissions.get_group("Default") 
	for action_name, _ in pairs(defines.input_action) do
		if global.team_manager_default_permissions[action_name] then
			p.set_allows_action(defines.input_action[action_name], true)
		end
	end
	--EVL Use saved time from when players were freezed to get real_played_time
	if global.freezed_start == 999999999 then game.print("BUG : global.freezed_start = 999999999 in unfreeze players") end --useless??
	global.freezed_time=global.freezed_time + game.ticks_played-global.freezed_start
	global.freezed_start=999999999 -- could be nil, not useful until next freeze
	
	--EVL UNFREEZE BITERS
	local surface = game.surfaces[global.bb_surface_name] 
	for _, e in pairs(surface.find_entities_filtered({force = "north_biters"})) do
        e.active = true
    end
    for _, e in pairs(surface.find_entities_filtered({force = "south_biters"})) do
        e.active = true
    end
	if global.bb_debug then game.print("Debug: Players and Biters are unfrozen (Team_manager).") end
	--game.print("end of function unfreezing players at ".. game.ticks_played  .." ticks,     game.tick=" .. game.tick, {r = 255, g = 77, b = 77}) --EVL DEBUG
end

local function leave_corpse(player)
	if not player.character then return end
	
	local inventories = {
		player.get_inventory(defines.inventory.character_main),
		player.get_inventory(defines.inventory.character_guns),
		player.get_inventory(defines.inventory.character_ammo),
		player.get_inventory(defines.inventory.character_armor),
		player.get_inventory(defines.inventory.character_vehicle),
		player.get_inventory(defines.inventory.character_trash),
	}
	
	local corpse = false
	for _, i in pairs(inventories) do
		for index = 1, #i, 1 do
			if not i[index].valid then break end
			corpse = true
			break
		end
		if corpse then
			player.character.die()
			break
		end
	end
	
	if player.character then player.character.destroy() end	
	player.character = nil
	player.set_controller({type=defines.controllers.god})
	player.create_character()	
end

local function switch_force(player_name, force_name)
	if not game.players[player_name] then game.print("Team Manager >> Player " .. player_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	if not game.forces[force_name] then game.print("Team Manager >> Force " .. force_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	
	local player = game.players[player_name]
	player.force = game.forces[force_name]
				
	game.print(player_name .. " has been switched into team " .. force_name .. ".", {r=0.98, g=0.66, b=0.22})
    --Server.to_discord_bold(player_name .. " has joined team " .. force_name .. "!")
	
	
	
	leave_corpse(player)
	
	global.chosen_team[player_name] = nil	
	if force_name == "spectator" then	
		spectate(player, true)		
	else
		join_team(player, force_name, true)
		if #game.forces[force_name].connected_players > 3 then
			game.print(">>>>> BBC ALERT : Team " .. force_name .. " should NOT have more than 3 players !!!", {r=0.98, g=0.11, b=0.11})
		end
			
	end
	if global.bb_debug then 
		game.print("Debug: "..#game.forces["north"].connected_players.." player(s) at north and "..#game.forces["south"].connected_players.." player(s) at south")
	end
end

function Public.draw_top_toggle_button(player)
	if player.gui.top["team_manager_toggle_button"] then player.gui.top["team_manager_toggle_button"].destroy() end	
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_toggle_button", caption = "Team Manager", tooltip = "Reload frame to see new joined players" })
	button.style.font = "heading-2"
	button.style.font_color = {r = 0.88, g = 0.55, b = 0.11}
	button.style.minimal_height = 38
	button.style.minimal_width = 120
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end

local function draw_manager_gui(player)
	if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams", direction = "vertical"})

	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local l = t.add({type = "sprite-button", caption = string.upper(forces[i2].name).." (".. #game.forces[forces[i2].name].connected_players ..")", name = forces[i2].name})
			l.style.minimal_width = 160
			l.style.maximal_width = 160
			l.style.font_color = forces[i2].color
			l.style.font = "heading-1"
			i2 = i2 + 1
		else
			local tt = t.add({type = "label", caption = " "})
		end		
	end
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local list_box = t.add({type = "list-box", name = "team_manager_list_box_" .. i2, items = get_player_array(forces[i2].name)})
			list_box.style.minimal_height = 300 --EVL was 360
			list_box.style.minimal_width = 160
			list_box.style.maximal_height = 360 --EVL was 480
			i2 = i2 + 1
		else
			local tt = t.add({type = "table", column_count = 1})
			local b = tt.add({type = "sprite-button", name = i2 - 1, caption = "→"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
			local b = tt.add({type = "sprite-button", name = i2, caption = "←"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
		end		
	end
	
	frame.add({type = "label", caption = ""})
	--EVL Button for Reroll
		local t = frame.add({type = "table", name = "team_manager_reroll_buttons", column_count = 3})
		
		if global.reroll_left < 1 then 
			local tt = t.add({type = "label", caption = "NO MORE REROLL AVAILABLE, MATCH HAS TO BE PLAYED ON THIS MAP !"})
		else
			local tt = t.add({type = "label", caption = "CLICK TO REROLL THE MAP ("..global.reroll_left.." left) :"})
			local button = t.add({
				type = "button",
				name = "team_manager_reroll",
				caption = "REROLL MAP",
				tooltip = "No roll back !"
			})
			button.style.font = "heading-1"
			button.style.font_color = {r = 00, g = 00, b = 00}
			local tt = t.add({type = "label", caption = "  (team @home choice)"})
		end

		
	frame.add({type = "label", caption = ""})
	--EVL Buttons for packs 	--game.print("###:"..Tables.packs_total_nb)
	local t = frame.add({type = "table", name = "team_manager_pack_buttons", column_count = Tables.packs_total_nb+1})
	local tt = t.add({type = "label", caption = "PACKS:"})
	
	for _, pack_elem in pairs(Tables.packs_list) do
		local button = t.add({
			type = "button",
			name = pack_elem.name,
			caption = pack_elem.caption,
			tooltip = pack_elem.tooltip
		})
		button.style.font = "heading-3"
		if global.pack_choosen == "" then
			button.style.font_color = {r = 00, g = 00, b = 00}
		else 
			if global.pack_choosen == pack_elem.name then
				button.style.font_color = {r = 0, g = 125, b = 0}
			else
				button.style.font_color = {r = 225, g = 00, b = 00}
			end
		end
		--game.print("gui choosen:".. global_pack.choosen)
			
	end
	frame.add({type = "label", caption = ""})	
	-- END EVL Buttons for packs
	local t = frame.add({type = "table", name = "team_manager_bottom_buttons", column_count = 4})	
	local button = t.add({
			type = "button",
			name = "team_manager_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
	
	if global.tournament_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Mode Enabled",
			tooltip = "Only admins can move players and vote for difficulty.\nActive players can no longer go spectate.\nNew joining players are spectators."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Mode Disabled",
			tooltip = "Only admins can move players. Active players can no longer go spectate. New joining players are spectators."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
	end
	button.style.font = "heading-2"
	
	if global.freeze_players then
		local caption_tmp="Unfreeze (Unpause)" --EVL
		local color_tmp = {r = 0, g = 127, b = 0}
		if not global.match_running then --EVL first UNFREEZE = Starting match
			caption_tmp="START & UNFREEZE"
			if global.pack_choosen == "" then color_tmp = {r = 222, g = 22, b = 22} end
		end
		button = t.add({
			type = "button",
			name = "team_manager_freeze_players",
			caption = caption_tmp,
			tooltip = "Release all players and biters."
		})
		button.style.font_color = color_tmp
	else
		button = t.add({
			type = "button",
			name = "team_manager_freeze_players",
			caption = "Freeze (Pause)",
			tooltip = "Freeze players and biters,\navoid using it when attack is happening\n(turrets will keep shooting)."
		})
		button.style.font_color = {r = 55, g = 55, b = 222}
	end
	button.style.font = "heading-2"
	
	if global.training_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Mode Activated",
			tooltip = "Feed your own team's biters and only teams with players gain threat & evo."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Mode Disabled",
			tooltip = "Feed your own team's biters and only teams with players gain threat & evo."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
	end
	button.style.font = "heading-2"
end

local function set_custom_team_name(force_name, team_name)
	if team_name == "" then global.tm_custom_name[force_name] = nil return end
	if not team_name then global.tm_custom_name[force_name] = nil return end
	global.tm_custom_name[force_name] = tostring(team_name)
end

local function custom_team_name_gui(player, force_name)
	if player.gui.center["custom_team_name_gui"] then player.gui.center["custom_team_name_gui"].destroy() return end	
	local frame = player.gui.center.add({type = "frame", name = "custom_team_name_gui", caption = "Set custom team name:", direction = "vertical"})
	local text = force_name
	if global.tm_custom_name[force_name] then text = global.tm_custom_name[force_name] end
	
	local textfield = frame.add({ type = "textfield", name = force_name, text = text })	
	local t = frame.add({type = "table", column_count = 2})	
	local button = t.add({
			type = "button",
			name = "custom_team_name_gui_set",
			caption = "Set",
			tooltip = "Set custom team name."
		})
	button.style.font = "heading-2"
	
	local button = t.add({
			type = "button",
			name = "custom_team_name_gui_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
end

local function team_manager_gui_click(event)
	local player = game.players[event.player_index]
	local name = event.element.name
	
	if game.forces[name] then
		if not player.admin then player.print("Only admins can change team names.", {r = 175, g = 0, b = 0}) return end
		custom_team_name_gui(player, name)
		player.gui.center["team_manager_gui"].destroy()
		return
	end
	
	if name == "team_manager_close" then
		player.gui.center["team_manager_gui"].destroy()	
		return
	end
	
	if name == "team_manager_activate_tournament" then --EVL Only tournament mode, cant be disabled
		if true then
			game.print(">>>>>>  Tournament mode must stay activated in BBC", {r = 225, g = 0, b = 0}) --EVL
			return --EVL
		end
		if not player.admin then player.print("Only admins can switch tournament mode.", {r = 175, g = 0, b = 0}) return end
		if global.tournament_mode then
			global.tournament_mode = false
			draw_manager_gui(player)
			game.print(">>> Tournament Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.tournament_mode = true
		draw_manager_gui(player)
		game.print(">>> Tournament Mode has been enabled!", {r = 225, g = 0, b = 0})
		return
	end
	
	--EVL Reroll
	if name == "team_manager_reroll" then
		if not player.admin then player.print(">>>>> Only admins can reroll the map.", {r = 175, g = 0, b = 0}) return end
		global.reroll_do_it = true --EVL global_reroll_left decreased if main
		global.freeze_players = true
		--draw_manager_gui(player)
		player.gui.center["team_manager_gui"].destroy()	
		game.print(">>>> Asking for map reroll - Please wait...", {r = 175, g = 0, b = 0})
		return
	end
	--EVL Reroll
	--EVL Packs
	local pack=string.sub(name,0,5)
	if pack=="pack_" then
		if not player.admin then player.print(">>>>> Only admins can choose the starter pack.", {r = 175, g = 0, b = 0}) return end
		if global.match_running then -- No more changing, game has started
			player.print(">>>>> Pack cannot be changed after the match has started !", {r = 225, g = 11, b = 11})
			return
		end
		if global.fill_starter_chests then -- Chests are not filled yet, cant change pack
			player.print(">>>>> Chests are in filling sequence, please wait...", {r = 225, g = 11, b = 11})
			return
		end
		if not global.pack_choosen or global.pack_choosen=="" then 
			global.pack_choosen = name
			game.print(">>>>> Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name].caption .." has been choosen !", {r = 11, g = 225, b = 11})
			global.fill_starter_chests = true
		else 
			global.pack_choosen = name
			game.print(">>>>> Pack has been changed to Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name]["caption"] .." !", {r = 225, g = 11, b = 11})
			global.fill_starter_chests = true
		end
		draw_manager_gui(player)
		return
	end
	--EVL PACK FIN
	
	
	if name == "team_manager_freeze_players" then -- FREEZE/UNFREEZE
		if not player.admin then player.print(">>>>> Only admins can switch freeze mode.", {r = 175, g = 0, b = 0}) return end
		if global.bb_game_won_by_team then player.print(">>>>> You cannot switch freeze mode after match has finished.", {r = 175, g = 0, b = 0}) return end
		
		if global.freeze_players then --EVL Players are frozen
			if global.pack_choosen == "" then -- EVL dont start without pack choosen
				game.print(">>>>> A pack must be choosen before starting the game / unfreezing the players !", {r = 225, g = 11, b = 11})
				return
			end
			if global.reroll_do_it then -- EVL dont start if reroll is on the way
				game.print(">>>>> Reroll is not done yet, retry in a second...", {r = 225, g = 11, b = 11})
				return
			end			
			if not global.starter_chests_are_filled then -- EVL dont start before starter packs are filled
				game.print(">>>>> Starter Packs are not filled yet, retry in a second...", {r = 225, g = 11, b = 11})
				return
			end
			
			if not global.match_running then --First unfreeze meaning match is starting
				global.match_running=true 
				game.print(">>>>> Match is starting. Good luck !", {r = 11, g = 255, b = 11})
			end  	
			global.reroll_left=0		-- Match has started, no more reroll
			global.freeze_players = false
			unfreeze_players()
			draw_manager_gui(player)
			game.print(">>>>> Players & Biters have been unfrozen !", {r = 255, g = 77, b = 77})
			return
		end
		--EVL We're PAUSING the game, no change in global.match_running nor in global.pack_choosen (the game was initiated with global.freeze_players=true)

		global.freeze_players = true
		Public.freeze_players()
		draw_manager_gui(player)

		game.print(">>>>> Players & Biters have been frozen !", {r = 111, g = 111, b = 255}) --EVL
		return
	end
	
	if name == "team_manager_activate_training" then 
		if not player.admin then player.print(">>>>> Only admins can switch training mode.", {r = 175, g = 0, b = 0}) return end
		if global.training_mode then
			global.training_mode = false
			global.game_lobby_active = true
			draw_manager_gui(player)
			game.print(">>>>> Training Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.training_mode = true
		global.game_lobby_active = false
		draw_manager_gui(player)
		game.print(">>>>> Training Mode has been enabled!", {r = 225, g = 0, b = 0})
		return
	end
	
	if not event.element.parent then return end
	local element = event.element.parent
	if not element.parent then return end
	local element = element.parent
	if element.name ~= "team_manager_root_table" then return end		
	if not player.admin then player.print(">>>>> Only admins can manage teams.", {r = 175, g = 0, b = 0}) return end
	
	local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_" .. tonumber(name)]
	local selected_index = listbox.selected_index
	if selected_index == 0 then player.print("No player selected.", {r = 175, g = 0, b = 0}) return end
	local player_name = listbox.items[selected_index]
	
	local m = -1
	if event.element.caption == "→" then m = 1 end
	local force_name = forces[tonumber(name) + m].name
	
	switch_force(player_name, force_name)
	
	draw_manager_gui(player)
end

function Public.gui_click(event)	
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	
	if name == "team_manager_toggle_button" then
		if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() return end
		draw_manager_gui(player)
		return
	end
	
	if player.gui.center["team_manager_gui"] then team_manager_gui_click(event) end
	
	if player.gui.center["custom_team_name_gui"] then
		if name == "custom_team_name_gui_set" then
			local custom_name = player.gui.center["custom_team_name_gui"].children[1].text
			local force_name = player.gui.center["custom_team_name_gui"].children[1].name
			set_custom_team_name(force_name, custom_name)
			player.gui.center["custom_team_name_gui"].destroy()
			draw_manager_gui(player)
			return
		end
		if name == "custom_team_name_gui_close" then
			player.gui.center["custom_team_name_gui"].destroy()
			draw_manager_gui(player)
			return
		end
	end	
end

return Public
