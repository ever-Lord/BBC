local Public = {}
local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Sendings_Patterns = require "maps.biter_battles_v2.sendings_tab" --EVL (none)
local Terrain = require "maps.biter_battles_v2.terrain" --EVL (none)
local feed_the_biters = require "maps.biter_battles_v2.feeding" --EVL to use with config training > single sending
local bb_config = require "maps.biter_battles_v2.config" --EVL need  bb_config.spawn_manager_pos to switch managers to their spot
local Score = require "comfy_panel.score" --EVL (none) used to init scores (so ne need to call init each time scores are used)
--local show_inventory = require 'modules.show_inventory_bbc' --EVL(none) used to close inventories opened when transfering inv from player disco --TODO--????
local Functions = require "maps.biter_battles_v2.functions" --EVL (none) used to find real number of players (ie removing manager if global.managers_in_team=true)

local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}
local colorAdmin="#FFBB77"
local colorSpecGod="#FF77BB"

--EVL list of player of a force  (plus specgod if force=spectator) (plus disconnected players)
local function get_player_array(force_name)
	local a = {}	
	--EVL had to rewrote loop with all players to find disconnected players in team north or south
	--(to get their inventory back ingame for substitute)
	for _, p in pairs(game.forces[force_name].players) do 
		local _name=p.name
		local _force=p.force.name
		--if player is manager, dont add to spectator list
		if p.connected then
			if _name==global.manager_table["north"] or _name==global.manager_table["south"] then
				--Dont add managers (see draw_manager_gui)
			else
				if p.admin then _name="[color="..colorAdmin.."]".._name.."[/color]:A" end
				a[#a + 1] = _name
			end
		else --player not connected
			if (force_name=="north" or force_name=="south") and (_force==force_name) then
				--Player is in a team but deconnected
				--game.print("debug:found disconnected player : ".._name.. "(force=".._force..")")
				a[#a + 1] = _name..":D"
			end	
		end
	end
	--Add Spec_gods to spectator list with tag :G (tag :? should never happen)
	if force_name=="spectator" and game.forces["spec_god"] and #game.forces["spec_god"].connected_players>0 then
		for _, p in pairs(game.forces["spec_god"].connected_players) do 
			local _name=p.name
			local _force=p.force.name
			--EVL Add spec-god tag to the list (to see easily who is in spec-god mode)
			if p.admin then _name="[color="..colorSpecGod.."]".._name.."[/color]:G"
			else name="[color="..colorSpecGod.."]".._name.."[/color]:?" end --should be always admin 
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
	if global.freezed_start ~= 999999999 then game.print("Debug: global.freezed_start <> 999999999(="..global.freezed_start..") in freeze_players") end --useless
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
	if global.difficulty_vote_index==1 then --EVL Set BluePrint authorisations
		--Biter league
		p.set_allows_action(defines.input_action.open_blueprint_library_gui, true)
		p.set_allows_action(defines.input_action.import_blueprint_string, true)
	else
		--Behemoth league
		p.set_allows_action(defines.input_action.open_blueprint_library_gui, false)
		p.set_allows_action(defines.input_action.import_blueprint_string, false)
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

local function get_all_inventories(player)

	--Store Main inventory
	--local inventory = player.get_inventory(defines.inventory.character_main).get_contents()
	local inventory = player.get_main_inventory().get_contents() --same as above
	
	--Work on real inventory
	local this_inventory = player.get_main_inventory()
	--now we remove everything but armors to make room before cancelling craftings
	for _item,_qty in pairs (inventory) do
		if not(_item=="modular-armor" or _item=="power-armor" or _item=="power-armor-mk2") then
			local tmp=this_inventory.remove({name=_item, count=_qty})
		end
	end

	--Get armor components (when armor is in inventory, ie not equiped. equiped armor is done below)
	if this_inventory.valid then
		for _,this_armor_name in pairs({"modular-armor","power-armor","power-armor-mk2"}) do
			local this_armor_qtity=this_inventory.get_item_count(this_armor_name)
			while this_armor_qtity>0 do
				local this_armor=this_inventory.find_item_stack(this_armor_name)
				if this_armor and this_armor.valid and this_armor.grid then
					if global.bb_debug_gui then game.print("DEBUGUI: armor grid valid "..this_armor_name.." (loop="..this_armor_qtity..")") end
					local components_inv=this_armor.grid.get_contents()
					if components_inv and table_size(components_inv)>0 then
						for _item,_qty in pairs(components_inv) do
							if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
						end
						this_armor.clear()
						this_inventory.remove(this_armor)
					end
				--else
					--dont care
				end
				this_armor_qtity=this_armor_qtity-1
			end --while this_armor_qtity>0
		end --for this_armor_name
	else 
		if global.bb_debug_gui then game.print("DEBUGUI: inventory not valid for "..player.name.." in get_all_inventories.") end
	end

	--Main inventory is empty, cancel craftings and hope there is no more than one inventory in ingredients of crafting list
	
	--Cancel crafting list (then need to count again ingredients that are back in inventory)
	--Bug if chest-plosion, items that cannot go back into inventory will be spilled on ground
	if player.crafting_queue_size>0 then
		while player.crafting_queue do
			--EVL Cancel crafting from right-to-left
			local this = player.crafting_queue[#player.crafting_queue]
			player.cancel_crafting({index=this.index, count=this.count})
		end
		--Store ingredients from main inventory
		local ingredients = player.get_main_inventory().get_contents() --same as above
		--now add ingredients to inventory
		for _item,_qty in pairs (ingredients) do
			if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
		end
	end

	--Cursor stack
	local cursor_stack = player.cursor_stack
	if cursor_stack and cursor_stack.count>0 then
		local _item=cursor_stack.name
		local _qty=cursor_stack.count
		if inventory[_item] then inventory[_item]=inventory[_item]+_qty else	inventory[_item]=_qty end
	end
	--Guns
	local guns_inventory = player.get_inventory(defines.inventory.character_guns).get_contents()
	if table_size(guns_inventory)>0 then
		for _item,_qty in pairs(guns_inventory) do
			if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
		end
	end
	--Ammunition
	local ammo_inventory = player.get_inventory(defines.inventory.character_ammo).get_contents()
	if table_size(ammo_inventory)>0 then			
		for _item,_qty in pairs(ammo_inventory) do
			if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
		end
	end
	--Armor & Components Note:if armor is in inventory components in grid will be lost
	local armor_inventory = player.get_inventory(defines.inventory.character_armor).get_contents()
	if table_size(armor_inventory)>0 then
		--THIS LOOP IS DONE ONLY ONCE (cant have two armors)
		for _item,_qty in pairs(armor_inventory) do
			--SO WE DONT CARE TO PUT THE GRID THING HERE			
			if player.get_inventory(5)[1].grid then
				local p_armor = player.get_inventory(5)[1].grid.get_contents()
				if table_size(p_armor)>0 then
					for _item,_qty in pairs(p_armor) do
						if inventory[_item] then
							inventory[_item]=inventory[_item]+_qty
						else
							inventory[_item]=_qty
						end
					end
				end
			--else
				--dont care
			end			
			if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
		end
	end
	--Trash slots
	local trash_inventory = player.get_inventory(defines.inventory.character_trash).get_contents()
	if table_size(trash_inventory)>0 then
		for _item,_qty in pairs(trash_inventory) do
			if inventory[_item] then inventory[_item]=inventory[_item]+_qty else inventory[_item]=_qty end
		end
	end
	--[[EVL NOT WORKING --DEBUG--
	--Vehicule slots
	game.print("get_all_inventories:vehicule")
	local in_vehicle = player.get_inventory(defines.inventory.character_vehicle)
	if in_vehicle then 
		local vehicle_inventory = player.get_inventory(defines.inventory.character_vehicle).get_contents()
		if table_size(vehicle_inventory)>0 then
			for _item,_qty in pairs(vehicle_inventory) do
				if inventory[_item] then
					inventory[_item]=inventory[_item]+_qty
				else
					inventory[_item]=_qty
				end
			end
		end
	end
	]]--
	--Anything else ???
	if global.bb_debug_gui then game.print("DEBUGUI: get_all_inventories("..player.name..") done: "..table_size(inventory).." items found.") end
	return inventory
end


local function leave_corpse(player)
	if not player.character then 
		--game.print("Debug: no character ! skip :-( (in leave corpse)")
		return 
	end
	
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
	local surface = game.surfaces[global.bb_surface_name]
	--EVL Is player disconnected ? -> going for substitution with manager ?
	-- will put his inventory in chest(s)
	local is_disconnected=false
	if string.sub(_player_name,-2)==":D" then
		is_disconnected=true
		_player_name=string.sub(_player_name,1,string.len(_player_name)-2)
	end
	--EVL We remove tag Admin before switching force (see get_player_array above)
	if string.sub(_player_name,1,15) == "[color="..colorAdmin.."]" then
		_player_name=string.sub(_player_name,16,#_player_name-10)
	end
	if not game.players[_player_name] then 
		if global.bb_debug_gui then 
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			game.print("DEBUGUI: in switch_force >> Player " .. _player_name .. " does not exist.", {r=0.98, g=0.66, b=0.22})
		end
		return 
	end
	if not game.forces[force_name] then 
		if global.bb_debug_gui then 
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			game.print("DEBUGUI: in switch_force >> Force " .. force_name .. " does not exist.", {r=0.98, g=0.66, b=0.22})
		end
		return 
	end
	
	local player = game.players[_player_name]
	local old_force=player.force.name
	--If player is disconnected, relocate inventory to chest at spawn
	if is_disconnected and (old_force=="north" or old_force=="south") then --testing old_force is unnecessary
		local inventory = get_all_inventories(player) --Main, cursor, crafting, ammo, gun, armor(s)(& components), trash, [vehicle not working]--TODO--
		if table_size(inventory)>0 then
			if global.bb_debug_gui then
				game.print("DEBUGUI: in switch_force disconnected player "..player.name.." will be switched to spectators, translocating his inventory to chests at spawn.", {r=0.98, g=0.66, b=0.22})
			end
			--Remove all items from this player (should be almost done : main inventory is almost cleared, only armor/guns/ammos/trash remaining plus craftings ingredients if any)
			player.clear_items_inside()
			--Transfer all inventories to chests
			Terrain.fill_disconnected_chests(surface, old_force, inventory, "inventory of disconnected player:"..player.name.." ("..old_force..") ")
		else
			game.print("Disconnected player: "..player.name.." will be switched (inventory is empty).", {r = 197, g = 197, b = 17})
		end
	end
	player.force = game.forces[force_name]
	--EVL SET UP Score table so we dont have to test it everytime in score.lua (save ups)
	if player.force.name=="north" or player.force.name=="south" then Score.init_player_table(player) end
	game.print(">>>>> ".._player_name.." has been switched into team "..force_name..".", {r=0.98, g=0.66, b=0.22})
	Server.to_discord_bold(_player_name.." has joined team "..force_name.. "!")
	
	if is_disconnected then --DEBUG-- look closer to this (will put a corpse is disco player is moved again to side)
		if player.character then 
			if global.bb_debug_gui then game.print("DEBUGUI: in switch_force: ".._player_name.." IS character. Is that OK ???", {r=0.98, g=0.66, b=0.22}) end
			--player.character.destroy()
			--player.character = nil
			--player.set_controller({type=defines.controllers.god})
			--player.create_character()
		else
			if global.bb_debug_gui then game.print("DEBUGUI: in switch_force: ".._player_name.." is NOT character. Is that OK ???", {r=0.98, g=0.66, b=0.22}) end
			--player.set_controller({type=defines.controllers.god})
			--player.create_character()
		end	
		--if player.character then player.character.destroy() end	
	else
		leave_corpse(player)
	end
	
	global.chosen_team[_player_name] = nil	
	if force_name == "spectator" then	
		spectate(player, old_force, true) -- Standard spectate
		Score.undo_init_player_table(player) -- clear score if game has not started
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
	else
		if player.admin then 
			game.print(">>>>> Alert : Player ".._player_name.." is Admin and should not be switched into a team (unless training or scrim mode).", {r=0.98, g=0.77, b=0.77})
		end
		join_team(player, force_name, true)
		if Functions.get_nb_players(force_name) > global.max_players then
			game.print(">>>>> Alert : Team "..force_name.." should NOT have more than "..global.max_players.." players !", {r=0.98, g=0.77, b=0.77})
		end
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
	end
	if global.bb_debug_gui then 
		game.print("DEBUGUI: "..Functions.get_nb_players("north").." player.s at north and "..Functions.get_nb_players("south").." player.s at south (in switch_force).")
	end

end
--EVL Draw team_manager button
function Public.draw_top_toggle_button(player)
	if player.gui.top["team_manager_toggle_button"] then player.gui.top["team_manager_toggle_button"].destroy() end	
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_toggle_button", caption = "Team Manager", tooltip = "Open team manager and set up official/scrim/training mode." })
	button.style.font = "heading-2"
	button.style.font_color = {r = 0.88, g = 0.55, b = 0.11}
	button.style.minimal_height = 38
	button.style.minimal_width = 120
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end

--EVL Draw game_type button (Official/training/Scrim)
local function create_game_type_button(player)
	if player.gui.top["bbc_game_type_button"] then player.gui.top["bbc_game_type_button"].destroy() end
	local game_type
	if global.game_id=="training" then game_type="Training"
	elseif global.game_id=="scrim" then game_type="Scrim"
	elseif global.game_id%123==0 then game_type="Official"
	else
		if global.bb_debug then game.print("Debug: Game_Id is inappropriate...  skipping") end
		return
	end
	local b = player.gui.top.add({type = "sprite-button", caption = game_type, name = "bbc_game_type_button"})
	b.style.font = "heading-1"
	b.style.horizontal_align = "center"
	b.style.font_color = {r=0.59, g=0.99, b=0.99}
	b.style.minimal_width = 80
	b.style.minimal_height = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

--EVL Add a pause button with countdown in TOP gui
local function draw_pause_toggle_button(player)
	if player.gui.top["team_manager_pause_button"] then player.gui.top["team_manager_pause_button"].destroy() end
	local _caption="Pause"
	local _tooltip="Spam [font=default-bold]pp[/font] in chat so admin will pause the game\n  [font=default-small][color=#999999](while chat still active, use it wisely).[/color][/font]"
	local _color={r = 0.11, g = 0.55, b = 0.88}
	if game.tick_paused==true then
		if global.cant_unpause then  --EVL Avoid double pause click (second one would engage unpause)
			_caption="Ready?"
			_tooltip="Click when you're ready to engage unpausing process."
			_color={r = 0.88, g = 0.55, b = 0.55}
		else
			_caption="UnPause"
			_tooltip="UnPause the game after a 3s countdown (referee/admin)"
			_color={r = 0.11, g = 0.88, b = 0.55}
		end
	end
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_pause_button", caption = _caption, tooltip = _tooltip })
	button.style.font = "heading-1"
	button.style.horizontal_align = "center"
	button.style.font_color = _color
	button.style.minimal_height = 38
	button.style.width = 80
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end

--EVL Toggle pause/unpause with countdown
local function switch_pause_toggle_button(admin)
	if game.tick_paused==true then
		if global.cant_unpause then  --EVL Avoid double pause click (second one would engage unpause)
			global.cant_unpause=false
			game.play_sound{path = global.sound_low_bip, volume_modifier = 1}
			game.print(">>>>> Game is set to ready for unpause (by "..admin.name..").", {r = 111, g = 111, b = 255})
			--Redraw button for all players
			for _, player in pairs(game.connected_players) do	
				draw_pause_toggle_button(player)
			end
			return
		end
		if global.freeze_players==false then game.print(">>>>> Unexpected value (false) for global.freeze_players", {r = 11, g = 255, b = 11}) return end		
		game.tick_paused=false
		game.print(">>>>> Game unpaused by "..admin.name..". Match will resume very shortly !", {r = 11, g = 255, b = 11})
		game.print(">>>>> Note/Bug : If you feel frozen, clic on map to unfreeze (sorry).", {r = 11, g = 255, b = 11})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		global.freeze_players = false
		global.match_countdown = 3
		--Public.unfreeze_players() is done in main.lua after countdown
	else --game.tick_paused=false
		if not global.match_running then
			admin.print(">>>>> Game has not started ! You can't pause ;)", {r = 175, g = 11, b = 11}) 
			admin.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if global.bb_game_won_by_team then
			admin.print(">>>>> Game has finished ! You can't pause ;)", {r = 175, g = 11, b = 11})
			admin.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if global.match_countdown >= 0 then
			admin.print(">>>>> Please wait "..(global.match_countdown+1).."s (game is currently in ~unfreezing~ process) ...", {r = 175, g = 11, b = 11})
			admin.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if global.freeze_players==true then 
			game.print(">>>>> Unexpected value (true) for global.freeze_players", {r = 11, g = 255, b = 11})
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		global.freeze_players = true
		Public.freeze_players()
		game.print(">>>>> Game paused by "..admin.name..". Players & Biters have been frozen !", {r = 111, g = 111, b = 255}) --EVL
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		game.tick_paused=true
		global.cant_unpause=true --EVL Avoid double pause click (second one would engage unpause)
		
	end
	--Redraw button for all players
	for _, player in pairs(game.connected_players) do	
		draw_pause_toggle_button(player)
	end
end

local function draw_manager_gui(player)
	if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams    [font=default-small][color=#999999]Please don't spam me[/color][/font]", direction = "vertical"})

	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	-------------------------------------------------
	--Title (north button / spectators / south button)
	-------------------------------------------------
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local _maxim="Click to customize team name\n"
			--Search for team name and maxim
			if global.tm_custom_name[forces[i2].name] then 
				local _team_name=global.tm_custom_name[forces[i2].name]
				_maxim = _maxim.." Team ".._team_name.."\n"
				if Tables.maxim_teams[_team_name] and Tables.maxim_teams[_team_name]~="" and Tables.maxim_teams[_team_name]~="tbd" then
					_maxim = _maxim.."[color=#AAAAAA]"..Tables.maxim_teams[_team_name].."[/color]"
				else
					_maxim = _maxim.."<<Put the maxim here>>"
				end
			end
			
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
	
	-------------------------------------------------
	-- Managers line
	-------------------------------------------------
	--If north manager or not :
	local manager_north_arrow="←"
	local manager_north="[color=#AAAAAA](no manager)[/color]"
	local manager_north_button="tm_north_manager_box_add"
	local manager_north_tooltip="Select a spectator then click to add as north manager."
	
	if global.manager_table["north"] then --TODO-- =nil in init
		manager_north_arrow="→" 
		manager_north="[color=#AAFFAA]"..global.manager_table["north"].."[/color]"
		local _player = game.players[global.manager_table["north"]]
		if _player.admin then manager_north=manager_north..":A" end
		manager_north_button="tm_north_manager_box_remove"
		manager_north_tooltip="Remove north manager, back to spectators."
	end
	--Manager
	local manager_north_box = t.add({type = "list-box", name = "tm_north_manager_box", items = {manager_north}  })
	manager_north_box.style.width = 160
	--Button	
	local north_manager_button = t.add({type = "sprite-button", name = manager_north_button, caption = manager_north_arrow, tooltip = manager_north_tooltip})
	north_manager_button.style.font = "heading-1"
	north_manager_button.style.maximal_height = 38
	north_manager_button.style.maximal_width = 38
	
	
	--Separator (spec column)
	local tt=t.add({type = "label", caption = "<<<   TEAM MANAGERS   >>>"})
	tt.style.font = "heading-2"
	--tt.style.horizontal_align="center"
	tt.style.font_color = {r = 111, g = 190, b = 111}

	--If north manager or not :
	local manager_south_arrow="→"
	local manager_south="[color=#AAAAAA](no manager)[/color]"	
	local manager_south_button="tm_south_manager_box_add"
	local manager_south_tooltip="Select a spectator then click to add as south manager."
	if global.manager_table["south"] then 
		manager_south_arrow="←"
		manager_south="[color=#AAFFAA]"..global.manager_table["south"].."[/color]"
		local _player = game.players[global.manager_table["south"]]
		if _player.admin then manager_south=manager_south..":A" end

		manager_south_button="tm_south_manager_box_remove"
		manager_south_tooltip="Remove south manager, back to spectators."
	end
	--Button
	local south_manager_button = t.add({type = "sprite-button", name = manager_south_button, caption = manager_south_arrow, tooltip = manager_south_tooltip})
	south_manager_button.style.font = "heading-1"
	south_manager_button.style.maximal_height = 38
	south_manager_button.style.maximal_width = 38
	--Manager
	local manager_south_box = t.add({type = "list-box", name = "tm_south_manager_box", items = {manager_south}  })
	manager_south_box.style.width = 160

	-------------------------------------------------
	-- Players (north/spec/south)
	-------------------------------------------------
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
			local b = tt.add({type = "sprite-button", name = i2 - 1, caption = "→"})--, tooltip="Move player to Spectators") --TODO--?
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
			local b = tt.add({type = "sprite-button", name = i2, caption = "←"})--, tooltip="Move player to Spectators") --TODO--?
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
		end		
	end
	
	
	-------------------------------------------------
	--EVL Infos, buttons, patcks etc. for BBChampions
	-------------------------------------------------
	local tnote=frame.add({type = "label", caption = "Note : [color="..colorAdmin.."]Only[/color] Referee and Streamers should be admins,               >>>>> use [color=#EEEEEE]/promote[/color] and.or [color=#EEEEEE]/demote[/color]\n"
														.."Players, Managers and Spectators should [color="..colorAdmin.."]NOT[/color] be admins"})
	tnote.style.single_line = false
	tnote.style.font = "default-small"
	tnote.style.font_color = {r = 150, g = 150, b = 150}
	
	frame.add({type = "label", caption = ""})
	-------------------------------------------------
	--EVL Button for Reroll
	-------------------------------------------------
	local t = frame.add({type = "table", name = "team_manager_reroll_buttons", column_count = 6})
	
	if global.match_running then 
		local tt = t.add({type = "label", caption = "MATCH HAS STARTED AFTER "..(global.reroll_max-global.reroll_left).." REROLL(S).                                              \n                    !!! ENJOY THE SHOW !!!"})
		tt.style.single_line = false
		tt.style.font = "heading-2"
		tt.style.font_color = {r = 250, g = 250, b = 250}
	elseif global.reroll_left < 1 then 
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
	-------------------------------------------------
	--EVL Buttons for packs 	--game.print("###:"..Tables.packs_total_nb)
	-------------------------------------------------
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

	-------------------------------------------------
	-- Bottom Buttons
	-------------------------------------------------
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
	
	-- Training toggle button + Config training mode button
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

function Public.redraw_all_team_manager_guis()
	for _, player in pairs(game.connected_players) do
		if player.gui.center["team_manager_gui"] then
			draw_manager_gui(player)
		end
	end

end

local function set_custom_team_name(force_name, team_name)
	if not team_name or team_name == "" then 
		global.tm_custom_name[force_name] = nil 
		if force_name=="north" then
			if global.manager_speaker["north_text"] and global.manager_speaker["north_text"]>0 then
				rendering.destroy(global.manager_speaker["north_text"])
			end
			if global.rocket_silo["north_logo"] and global.rocket_silo["north_logo"]>0 then
				rendering.destroy(global.rocket_silo["north_logo"])
			end
		elseif force_name=="south" then
			if global.manager_speaker["south_text"] and global.manager_speaker["south_text"]>0 then
				rendering.destroy(global.manager_speaker["south_text"])
			end
			if global.rocket_silo["south_logo"] and global.rocket_silo["south_logo"]>0 then
				rendering.destroy(global.rocket_silo["south_logo"])
			end
		else
			game.print(">>>>> Bug in set_custom_team_name (no force)")
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		return 
	end
	--if not team_name then global.tm_custom_name[force_name] = nil return end --EVL condition moved above
	global.tm_custom_name[force_name] = tostring(team_name)

	if force_name=="north" then
		if global.manager_speaker["north_text"] and global.manager_speaker["north_text"]>0 then
			rendering.destroy(global.manager_speaker["north_text"])
		end
		global.manager_speaker["north_text"]=rendering.draw_text {	--Add Team name above manager slot
					text = global.tm_custom_name["north"],
					surface = game.surfaces[global.bb_surface_name],
					target = {x = 0, y = -bb_config.spawn_manager_pos-6},
					target_offset = {0, -5.0},
					color = {88, 88, 255},
					scale = 3.00,
					font = "count-font",
					alignment = "center",
					scale_with_zoom = false,
					--forces = {game.forces["spectator"],game.forces["north"],game.forces["south"]}
			}
		if Tables.logo_teams[global.tm_custom_name["north"]] then
			if global.rocket_silo["north_logo"] and global.rocket_silo["north_logo"]>0 then
				rendering.destroy(global.rocket_silo["north_logo"])
			end
			global.rocket_silo["north_logo"]=rendering.draw_sprite{
				sprite="file/png/"..Tables.logo_teams[global.tm_custom_name["north"]],
				x_scale=1,
				y_scale=1,
				target=global.rocket_silo["north"], 
				target_offset={0, 0},
				surface=game.surfaces[global.bb_surface_name]
			}
			rendering.set_orientation(global.manager_speaker["north_text"],0)
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		else
			game.print(">>>>> Team "..global.tm_custom_name["north"].." is not known (spelling error?) or team has no logo.", {88, 88, 255})
			game.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		end

		
	elseif force_name=="south" then
		if global.manager_speaker["south_text"] and global.manager_speaker["south_text"]>0 then
			rendering.destroy(global.manager_speaker["south_text"])
		end
		global.manager_speaker["south_text"]=rendering.draw_text {
					text = global.tm_custom_name["south"],
					surface = game.surfaces[global.bb_surface_name],
					target = {x = 0, y = bb_config.spawn_manager_pos+3},
					target_offset = {0, 2.0},
					color = {200, 33, 33},
					scale = 3.00,
					font = "count-font",
					alignment = "center",
					scale_with_zoom = false
			}
		rendering.set_orientation(global.manager_speaker["south_text"],0)
		if Tables.logo_teams[global.tm_custom_name["south"]] then
			if global.rocket_silo["south_logo"] and global.rocket_silo["south_logo"]>0 then
				rendering.destroy(global.rocket_silo["south_logo"])
			end
			global.rocket_silo["south_logo"]=rendering.draw_sprite{
				sprite="file/png/"..Tables.logo_teams[global.tm_custom_name["south"]],
				x_scale=1,
				y_scale=1,
				target=global.rocket_silo["south"], 
				target_offset={0, 0},
				surface=game.surfaces[global.bb_surface_name]
			}
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		else
			game.print(">>>>> Team "..global.tm_custom_name["south"].." is not known (spelling error?) or team has no logo.", {200, 33, 33})
			game.play_sound{path = global.sound_low_bip, volume_modifier = 1}
		end			
	else
		game.print(">>>>> Error in set_custom_team_name (wrong force)")
		game.play_sound{path = global.sound_error, volume_modifier = 0.8}
	end

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
	if not gameid then global.game_id=nil return end
	--Set global.game_id to train if needed
	if gameid=="training" then 
		if global.game_id=="scrim" then game.print(">>>>> Scrim Mode has been disabled.", {r = 175, g = 11, b = 11}) end
		if not global.training_mode then game.print(">>>>> Training Mode has been enabled.", {r = 11, g = 192, b = 11}) end
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		global.game_id="training" --EVL Add special GAME_ID if training mode
		global.training_mode = true
		global.game_lobby_active = false
		return
	end
	--Set global.game_id to scrim for 3v3 training, show match etc...
	if gameid=="scrim" then 
		if global.training_mode then game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11}) end
		if global.game_id~="scrim" then game.print(">>>>> Scrim Mode has been enabled.", {r = 11, g = 192, b = 11}) end
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		global.game_id="scrim" --EVL Add special GAME_ID if scrim/showmatch
		global.training_mode = false
		global.game_lobby_active = true
		return
	end	
	--If was in scrim mode with admins, cannot switch to official mode
	if global.game_id=="scrim" then
		for _,force_name in pairs({"north","south"}) do
			for _, p in pairs(game.forces[force_name].connected_players) do
				if p.admin then 
					game.print(">>>>> Alert: Admin detected in team "..force_name..", <<scrim>> mode can't be disabled.", {r = 175, g = 11, b = 11})
					game.play_sound{path = global.sound_error, volume_modifier = 0.8}
					return
				end
			end
		end
		game.print(">>>>> Scrim Mode has been disabled.", {r = 175, g = 11, b = 11})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
	end
	--We are not in training or scrim mode, check validity of game_id
	local _game_id=tonumber(gameid)
	if not _game_id then 
		global.game_id=nil
		player.print("ID:"..gameid.." is not a number, pleasy retry.",{r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return 
	end
	if (_game_id<1000) or math.floor(_game_id%123) ~= 0 then 
		global.game_id=nil
		player.print("ID:".._game_id.." is not valid, pleasy retry.",{r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	-- Everything went fine, switch to official mode
	if global.training_mode then 
		game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
	end
	global.training_mode = false
	global.game_lobby_active = true
	global.game_id=_game_id
	game.print(">>>>> Game_ID has been registered by "..player.name,{r = 11, g = 222, b = 11})
	game.play_sound{path = global.sound_success, volume_modifier = 0.8}
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

-- EVL ADD A WINDOW TO HELP REFEREE WITH PROCEDURE
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
	_text=_text.."4/ <</demote>> Players and Managers, <</promote>> Streamers.\n"
	_text=_text.."   [font=default-small][color=#999999]Note: when match has finished, give back permissions[/color][/font]\n"	
	_text=_text.."5/ Switch 3 players to each side, switch managers to manager slots.\n"
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

-- EVL CONSTRUCT TOOLTIP WITH ALL SENDINGS FROM A PATTERN
local function build_tooltip_pattern(pattern)		
	local _tooltip = "[font=default-bold][color=#FFFFFF]"..pattern["Team"].."[/color][/font] with "..Tables.packs_list[pattern["Pack"]].caption.." Pack :"
	.."\n [font=default-small][color=#999999]"..pattern["Info"].." vs "..pattern["Versus"].." in "..pattern["Last"].." min, on "..pattern["Date"].."[/color][/font]\n"
	
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
-- EVL CONSTRUCT GUI WITH ALL SENDINGS FROM A PATTERN "ctg_" ie "config_training_gui"
local function build_gui_pattern(player, gameId, pattern)
	
	if player.gui.center["ctg_pattern"] then player.gui.center["ctg_pattern"].destroy() end	
	local frame = player.gui.center.add({type = "frame", name = "ctg_pattern", caption = "[font=default-bold]Full list of sendings[/font] [font=default][color=#999999](pattern #"..gameId..")[/color][/font]", direction = "vertical"})
	
	local _global_info1 = "Executed by [font=default-bold][color=#AAAAFF]"..pattern["Team"].."[/color][/font] with "..Tables.packs_list[pattern["Pack"]].caption.." Pack :"
	local _global_info2 = "[font=default-bold][color=#AAAAFF]"..pattern["Info"].."[/color][/font] [font=default-small][color=#999999]vs "..pattern["Versus"].." in "..pattern["Last"].." min, on "..pattern["Date"].."[/color][/font]\n"
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
	_table_end.add({ type = "label", caption = "[font=default-small][color=#999999](the last qtity will be sent every min after min "..pattern["Last"]..")[/color][/font]  "})

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
-- EVL CONSTRUCT GUI FRAME OF PATTERNS BY TEAM OR FOR ALL (in player.gui.center["config_training"]["patterns_gui"])
local function pattern_training_gui(frame)-- use global.pattern_team_select
	if frame then frame.clear() else return end	-- should not happen
	
	frame.add({ type = "label", caption = "[font=default-bold][color=#FF9740]LIST OF PATTERNS[/color][/font]  [font=default-small][color=#999999](hover to see full details)[/color][/font]" })
	local pattern_teams=frame.add {type = "table", name = "pattern_teams", column_count = table_size(Sendings_Patterns.list_teams)}
	for _,team_name in pairs(Sendings_Patterns.list_teams) do
		local button = pattern_teams.add({
				type = "button",
				name = "pattern_teams_"..string.gsub(team_name," ","_"),
				caption = " "..team_name.." ",
				tooltip = "Select only this team patterns."
			})
		if team_name==global.pattern_team_select then
			button.style.font_color = {r=0.05, g=.35, b=0.05}
		else
			button.style.font_color = {r=0.15, g=.15, b=0.15}
		end
		button.style.height = 20
		button.style.minimal_width = 40
		button.style.top_padding = -5
		button.style.horizontal_align = "center"
	end
	local _column_count=6
	if global.pattern_team_select == "All" then _column_count = 9 end
	local pattern_training= frame.add {type = "table", name = "pattern_training", column_count = _column_count}

	for gameId, pattern in pairs(Sendings_Patterns.detail_game_id) do
		if pattern["Team"]==global.pattern_team_select	 or global.pattern_team_select == "All" then
		
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
-- NEW GUI FOR CONFIG TRAINING SETTINGS (single sending, automatic sendings, limit groups, simulate past game)
local function config_training_gui(player)
	
	if player.gui.center["config_training"] then player.gui.center["config_training"].destroy() return end	
	
	local frame = player.gui.center.add({type = "frame", name = "config_training", caption = "Configure training mode  [font=default-small][color=#999999](admin only)[/color][/font]", direction = "vertical"})
	local _simul_tooltip="Simulate pattern from previous game\n[font=default-bold][color=#FF9740]Important:[/color][/font] your sendings will feed opponent's biters,\n not yours. Id est you really fight against "
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
	north_training.add({ type = "label", caption = "         Simulator using" })
	local _caption_ngp="[color=#999999](no pattern active)[/color]"
	local _tooltip_ngp=""
	if global.pattern_training["north"]["active"] then
		_caption_ngp="pattern [color=#88FF88]#"..global.pattern_training["north"]["gameid"].."[/color]"
		_tooltip_ngp=build_tooltip_pattern(Sendings_Patterns.detail_game_id[global.pattern_training["north"]["gameid"]])
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
	south_training.add({ type = "label", caption = "         Simulator using" })
	local _caption_ngp="[color=#999999](no pattern active)[/color]"
	local _tooltip_ngp=""
	if global.pattern_training["south"]["active"] then
		_caption_ngp="pattern [color=#88FF88]#"..global.pattern_training["south"]["gameid"].."[/color]"
		_tooltip_ngp=build_tooltip_pattern(Sendings_Patterns.detail_game_id[global.pattern_training["south"]["gameid"]])
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
	local patterns_gui = frame.add {type = "frame", name = "patterns_gui", direction = "vertical"}
	pattern_training_gui(patterns_gui)
end
--EVL SINGLE/UNIQUE SENDING FROM CONFIG TRAINING
local function training_single_sending(player, food_index, qtity_index, force)
	if food_index==1 or food_index==2 then 
		player.print(">>>>> Single sending : Choose science first.", {r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	food_index=food_index-2 --first 2 index are not science pack[i]
	local _food=Tables.food_long_and_short[food_index].long_name
	
	if qtity_index==1 or qtity_index==2 then 
		player.print(">>>>> Single sending : Choose quantity first.", {r = 175, g = 11, b = 11}) 
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return 
	end
	local _qtity=Tables.qtity_config_training[qtity_index] -- no offset
	
	game.print("Single sending : [font=default-bold][color=#FFFFFF]".._qtity.."[/color][/font] flasks of [color="..Tables.food_values[_food].color.."]" .. Tables.food_values[_food].name .. "[/color]"
				.."[img=item/".. _food.. "] sent to [font=default-bold][color=#FFFFFF]"..force.."-biters[/color][/font] by [color=#AAAAAA]"..player.name.."[/color]", {r = 77, g = 192, b = 192})
	feed_the_biters(player, _food, _qtity, force.."_biters")	
	player.play_sound{path = global.sound_success, volume_modifier = 0.8}
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
		player.play_sound{path = global.sound_success, volume_modifier = 0.8}
		return 
	end
	
	if food_index==1 then 
		player.print(">>>>> Choose science first.", {r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	food_index=food_index-2 --first 2 index are not science pack[i]
	local _food=Tables.food_long_and_short[food_index].long_name

	if qtity_index==1 then 
		player.print(">>>>> Choose quantity first.", {r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	local _qtity=Tables.qtity_config_training[qtity_index] --no offset
	
	if timing_index==1 then 
		player.print(">>>>> Choose timing first.", {r = 175, g = 11, b = 11})
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
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
	player.play_sound{path = global.sound_success, volume_modifier = 0.8}
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
	player.play_sound{path = global.sound_success, volume_modifier = 0.8}
	return
end
--EVL SIMULATE PREVIOUS GAME (PATTERN) FROM CONFIG TRAINING
local function training_simul_pattern(player, gameid_index, force)
	if gameid_index==1 then 
		player.print(">>>>> Choose pattern/ gameID first.", {r = 175, g = 11, b = 11})	
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	elseif gameid_index==2 then --DEACTIVATE SIMULATOR
		global.pattern_training[force]={["player"]="",["active"]=false,["gameid"]=0}
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].caption="[color=#999999](no pattern active)[/color]"
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].tooltip=""
		game.print(">>>>> Simulation mode canceled/deactivated by [font=default-large-bold][color=#FFFFFF]"..player.name.."[/color][/font] for [font=default-large-bold][color=#FFFFFF]"..force.."[/color][/font] side.", {r = 77, g = 192, b = 192})		
		player.play_sound{path = global.sound_success, volume_modifier = 0.8}
		return
	else --ACTIVATE SIMULATOR
		local _game_id=Sendings_Patterns.list_game_id[gameid_index]
		global.pattern_training[force]={["player"]=player.name,["active"]=true,["gameid"]=_game_id}
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].caption="pattern [color=#88FF88]#".._game_id.."[/color]"
		player.gui.center["config_training"][force.."_config_training"][force.."_gameid_pattern"].tooltip=build_tooltip_pattern(Sendings_Patterns.detail_game_id[_game_id])
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
		player.play_sound{path = global.sound_success, volume_modifier = 0.8}
	end
	return

end

local function team_manager_gui_click(event)

	local player = game.players[event.player_index]
	local name = event.element.name
	--game.print("event : "..name)

	if (name=="north" or name=="south") and game.forces[name] then --EVL do not change name of spectator force
		if not player.admin then 
			player.print(">>>>> Only admins can change team names.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		custom_team_name_gui(player, name)
		player.gui.center["team_manager_gui"].destroy()
		return
	end

	if name == "team_manager_gameid" then
		if not player.admin then 
			player.print(">>>>> Only admins can set the Game Identificator.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if global.match_running then 
			player.print(">>>>> Cannot modify GameId after match has started (contact website admin).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		player.gui.center["team_manager_gui"].destroy()
		custom_game_id_gui(player)
		return
	end	
	if name == "team_manager_procedure" then
		if not player.admin then 
			player.print(">>>>> Only admins can learn the procedure.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
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
		--[[
		if not player.admin then 
			player.print("Only admins can switch tournament mode.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		]]--
		if true then
			player.print(">>>>>  Tournament mode must stay activated in BBChampions", {r = 175, g = 11, b = 11}) --EVL
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return --EVL
		end
		--[[EVL not used in BBChampions
		if global.tournament_mode then
			global.tournament_mode = false
			draw_manager_gui(player)
			game.print(">>> Tournament Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.tournament_mode = true
		draw_manager_gui(player)
		game.print(">>> Tournament Mode has been enabled!", {r = 175, g = 11, b = 11})
		]]--
		return
	end
	
	--EVL Reroll
	if name == "team_manager_reroll" then
		if not player.admin then 
			player.print(">>>>> Only admins can reroll the map.", {r = 175, g = 11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if global.reveal_init_map then --map has not been revealed yet
			game.print(">>>>> Wait for map to be revealed before asking Reroll.", {r = 175, g = 11, b = 11})
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if not global.reroll_confirm then
			player.print(">>>>> Click again to confirm reroll.", {r = 175, g = 175, b = 11})
			player.play_sound{path = "utility/wire_connect_pole", volume_modifier = 0.8}
			global.reroll_confirm = true
			return
		end
		global.reroll_do_it = true --EVL global_reroll_left decreased if main
		global.freeze_players = true
		global.reroll_confirm = false
		--draw_manager_gui(player)
		player.gui.center["team_manager_gui"].destroy()	
		game.print(">>>>> Admin "..player.name.." asked for map reroll - Please wait...", {r = 175, g = 175, b = 11})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		return
	end
	--EVL Reroll
	--EVL Packs
	local pack=string.sub(name,0,5)
	if pack=="pack_" then
		if not player.admin then 
			player.print(">>>>> Only admins can choose the starter pack.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if global.match_running then -- No more changing, game has started
			player.print(">>>>> Pack cannot be changed after the match has started !", {r = 175, g = 11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if global.fill_starter_chests then -- Chests are not filled yet, cant change pack
			player.print(">>>>> Chests are in filling sequence, please wait...", {r = 175, g = 11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		if not global.pack_choosen or global.pack_choosen=="" then 
			global.pack_choosen = name
			game.print(">>>>> Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name].caption .." has been chosen !", {r = 11, g = 225, b = 11})
			--EVL no sound (sound plays when chests are filled)
			global.fill_starter_chests = true
		else 
			global.pack_choosen = name
			game.print(">>>>> Pack has been changed to Pack#" .. string.sub(name,6,8) .. " - " .. Tables.packs_list[name]["caption"] .." !", {r = 175, g = 11, b = 11})
			--EVL no sound (sound plays when chests are filled)
			global.starter_chests_are_filled = false
			global.fill_starter_chests = true
		end
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	--EVL PACK FIN
	
	--------------------------------------
	--EVL Config TEAM MANAGERS
	--------------------------------------
	if name=="tm_north_manager_box_add" then --ADD MANAGER TO TEAM NORTH
		if not player.admin then 
			player.print(">>>>> Only admins can add manager to teams (north).", {r = 175, g =11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_2"]
		local selected_index = listbox.selected_index
		if selected_index == 0 then player.print("No player selected.", {r = 175, g = 11, b = 11}) return end
		local player_name = listbox.items[selected_index]
		local _player_this=player_name
		if string.sub(_player_this,1,15) == "[color="..colorAdmin.."]" then
			_player_this=string.sub(_player_this,16,#_player_this-10)
		end
		if not game.players[_player_this] then 
			player.print(">>>>> Player " .. _player_this .. " doesn't exist.", {r=0.98, g=0.66, b=0.22}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _player = game.players[_player_this]
		
		if 	not(_player.admin) or ((_player.admin) and (global.training_mode or global.game_id=="scrim")) then -- in training or scrim mode, admins can be switched into teams
			_player.teleport(_player.surface.find_non_colliding_position("character", {0,-bb_config.spawn_manager_pos}, 4, 1)) -- north spot
			if global.managers_in_team then _player.force=game.forces["north"] end --EVL in this mode manager are set to team
			global.manager_table["north"]=_player_this
			local _team_name="Team North"  --Name to be shown above Manager Speaker
			if global.tm_custom_name["north"] then _team_name = global.tm_custom_name["north"] end
			if global.manager_speaker["north_text"] and global.manager_speaker["north_text"]>0 then
				rendering.destroy(global.manager_speaker["north_text"])
			end
			global.manager_speaker["north_text"]=rendering.draw_text {	--Add Team name above manager slot
						text = _team_name,
						surface = _player.surface,
						target = {x = 0, y = -bb_config.spawn_manager_pos-6}, --global.manager_speaker["north"],
						--target_offset = {0, -5.0},
						color = {88, 88, 255},
						scale = 3.00,
						font = "count-font",
						alignment = "center",
						scale_with_zoom = false
				}	
			game.print(_player_this.." (".._player.force.name..") has been appointed as manager for team north.", {r=0.66, g=0.98, b=0.66})
			
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		elseif _player.admin then -- not training or scrim mode, but admin, we cannot switch
			player.print(">>>>> Player "..player_name.." is Admin and cannot be switched into manager slot (north).", {r=0.98, g=0.77, b=0.77})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	if name=="tm_south_manager_box_add" then --ADD MANAGER TO TEAM SOUTH
		if not player.admin then 
			player.print(">>>>> Only admins can add manager to teams (north).", {r = 175, g =11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_2"]
		local selected_index = listbox.selected_index
		if selected_index == 0 then player.print("No player selected.", {r = 175, g = 11, b = 11}) return end
		local player_name = listbox.items[selected_index]
		local _player_this=player_name
		if string.sub(_player_this,1,15) == "[color="..colorAdmin.."]" then
			_player_this=string.sub(_player_this,16,#_player_this-10)
		end
		if not game.players[_player_this] then 
			player.print(">>>>> Player " .. _player_this .. " doesn't exist.", {r=0.98, g=0.66, b=0.22}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}		
			return 
		end
		local _player = game.players[_player_this]
		
		if 	not(_player.admin) or ((_player.admin) and (global.training_mode or global.game_id=="scrim")) then -- in training or scrim mode, admins can be switched into teams
			_player.teleport(_player.surface.find_non_colliding_position("character", {0,bb_config.spawn_manager_pos}, 4, 1))--south spot
			if global.managers_in_team then _player.force=game.forces["south"] end --EVL in this mode manager are set to team
			global.manager_table["south"]=_player_this
			local _team_name="Team South" --Name to be shown above Manager Speaker
			if global.tm_custom_name["south"] then _team_name = global.tm_custom_name["south"] 	end
			if global.manager_speaker["south_text"] and global.manager_speaker["south_text"]>0 then
				rendering.destroy(global.manager_speaker["south_text"])
			end
			global.manager_speaker["south_text"]=rendering.draw_text {
						text = _team_name,
						surface = _player.surface,
						target = {x = 0, y = bb_config.spawn_manager_pos+3}, --global.manager_speaker["south"],
						--target_offset = {0, 2.0},
						color = {200, 33, 33},
						scale = 3.00,
						font = "count-font",
						alignment = "center",
						scale_with_zoom = false
				}		
			game.print(_player_this.." (".._player.force.name..") has been appointed as manager for team south.", {r=0.66, g=0.98, b=0.66})
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		elseif _player.admin then -- not training or scrim mode, but admin, we cannot switch
			player.print(">>>>> Player "..player_name.." is Admin and cannot be switched into manager slot (south).", {r=0.98, g=0.77, b=0.77})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	if name=="tm_north_manager_box_remove" then --REMOVE MANAGER FROM TEAM NORTH
		if not player.admin then 
			player.print(">>>>> Only admins can remove manager from teams (north).", {r = 175, g =11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["tm_north_manager_box"]
		local selected_index = 1
		local player_name = listbox.items[selected_index]
		local _player_this=player_name
		if string.sub(_player_this,-2) == ":A" then
			_player_this=string.sub(_player_this,16,#_player_this-10)
			--game.print("Admin manager : ".._player_this)
		else
			_player_this=string.sub(_player_this,16,#_player_this-8)
			--game.print("Regular manager : ".._player_this)
		end
		local _player = game.players[_player_this] --be careful with user and target
		if _player.name ~= global.manager_table["north"] then 
			player.print(">>>>> Local Manager does not match global Manager (north) .", {r = 175, g =11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		global.manager_table["north"]=nil
		_player.teleport(_player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
		if global.managers_in_team then _player.force=game.forces["spectator"] end --EVL in this mode manager are set to team
		game.print(_player_this.." (".._player.force.name..")  has been removed from manager of team north.", {r=0.66, g=0.98, b=0.66})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	if name=="tm_south_manager_box_remove" then --REMOVE MANAGER FROM TEAM SOUTH
		if not player.admin then 
			player.print(">>>>> Only admins can remove manager from teams (south).", {r = 175, g =11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["tm_south_manager_box"]
		local selected_index = 1
		local player_name = listbox.items[selected_index]
		local _player_this=player_name
		if string.sub(_player_this,-2) == ":A" then
			_player_this=string.sub(_player_this,16,#_player_this-10)
		else
			_player_this=string.sub(_player_this,16,#_player_this-8)
		end
		local _player = game.players[_player_this] --be careful with user and target
		if _player.name ~= global.manager_table["south"] then 
			player.print(">>>>> Local Manager does not match global Manager (south) .", {r = 175, g =11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		global.manager_table["south"]=nil
		_player.teleport(_player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
		if global.managers_in_team then _player.force=game.forces["spectator"] end --EVL in this mode manager are set to team
		game.print(_player_this.." (".._player.force.name..") has been removed from manager of team south.", {r=0.66, g=0.98, b=0.66})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	--EVL end of Config TEAM MANAGERS
	

	if name == "team_manager_freeze_players" then -- NO MORE FREEZE/UNFREEZE (now there is a pause button), only START MATCH
		if not player.admin then 
			player.print(">>>>> Only admins can switch freeze mode.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if global.bb_game_won_by_team then player.print(">>>>> You cannot switch freeze mode after match has finished.", {r = 175, g = 11, b = 11}) return end
		
		if global.freeze_players then --EVL Players are frozen
			if global.pack_choosen == "" then -- EVL dont start without pack choosen
				game.print(">>>>> A pack must be choosen before starting the game / unfreezing the players !", {r = 175, g = 11, b = 11})
				game.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			if global.reroll_do_it then -- EVL dont start if reroll is on the way
				player.print(">>>>> Reroll is not done yet, retry in a second...", {r = 175, g = 11, b = 11})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end			
			if not global.starter_chests_are_filled then -- EVL dont start before starter packs are filled
				player.print(">>>>> Starter Packs are not filled yet, retry in a second...", {r = 175, g = 11, b = 11})
				player.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			if not global.game_id then -- EVL dont start before game_id is registered (or ='training')
				game.print(">>>>> Game Id has not been set, DO IT REFEREE (please) !", {r = 175, g = 11, b = 11})
				game.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			--EVL TESTING PRESENCE OF PLAYERS
			local starting_msg=">>>>>"
			--No player on one side and tournament mode --> game cannot start 
			local nb_players_north=Functions.get_nb_players("north")
			local nb_players_south=Functions.get_nb_players("south")
			if (nb_players_north<global.min_players or nb_players_south<global.min_players) and not global.training_mode then
				starting_msg=starting_msg.." Alert : Not enough players on  "
				if nb_players_north<global.min_players then 
					starting_msg=starting_msg.." NORTH ("..nb_players_north.."<"..global.min_players..") "
				end
				if nb_players_south<global.min_players then 
					starting_msg=starting_msg.." SOUTH ("..nb_players_south.."<"..global.min_players..") "
				end
				game.print(starting_msg.." side(s). Match cannot start...", {r = 175, g = 11, b = 11})
				game.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			--Too much player on one side --> not blocking, just an alert
			if nb_players_north>global.max_players or nb_players_south>global.max_players then
				starting_msg=starting_msg.." Info : too many players on  "
				if nb_players_north>global.max_players then 
					starting_msg=starting_msg.." NORTH ("..nb_players_north.." players) "
				end
				if nb_players_south>global.max_players then 
					starting_msg=starting_msg.." SOUTH ("..nb_players_south.." players) "
				end
				game.print(starting_msg.." side(s). Match will still start...", {r = 11, g = 175, b = 11})
				
			end
			
			--draw_manager_gui(player) -- Will be destroyed when starting match NOT NEEDED AT ALL?
			
			
			--EVL Everything went fine, we can start
			if not global.match_running then --First unfreeze meaning match is starting
				--Add the game_type button, the pause button and close team_manager for everybody
				for _, player in pairs(game.connected_players) do
					create_game_type_button(player)
					draw_pause_toggle_button(player)
					--indiquer "scrim" mode (or training) (top gui button ?)
					if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
				end
				global.match_running=true 
				global.bb_threat["north_biters"] = 9 --EVL we start at threat=9 to avoid weird sendings at the beginning
				global.bb_threat["south_biters"] = 9 
				game.surfaces[global.bb_surface_name].daytime = 0.6 -- we set time to dawn
				game.print(">>>>> Match is starting shortly. Good luck ! Have Fun !", {r = 11, g = 255, b = 11})
				game.play_sound{path = global.sound_success, volume_modifier = 0.8}
				
			end  	
			
			global.freeze_players = false
			
			if global.match_countdown < 0 then -- First unfreeze depends on init, then we use 3 seconds timer (after pause)
				global.match_countdown = 3
				game.print(">>>>> Match will resume very shortly !", {r = 11, g = 255, b = 11})
				if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
			end
			
			return
		end
		
		if global.match_countdown >= 0 then --WAIT FOR UNFREEZE BEFORE FREEZE AGAIN
			player.print(">>>>> Please wait "..(global.match_countdown+1).."s (game is currently in ~unfreezing~ process) ...", {r = 175, g = 11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		global.freeze_players = true
		Public.freeze_players()
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		game.print(">>>>> Players & Biters have been frozen !", {r = 111, g = 111, b = 255}) --EVL
		return
	end
	
	if name == "team_manager_activate_training" then 		
		if not player.admin then 
			player.print(">>>>> Only admins can switch training mode.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if global.match_running then player.print(">>>>> Cannot modify Game Mode [training] after match has started.", {r = 175, g = 11, b = 11}) return end
		if global.training_mode then --Testing players in forces
			for _,force_name in pairs({"north","south"}) do
				for _, p in pairs(game.forces[force_name].connected_players) do
					if p.admin then 
						game.print(">>>>> Alert: Admin detected in team "..force_name..", Training Mode can't be disabled.", {r = 175, g = 11, b = 11})
						game.play_sound{path = global.sound_error, volume_modifier = 0.8}
						return
					end
				end
			end	
			if global.manager_table["north"] and game.players[global.manager_table["north"]].admin then --Testing manager north
				game.print(">>>>> Alert: Admin detected in north manager slot, Training Mode can't be disabled.", {r = 175, g = 11, b = 11})
				game.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			if global.manager_table["south"] and game.players[global.manager_table["south"]].admin then --Testing manager south
				game.print(">>>>> Alert: Admin detected in south manager slot, Training Mode can't be disabled.", {r = 175, g = 11, b = 11})
				game.play_sound{path = global.sound_error, volume_modifier = 0.8}
				return
			end
			--Everything is OK we can switch
			global.training_mode = false
			global.game_lobby_active = true
			global.game_id=nil --EVL Remove GAME_ID if not training mode
			Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
			game.print(">>>>> Training Mode has been disabled.", {r = 175, g = 11, b = 11})
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
			return
		end
		global.training_mode = true
		global.game_lobby_active = false
		global.game_id="training" --EVL Add special GAME_ID if training mode
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		game.print(">>>>> Training Mode has been enabled!", {r = 11 , g = 225, b = 11})
		game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		return
	end
	
	if not event.element.parent then return end
	local element = event.element.parent
	if not element.parent then return end
	local element = element.parent
	if element.name ~= "team_manager_root_table" then return end		
	if not player.admin then 
		player.print(">>>>> Only admins can manage teams.", {r = 175, g =11, b = 11}) 
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return 
	end
	
	local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_" .. tonumber(name)]
	local selected_index = listbox.selected_index
	if selected_index == 0 then 
		player.print("Team Manager >> No player selected.", {r = 175, g = 11, b = 11}) 
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return 
	end
	local player_name = listbox.items[selected_index]
	
	local m = -1
	if event.element.caption == "→" then m = 1 end
	local force_name = forces[tonumber(name) + m].name
	
	--EVL exception for spec/god mode players
	if string.sub(player_name,-2)==":G" then
		local _player_name=string.sub(player_name,1,string.len(player_name)-2)
		game.print("Team Manager >> Player " .. _player_name .. " is in Spec/God mode, must be back on island first.", {r=0.98, g=0.66, b=0.22})
		game.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	
	--EVL We remove tag Admin before switching force (see get_player_array above)
	local _player_this=player_name
	if string.sub(_player_this,1,15) == "[color="..colorAdmin.."]" then
		_player_this=string.sub(_player_this,16,#_player_this-10)
	end
	--EVL Test if  player exists (with exception for disconnected players)
	if string.sub(player_name,-2)==":D" then
		local _disco_name=string.sub(player_name,1,string.len(player_name)-2)
		if not game.players[_disco_name] then 
			game.print("Debug: Team Manager >> Player ".._player_this.."/".._disco_name.." doesn't exist.", {r=0.98, g=0.66, b=0.22}) 
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		else
			_player_this=_disco_name
		end
	elseif not game.players[_player_this] then 
		game.print("Debug: Team Manager >> Player " .. _player_this .. " doesn't exist.", {r=0.98, g=0.66, b=0.22}) 
		game.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return 
	end
	local _player = game.players[_player_this]

	--TEST BELOW --TODO--(can be done in 2 tests)
	if 	global.training_mode or global.game_id=="scrim" then -- in training or scrim mode, admins can be switched into teams
		switch_force(player_name, force_name)
	elseif _player.admin then -- not training or scrim mode, but admin, we cannot switch
		game.print(">>>>> Alert : Player " .. player_name .. " is Admin and cannot be switched into a team (unless training or scrim mode).", {r=0.98, g=0.77, b=0.77})
		game.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	else -- not training or scrim mode, not admin, we can switch
		switch_force(player_name, force_name)
	end
	Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
end

function Public.gui_click(event)	
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	--game.print("event : "..name)
	if name == "team_manager_toggle_button" then
		if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() return end
		draw_manager_gui(player)
		return
	end
	--EVL pause button
	if name == "team_manager_pause_button" then
		if not player.admin then 
			player.print(">>>>> Ask referee/admin to pause/unpause the game.", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
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
			Public.redraw_all_team_manager_guis()
			draw_manager_gui(player)
			return
		end
		if name == "custom_team_name_gui_close" then
			player.gui.center["custom_team_name_gui"].destroy()
			Public.redraw_all_team_manager_guis()
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
			Public.redraw_all_team_manager_guis()
			draw_manager_gui(player)
			return
		end
		if name == "custom_game_id_gui_close" then
			player.gui.center["custom_game_id_gui"].destroy()
			Public.redraw_all_team_manager_guis()
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
	------------------------
	--EVL CONFIG TRAINING --
	------------------------
	--Single sending
	if name == "north_send_button" then --Single sending to north_biters
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (single/north).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if not global.match_running then 
			player.print(">>>>> Cannot send flasks until match has started (north).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _food=player.gui.center["config_training"]["north_config_training"]["north_send_food"].selected_index
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_send_qtity"].selected_index
		training_single_sending(player, _food, _qtity, "north") --careful food&qtity are selected_index, not real values yet
		return
	end
	if name == "south_send_button" then --Single sending to south_biters
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (single/south).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		if not global.match_running then 
			player.print(">>>>> Cannot send flasks until match has started (south).", {r = 175, g = 11, b = 11})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _food=player.gui.center["config_training"]["south_config_training"]["south_send_food"].selected_index
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_send_qtity"].selected_index
		training_single_sending(player, _food, _qtity, "south") --careful food&qtity are selected_index, not real values yet
		return		
	end
	--Automatic sendings
	if name == "north_training_button" then --Automatic sending to north_biters
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (auto/north).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _food=player.gui.center["config_training"]["north_config_training"]["north_training_food"].selected_index
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_training_qtity"].selected_index
		local _timing=player.gui.center["config_training"]["north_config_training"]["north_training_timing"].selected_index   
		training_auto_sendings(player, _food, _qtity, _timing, "north") --careful food&qtity&timing are selected_index, not real values yet
		return		
	end
	if name == "south_training_button" then --Automatic sending to south_biters
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (auto/south).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _food=player.gui.center["config_training"]["south_config_training"]["south_training_food"].selected_index
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_training_qtity"].selected_index
		local _timing=player.gui.center["config_training"]["south_config_training"]["south_training_timing"].selected_index   
		training_auto_sendings(player, _food, _qtity, _timing, "south") --careful food&qtity&timing are selected_index, not real values yet
		return		
	end	
	--	Limit groups
	if name == "north_waves_button" then --Limit number of groups attacking every 2 min
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (groups/north).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _qtity=player.gui.center["config_training"]["north_config_training"]["north_waves_qtity"].selected_index
		training_limit_groups(player, _qtity, "north") --careful qtity is selected_index, not real value yet
		return		
	end		
	if name == "south_waves_button" then --Limit number of groups attacking every 2 min
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (groups/south).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _qtity=player.gui.center["config_training"]["south_config_training"]["south_waves_qtity"].selected_index
		training_limit_groups(player, _qtity, "south") --careful qtity is selected_index, not real value yet
		return		
	end	
	--	Simulate previous game (pattern)
	if name == "north_pattern_button" then --Limit number of groups attacking every 2 min
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (pattern/north).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		local _gameid=player.gui.center["config_training"]["north_config_training"]["north_pattern_gameid"].selected_index
		training_simul_pattern(player, _gameid, "north") --careful qtity is selected_index, not real value yet
		return		
	end		
	if name == "south_pattern_button" then --Limit number of groups attacking every 2 min
		if not player.admin then 
			player.print(">>>>> Only admins can use config training pane (pattern/south).", {r = 175, g = 11, b = 11}) 
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		local _gameid=player.gui.center["config_training"]["south_config_training"]["south_pattern_gameid"].selected_index
		training_simul_pattern(player, _gameid, "south") --careful qtity is selected_index, not real value yet
		return		
	end	
	-- Select sendings from team or all
	if string.sub(name,1,14) == "pattern_teams_" then
		local _team_name=string.sub(name,15)
		_team_name = string.gsub(_team_name,"_"," ")
		if not Sendings_Patterns.list_teams[_team_name] then 
			game.print("BUG : cannot find team ".._team_name.." (in team_manager/Public.gui_click)") 
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return 
		end
		global.pattern_team_select=_team_name
		pattern_training_gui(player.gui.center["config_training"]["patterns_gui"])
		player.play_sound{path = global.sound_low_bip, volume_modifier = 0.8}
		return
	end
	--EVL FULL LIST OF PATTERN FROM CONFIG TRAINING
	if string.sub(name,1,13) == "training_cpd_" then
		local _gameId=tonumber(string.sub(name,14))
		--game.print("gameId="..serpent.block(_gameId))
		if not(_gameId) or _gameId<=0 or not(Sendings_Patterns.detail_game_id[_gameId]) then
			game.print(">>>>> Bug: can't find gameId for full listing...", {r = 175, g = 11, b = 11})
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		else
			--player.gui.center["team_manager_gui"].destroy()
			--config_training_gui(player)
			--game.print("GameId=".._gameId)
			build_gui_pattern(player, _gameId, Sendings_Patterns.detail_game_id[_gameId])
			player.play_sound{global.sound_low_bip, volume_modifier = 0.8}
			return
		end
	end	
	--EVL CLOSE FULL LIST OF PATTERN FROM CONFIG TRAINING "ctg_" ie "config_training_gui"
	if name == "ctg_pattern_close_button" then
		player.gui.center["ctg_pattern"].destroy()
		--draw_manager_gui(player)
		return
	end	
	--EVL END OF CONFIG TRAINING
end
--EVL Close "text gui inputs" with <enter> key
function Public.on_gui_confirmed(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	local parent=""
	if event.element.parent then parent=event.element.parent.name end
	--EVL Confirm set_team_name
	if parent == "custom_team_name_gui" then
		local custom_name = event.element.text
		local force_name = name
		set_custom_team_name(force_name, custom_name)
		player.gui.center["custom_team_name_gui"].destroy()
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
	--EVL Confirm set_game_Id
	if name=="game_id_text_field" then
		local gameid = player.gui.center["custom_game_id_gui"].children[1].text
		set_custom_game_id(player,gameid)
		player.gui.center["custom_game_id_gui"].destroy()
		Public.redraw_all_team_manager_guis()--draw_manager_gui(player)
		return
	end
end
return Public
