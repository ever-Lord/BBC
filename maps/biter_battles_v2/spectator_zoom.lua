--Adds a small gui to quick select an icon tag for your character - mewmew

local Event = require 'utils.event'

local function draw_top_gui(player)
	if player.gui.top.spec_zoom_zoom then return end
	
	local button = player.gui.top.add({type = "sprite-button", name = "spec_zoom_zoom", caption = "Zoom", tooltip = "Only admins in spectator-list can zoom out"})
	button.style.font = "heading-2"
	button.style.font_color = {212, 212, 212}
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
	if name == "spec_zoom_1" then
		if global.bb_debug then game.print("Debug: player:" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name..") asks for Zoom +") end
		if game.players[event.player_index].admin and game.players[event.player_index].force.name == "spectator" then
			game.players[event.player_index].zoom=0.12 -- EVL WRITE ONLY :-(
		else 
			game.players[event.player_index].print(">>>>> Only admins as spectators can switch zoom mode.", {r = 175, g = 0, b = 0})
		end

		return
	end
	if name == "spec_zoom_2" then
		if global.bb_debug then game.print("Debug: player :" ..  game.players[event.player_index].name .." ("..game.players[event.player_index].force.name.. ") asks for Zoom ++") end
		if game.players[event.player_index].admin and game.players[event.player_index].force.name == "spectator" then
			game.players[event.player_index].zoom=0.06 -- EVL WRITE ONLY :-(
		else
			game.players[event.player_index].print(">>>>> Only admins as spectators can switch zoom mode.", {r = 175, g = 0, b = 0})
		end
		return
	end
end

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)