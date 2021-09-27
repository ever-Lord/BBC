local Functions = require "maps.biter_battles_v2.functions"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Score = require "comfy_panel.score"
local Server = require 'utils.server'

local math_random = math.random

local Public = {}

local gui_values = {
    ["north"] = {c1 = "Team North", color1 = {r = 0.55, g = 0.55, b = 0.99}},
    ["south"] = {c1 = "Team South", color1 = {r = 0.99, g = 0.33, b = 0.33}}
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

function Public.reveal_map()
    for _, f in pairs({"north", "south", "player", "spectator"}) do
        local r = 768
        game.forces[f].chart(game.surfaces[global.bb_surface_name],
                             {{r * -1, r * -1}, {r, r}})
    end
end

function Public.reveal_init_map(radius) --EVL We show a bit more for rerolling purpose
    for _, f in pairs({"north", "south", "player", "spectator"}) do
        local r = radius
        game.forces[f].chart(game.surfaces[global.bb_surface_name],
                             {{r * -1, r * -1}, {r, r}})
    end
end


local function create_victory_gui(player)
    local values = gui_values[global.bb_game_won_by_team]
    local c = values.c1
    if global.tm_custom_name[global.bb_game_won_by_team] then
        c = global.tm_custom_name[global.bb_game_won_by_team]
    end
    local frame = player.gui.left.add {
        type = "frame",
        name = "bb_victory_gui",
        direction = "vertical",
        caption = c .. " won!"
    }
    frame.style.font = "heading-1"
    frame.style.font_color = values.color1

    local l = frame.add {type = "label", caption = global.victory_time}
    l.style.font = "heading-2"
    l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
end

local function silo_kaboom(entity)
    local surface = entity.surface
    local center_position = entity.position
    local force = entity.force
    surface.create_entity({
        name = "atomic-rocket",
        position = center_position,
        force = force,
        source = center_position,
        target = center_position,
        max_range = 1,
        speed = 0.1
    })
	--TODO-- EVL Need to accelerate this (big lag at end of the game, not enough smooth
    local drops = {}
    for x = -32, 32, 1 do
        for y = -32, 32, 1 do
            local p = {x = center_position.x + x, y = center_position.y + y}
            local distance_to_silo = math.sqrt(
                                         (center_position.x - p.x) ^ 2 +
                                             (center_position.y - p.y) ^ 2)
            local count = math.floor((32 - distance_to_silo * 1.2) * 0.28)
            if distance_to_silo < 32 and count > 0 then
                table.insert(drops, {p, count})
            end
        end
    end
    for _, drop in pairs(drops) do
        for _ = 1, drop[2], 1 do
            entity.surface.spill_item_stack(
                {
                    drop[1].x + math.random(0, 9) * 0.1,
                    drop[1].y + math.random(0, 9) * 0.1
                }, {name = "raw-fish", count = 1}, false, nil, true)
        end
    end
end

local function get_sorted_list(column_name, score_list)
    for _ = 1, #score_list, 1 do
        for y = 1, #score_list, 1 do
            if not score_list[y + 1] then break end
            if score_list[y][column_name] < score_list[y + 1][column_name] then
                local key = score_list[y]
                score_list[y] = score_list[y + 1]
                score_list[y + 1] = key
            end
        end
    end
    return score_list
end

local function get_mvps(force)
    local get_score = Score.get_table().score_table
    if not get_score[force] then return false end
    local score = get_score[force]
    local score_list = {}
    for _, p in pairs(game.players) do
        if score.players[p.name] then
            local killscore = 0
            if score.players[p.name].killscore then
                killscore = score.players[p.name].killscore
            end
            local deaths = 0
            if score.players[p.name].deaths then
                deaths = score.players[p.name].deaths
            end
            local built_entities = 0
            if score.players[p.name].built_entities then
                built_entities = score.players[p.name].built_entities
            end
            local mined_entities = 0
            if score.players[p.name].mined_entities then
                mined_entities = score.players[p.name].mined_entities
            end
            table.insert(score_list, {
                name = p.name,
                killscore = killscore,
                deaths = deaths,
                built_entities = built_entities,
                mined_entities = mined_entities
            })
        end
    end
    local mvp = {}
    score_list = get_sorted_list("killscore", score_list)
    mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
    score_list = get_sorted_list("deaths", score_list)
    mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
    score_list = get_sorted_list("built_entities", score_list)
    mvp.built_entities = {
        name = score_list[1].name,
        score = score_list[1].built_entities
    }
    return mvp
end

local function show_mvps(player)
    local get_score = Score.get_table().score_table
    if not get_score then return end
    if player.gui.left["mvps"] then return end
    local frame = player.gui.left.add({
        type = "frame",
        name = "mvps",
        direction = "vertical"
    })
    local l = frame.add({type = "label", caption = "MVPs - North:"})
    l.style.font = "default-listbox"
    l.style.font_color = {r = 0.55, g = 0.55, b = 0.99}

    local t = frame.add({type = "table", column_count = 2})
    local mvp = get_mvps("north")
    if mvp then

        local l = t.add({type = "label", caption = "Defender >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.killscore.name .. " with a score of " ..
                mvp.killscore.score
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local l = t.add({type = "label", caption = "Builder >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.built_entities.name .. " built " ..
                mvp.built_entities.score .. " things"
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local l = t.add({type = "label", caption = "Deaths >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.deaths.name .. " died " .. mvp.deaths.score ..
                " times"
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        if not global.results_sent_north then
            local result = {}
            table.insert(result, 'NORTH: \\n')
            table.insert(result, 'MVP Defender: \\n')
            table.insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n")
            table.insert(result, '\\n')
            table.insert(result, 'MVP Builder: \\n')
            table.insert(result,
                         mvp.built_entities.name .. " built " ..
                             mvp.built_entities.score .. " things\\n")
            table.insert(result, '\\n')
            table.insert(result, 'MVP Deaths: \\n')
            table.insert(result,
                         mvp.deaths.name .. " died " .. mvp.deaths.score ..
                             " times")
            local message = table.concat(result)
            Server.to_discord_embed(message)
            global.results_sent_north = true
        end
    end

    local l = frame.add({type = "label", caption = "MVPs - South:"})
    l.style.font = "default-listbox"
    l.style.font_color = {r = 0.99, g = 0.33, b = 0.33}

    local t = frame.add({type = "table", column_count = 2})
    local mvp = get_mvps("south")
    if mvp then
        local l = t.add({type = "label", caption = "Defender >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.killscore.name .. " with a score of " ..
                mvp.killscore.score
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local l = t.add({type = "label", caption = "Builder >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.built_entities.name .. " built " ..
                mvp.built_entities.score .. " things"
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local l = t.add({type = "label", caption = "Deaths >> "})
        l.style.font = "default-listbox"
        l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
        local l = t.add({
            type = "label",
            caption = mvp.deaths.name .. " died " .. mvp.deaths.score ..
                " times"
        })
        l.style.font = "default-bold"
        l.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        if not global.results_sent_south then
            local result = {}
            table.insert(result, 'SOUTH: \\n')
            table.insert(result, 'MVP Defender: \\n')
            table.insert(result, mvp.killscore.name .. " with a score of " ..
                             mvp.killscore.score .. "\\n")
            table.insert(result, '\\n')
            table.insert(result, 'MVP Builder: \\n')
            table.insert(result,
                         mvp.built_entities.name .. " built " ..
                             mvp.built_entities.score .. " things\\n")
            table.insert(result, '\\n')
            table.insert(result, 'MVP Deaths: \\n')
            table.insert(result,
                         mvp.deaths.name .. " died " .. mvp.deaths.score ..
                             " times")
            local message = table.concat(result)
            Server.to_discord_embed(message)
            global.results_sent_south = true
        end
    end
end



local enemy_team_of = {["north"] = "south", ["south"] = "north"}

function Public.server_restart()
    
	if not global.server_restart_timer then  game.print("BUG asking for server_restart without server_restart_timer") return end --EVL debug
	--if global.bb_debug then game.print("Debug: server_restart : timer="..global.server_restart_timer) end -- EVL debug
	global.server_restart_timer = global.server_restart_timer - 5

    if global.server_restart_timer == 0 then
        --EVL Removed, not used in BBC
		--[[if global.restart then
            if not global.announced_message then
                local message =
                    'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                game.print(message, {r = 0.22, g = 0.88, b = 0.22})
                Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                Server.start_scenario('Biter_Battles')
                global.announced_message = true
                return
            end
        end
        if global.shutdown then
            if not global.announced_message then
                local message =
                    'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
                game.print(message, {r = 0.22, g = 0.88, b = 0.22})
                Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                Server.stop_scenario()
                global.announced_message = true
                return
            end
        end
		]]--
       --[[ EVL THIS IS NOT WORKING AND I DONT GET WHY....
		--EVL spec_god players have to be back on ground
		game.print("spec to real"..table_size(global.god_players))
		for _player,_bool in pairs(global.god_players) do
			game.print(">".._player.." ".._bool)
			if _bool then
				local player = game.players[_player]
				game.print(player.name.."/".._player)
				player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
				player.create_character()
				player.force = game.forces["spectator"]
				player.zoom=0.30
				global.god_players[_player] = false
				if global.bb_debug then game.print("DEBUG: reset incoming -> player:" .._player.."/".. player.name .." ("..player.force.name..") switches back to real mode") end
			end
		end
		]]--
		--EVL Starting reset
		game.print(">>>>> Map is restarting !  (10s before reveal)", {r = 0.22, g = 0.88, b = 0.22}) --EVL BBC has a reveal of 127x127 for reroll purpose
        local message = 'Map is restarting! '
        Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
		-- REMOVE STATS BUTTON BEFORE RESTART (see main.lua)
		for _, player in pairs(game.players) do
			if player.gui.top["bb_export_button"] then player.gui.top["bb_export_button"].destroy() end
		end
		
		local prev_surface = global.bb_surface_name

       --EVL SAVE DATAS BEFORE REROLL (global.freeze_players, global.reroll_left)
		local _freeze_players = global.freeze_players --if player are freezed then dont freeze them again
		local _reroll_left = global.reroll_left --EVL need to remember how many rolls we did
		local _force_map_reset_export_reason=global.force_map_reset_export_reason --EVL used in export stats
		--EVL REWORK INIT PROCEDURE
		Init.tables()
		global.freeze_players = _freeze_players
		global.reroll_left = _reroll_left
		global.force_map_reset_export_reason=_force_map_reset_export_reason
		global.server_restart_timer = nil
		
		Init.initial_setup() -- EVL (none)
		Init.playground_surface()
		Init.forces()
		Init.draw_structures()
       Init.load_spawn()
		--EVL Looking why always south gets attacked first
		local whoisattackedfirst=math.random(1,2)
		if whoisattackedfirst == 1 then global.next_attack = "south" end
		if global.bb_debug then game.print("DEBUG: first wave will attack "..global.next_attack.." (after reroll)") end -- EVL or reset but no need to talk about that unusual command
	


		for _, player in pairs(game.players) do
            Functions.init_player(player)
            for _, e in pairs(player.gui.left.children) do
                e.destroy()
            end
            Gui.create_main_gui(player)
		end
		--game.reset_time_played() -- EVL moved to init.lua
       game.speed = 1
		game.delete_surface(prev_surface)
		return
    end
    if global.server_restart_timer % 15 == 0 then --EVL was 30
        game.print(">>>>> Map will [color=#FF9740]exceptionally[/color] restart after "..global.server_restart_timer.." seconds ...", {r = 0.22, g = 0.88, b = 0.22})
        --if global.server_restart_timer / 15 == 1 then --EVL was 30 NOT NEEDED
        ---   game.print("Good luck with your next match!", {r=0.98, g=0.66, b=0.22})
        --end
    end
end

local function set_victory_time()
    local tick = game.ticks_played
	--[[local minutes = tick % 216000
    local hours = tick - minutes
    minutes = math.floor(minutes / 3600)
    hours = math.floor(hours / 216000)
    if hours > 0 then
        hours = hours .. " hours and "
    else
        hours = ""
    end
    global.victory_time = "Time - " .. hours
    global.victory_time = global.victory_time .. minutes
    global.victory_time = global.victory_time .. " minutes"
	--]]
	--EVL SUBSTRACT FREEZED TIME TO TIME PLAYED
	local _freezed_time = global.freezed_time
	tick=tick-_freezed_time
	local minutes = tick % 216000
	local hours = tick - minutes
	minutes = math.floor(minutes / 3600)
	hours = math.floor(hours / 216000)
	if minutes<10 then minutes="0"..minutes end
	global.victory_time = "in " .. hours .. "h" .. minutes	.. "m"
	local _freeze_tps=math.floor(_freezed_time/3600)
	if _freeze_tps == 0 then _freeze_tps=math.floor(_freezed_time/60).."s" else _freeze_tps=_freeze_tps.."m" end
	global.victory_time = global.victory_time.."  (plus ".._freeze_tps.." paused)"
end

local function freeze_all_biters(surface)
    for _, e in pairs(surface.find_entities_filtered({force = "north_biters"})) do
        e.active = false
    end
    for _, e in pairs(surface.find_entities_filtered({force = "south_biters"})) do
        e.active = false
    end
	if global.bb_debug then game.print("Debug: Biters are frozen (Game_over.lua).") end
end




local function biter_killed_the_silo(event)
	local force = event.force
	if force ~= nil then
		return string.find(event.force.name, "_biters")
	end

	local cause = event.cause
	if cause ~= nil then
		return (cause.valid and cause.type == 'unit')
	end

	log("Could not determine what destroyed the silo")
	if global.bb_debug then game.print("Debug: Could not determine what destroyed the silo") end
	return false
end

local function respawn_silo(event)
	local entity = event.entity
	local surface = entity.surface
	if surface == nil or not surface.valid then
		log("Surface " .. global.bb_surface_name .. " invalid - cannot respawn silo")
		return
	end

	local force_name = entity.force.name
	-- Has to be created instead of clone otherwise it will be moved to south.
	entity = surface.create_entity {
		name = entity.name,
		position = entity.position,
		surface = surface,
		force = force_name,
		create_build_effect_smoke = false,
	}
	entity.minable = false
	entity.health = 9 --EVL was 5
	global.rocket_silo[force_name] = entity
end

function Public.silo_death(event)
    local entity = event.entity
    if not entity.valid then return end
    if entity.name ~= "rocket-silo" then return end
    if global.bb_game_won_by_team then return end
    if entity == global.rocket_silo.south or entity == global.rocket_silo.north then

		-- Respawn Silo in case of friendly fire
		if not biter_killed_the_silo(event) then
			respawn_silo(event)
			return
		end
		
		global.bb_game_won_by_team = enemy_team_of[entity.force.name]
		set_victory_time()
		north_players = "NORTH PLAYERS: \\n"
		south_players = "SOUTH PLAYERS: \\n"
			
		for _, player in pairs(game.connected_players) do
			player.play_sound {path = "utility/game_won", volume_modifier = 1}
			if player.gui.left["bb_main_gui"] then
				player.gui.left["bb_main_gui"].visible = false
			end
			create_victory_gui(player)
			show_mvps(player)
			if (player.force.name == "south") then
				south_players = south_players .. player.name .. "   "
			elseif (player.force.name == "north") then
				north_players = north_players .. player.name .. "   "
			end
		end
		game.print(">>>>> GG ! Don't forget to re-allocate permissions as they were (use [color=#DDDDDD]/promote[/color] or [color=#DDDDDD]/demote[/color]).",{r = 197, g = 197, b = 17}) 
		global.spy_fish_timeout["north"] = game.tick + 999999
		global.spy_fish_timeout["south"] = game.tick + 999999
		global.server_restart_timer = 999999 --EVL see main.lua

		local c = gui_values[global.bb_game_won_by_team].c1
		if global.tm_custom_name[global.bb_game_won_by_team] then
			c = global.tm_custom_name[global.bb_game_won_by_team]
		end
			
		north_evo = math.floor(1000 * global.bb_evolution["north_biters"]) * 0.1
		north_threat = math.floor(global.bb_threat["north_biters"])
		south_evo = math.floor(1000 * global.bb_evolution["south_biters"]) * 0.1
		south_threat = math.floor(global.bb_threat["south_biters"])

		discord_message = "*** Team " .. global.bb_game_won_by_team .. " has won! ***" .. "\\n" ..
								global.victory_time .. "\\n\\n" .. 
								"North Evo: " .. north_evo .. "%\\n" ..
								"North Threat: " .. north_threat .. "\\n\\n" ..
								"South Evo: " .. south_evo .. "%\\n" ..
								"South Threat: " .. south_threat .. "\\n\\n" ..
								north_players .. "\\n\\n" .. south_players

		Server.to_discord_embed(discord_message)

		global.results_sent_south = false
		global.results_sent_north = false
		silo_kaboom(entity)

		freeze_all_biters(entity.surface)
    end
end

return Public
