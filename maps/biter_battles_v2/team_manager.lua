local Public = {}
local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Sendings_Patterns = require "maps.biter_battles_v2.sendings_tab" --EVL (none)
local Terrain = require "maps.biter_battles_v2.terrain" --EVL (none)
local feed_the_biters = require "maps.biter_battles_v2.feeding" --EVL to use with config training > single sending

local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}
local colorAdmin="#FFBB77"
local colorSpecGod="#FF9955"

--EVL list of player of a force  (plus specgod if force=spectator)
local function get_player_array(force_name)
	local a = {}	
	for _, p in pairs(game.forces[force_name].connected_players) do 
		local _name=p.name
		--EVL We add admin tag to the list (so we see easily who is admin)
		if p.admin then _name="[color="..colorAdmin.."]".._name.."[/color]:A" end
		a[#a + 1] = _name
	end
	if force_name=="spectator" and game.forces["spec_god"] then --add spec-gods if we have any
		for _, p in pairs(game.forces["spec_god"].connected_players) do 
			local _name=p.name
			--EVL We add admin tag to the list (so we see easily who is admin)
			if p.admin then _name="[color="..colorSpecGod.."]".._name.."[/color]:G"
			else name="[color="..colorSpecGod.."]".._name.."[/color]:?" end
			a[#a + 1] = _name
		end
		
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
	--if global.bb_debug then game.print("Debug: Players and Biters are frozen (Team_manager).") end
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
	--if global.bb_debug then game.print("Debug: Players and Biters are unfrozen (Team_manager).") end
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
			game.print(">>>>> BBC ALERT : Player " .. _player_name .. " is Admin and should not be switched into a team (unless training or scrim mode).", {r=0.98, g=0.77, b=0.77})
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

function Public.draw_pause_toggle_button(player)
	if player.gui.top["team_manager_pause_button"] then player.gui.top["team_manager_pause_button"].destroy() end	
	local _caption="Pause"
	local _tooltip="Spam [font=default-bold]pp[/font] in chat so admin will pause the game\n  [font=default-small][color=#999999](while chat still active, use it wisely).[/color][/font]"
	if game.tick_paused==true then
		_caption="UnPause"
		_tooltip="UnPause the game after a 3s countdown (referee/admin)"
	end
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_pause_button", caption = _caption, tooltip = _tooltip })
	button.style.font = "heading-2"
	button.style.font_color = {r = 0.11, g = 0.55, b = 0.88}
	button.style.minimal_height = 38
	button.style.minimal_width = 60
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end
--EVL Add a pause button with countdown in TOP gui
function switch_pause_toggle_button(admin)
	local _caption="Pause"
	local _tooltip="Spam [font=default-bold]pp[/font] in chat so admin will pause the game\n  [font=default-small][color=#999999](while chat still active, use it wisely).[/color][/font]"
	local _color={r = 0.11, g = 0.55, b = 0.88}
	if game.tick_paused==true then
		if global.freeze_players==false then game.print(">>>>> Unexpected value (false) for global.freeze_players", {r = 11, g = 255, b = 11}) return end		
		game.tick_paused=false
		game.print(">>>>> Game unpaused by "..admin.name..". Match will resume very shortly !", {r = 11, g = 255, b = 11})
		global.freeze_players = false
		global.match_countdown = 3
		--Public.unfreeze_players() is done in main.lua after countdown
	else --game.tick_paused=false
		if not global.match_running then
			admin.print(">>>>> Game has not started ! You can't pause ;)", {r = 175, g = 11, b = 11}) 
			return
		end
		if global.match_countdown >= 0 then
			--admin.print(">>>>> Game has not yet (re)started ! You can't pause ;)", {r = 175, g = 11, b = 11}) 
			admin.print(">>>>> Please wait "..(global.match_countdown+1).."s (game is currently in ~unfreezing~ process) ...", {r = 175, g = 11, b = 11})
			return
		end
		if global.freeze_players==true then game.print(">>>>> Unexpected value (true) for global.freeze_players", {r = 11, g = 255, b = 11}) return end
		global.freeze_players = true
		Public.freeze_players()
		game.print(">>>>> Game paused by "..admin.name..". Players & Biters have been frozen !", {r = 111, g = 111, b = 255}) --EVL
		_caption="UnPause"
		_tooltip="UnPause the game after a 3s countdown (referee/admin)"
		game.tick_paused=true
		_color={r = 0.11, g = 0.88, b = 0.55}
	end
	--Redraw buttons for all players
	for _, player in pairs(game.connected_players) do	
		if player.gui.top["team_manager_pause_button"] then player.gui.top["team_manager_pause_button"].destroy() end	
		local button = player.gui.top.add({type = "sprite-button", name = "team_manager_pause_button", caption = _caption, tooltip = _tooltip })
		button.style.font = "heading-2"
		button.style.font_color = _color
		button.style.minimal_height = 38
		button.style.minimal_width = 80
		button.style.top_padding = 2
		button.style.left_padding = 0
		button.style.right_padding = 0
		button.style.bottom_padding = 2
	end
end

local function draw_manager_gui(player)
	if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams    [font=default-small][color=#999999]Please don't spam me[/color][/font]", direction = "vertical"})

	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local _maxim="Click to customize team name\n".."<<Put the maxim here>>" --TODO--
			local _nb_force_players=#game.forces[forces[i2].name].connected_players
			if forces[i2].name == "spectator" then 
				_maxim="Whoever assists as a spectator sees clearly,\nwhoever takes sides is led astray."
				if game.forces["spec_god"] then
					_nb_force_players = _nb_force_players + #game.forces["spec_god"].connected_players
				end
			end
			
			local l = t.add({type = "sprite-button", 
				caption = string.upper(forces[i2].name).." (".. _nb_force_players ..")",
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
			--get_player_array add spec-god players to spectator list
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
	local tnote=frame.add({type = "label", caption = "Note : [color="..colorAdmin.."]Only[/color] Referee and Streamers should be admins,               >>>>> use [color=#EEEEEE]/promote[/color] and.or [color=#EEEEEE]/demote[/color]\n"
														.."Players, Coach/Substitute and Spectators should [color="..colorAdmin.."]NOT[/color] be admins"})
	tnote.style.single_line = false
	tnote.style.font = "default-small"
	tnote.style.font_color = {r = 150, g = 150, b = 150}
	--local tnote=frame.add({type = "label", caption = "Players, Coach/Substitute and Spectators should [color="..colorAdmin.."]NOT[/color] be admins"})
	--tnote.style.font = "default-small"
	--tnote.style.font_color = {r = 150, g = 150, b = 150}
	
	frame.add({type = "label", caption = ""})
	
	--EVL Button for Reroll
		local t = frame.add({type = "table", name = "team_manager_reroll_buttons", column_count = 6})
		
		if global.match_running or global.reroll_left < 1 then 
			local tt = t.add({type = "label", caption = "NO MORE REROLL AVAILABLE,\nMATCH HAS TO BE PLAYED ON THIS MAP !                                       "})
			tt.style.single_line = false
			tt.style.font = "heading-2"
			tt.style.font_color = {r = 250, g = 250, b = 250}
			
		else
			local tt = t.add({type = "label", caption = "CLICK TO REROLL ("..global.reroll_left.." left) :"})
			tt.style.font = "heading-2"
			tt.style.font_color = {r = 200, g = 200, b = 200}
			local buttonrr = t.add({type = "button",	name = "team_manager_reroll", caption = "REROLL MAP", tooltip = "No roll back !"})
			buttonrr.style.font = "heading-1"
			buttonrr.style.font_color = {r = 10, g = 10, b = 10}
			local tt = t.add({type = "label", caption = " <--- up to team\n~AtHome~ choice        "})
			tt.style.single_line = false
			tt.style.font = "heading-3"
			tt.style.font_color = {r = 180, g = 180, b = 180}

		end
		
		--EVL BUTTON FOR GAME ID
		local _game_id = "GAME_ID"
		if 	global.game_id then _game_id =	global.game_id end
		local buttonid = t.add({type = "button",	name = "team_manager_gameid", caption = _game_id, tooltip = "Please fill up the Game ID before match can start\n>type 'scrim' for scrim or show match\n>type 'training' for training mode"})
		buttonid.style.font = "heading-2"
		if 	global.game_id then 
			buttonid.style.font_color = {r = 22, g = 111, b = 22}
		else
			buttonid.style.font_color = {r = 222, g = 22, b = 22}
		end
		buttonid.style.width = 100
				
		--EVL BUTTON PROCEDURE TO START A GAME
		local _space_ = t.add({type = "label", caption = "               "})
		local buttonproc = t.add({type = "button",	name = "team_manager_procedure", caption = "?", tooltip = "Read the procedure to start an official match,\n or a scrim/training game"})
		buttonproc.style.font = "heading-1"
		buttonproc.style.font_color = {r = 122, g = 22, b = 22}
		buttonproc.style.padding = -1
		buttonproc.style.width = 30


			
	frame.add({type = "label", caption = ""})
	--EVL Buttons for packs 	--game.print("###:"..Tables.packs_total_nb)
	local t = frame.add({type = "table", name = "team_manager_pack_buttons", column_count = Tables.packs_total_nb+1})
	local tt = t.add({type = "label", caption = "STARTER: "})
	tt.style.font = "heading-2"
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
	local t = frame.add({type = "table", name = "team_manager_bottom_buttons", column_count = 5})	
	local button = t.add({type = "button", name = "team_manager_close", caption = "Close", tooltip = "Close this window."})
	button.style.font = "heading-2"
	
	if global.tournament_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Enabled",
			tooltip = "Only admins can move players and vote for difficulty.\nActive players can no longer go spectate.\nNew joining players are spectators."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Disabled",
			tooltip = "Only admins can move players.\nActive players can no longer go spectate.\nNew joining players are spectators."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
	end
	button.style.font = "heading-2"
	
	if global.freeze_players then
		local caption_tmp="Unfreeze (Unpause)" --EVL
		local tooltip_tmp="[color=#55FF55]Release all players and biters,[/color]"
		local color_tmp = {r = 0, g = 127, b = 0}
		if not global.match_running then --EVL first UNFREEZE = Starting match
			caption_tmp="START & UNFREEZE"
			tooltip_tmp=tooltip_tmp.."\n [color=#FF5555]Once started, settings will be locked,[/color]\n[font=default-small][color=#999999](players can still be switched)[/color][/font]."
			if global.pack_choosen == "" then color_tmp = {r = 222, g = 22, b = 22} end
			button = t.add({
				type = "button",
				name = "team_manager_freeze_players",
				caption = caption_tmp,
				tooltip = tooltip_tmp
			})
			button.style.font_color = color_tmp
		
		else --EVL deactivation of button once match has started (match paused)
			button = t.add({
				type = "button",
				name = "team_manager_freeze_players_deactivated",
				--caption = "Freeze (Pause)",
				caption = "Match paused",
				--tooltip = "[color=#5555FF]Freeze players and biters,[/color]\n[color=#FF5555]avoid using[/color] [color=#5555FF]FREEZE[/color] [color=#FF5555]when attacks are in progress,[/color]\n[font=default-small][color=#999999](cause turrets will keep shooting)[/color][/font]."
				tooltip = "[color=#5555FF]Use ~UNPAUSE~ button in top Gui[/color]\n[font=default-small][color=#999999](admin/referee only, type pp in chat to ask for pause)[/color][/font]"
			})
			--button.style.font_color = {r = 55, g = 55, b = 222}
			button.style.font_color = {r = 222, g = 22, b = 22}
		end
	else --EVL deactivation of button once match has started (match running)
		button = t.add({
			type = "button",
			name = "team_manager_freeze_players_deactivated",
			--caption = "Freeze (Pause)",
			caption = "Match running",
			--tooltip = "[color=#5555FF]Freeze players and biters,[/color]\n[color=#FF5555]avoid using[/color] [color=#5555FF]FREEZE[/color] [color=#FF5555]when attacks are in progress,[/color]\n[font=default-small][color=#999999](cause turrets will keep shooting)[/color][/font]."
			tooltip = "[color=#5555FF]Use ~PAUSE~ button in top Gui[/color]\n[font=default-small][color=#999999](admin/referee only, type pp in chat to ask for pause)[/color][/font]"
		})
		--button.style.font_color = {r = 55, g = 55, b = 222}
		button.style.font_color = {r = 222, g = 22, b = 22}
	end
	button.style.font = "heading-2"
	
	if global.training_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Activated",
			tooltip = "Feed your own team's biters, auto-training, limit waves, pattern-training\nClick on [img=item.iron-gear-wheel] to set parameters."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
		button.style.font = "heading-2"
		--EVL Add button for managing training mode
		button = t.add({type = "button",	name = "team_manager_config_training", caption = "[img=item.iron-gear-wheel]", tooltip = "Config training mode" })
		button.style.font = "heading-2"	
		button.style.width = 50
		
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Disabled",
			tooltip = "Feed your own team's biters and\nonly teams with players gain threat & evo."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
		button.style.font = "heading-2"
	end
	
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
local function set_custom_game_id(player,gameid)
	
	if not gameid then 
		global.game_id=nil
		return 
	end
	--Set global.game_id to train if needed
	if gameid=="training" then 
		if not global.training_mode then game.print(">>>>> Training Mode has been enabled.", {r = 11, g = 192, b = 11}) end
		global.game_id="training" --EVL Add special GAME_ID if training mode
		global.training_mode = true
		global.game_lobby_active = false
		return
	end
	--Set global.game_id to scrim for 3v3 training, show match etc...
	if gameid=="scrim" then 
		if global.training_mode then game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11}) end
		global.game_id="scrim" --EVL Add special GAME_ID if scrim/showmatch
		global.training_mode = false
		global.game_lobby_active = true
		return
	end	
	--We are not in training or scrim mode, check validity of game_id
	if global.training_mode then game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11}) end
	global.training_mode = false
	global.game_lobby_active = true
	local _game_id=tonumber(gameid)
	if not _game_id then 
		global.game_id=nil
		player.print("ID:"..gameid.." is not a number, pleasy retry.",{r = 175, g = 11, b = 11})
		return 
	end
	if (_game_id<1000) or math.floor(_game_id%123) ~= 0 then 
		global.game_id=nil
		player.print("ID:".._game_id.." is not valid, pleasy retry.",{r = 175, g = 11, b = 11})
		return
	end
	global.game_id=_game_id
	game.print(">>>>> Game_ID has been registered by "..player.name,{r = 11, g = 222, b = 11})
end
-- EVL ADD A TEXTFIELD TO SET GAME ID
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

--WE ADD A WINDOW TO HELP REFEREE WITH PROCEDURE
local function procedure_game_gui(player)
	
	if player.gui.center["procedure_game"] then player.gui.center["procedure_game"].destroy() return end	
	
	local frame = player.gui.center.add({type = "frame", name = "procedure_game", caption = "How to use the team manager in BBC", direction = "vertical"})
	--local frame = frame.add {type = "frame", direction = "vertical"}				
	local _text = "[font=default-bold][color=#FF9740]While not automatic (todo), you need to fill up the settings and \n switch the players manually\n       >>>       go to website to get the parameters.[/color][/font]"
	_text=_text.."\n\n"
	_text=_text.."[font=default-bold]Starting procedure : [/font]\n"
	_text=_text.."0/ Start with a fresh map with the command <</starting-sequence>>\n"
	_text=_text.."1/ Ask team at HOME for the rerolls (up to twice)\n"
	_text=_text.."2/ Set league [font=default-bold][color=#5555FF]Biter[/color][/font] | [font=default-bold][color=#55FF55]Behemoth[/color][/font] via the top button (right to Manager).\n"
	_text=_text.."3/ Ask team at HOME for SIDE (north | south) and STARTER PACK.\n"
	_text=_text.."4/ <</demote>> Players and Spys, <</promote>> Streamers.\n"
	_text=_text.."   [font=default-small][color=#999999]Note: when match has finished, give back permissions[/color][/font]\n"	
	_text=_text.."5/ Switch 3 players to each side, spy stays as spectator.\n"
	_text=_text.."6/ Set the team names by clicking on [font=default-bold][color=#2222FF]NORTH[/color][/font] and [font=default-bold][color=#CC2222]SOUTH[/color][/font].\n"
	_text=_text.."7/ Set the Game Id (must be [color=#55FF55]green[/color]).\n"
	_text=_text.."8/ [font=default-bold]When everything is set, [color=#55FF55]double check[/color] before starting the game.[/font]\n\n"
	_text=_text.."9/ [color=#33DD33]START & UNFREEZE[/color] when both teams are ready (5 minutes max).\n"
	_text=_text.."\n"
	_text=_text.."Players ask for [font=default-bold]Pause[/font] with 'pp' in chat, use top button to switch [color=#5555FF]Pause[/color]/[color=#55FF55]UnPause[/color].\n"
	_text=_text.."\n"
	_text=_text.."- Training mode must be [color=#FF5555]DISABLED[/color] unless :\n"
	_text=_text.."   [font=default-small][color=#999999]Set GAME_ID to [/color][color=#55FF55]scrim[/color][color=#999999] for showmatch/scrims, "
	_text=_text.."or [/color][color=#55FF55]training[/color][color=#999999] for training mode.[/color][/font]\n"	
	_text=_text.."   [font=default-small][color=#999999]Note: on training mode, teams send potions to themselves.[/color][/font]\n"
	_text=_text.."   [font=default-small][color=#999999]Also: config training mode by clicking on [item=iron-gear-wheel] button.[/color][/font]\n"
	--_text=_text.."[font=default-bold][color=#FF9740]AFTER THE MATCH :[/color][/font]"
	--_text=_text.." - Report the results on the Website (using GameID),\n"
	--_text=_text.."                                       - Upload and Set the url of the replay."

	local l = frame.add({ type = "label", caption = _text, name = "procedure_game_text" })	

	l.style.single_line = false
	l.style.font = "default"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}	
		
	frame.add { type = "line", caption = "this line", direction = "horizontal" }
	local t = frame.add({type = "table", name = "procedure_game_table", column_count = 2})	
	local l = t.add({ type = "label", caption = "                                               "})
	local button = t.add({
			type = "button",
			name = "procedure_game_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
end

--CONSTRUCT TOOLTIP WITH ALL SENDINGS FROM A PATTERN
local function build_tooltip_pattern(pattern)		
	local _tooltip = "[font=default-bold][color=#FFFFFF]"..pattern["Team"].."[/color][/font] with "..Tables.packs_list[pattern["Pack"]].caption.." Pack :"
					.."\n [font=default-small][color=#999999]"..pattern["Info"].."[/color][/font]"
					.." [font=default-small][color=#999999]vs "..pattern["Versus"].."[/color][/font]"
					.." [font=default-small][color=#999999]on "..pattern["Date"].."[/color][/font]\n"
	--Can't make 2 columns (tooltip is limited in width)
	for _time,_sendings in pairs(pattern["Pattern"]) do
		--local _nb_sendings=#_sendings/2
		if #_sendings>0 and #_sendings%2==0 then
			if _time == 999 then
				_tooltip = _tooltip.."        [font=default-bold]then[/font] ► "
			elseif _time<10 then
				_tooltip = _tooltip.."    min 0".._time.." ► "
			else
				_tooltip = _tooltip.."    min ".._time.." ► "
			end

			for _i=1,#_sendings,2 do
				--game.print( _sendings[_i].."  -  ".. _sendings[_i+1].."  -  "..Tables.food_short_to_long[_sendings[_i]])
				if _sendings[_i] and _sendings[_i+1] and Tables.food_short_to_long[_sendings[_i]] then
					local _food=_sendings[_i]
					local _qtity=_sendings[_i+1]
					_tooltip = _tooltip.._qtity.." [item="..Tables.food_short_to_long[_food].."]    "
				else
					game.print(">>>>> Error : Pattern #".. gameId .." is badly formatted (skipped)",{r = 175, g = 25, b = 25})
				end
			end
			_tooltip = _tooltip.."\n"
		else
			game.print(">>>>> Error : Pattern #".. gameId .." has odd parameters (skipped).",{r = 175, g = 25, b = 25})
		end
	end
	_tooltip = _tooltip.."[font=default-small][color=#999999](this last qtity will be sent every min after min "..pattern["Last"]..")[/color][/font]"
	return _tooltip
end	
----CONSTRUCT GUI WITH ALL SENDINGS FROM A PATTERN "ctg_" ie "config_training_gui"
local function build_gui_pattern(player, gameId, pattern)
	
	if player.gui.center["ctg_pattern"] then player.gui.center["ctg_pattern"].destroy() end	
	local frame = player.gui.center.add({type = "frame", name = "ctg_pattern", caption = "[font=default-bold]Full list of sendings[/font] [font=default][color=#999999](pattern #"..gameId..")[/color][/font]", direction = "vertical"})
	
	local _global_info1 = "Executed by [font=default-bold][color=#AAAAFF]"..pattern["Team"].."[/color][/font] with "..Tables.packs_list[pattern["Pack"]].caption.." Pack :"
	local _global_info2 = "[font=default-bold][color=#AAAAFF]"..pattern["Info"].."[/color][/font]"
					.." [font=default][color=#CCCCCC]vs "..pattern["Versus"].."[/color][/font]"
					.." [font=default][color=#CCCCCC]on "..pattern["Date"].."[/color][/font]\n"
	frame.add({ type = "label", caption = _global_info1})
	frame.add({ type = "label", caption = _global_info2})
	local _total_sendings=table_size(pattern["Pattern"])
	
	local _max_lines=25 --maximum lines for 1080p resolution
	local _tot_column=math.ceil(_total_sendings/_max_lines) --so we need this nb columns
	_max_lines=math.ceil(_total_sendings/_tot_column) --equalization of columns height
	
	--game.print("send=".._total_sendings.." line=".._max_lines.."col=".._tot_column)
	local _table_details=frame.add {type = "table", name = "ctg_pattern_table", column_count = _tot_column*2}
	_table_details.vertical_centering=false
	
	local _line=0
	local _column=1
	local _table_column=_table_details.add {type = "table", column_count = 1}

	for _time,_sendings in pairs(pattern["Pattern"]) do
		--local _nb_sendings=#_sendings/2
		local _cell_str=""
		if #_sendings>0 and #_sendings%2==0 then
			if _time == 999 then
				_cell_str = _cell_str.."  [font=default-bold]then[/font] ►"
			elseif _time<10 then
				_cell_str = _cell_str.."0".._time.."m ►"
			else
				_cell_str = _cell_str.."".._time.."m ►"
			end

			for _i=1,#_sendings,2 do
				--game.print( _sendings[_i].."  -  ".. _sendings[_i+1].."  -  "..Tables.food_short_to_long[_sendings[_i]])
				if _sendings[_i] and _sendings[_i+1] and Tables.food_short_to_long[_sendings[_i]] then
					local _food=_sendings[_i]
					local _qtity=_sendings[_i+1]
					_cell_str = _cell_str.." ".._qtity.." [item="..Tables.food_short_to_long[_food].."],"
				else
					game.print(">>>>> Error : Pattern #".. gameId .." is badly formatted (skipped)",{r = 175, g = 25, b = 25})
				end
			end
			_cell_str = string.sub(_cell_str,1,string.len(_cell_str)-1)
			if _line==_max_lines then
				_table_details.add({ type = "label", caption = "  "})
				_table_column=_table_details.add {type = "table", column_count = 1}
				_table_column.add({ type = "label", caption = _cell_str })
				_line=1
				_column=_column+1
				
			else
				--game.print(_column.."-".._line)
				_table_column.add({ type = "label", caption = _cell_str })
				_line=_line+1
			end
			
		else
			game.print(">>>>> Error : Pattern #".. gameId .." has odd parameters (skipped).",{r = 175, g = 25, b = 25})
		end
	end

	--LAST QTITY (maintain pressure) & CLOSE WINDOW
	local _table_end=frame.add {type = "table", column_count = 2}
	_table_end.add({ type = "label", caption = "[font=default-small][color=#999999](the last qtity will be sent every min after min "..pattern["Last"]..")[/color][/font]                           "})

	local button = _table_end.add({
			type = "button",
			name = "ctg_pattern_close_button",
			caption = "     Close details     ",
			tooltip = "Close this window."
		})
	--button.style.font = "heading-2"
	button.style.font_color = {r=0.40, g=0, b=0}
	button.style.height = 20
	button.style.top_padding = -5
	button.style.horizontal_align = "center"
end


-- NEW GUI FOR CONFIG TRAINING SETTINGS (single sending, automatic sendings, limit groups, simulate past game)
local function config_training_gui(player)
	
	if player.gui.center["config_training"] then player.gui.center["config_training"].destroy() return end	
	
	local frame = player.gui.center.add({type = "frame", name = "config_training", caption = "Configure training mode  [font=default-small][color=#999999](admin only)[/color][/font]", direction = "vertical"})
	local _simul_tooltip="Simulate pattern from previous game\n[font=default-bold][color=#FF9740]Important:[/color][/font] your sendings will feed opponent's biters, not yours\n ie you really fight against "
	------------------	
	--NORTH SETTINGS--
	------------------
	frame.add({ type = "label", 
		caption = "[font=default-bold][color=#FF9740]NORTH Settings[/color][/font]  [color=#999999](these will send science[/color] [color=#FF3333]to[/color] [color=#999999]north)[/color]" })
	local north_training= frame.add {type = "table", name = "north_config_training", column_count = 5}
	--
	--SELECT SINGLE/UNIQUE SENDING
	--
	north_training.add({ type = "label", caption = "Single sending :" })
	
	local north_send_food = north_training.add { name = "north_send_food", type = "drop-down", items = Tables.food_config_training, selected_index = 1 }
	north_send_food.style.height = 20
	north_send_food.style.top_padding = -6
	north_send_food.style.vertical_align = 'top'
	
	local north_send_qtity = north_training.add { name = "north_send_qtity", type = "drop-down", items = Tables.qtity_config_training, selected_index = 1 }
	north_send_qtity.style.height = 20
	north_send_qtity.style.top_padding = -6
	north_send_qtity.style.vertical_align = 'top'
	
	north_training.add({ type = "label", caption = " " })
	
	local north_send_button = north_training.add { name = "north_send_button", type = "button",	caption = "Send",	tooltip = "Send one batch of science to north_biters." }
	north_send_button.style.height = 20
	north_send_button.style.top_padding = -6
	north_send_button.style.vertical_align = 'top'
	north_send_button.style.width = 65
	north_send_button.style.font = "default-bold"
	north_send_button.style.font_color = {r=0, g=0.35, b=0}
	--
	--SELECT AUTOMATIC SENDINGS
	--
	north_training.add({ type = "label", caption = "Automatic sendings :" })
	--Set the selected indexes to values from automatic sendings if active
	local selected_food=1
	local selected_qtity=1
	local selected_timing=1
	if global.auto_training["north"]["active"] then
		for _index_food=1,7,1 do
			--game.print(global.auto_training["north"]["science"].."  -  "..Tables.food_long_and_short[_index_food].long_name)
			if global.auto_training["north"]["science"]==Tables.food_long_and_short[_index_food].long_name then
				selected_food=_index_food+2
				break
			end
		end
		for _index_qtity,_qtity in pairs(Tables.qtity_config_training) do
			if global.auto_training["north"]["qtity"]==_qtity then
				selected_qtity=_index_qtity
				break
			end
		end		
		for _index_timing,_ in pairs(Tables.timing_config_training) do
			if global.auto_training["north"]["timing"]==(_index_timing-2) then
				selected_timing=_index_timing
				break
			end
		end
	end
	
	local north_training_food = north_training.add { name = "north_training_food", type = "drop-down", items = Tables.food_config_training, selected_index = selected_food }
	north_training_food.style.height = 20
	north_training_food.style.top_padding = -6
	north_training_food.style.vertical_align = 'top'
	
	local north_training_qtity = north_training.add { name = "north_training_qtity", type = "drop-down", items = Tables.qtity_config_training, selected_index = selected_qtity }  
	north_training_qtity.style.height = 20
	north_training_qtity.style.top_padding = -6
	north_training_qtity.style.vertical_align = 'top'
	
	local north_training_timing = north_training.add { name = "north_training_timing", type = "drop-down", items = Tables.timing_config_training, selected_index = selected_timing }  
	north_training_timing.style.height = 20
	north_training_timing.style.top_padding = -6
	north_training_timing.style.vertical_align = 'top'
	
	local north_training_button = north_training.add { name = "north_training_button", type = "button",	caption = "Apply",	tooltip = "Will send ## of science every xx minutes to self (north_biters)." }
	north_training_button.style.height = 20
	north_training_button.style.vertical_align = 'top'
	north_training_button.style.top_padding = -6
	north_training_button.style.width = 65
	north_training_button.style.font = "default-bold"
	north_training_button.style.font_color = {r=0, g=0.35, b=0}
	--
	--SELECT NUMBER OF GROUPS ATTACKING EVERY 2 MIN
	--
	north_training.add({ type = "label", caption = "             Limit number" })
	north_training.add({ type = "label", caption = " of groups attacking every" })
	north_training.add({ type = "label", caption = "two minutes :" })
	--Set the selected index to number from wave sendings if active
	local selected_number=1
	if global.wave_training["north"]["active"] then
		selected_number=global.wave_training["north"]["number"]+2
	end
	local north_waves_qtity = north_training.add { name = "north_waves_qtity", type = "drop-down", items = Tables.waves_config_training, selected_index = selected_number }
	north_waves_qtity.style.height = 20
	north_waves_qtity.style.top_padding = -6
	north_waves_qtity.style.vertical_align = 'top'
	north_waves_qtity.style.width = 135
	
	local north_waves_button = north_training.add { name = "north_waves_button", type = "button",	caption = "Set",	tooltip = "Will send ## groups every 2 min (unless insufficient threat)." }
	north_waves_button.style.height = 20
	north_waves_button.style.top_padding = -6
	north_waves_button.style.vertical_align = 'top'
	north_waves_button.style.width = 65
	north_waves_button.style.font = "default-bold"
	north_waves_button.style.font_color = {r=0, g=0.35, b=0}
	--
	-- SELECT A PATTERN FOR SIMULATION
	--
	north_training.add({ type = "label", caption = "         Currently using" })
	local _caption_ngp="[color=#999999](no pattern active)[/color]"
	local _tooltip_ngp=""
	if global.pattern_training["north"]["active"] then
		_caption_ngp="pattern [color=#88FF88]#"..global.pattern_training["north"]["gameid"].."[/color]"
		_tooltip_ngp=build_tooltip(Sendings_Patterns.detail_game_id[global.pattern_training["north"]["gameid"]])
	end
	north_training.add({ name = "north_gameid_pattern", type = "label", caption = _caption_ngp, tooltip = _tooltip_ngp })
	north_training.add({ type = "label", caption = "Change to pattern :" })
	
	local north_pattern_gameid = north_training.add { name = "north_pattern_gameid", type = "drop-down", items = Sendings_Patterns.list_game_id, selected_index = 1 }
	north_pattern_gameid.style.height = 20
	north_pattern_gameid.style.top_padding = -6
	north_pattern_gameid.style.vertical_align = 'top'
	
	local north_pattern_button = north_training.add { name = "north_pattern_button", type = "button",	caption = "Use",	tooltip = _simul_tooltip.."South." }
	north_pattern_button.style.height = 20
	north_pattern_button.style.top_padding = -6
	north_pattern_button.style.vertical_align = 'top'
	north_pattern_button.style.width = 65
	north_pattern_button.style.font = "default-bold"
	north_pattern_button.style.font_color = {r=0, g=0.35, b=0}
		--
	frame.add { type = "line", caption = "this line", direction = "horizontal" }
	
	-------------------
	--SOUTH SETTINGS --
	-------------------
	
	frame.add({ type = "label", 
		caption = "[font=default-bold][color=#FF9740]SOUTH Settings[/color][/font]  [color=#999999](these will send science[/color] [color=#FF3333]to[/color] [color=#999999]south)[/color]" })
	local south_training= frame.add {type = "table", name = "south_config_training", column_count = 5}
	--
	--SELECT SINGLE/UNIQUE SENDING
	--
	south_training.add({ type = "label", caption = "Single sending :" })
	
	local south_send_food = south_training.add { name = "south_send_food", type = "drop-down", items = Tables.food_config_training, selected_index = 1 }
	south_send_food.style.height = 20
	south_send_food.style.top_padding = -6
	south_send_food.style.vertical_align = 'top'
	
	local south_send_qtity = south_training.add { name = "south_send_qtity", type = "drop-down", items = Tables.qtity_config_training, selected_index = 1 }
	south_send_qtity.style.height = 20
	south_send_qtity.style.top_padding = -6
	south_send_qtity.style.vertical_align = 'top'
	
	south_training.add({ type = "label", caption = " " })
	
	local south_send_button = south_training.add { name = "south_send_button", type = "button",	caption = "Send",	tooltip = "Send one batch of science to south_biters." }
	south_send_button.style.height = 20
	south_send_button.style.top_padding = -6
	south_send_button.style.vertical_align = 'top'
	south_send_button.style.width = 65
	south_send_button.style.font = "default-bold"
	south_send_button.style.font_color = {r=0, g=0.35, b=0}
	--
	--SELECT AUTOMATIC SENDINGS
	--
	south_training.add({ type = "label", caption = "Automatic sendings :" })
	--Set the selected indexes to values from automatic sendings if active
	local selected_food=1
	local selected_qtity=1
	local selected_timing=1
	if global.auto_training["south"]["active"] then
		for _index_food=1,7,1 do
			--game.print(global.auto_training["north"]["science"].."  -  "..Tables.food_long_and_short[_index_food].long_name)
			if global.auto_training["south"]["science"]==Tables.food_long_and_short[_index_food].long_name then
				selected_food=_index_food+2
				break
			end
		end
		for _index_qtity,_qtity in pairs(Tables.qtity_config_training) do
			if global.auto_training["south"]["qtity"]==_qtity then
				selected_qtity=_index_qtity
				break
			end
		end		
		for _index_timing,_ in pairs(Tables.timing_config_training) do
			if global.auto_training["south"]["timing"]==(_index_timing-2) then
				selected_timing=_index_timing
				break
			end
		end
	end
	
	local south_training_food = south_training.add { name = "south_training_food", type = "drop-down", items = Tables.food_config_training, selected_index = selected_food }  
	south_training_food.style.height = 20
	south_training_food.style.top_padding = -6
	south_training_food.style.vertical_align = 'top'
	
	local south_training_qtity = south_training.add { name = "south_training_qtity", type = "drop-down", items = Tables.qtity_config_training, selected_index = selected_qtity }  
	south_training_qtity.style.height = 20
	south_training_qtity.style.top_padding = -6
	south_training_qtity.style.vertical_align = 'top'
	
	local south_training_timing = south_training.add { name = "south_training_timing", type = "drop-down", items = Tables.timing_config_training, selected_index = selected_timing }  
	south_training_timing.style.height = 20
	south_training_timing.style.top_padding = -6
	south_training_timing.style.vertical_align = 'top'
	
	local south_training_button = south_training.add { name = "south_training_button", type = "button",	caption = "Apply",	tooltip = "Will send ## of science every xx minutes to self (south_biters)." }
	south_training_button.style.height = 20
	south_training_button.style.vertical_align = 'top'
	south_training_button.style.top_padding = -6
	south_training_button.style.width = 65
	south_training_button.style.font = "default-bold"
	south_training_button.style.font_color = {r=0, g=0.35, b=0}
	--
	--SELECT NUMBER OF GROUPS ATTACKING EVERY 2 MIN
	--
	south_training.add({ type = "label", caption = "             Limit number" })
	south_training.add({ type = "label", caption = " of groups attacking every" })
	south_training.add({ type = "label", caption = "two minutes :" })
	--Set the selected index to number from wave sendings if active
	local selected_number=1
	if global.wave_training["south"]["active"] then
		selected_number=global.wave_training["south"]["number"]+2
	end
	local south_waves_qtity = south_training.add { name = "south_waves_qtity", type = "drop-down", items = Tables.waves_config_training, selected_index = selected_number }
	south_waves_qtity.style.height = 20
	south_waves_qtity.style.top_padding = -6
	south_waves_qtity.style.vertical_align = 'top'
	south_waves_qtity.style.width = 135
	
	local south_waves_button = south_training.add { name = "south_waves_button", type = "button",	caption = "Set",	tooltip = "Will send ## groups every 2 min (unless insufficient threat)." }
	south_waves_button.style.height = 20
	south_waves_button.style.top_padding = -6
	south_waves_button.style.vertical_align = 'top'
	south_waves_button.style.width = 65
	south_waves_button.style.font = "default-bold"
	south_waves_button.style.font_color = {r=0, g=0.35, b=0}
	--
	-- SELECT A PATTERN FOR SIMULATION
	--
	south_training.add({ type = "label", caption = "         Currently using" })
	local _caption_ngp="[color=#999999](no pattern active)[/color]"
	local _tooltip_ngp=""
	if global.pattern_training["south"]["active"] then
		_caption_ngp="pattern [color=#88FF88]#"..global.pattern_training["south"]["gameid"].."[/color]"
		_tooltip_ngp=build_tooltip(Sendings_Patterns.detail_game_id[global.pattern_training["south"]["gameid"]])
	end
	south_training.add({ name = "south_gameid_pattern", type = "label", caption = _caption_ngp, tooltip = _tooltip_ngp})
	south_training.add({ type = "label", caption = "Change to pattern :" })
	
	local south_pattern_gameid = south_training.add { name = "south_pattern_gameid", type = "drop-down", items = Sendings_Patterns.list_game_id, selected_index = 1 }
	south_pattern_gameid.style.height = 20
	south_pattern_gameid.style.top_padding = -6
	south_pattern_gameid.style.vertical_align = 'top'
	
	local south_pattern_button = south_training.add { name = "south_pattern_button", type = "button",	caption = "Use",	tooltip = _simul_tooltip.."North."}
	south_pattern_button.style.height = 20
	south_pattern_button.style.top_padding = -6
	south_pattern_button.style.vertical_align = 'top'
	south_pattern_button.style.width = 65
	south_pattern_button.style.font = "default-bold"
	south_pattern_button.style.font_color = {r=0, g=0.35, b=0}
	
	frame.add { type = "line", caption = "this line", direction = "horizontal" }

	---------------------
	--LIST OF PATTERNS --
	---------------------
	frame.add({ type = "label", caption = "[font=default-bold][color=#FF9740]LIST OF PATTERNS[/color][/font]  [font=default-small][color=#999999](hover to see full details)[/color][/font]" })
	local pattern_training= frame.add {type = "table", name = "pattern_training", column_count = 6}

	for gameId, pattern in pairs(Sendings_Patterns.detail_game_id) do
		local _caption = "[font=default-bold][color=#FFFFFF]"..gameId.."[/color][/font] by "..pattern["Team"].." : [font=default-small][color=#999999]"..pattern["Info"].."[/color][/font]"
		if global.pattern_training["north"]["active"] and global.pattern_training["north"]["gameid"]==gameId then
			_caption = "[font=default-bold][color=#4444FF]"..gameId.."[/color][/font] by [color=#44FF44]"..pattern["Team"].."[/color] : [font=default-small][color=#999999]"..pattern["Info"].."[/color][/font]"
		elseif global.pattern_training["south"]["active"] and global.pattern_training["south"]["gameid"]==gameId then
			_caption = "[font=default-bold][color=#FF4444]"..gameId.."[/color][/font] by [color=#44FF44]"..pattern["Team"].."[/color] : [font=default-small][color=#999999]"..pattern["Info"].."[/color][/font]"
		end

		local _tooltip = build_tooltip_pattern(pattern)		
		if #pattern["Pattern"]>30 then --If pattern is very long, we open a gui table;  "training_cpd_" ie "training_config_pattern_detail"
			local detail_button = pattern_training.add({ type = "button", name="training_cpd_"..gameId, caption = " ", tooltip = "[color=#22BB22]Open full listing of this pattern.[/color]"})
			detail_button.style.height = 10
			detail_button.style.width = 10
		else
			pattern_training.add({ type = "label", caption = " "})
		end
		pattern_training.add({ type = "label", caption = _caption, tooltip = _tooltip })
		pattern_training.add({ type = "label", caption = "     "})
	end
	--CLOSE WINDOW
	pattern_training.add({ type = "label", caption = "  "})
	local button = pattern_training.add({
			type = "button",
			name = "config_training_close_button",
			caption = "     Back to team manager     ",
			tooltip = "Close this window (without saving parameters)."
		})
	button.style.font_color = {r=0.40, g=0, b=0}
	button.style.height = 20
	button.style.top_padding = -5
	button.style.horizontal_align = "center"
end

--EVL SINGLE/UNIQUE SENDING FROM CONFIG TRAINING
local function training_single_sending(player, food_index, qtity_index, force)

	if food_index==1 or food_index==2 then player.print(">>>>> Single sending : Choose science first.", {r = 175, g = 11, b = 11}) return end
	food_index=food_index-2 --first 2 index are not science pack[i]
	local _food=Tables.food_long_and_short[food_index].long_name
	
	if qtity_index==1 or qtity_index==2 then player.print(">>>>> Single sending : Choose quantity first.", {r = 175, g = 11, b = 11}) return end
	local _qtity=Tables.qtity_config_training[qtity_index] -- no offset
	
	feed_the_biters(player, _food, _qtity, force.."_biters")	
	game.print("Single sending : [font=default-bold][color=#FFFFFF]".._qtity.."[/color][/font] flasks of [color="..Tables.food_values[_food].color.."]" .. Tables.food_values[_food].name .. "[/color]"
				.."[img=item/".. _food.. "] sent to [font=default-bold][color=#FFFFFF]"..force.."-biters[/color][/font] by [color=#AAAAAA]"..player.name.."[/color]", {r = 77, g = 192, b = 192})
	return
end
--EVL AUTOMATIC SENDINGS FROM CONFIG TRAINING
local function training_auto_sendings(player, food_index, qtity_index, timing_index, force)

	if food_index==2 or qtity_index==2 or timing_index==2 then -- Set autosending to OFF
		global.auto_training[force]={["player"]="",["active"]=false,["qtity"]=0,["science"]="",["timing"]=0}
		player.gui.center["config_training"][force.."_config_training"][force.."_training_food"].selected_index=1
		player.gui.center["config_training"][force.."_config_training"][force.."_training_qtity"].selected_index=1
		player.gui.center["config_training"][force.."_config_training"][force.."_training_timing"].selected_index=1		
		game.print(">>>>> Auto-training mode canceled/deactivated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side", {r = 77, g = 192, b = 192})	
		return 
	end
	
	if food_index==1 then player.print(">>>>> Choose science first.", {r = 175, g = 11, b = 11}) return end
	food_index=food_index-2 --first 2 index are not science pack[i]
	local _food=Tables.food_long_and_short[food_index].long_name

	if qtity_index==1 then player.print(">>>>> Choose quantity first.", {r = 175, g = 11, b = 11}) return end
	local _qtity=Tables.qtity_config_training[qtity_index] --no offset
	
	if timing_index==1 then player.print(">>>>> Choose timing first.", {r = 175, g = 11, b = 11}) return end
	local _timing=timing_index-2 --first 2 index are not timings
	--OK WE HAVE ALL WE NEED
	
	-- DEACTIVATE SIMULATION : incompatibility between auto-training and pattern-training (simulation)
	if global.pattern_training[force]["active"] then
		game.print(">>>>> Deactivation of Pattern-training (ie simulation), incompatible with auto-training.", {r = 125, g = 100, b = 100})
		global.pattern_training[force] = {["player"]="",["active"]=false,["gameid"]=0}
		
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].caption="[color=#999999](no pattern active)[/color]"
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].tooltip=""
		player.gui.center["config_training"][force.."_config_training"][force.."_pattern_gameid"].selected_index=1
	end	
	
	-- SET auto-training parameters
	global.auto_training[force]={["player"]=player.name,["active"]=true,["qtity"]=_qtity,["science"]=_food,["timing"]=_timing}
	game.print(">>>>> Auto-training mode activated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side : [font=default-large-bold][color=#FFFFFF]"
				.._qtity.."[/color][/font] flasks of [img=item/".. _food.. "] [color="..Tables.food_values[_food].color.."]".._food.."[/color] will be sent every [font=default-large-bold][color=#FFFFFF]".._timing.."[/color][/font] minute(s).", {r = 77, g = 192, b = 192})
	if not global.match_running then 
		game.print(">>>>> Auto-training mode : Sendings will start after game has started", {r = 77, g = 192, b = 192})
	end
	return
end
--EVL LIMIT GROUPS FROM CONFIG TRAINING
local function training_limit_groups(player, qtity_index, force)

	if qtity_index==1 then -- DEACTIVATE LIMIT GROUPS
		global.wave_training[force]={["player"]="",["active"]=false,["number"]=0}
		game.print(">>>>> Wave-training mode canceled/deactivated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side. Back to random(3,6).", {r = 77, g = 192, b = 192})		
	else --ACTIVATE LIMIT GROUPS
		local _qtity=qtity_index-2 --offset from drop-down (including 0 group)
		global.wave_training[force]={["player"]=player.name,["active"]=true,["number"]=_qtity}
		game.print(">>>>> Wave-training mode activated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] : [font=default-large-bold][color=#FFFFFF]".._qtity
			.."[/color][/font] wave(s) of biters will attack [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side every [font=default-large-bold][color=#FFFFFF]2[/color][/font] minutes.", {r = 77, g = 192, b = 192})
	end
	return

end
--EVL SIMULATE PREVIOUS GAME (PATTERN) FROM CONFIG TRAINING
local function training_simul_pattern(player, gameid_index, force)
	if gameid_index==1 then 
		player.print(">>>>> Choose pattern/ gameID first.", {r = 175, g = 11, b = 11})	
		return
	elseif gameid_index==2 then --DEACTIVATE SIMULATOR
		global.pattern_training[force]={["player"]="",["active"]=false,["gameid"]=0}
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].caption="[color=#999999](no pattern active)[/color]"
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].tooltip=""
		
		game.print(">>>>> Wave-training mode canceled/deactivated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side.", {r = 77, g = 192, b = 192})		
		return
	else --ACTIVATE SIMULATOR
		local _game_id=Sendings_Patterns.list_game_id[gameid_index]
		global.pattern_training[force]={["player"]=player.name,["active"]=true,["gameid"]=_game_id}
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].caption="pattern [color=#88FF88]#".._game_id.."[/color]"
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].tooltip=build_tooltip(Sendings_Patterns.detail_game_id[_game_id])

		-- BUT DEACTIVATE AUTO-TRAINING : incompatibility between auto-training and pattern-training (simulation)
		if global.auto_training[force]["active"] then
			game.print(">>>>> Deactivation of Auto-training, incompatible with pattern-training (ie simulation).", {r = 125, g = 100, b = 100})
			global.auto_training[force] = {["player"]="",["active"]=false,["qtity"]=0,["science"]="",["timing"]=0}
			player.gui.center["config_training"][force.."_config_training"][force.."_training_food"].selected_index=1
			player.gui.center["config_training"][force.."_config_training"][force.."_training_qtity"].selected_index=1
			player.gui.center["config_training"][force.."_config_training"][force.."_training_timing"].selected_index=1
		end	
	
		game.print(">>>>> Simulation activated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] with Pattern #[font=default-large-bold][color=#FFFFFF]".._game_id
			.."[/color][/font] (ie gameID) by [color=#FFFFFF]"..Sendings_Patterns.detail_game_id[_game_id]["Team"].."[/color] : [color=#AAAAAA]"..Sendings_Patterns.detail_game_id[_game_id]["Info"].."[/color].", {r = 77, g = 192, b = 192})
	end
	return

end

local function team_manager_gui_click(event)

	local player = game.players[event.player_index]
	local name = event.element.name

	if game.forces[name] then
		if not player.admin then player.print(">>>>> Only admins can change team names.", {r = 175, g = 11, b = 11}) return end
		custom_team_name_gui(player, name)
		player.gui.center["team_manager_gui"].destroy()
		return
	end

	if name == "team_manager_gameid" then
		if not player.admin then player.print(">>>>> Only admins can set the Game Identificator.", {r = 175, g = 11, b = 11}) return end
		if global.match_running then player.print(">>>>> Cannot modify GameId after match has started (contact website admin).", {r = 175, g = 11, b = 11}) return end
		player.gui.center["team_manager_gui"].destroy()
		custom_game_id_gui(player)
		return
	end	
	if name == "team_manager_procedure" then
		if not player.admin then player.print(">>>>> Only admins can learn the procedure.", {r = 175, g = 11, b = 11}) return end
		procedure_game_gui(player)
		return
	end	
	
	--EVL CONFIG TRAINING MODE
	if name == "team_manager_config_training" then
		--if not player.admin then player.print(">>>>> Only admins can open config training mode.", {r = 175, g = 11, b = 11}) return end
		--everyone can see the training config but only admins can use it
		player.gui.center["team_manager_gui"].destroy()
		config_training_gui(player)
		return
	end	
	--EVL END OF CONFIG TRAINING MODE
	
	if name == "team_manager_close" then
		player.gui.center["team_manager_gui"].destroy()	
		return
	end
	
	if name == "team_manager_activate_tournament" then --EVL Only tournament mode, cant be disabled
		if not player.admin then player.print("Only admins can switch tournament mode.", {r = 175, g = 11, b = 11}) return end
		if true then
			game.print(">>>>>  Tournament mode must stay activated in BBC", {r = 175, g = 11, b = 11}) --EVL
			return --EVL
		end
		if global.tournament_mode then
			global.tournament_mode = false
			draw_manager_gui(player)
			game.print(">>> Tournament Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.tournament_mode = true
		draw_manager_gui(player)
		game.print(">>> Tournament Mode has been enabled!", {r = 175, g = 11, b = 11})
		return
	end
	
	--EVL Reroll
	if name == "team_manager_reroll" then
		if not player.admin then player.print(">>>>> Only admins can reroll the map.", {r = 175, g = 11, b = 11}) return end
		global.reroll_do_it = true --EVL global_reroll_left decreased if main
		global.freeze_players = true
		--draw_manager_gui(player)
		player.gui.center["team_manager_gui"].destroy()	
		game.print(">>>> Admin "..player.name.." asked for map reroll - Please wait...", {r = 175, g = 11, b = 11})
		return
	end
	--EVL Reroll
	--EVL Packs
	local pack=string.sub(name,0,5)
	if pack=="pack_" then
		if not player.admin then player.print(">>>>> Only admins can choose the starter pack.", {r = 175, g = 11, b = 11}) return end
		if global.match_running then -- No more changing, game has started
			player.print(">>>>> Pack cannot be changed after the match has started !", {r = 175, g = 11, b = 11})
			return
		end
		if global.fill_starter_chests then -- Chests are not filled yet, cant change pack
			player.print(">>>>> Chests are in filling sequence, please wait...", {r = 175, g = 11, b = 11})
			return
		end
		if not global.pack_choosen or global.pack_choosen=="" then 
			global.pack_choosen = name
			game.print(">>>>> Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name].caption .." has been chosen !", {r = 11, g = 225, b = 11})
			global.fill_starter_chests = true
		else 
			global.pack_choosen = name
			game.print(">>>>> Pack has been changed to Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name]["caption"] .." !", {r = 175, g = 11, b = 11})
			global.fill_starter_chests = true
		end
		draw_manager_gui(player)
		return
	end
	--EVL PACK FIN
	
	
	if name == "team_manager_freeze_players" then -- NO MORE FREEZE/UNFREEZE, only START MATCH
		if not player.admin then player.print(">>>>> Only admins can switch freeze mode.", {r = 175, g = 11, b = 11}) return end
		if global.bb_game_won_by_team then player.print(">>>>> You cannot switch freeze mode after match has finished.", {r = 175, g = 11, b = 11}) return end
		
		if global.freeze_players then --EVL Players are frozen
			if global.pack_choosen == "" then -- EVL dont start without pack choosen
				game.print(">>>>> A pack must be choosen before starting the game / unfreezing the players !", {r = 175, g = 11, b = 11})
				return
			end
			if global.reroll_do_it then -- EVL dont start if reroll is on the way
				game.print(">>>>> Reroll is not done yet, retry in a second...", {r = 175, g = 11, b = 11})
				return
			end			
			if not global.starter_chests_are_filled then -- EVL dont start before starter packs are filled
				game.print(">>>>> Starter Packs are not filled yet, retry in a second...", {r = 175, g = 11, b = 11})
				return
			end
			if not global.game_id then -- EVL dont start before game_id is registered (or ='training')
				game.print(">>>>> Game Id has not been set, DO IT REFEREE (please) !", {r = 175, g = 11, b = 11})
				return
			end
			--draw_manager_gui(player) -- Will be destroyed when starting match NOT NEEDED AT ALL?
			if not global.match_running then --First unfreeze meaning match is starting
				global.match_running=true 
				 
				global.bb_threat["north_biters"] = 9 --EVL we start at threat=9 to avoid weird sendings at the beginning
				global.bb_threat["south_biters"] = 9 
				game.surfaces[global.bb_surface_name].daytime = 0.6 -- we set time to dawn
				game.print(">>>>> Match is starting shortly. Good luck ! Have Fun !", {r = 11, g = 255, b = 11})
				if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
			end  	
			--global.reroll_left=0		-- Match has started, no more reroll -> changed via match_running (so wee save #rerolls for export stats)
			--section below is deactivated, should not happen (see draw_manager_gui)
			global.freeze_players = false
			if global.match_countdown < 0 then -- First unfreeze depends on init, then we use 3 seconds timer (after pause)
				global.match_countdown = 3
				game.print(">>>>> Match will resume very shortly !", {r = 11, g = 255, b = 11})
				if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
			end
			
			return
		end
		--ELSE  global.freeze_players==false
		--section below is deactivated, should not happen (see draw_manager_gui)
		--CODING-- remove all this could interact with new pause button
		--EVL We're PAUSING the game, no change in global.match_running nor in global.pack_choosen (the game was initiated with global.freeze_players=true)
		
		if global.match_countdown >= 0 then --WAIT FOR UNFREEZE BEFORE FREEZE AGAIN
			game.print(">>>>> Please wait "..(global.match_countdown+1).."s (game is currently in ~unfreezing~ process) ...", {r = 175, g = 11, b = 11})
			return
		end
		global.freeze_players = true
		Public.freeze_players()
		draw_manager_gui(player)
		game.print(">>>>> Players & Biters have been frozen !", {r = 111, g = 111, b = 255}) --EVL
		--game.tick_paused=true --EVL New way to freeze game (way better : craft, factory, research, everything is frozen but chat stay active) not accurate now
		--But need to type command /c game.tick_paused=false in chat to resume... not accurate now
		return
	end
	
	if name == "team_manager_activate_training" then 
		if not player.admin then player.print(">>>>> Only admins can switch training mode.", {r = 175, g = 11, b = 11}) return end
		if global.match_running then player.print(">>>>> Cannot modify Game Mode [training] after match has started.", {r = 175, g = 11, b = 11}) return end
		if global.training_mode then
			global.training_mode = false
			global.game_lobby_active = true
			global.game_id=nil --EVL Remove GAME_ID if not training mode
			draw_manager_gui(player)
			game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11})
			return
		end
		global.training_mode = true
		global.game_lobby_active = false
		global.game_id="training" --EVL Add special GAME_ID if training mode
		draw_manager_gui(player)
		game.print(">>>>> Training Mode has been enabled!", {r = 11 , g = 225, b = 11})
		return
	end
	
	if not event.element.parent then return end
	local element = event.element.parent
	if not element.parent then return end
	local element = element.parent
	if element.name ~= "team_manager_root_table" then return end		
	if not player.admin then player.print(">>>>> Only admins can manage teams.", {r = 175, g =11, b = 11}) return end
	
	local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_" .. tonumber(name)]
	local selected_index = listbox.selected_index
	if selected_index == 0 then player.print("No player selected.", {r = 175, g = 11, b = 11}) return end
	local player_name = listbox.items[selected_index]
	
	local m = -1
	if event.element.caption == "→" then m = 1 end
	local force_name = forces[tonumber(name) + m].name
	
	--EVL We remove tag Admin before switching force (see get_player_array above)
	local _player_this=player_name
	if string.sub(_player_this,1,15) == "[color="..colorAdmin.."]" then
		_player_this=string.sub(_player_this,16,#_player_this-10)
	end
	if not game.players[_player_this] then game.print("Team Manager >> Player " .. _player_this .. " doesn't exist.", {r=0.98, g=0.66, b=0.22}) return end
	local _player = game.players[_player_this]
	if 	global.training_mode or global.game_id=="scrim" then -- in training or scrim mode, admins can be switched into teams
		switch_force(player_name, force_name)
	elseif _player.admin then -- not training or scrim mode, but admin, we cannot switch
		game.print(">>>>> BBC ALERT : Player " .. player_name .. " is Admin and cannot be switched into a team (unless training or scrim mode).", {r=0.98, g=0.77, b=0.77})
	else -- not training or scrim mode, not admin, we can switch
		switch_force(player_name, force_name)
	end
	-- if not global.training_mode and player_name.admin==true then
	--	game.print("NOPE")
	--else
		
	--end
	
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
	--EVL pause button
	if name == "team_manager_pause_button" then
		if not player.admin then player.print(">>>>> Ask referee/admin to pause/unpause the game.", {r = 175, g = 11, b = 11}) return end
		if global.bb_debug then game.print("DEBUG: Switching Pause/Unpause", {r = 175, g = 11, b = 11}) end
		switch_pause_toggle_button(player)
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
			local gameid = player.gui.center["custom_game_id_gui"].children[1].text
			--local force_name = player.gui.center["custom_game_id_gui"].children[1].name
			set_custom_game_id(player,gameid)
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
	--EVL CLOSE THE FRAME "LEARN HOW TO USE TEAM MANAGER"
	if player.gui.center["procedure_game"] then
		if name == "procedure_game_close" then
			player.gui.center["procedure_game"].destroy()
			return
		end
		if name == "procedure_game_text" then
			player.gui.center["procedure_game"].destroy()
			return
		end		
	end	
	--EVL CLOSE THE FRAME "CONFIG TRAINING"(without saving)
	if name == "config_training_close_button" then
		player.gui.center["config_training"].destroy()
		draw_manager_gui(player)
		return
	end	
	
	--EVL CONFIG TRAINING
	--Single sending
	if name == "north_send_button" then --Single sending to north_biters
		if not player.admin then player.print(">>>>> Only admins can use config training pane (single/north).", {r = 175, g = 11, b = 11}) return end
		if not global.match_running then player.print(">>>>> Cannot send flasks until match has started (north).", {r = 175, g = 11, b = 11}) return end
		local _food=player.gui.center["config_training"]["north_config_training"]["north_send_food"].selected_index
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_send_qtity"].selected_index
		training_single_sending(player, _food, _qtity, "north") --careful food&qtity are selected_index, not real values yet
		return
	end
	if name == "south_send_button" then --Single sending to south_biters
		if not player.admin then player.print(">>>>> Only admins can use config training pane (single/south).", {r = 175, g = 11, b = 11}) return end
		if not global.match_running then player.print(">>>>> Cannot send flasks until match has started (south).", {r = 175, g = 11, b = 11}) return end
		local _food=player.gui.center["config_training"]["south_config_training"]["south_send_food"].selected_index
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_send_qtity"].selected_index
		training_single_sending(player, _food, _qtity, "south") --careful food&qtity are selected_index, not real values yet
		return		
	end
	--Automatic sendings
	if name == "north_training_button" then --Automatic sending to north_biters
		if not player.admin then player.print(">>>>> Only admins can use config training pane (auto/north).", {r = 175, g = 11, b = 11}) return end
		local _food=player.gui.center["config_training"]["north_config_training"]["north_training_food"].selected_index
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_training_qtity"].selected_index
		local _timing=player.gui.center["config_training"]["north_config_training"]["north_training_timing"].selected_index   
		training_auto_sendings(player, _food, _qtity, _timing, "north") --careful food&qtity&timing are selected_index, not real values yet
		return		
	end
	if name == "south_training_button" then --Automatic sending to south_biters
		if not player.admin then player.print(">>>>> Only admins can use config training pane (auto/south).", {r = 175, g = 11, b = 11}) return end
		local _food=player.gui.center["config_training"]["south_config_training"]["south_training_food"].selected_index
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_training_qtity"].selected_index
		local _timing=player.gui.center["config_training"]["south_config_training"]["south_training_timing"].selected_index   
		training_auto_sendings(player, _food, _qtity, _timing, "south") --careful food&qtity&timing are selected_index, not real values yet
		return		
	end	
	--	Limit groups
	if name == "north_waves_button" then --Limit number of groups attacking every 2 min
		if not player.admin then player.print(">>>>> Only admins can use config training pane (groups/north).", {r = 175, g = 11, b = 11}) return end
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_waves_qtity"].selected_index
		training_limit_groups(player, _qtity, "north") --careful qtity is selected_index, not real value yet
		return		
	end		
	if name == "south_waves_button" then --Limit number of groups attacking every 2 min
		if not player.admin then player.print(">>>>> Only admins can use config training pane (groups/south).", {r = 175, g = 11, b = 11}) return end
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_waves_qtity"].selected_index
		training_limit_groups(player, _qtity, "south") --careful qtity is selected_index, not real value yet
		return		
	end	
	--	Simulate previous game (pattern)
	if name == "north_pattern_button" then --Limit number of groups attacking every 2 min
		if not player.admin then player.print(">>>>> Only admins can use config training pane (pattern/north).", {r = 175, g = 11, b = 11}) return end
		local _gameid=player.gui.center["config_training"]["north_config_training"]["north_pattern_gameid"].selected_index
		training_simul_pattern(player, _gameid, "north") --careful qtity is selected_index, not real value yet
		return		
	end		
	if name == "south_pattern_button" then --Limit number of groups attacking every 2 min
		if not player.admin then player.print(">>>>> Only admins can use config training pane (pattern/south).", {r = 175, g = 11, b = 11}) return end
		local _gameid=player.gui.center["config_training"]["south_config_training"]["south_pattern_gameid"].selected_index
		training_simul_pattern(player, _gameid, "south") --careful qtity is selected_index, not real value yet
		return		
	end	

	--EVL FULL LIST OF PATTERN FROM CONFIG TRAINING
	if string.sub(name,1,13) == "training_cpd_" then
		local _gameId=tonumber(string.sub(name,14))
		--game.print("gameId="..serpent.block(_gameId))
		if not(_gameId) or _gameId<=0 or not(Sendings_Patterns.detail_game_id[_gameId]) then
			game.print("WTF can't find gameId for full listing...")
			return
		else
			--player.gui.center["team_manager_gui"].destroy()
			--config_training_gui(player)
			--game.print("GameId=".._gameId)
			build_gui_pattern(player, _gameId, Sendings_Patterns.detail_game_id[_gameId])	
			return
		end
	end	
	
	--EVL CLOSE FULL LIST OF PATTERN FROM CONFIG TRAINING "ctg_" ie "config_training_gui"
	if name == "ctg_pattern_close_button" then
		player.gui.center["ctg_pattern"].destroy()
		--draw_manager_gui(player)
		return
	end	
end

return Public
