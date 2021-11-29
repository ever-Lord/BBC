local bb_config = require "maps.biter_battles_v2.config"
local ai = require "maps.biter_battles_v2.ai"
local event = require 'utils.event'
local Server = require 'utils.server'
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
-- EVL Changing difficulties for BBC 
--[[
local difficulties = {
	
	[1] = {name = "I'm Too Young to Die", str = "25%", value = 0.25, color = {r=0.00, g=0.45, b=0.00}, print_color = {r=0.00, g=0.9, b=0.00}},
	[2] = {name = "Piece of Cake", str = "50%", value = 0.5, color = {r=0.00, g=0.35, b=0.00}, print_color = {r=0.00, g=0.7, b=0.00}},
	[3] = {name = "Easy", str = "75%", value = 0.75, color = {r=0.00, g=0.25, b=0.00}, print_color = {r=0.00, g=0.5, b=0.00}},
	[4] = {name = "Normal", str = "100%", value = 1, color = {r=0.00, g=0.00, b=0.25}, print_color = {r=0.0, g=0.0, b=0.7}},
	[5] = {name = "Hard", str = "150%", value = 1.5, color = {r=0.25, g=0.00, b=0.00}, print_color = {r=0.5, g=0.0, b=0.00}},
	[6] = {name = "Nightmare", str = "300%", value = 3, color = {r=0.35, g=0.00, b=0.00}, print_color = {r=0.7, g=0.0, b=0.00}},
	[7] = {name = "Fun and Fast", str = "500%", value = 5, color = {r=0.55, g=0.00, b=0.00}, print_color = {r=0.9, g=0.0, b=0.00}}
}
]]--

-- EVL BBC LEAGUES
local difficulties = {
	[1] = {name = "Biter league", str = "100%", value = 1, color = {r=0.00, g=0.00, b=0.25}, print_color = {r=0.4, g=0.4, b=1.0}, bplib = "[color=#55FF55]opened[/color]"}, --EVL Add blue print library opened/closed
	[2] = {name = "Behemoth league", str = "150%", value = 1.5, color = {r=0.00, g=0.25, b=0.00}, print_color = {r=0.1, g=0.8, b=0.1}, bplib = "[color=#FF5555]closed[/color]"}
}


local function difficulty_gui()
	local str_tooltip = table.concat({"Global map difficulty is ", difficulties[global.difficulty_vote_index].name," (",difficulties[global.difficulty_vote_index].str,")",
							".\nMutagen has ", math.floor(global.difficulty_vote_value*100), "% effectiveness.\n"})
	str_tooltip = str_tooltip.."[color=#8888FF]Blue print library is "..difficulties[global.difficulty_vote_index].bplib..".[/color]\n"

	for _science_nb = 1, 7 do
			local _mutagen_value=Tables.food_values[Tables.food_long_and_short[_science_nb].long_name].value*10000
			str_tooltip=str_tooltip.."[item="..Tables.food_long_and_short[_science_nb].long_name.."]"..Tables.food_long_and_short[_science_nb].short_name.."=".._mutagen_value.." | "
			if _science_nb == 3  or _science_nb == 5 then str_tooltip=str_tooltip.."\n" end
	end
	for _, player in pairs(game.connected_players) do
		if player.gui.top["difficulty_gui"] then player.gui.top["difficulty_gui"].destroy() end
		

		
		local b = player.gui.top.add { type = "sprite-button", caption = difficulties[global.difficulty_vote_index].name, tooltip = str_tooltip, name = "difficulty_gui" }
		b.style.font = "heading-2"
		b.style.font_color = difficulties[global.difficulty_vote_index].print_color
		b.style.minimal_height = 38
		b.style.minimal_width = 127
	end
end

local function poll_difficulty(player)
	if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() return end
	
	if global.bb_settings.only_admins_vote or global.tournament_mode then
		if not player.admin then 
			player.print("Only admins can change difficulty (tournament mode)." ,{r = 0.78, g = 0.22, b = 0.22})
			return 
		end
	end
	if global.match_running then --EVL Do not change difficulty after match has started
		player.print("Difficulty cannot be changed after match has started." ,{r = 0.78, g = 0.22, b = 0.22})
		return
	end
	
	local tick = game.ticks_played
	if tick > global.difficulty_votes_timeout then
		if player.online_time ~= 0 then
			local t = math.abs(math.floor((global.difficulty_votes_timeout - tick) / 3600))
			local str = "Votes have closed " .. t
			str = str .. " minute"
			if t > 1 then str = str .. "s" end
			str = str .. " ago."
			player.print(str)
		end
		return 
	end
	
	
	local frame = player.gui.center.add { type = "frame", caption = "Set the league:", name = "difficulty_poll", direction = "vertical" }
	for key, _ in pairs(difficulties) do
		local b = frame.add({type = "button", name = tostring(key), caption = difficulties[key].name .. " (" .. difficulties[key].str .. ")"})
		b.style.font_color = difficulties[key].color
		b.style.font = "heading-2"
		b.style.minimal_width = 180
	end
	local b = frame.add({type = "label", caption = "- - - - - - - - - - - - - - - - - - - -"})
	local b = frame.add({type = "button", name = "close", caption = "Close (" .. math.floor((global.difficulty_votes_timeout - tick) / 3600) .. " minutes left)"})
	b.style.font_color = {r=0.66, g=0.0, b=0.66}
	b.style.font = "heading-3"
	b.style.minimal_width = 96
end

local function set_difficulty()
	local a = {}
	local vote_count = 0
	local c = 0
	local v = 0
	for _, d in pairs(global.difficulty_player_votes) do
		c = c + 1
		a[c] = d
		vote_count = vote_count + 1
	end
	if vote_count == 0 then return end
	v= math.floor(vote_count/2)+1
	table.sort(a)
	local new_index = a[v]
	if global.difficulty_vote_index ~= new_index then
		local message_blueprint=""
		if new_index==1 then
           message_blueprint="[color=#FF9740](Blue print library opened)[/color]" 
			game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui,true)
			game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, true)
		
		elseif new_index==2 then
           message_blueprint="[color=#FF9740](Blue print library closed)[/color]" 
			game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui, false)
			game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, false)
		else
		   game.print(">>>>> BBC ALERT : Vote difficulty is not available, switching to Biter league by default...", {r=0.98, g=0.11, b=0.11})
           message_blueprint="[color=#FF9740](Blue print library opened)[/color]" 
			game.permissions.get_group('Default').set_allows_action(defines.input_action.open_blueprint_library_gui,true)
			game.permissions.get_group('Default').set_allows_action(defines.input_action.import_blueprint_string, true)
		end
		
		local message = table.concat({">>>>> Map difficulty has changed to ", difficulties[new_index].name, " difficulty!   ", message_blueprint})
	
		game.print(message, difficulties[new_index].print_color)
		Server.to_discord_embed(message)
	end
	 global.difficulty_vote_index = new_index
	 global.difficulty_vote_value = difficulties[new_index].value
	 ai.reset_evo()
end

local function on_player_joined_game(event)
	if not global.difficulty_vote_value then global.difficulty_vote_value = 1 end
	if not global.difficulty_vote_index then global.difficulty_vote_index = 1 end --was 4 EVL (probably not useful)
	if not global.difficulty_player_votes then global.difficulty_player_votes = {} end
	
	local player = game.players[event.player_index]
	if game.ticks_played < global.difficulty_votes_timeout then
		if not global.difficulty_player_votes[player.name] then
			if global.bb_settings.only_admins_vote or global.tournament_mode then
				if not(global.match_running) and player.admin then poll_difficulty(player) end  -- dont show vote if game has started
			end
		end
	else
		if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() end
	end
	
	difficulty_gui()
end

local function on_player_left_game(event)
	if game.ticks_played > global.difficulty_votes_timeout then return end
	local player = game.players[event.player_index]
	if not global.difficulty_player_votes[player.name] then return end
	global.difficulty_player_votes[player.name] = nil
	set_difficulty()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "difficulty_gui" then
		poll_difficulty(player)
		return
	end
	if event.element.type ~= "button" then return end
	if event.element.parent.name ~= "difficulty_poll" then return end
	if event.element.name == "close" then event.element.parent.destroy() return end
	if game.ticks_played > global.difficulty_votes_timeout then event.element.parent.destroy() return end
	local i = tonumber(event.element.name)
	if global.match_running then --EVL Do not change difficulty after match has started
		game.print("Difficulty cannot be changed after match has started ! ("..player.name .. " asked for " .. difficulties[i].name .. ")" ,{r = 0.78, g = 0.22, b = 0.22})
		return
	end
	if global.bb_settings.only_admins_vote or global.tournament_mode then
		if player.admin then
			game.print(player.name .. " has voted for " .. difficulties[i].name .. " difficulty!", difficulties[i].print_color)
			global.difficulty_player_votes[player.name] = i
			set_difficulty()
			difficulty_gui()				
		end
		event.element.parent.destroy()
		return
	end

    if player.spectator then
        player.print("spectators can't vote for difficulty")
		event.element.parent.destroy()
        return
    end

	if game.tick - global.spectator_rejoin_delay[player.name] < 3600 then
        player.print(
            "Not ready to vote. Please wait " .. 60-(math.floor((game.tick - global.spectator_rejoin_delay[player.name])/60)) .. " seconds.",
            {r = 0.98, g = 0.66, b = 0.22}
        )
		event.element.parent.destroy()
        return
    end
	
	game.print(player.name .. " has voted for " .. difficulties[i].name .. " difficulty!", difficulties[i].print_color)
	global.difficulty_player_votes[player.name] = i
	set_difficulty()
	difficulty_gui()	
	event.element.parent.destroy()
end
	
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

local Public = {}
Public.difficulties = difficulties
Public.difficulty_gui = difficulty_gui

return Public
