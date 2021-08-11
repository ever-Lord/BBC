--Adds 3 buttons to fly over the map and get 2 levels of zoom out
--Limited to Admins (referees) that are in spectator force (on the island)

local Event = require 'utils.event'
local God_Players={} -- List of players in god mode
local function draw_top_gui(player)
	if player.gui.top.spec_zoom_spec then return end
	
	local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_spec", caption = "Spec", tooltip = "Only admins in spectator-list can fly over the map \n Click to switch between REAL and GOD modes"})
	button.style.font = "heading-2"
	button.style.font_color = {112, 112, 255}
	button.style.minimal_height = 38
	button.style.minimal_width = 42
	button.style.padding = -2
	
	local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_1", caption = "+"})
	button.style.font = "default-large-bold"
	button.style.font_color = {112, 212, 112}
	button.style.minimal_height = 38
	button.style.minimal_width = 20
	button.style.padding = -2
	local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_2", caption = "++"})
	button.style.font = "default-large-bold"
	button.style.font_color = {255, 112, 112}
	button.style.minimal_height = 38
	button.style.minimal_width = 20
	button.style.padding = -2
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	draw_top_gui(player)
end

local function on_gui_click(event)
	local element = event.element
	if not element then return end
	if not element.valid then return end
	
	local name = element.name
	if name == "spec_zoom_spec" then
		local player = game.players[event.player_index]
		
		
		if player.admin and player.force.name == "spectator" then
			if not God_Players[player.name] then
				if player.character then player.character.destroy() end
				player.character = nil
				God_Players[player.name] = true
				if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") switches to God mode") end
			
			else
				player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
				player.create_character()
				God_Players[player.name] = false
				if global.bb_debug then game.print("Debug: player:" ..  player.name .." ("..player.force.name..") switches back to real mode") end
			end
			
		else 
			game.players[event.player_index].print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
		end
	end
	if name == "spec_zoom_1" then
		if global.bb_debug then game.print("Debug: player:" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name..") asks for Zoom +") end
		if game.players[event.player_index].admin and game.players[event.player_index].force.name == "spectator" then
			game.players[event.player_index].zoom=0.12 -- EVL WRITE ONLY :-(
		else 
			game.players[event.player_index].print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
		end

		return
	end
	if name == "spec_zoom_2" then
		if global.bb_debug then game.print("Debug: player :" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name.. ") asks for Zoom ++") end
		if game.players[event.player_index].admin and game.players[event.player_index].force.name == "spectator" then
			game.players[event.player_index].zoom=0.06 -- EVL WRITE ONLY :-(
		else
			game.players[event.player_index].print(">>>>> You are not allowed to do that.", {r = 175, g = 0, b = 0})
		end
		return
	end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)