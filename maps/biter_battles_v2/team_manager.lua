local Public = {}
local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Terrain = require "maps.biter_battles_v2.terrain" --EVL (none)

local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}
local colorAdmin="#FFBB77"

local function get_player_array(force_name)
	local a = {}	
	for _, p in pairs(game.forces[force_name].connected_players) do 
		local _name=p.name
		--EVL We add admin tag to the list (so we see easily who is admin)
		if p.admin then _name="[color="..colorAdmin.."]".._name.."[/color]:A" end
		a[#a + 1] = _name
	end
	return a
end

function Public.freeze_players() --EVL Needed to start game already frozen
	--game.print("start of function freeze players")
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

function Public.unfreeze_players()
	--game.print("start of function unfreeze players")
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
	local _player_name=player_name
	
	--EVL We remove tag Admin before switching force (see get_player_array above)
	if string.sub(_player_name,1,15) == "[color="..colorAdmin.."]" then
		_player_name=string.sub(_player_name,16,#_player_name-10)
	end

	if not game.players[_player_name] then game.print("Team Manager >> Player " .. _player_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	if not game.forces[force_name] then game.print("Team Manager >> Force " .. force_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	
	local player = game.players[_player_name]
	player.force = game.forces[force_name]
				
	game.print(_player_name .. " has been switched into team " .. force_name .. ".", {r=0.98, g=0.66, b=0.22})
    Server.to_discord_bold(_player_name .. " has joined team " .. force_name .. "!")
	
	
	
	leave_corpse(player)
	
	global.chosen_team[_player_name] = nil	
	if force_name == "spectator" then	
		spectate(player, true)		
	else
		if player.admin then 
			game.print(">>>>> BBC ALERT : Player " .. _player_name .. " is Admin and should not be switched into a team.", {r=0.98, g=0.77, b=0.77})
		end
		join_team(player, force_name, true)
		if #game.forces[force_name].connected_players > 3 then
			game.print(">>>>> BBC ALERT : Team " .. force_name .. " should NOT have more than 3 players !!!", {r=0.98, g=0.11, b=0.11})
		end
			
	end
	if global.bb_debug then 
		game.print("Debug: "..#game.forces["north"].connected_players.." player.s at north and "..#game.forces["south"].connected_players.." player.s at south")
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
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams    [font=default-small][color=#999999]Please don't spam me[/color][/font]", direction = "vertical"})

	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			_maxim="Click to customize team name\n".."<<Put the maxim here>>"
			if forces[i2].name == "spectator" then _maxim="Whoever assists as a spectator sees clearly,\nwhoever takes sides is led astray." end
			local l = t.add({type = "sprite-button", 
				caption = string.upper(forces[i2].name).." (".. #game.forces[forces[i2].name].connected_players ..")",
				name = forces[i2].name, 
				tooltip = _maxim})
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
	local tnote=frame.add({type = "label", caption = "Note : [color="..colorAdmin.."]Only[/color] Referee and Streamers should be admins,               >>>>> use [color=#EEEEEE]/promote and.or /demote[/color]\n"
														.."Players, Coach/Substitute and Spectators should [color="..colorAdmin.."]NOT[/color] be admins"})
	tnote.style.single_line = false
	tnote.style.font = "default-small"
	tnote.style.font_color = {r = 150, g = 150, b = 150}
	--local tnote=frame.add({type = "label", caption = "Players, Coach/Substitute and Spectators should [color="..colorAdmin.."]NOT[/color] be admins"})
	--tnote.style.font = "default-small"
	--tnote.style.font_color = {r = 150, g = 150, b = 150}
	
	frame.add({type = "label", caption = ""})
	
	--EVL Button for Reroll
		local t = frame.add({type = "table", name = "team_manager_reroll_buttons", column_count = 4})
		
		if global.match_running or global.reroll_left < 1 then 
			local tt = t.add({type = "label", caption = "NO MORE REROLL AVAILABLE, MATCH HAS TO BE PLAYED ON THIS MAP !               "})
			tt.style.font = "heading-2"
			tt.style.font_color = {r = 250, g = 250, b = 250}
			
		else
			local tt = t.add({type = "label", caption = "CLICK TO REROLL ("..global.reroll_left.." left) :"})
			tt.style.font = "heading-2"
			tt.style.font_color = {r = 200, g = 200, b = 200}
			local buttonrr = t.add({type = "button",	name = "team_manager_reroll", caption = "REROLL MAP", tooltip = "No roll back !"})
			buttonrr.style.font = "heading-1"
			buttonrr.style.font_color = {r = 10, g = 10, b = 10}
			local tt = t.add({type = "label", caption = " (team ~AtHome~ choice)               "})
			tt.style.font = "heading-3"
			tt.style.font_color = {r = 180, g = 180, b = 180}

		end
		--EVL BUTTON FOR GAME ID
		local _game_id = "GAME_ID"
		if 	global.game_id then _game_id =	global.game_id end
		local buttonid = t.add({type = "button",	name = "team_manager_gameid", caption = _game_id, tooltip = "Please fill up the game ID before match can start"})
		buttonid.style.font = "heading-2"
		if 	global.game_id then 
			buttonid.style.font_color = {r = 22, g = 111, b = 22}
		else
			buttonid.style.font_color = {r = 222, g = 22, b = 22}
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
	local button = t.add({type = "button", name = "team_manager_close", caption = "Close", tooltip = "Close this window."})
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

-- EVL SET GAME ID
local function set_custom_game_id(player,game_id)
	if not game_id then 
		global.game_id=nil
		return 
	end
	local _game_id=tonumber(game_id)
	if _game_id == 0 then 
		global.game_id=nil
		player.print("ID:"..game_id.." is not a number, pleasy retry.",{r = 222, g = 22, b = 22})
		return 
	end
	if (_game_id<10000) or math.floor(_game_id%123) ~= 0 then 
		global.game_id=nil
		player.print("ID:"..game_id.." is not valid, pleasy retry.",{r = 222, g = 22, b = 22})
		return
	end
	global.game_id=_game_id
	game.print(">>>>> Game_ID has been registered by "..player.name,{r = 22, g = 222, b = 22})
end
-- EVL SET GAME ID
local function custom_game_id_gui(player)
	if player.gui.center["custom_game_id_gui"] then player.gui.center["custom_game_id_gui"].destroy() return end	
	local frame = player.gui.center.add({type = "frame", name = "custom_game_id_gui", caption = "Set the game IDentificator :", tooltip = "If not auto, go to website to get GameId", direction = "vertical"})
	local _text = ""
	if global.game_id then _text = global.game_id end
	
	local textfield = frame.add({ type = "textfield", name = "game_id_text_field", text = _text })	
	local t = frame.add({type = "table", column_count = 2})	
	local button = t.add({
			type = "button",
			name = "custom_game_id_gui_set",
			caption = "Set",
			tooltip = "If not auto, go to website to get GameId."
		})
	button.style.font = "heading-2"
	
	local button = t.add({
			type = "button",
			name = "custom_game_id_gui_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
end


local function team_manager_gui_click(event)
	local player = game.players[event.player_index]
	local name = event.element.name
	
	if game.forces[name] then
		if not player.admin then player.print(">>>>> Only admins can change team names.", {r = 175, g = 0, b = 0}) return end
		custom_team_name_gui(player, name)
		player.gui.center["team_manager_gui"].destroy()
		return
	end

	if name == "team_manager_gameid" then
		if not player.admin then player.print(">>>>> Only admins can set the Game Identificator.", {r = 175, g = 0, b = 0}) return end
		if global.match_running then player.print(">>>>> Cannot modify GameId after match has started (contact website admin).", {r = 175, g = 0, b = 0}) return end
		custom_game_id_gui(player)
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
			if not global.game_id then -- EVL dont start before game_id is registered
				game.print(">>>>> Game Id has not been set, DO IT REFEREE (please) !", {r = 225, g = 11, b = 11})
				return
			end
			
			if not global.match_running then --First unfreeze meaning match is starting
				global.match_running=true 
				game.print(">>>>> Match is starting shortly. Good luck !", {r = 11, g = 255, b = 11})
			end  	
			--global.reroll_left=0		-- Match has started, no more reroll -> changed via match_running (so wee save #rerolls for export stats)
			global.freeze_players = false
			if global.match_countdown < 0 then -- First unfreeze depends on init, then we use 3 seconds timer (after pause)
				global.match_countdown = 3
			end
			draw_manager_gui(player)
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
	--EVL SET THE TEAM NAMES
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
	--EVL SET THE GAME ID CLICK
	if player.gui.center["custom_game_id_gui"] then
		if name == "custom_game_id_gui_set" then
			local game_id = player.gui.center["custom_game_id_gui"].children[1].text
			--local force_name = player.gui.center["custom_game_id_gui"].children[1].name
			set_custom_game_id(player,game_id)
			player.gui.center["custom_game_id_gui"].destroy()
			draw_manager_gui(player)
			return
		end
		if name == "custom_game_id_gui_close" then
			player.gui.center["custom_game_id_gui"].destroy()
			draw_manager_gui(player)
			return
		end
	end	

end

return Public
