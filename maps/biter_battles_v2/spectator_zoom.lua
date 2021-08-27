--MOVED TO GUI.LUA
--NOT USED ANYMORE

--Adds 3 buttons to fly over the map and get 2 levels of zoom out
--Limited to Admins (referees) that are in spectator force (on the island)

local Event = require 'utils.event'

local function draw_top_gui(player)
	if player.gui.top.spec_zoom_spec then return end
	--if player.admin and (player.force.name == "spectator" or player.force.name == "spec_god") then --EVL We only show buttons if admin+spectator (but this menu is static)
		local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_spec", caption = "Spec", tooltip = "Only admins as spectators can fly over the map,\n Click to switch between REAL and GOD modes."})
		button.style.font = "heading-2"
		button.style.font_color = {112, 112, 255}
		button.style.minimal_height = 38
		button.style.minimal_width = 42
		button.style.padding = -2
		
		local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_1", caption = "+", tooltip = "Large view"})
		button.style.font = "default-large-bold"
		button.style.font_color = {112, 212, 112}
		button.style.minimal_height = 38
		button.style.minimal_width = 20
		button.style.padding = -2
		local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_2", caption = "++", tooltip = "Larger view"})
		button.style.font = "default-large-bold"
		button.style.font_color = {255, 112, 112}
		button.style.minimal_height = 38
		button.style.minimal_width = 20
		button.style.padding = -2
	--end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	draw_top_gui(player)
end

local function on_gui_click(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
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
	
	local name = element.name
	if name == "spec_zoom_spec" then
		local player = game.players[event.player_index]
		
		if player.admin then
			if player.force.name == "spectator" then -- GO TO SPEC GOD MODE
				player.force = game.forces["spec_god"]
				if player.character then player.character.destroy() end
				player.character = nil
				game.players[event.player_index].zoom=0.18
				global.god_players[player.name] = true
				if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") switches to God mode") end
				--game.print("##"..table_size(global.god_players))
			elseif player.force.name == "spec_god" then -- GO TO SPEC REAL MODE
				player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
				player.create_character()
				player.force = game.forces["spectator"]
				game.players[event.player_index].zoom=0.30
				global.god_players[player.name] = false
				if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") switches back to Real mode") end
			
			else
				game.print(">>>>> Only spectators are allowed to use ~SPEC~ view.", {r = 175, g = 0, b = 0})
			end
		else
			player.print(">>>>> Only admins are allowed to use ~SPEC~ view.", {r = 175, g = 0, b = 0})
			return
		end
	end
	
	if name == "spec_zoom_1" then --EVL Asking for large view
		if global.bb_debug then game.print("Debug: player:" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name..") asks for Large view") end
		if game.players[event.player_index].admin then
		
			if game.players[event.player_index].force.name == "spec_god" then --EVL must in in spec_god mode first
				game.players[event.player_index].zoom=0.12 -- EVL WRITE ONLY :-(
			else
				game.players[event.player_index].print(">>>>> You must click on ~Spec~ button first.", {r = 175, g = 0, b = 0})
			end
		else 
			game.players[event.player_index].print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
		end
		return
	end
	if name == "spec_zoom_2" then --EVL Asking for larger view
		if global.bb_debug then game.print("Debug: player :" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name.. ") asks for LargeR view") end
		if game.players[event.player_index].admin then
			if game.players[event.player_index].force.name == "spec_god" then --EVL must in in spec_god mode first
				game.players[event.player_index].zoom=0.06 -- EVL WRITE ONLY :-(
			else
				game.players[event.player_index].print(">>>>> You must click on ~Spec~ button first.", {r = 175, g = 0, b = 0})
			end
		else
			game.players[event.player_index].print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
		end
		return
	end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)