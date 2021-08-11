-- Biter Battles v2 -- by MewMew

local Ai = require "maps.biter_battles_v2.ai"
local Functions = require "maps.biter_battles_v2.functions"
local Game_over = require "maps.biter_battles_v2.game_over"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"

local Mirror_terrain = require "maps.biter_battles_v2.mirror_terrain"
require 'modules.simple_tags'
local Team_manager = require "maps.biter_battles_v2.team_manager"
	
local Terrain = require "maps.biter_battles_v2.terrain"
local Session = require 'utils.datastore.session_data'
local Color = require 'utils.color_presets'
local diff_vote = require "maps.biter_battles_v2.difficulty_vote"



require "maps.biter_battles_v2.sciencelogs_tab"
-- require 'maps.biter_battles_v2.commands' --EVL no need (other way to restart : use /force_map_reset instead)
require "modules.spawners_contain_biters"

require 'spectator_zoom' -- EVL Zoom for spectators 

local function on_player_joined_game(event)
	local surface = game.surfaces[global.bb_surface_name]
	local player = game.players[event.player_index]
	if player.online_time == 0 or player.force.name == "player" then
		Functions.init_player(player)
	end
	Functions.create_map_intro_button(player)
	Functions.create_bbc_packs_button(player)
	Team_manager.draw_top_toggle_button(player)
	local msg_freeze = "unfrozen" --EVL not so useful (think about player disconnected then join again)
	if global.freeze_players then msg_freeze="frozen" end
	player.print(">>>>> WELCOME TO BBC ! Tournament mode is active, Players are "..msg_freeze..", Referee has to open TEAM MANAGER",{r = 00, g = 225, b = 00})
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end

	if Functions.map_intro_click(player, element) then 
		return 
	end
	if Functions.bbc_packs_click(player, element) then 
		return 
	end	
	Team_manager.gui_click(event)
end

local function on_research_finished(event)
	Functions.combat_balance(event)
end

local function on_console_chat(event)
	Functions.share_chat(event)
end

local function on_built_entity(event)
	Functions.no_turret_creep(event)
	Functions.add_target_entity(event.created_entity)
end

local function on_robot_built_entity(event)
	Functions.no_turret_creep(event)
	Terrain.deny_construction_bots(event)
	Functions.add_target_entity(event.created_entity)
end

local function on_robot_built_tile(event)
	Terrain.deny_bot_landfill(event)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if Ai.subtract_threat(entity) then Gui.refresh_threat() end
	if Functions.biters_landfill(entity) then return end
	Game_over.silo_death(event)
end

local tick_minute_functions = {
	[300 * 1] = Ai.raise_evo,
	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3 + 30 * 0] = Ai.pre_main_attack,		-- setup for main_attack
	[300 * 3 + 30 * 1] = Ai.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
	[300 * 3 + 30 * 2] = Ai.perform_main_attack,	-- some of these might do nothing (if there are no wave left)
	[300 * 3 + 30 * 3] = Ai.perform_main_attack,
	[300 * 3 + 30 * 4] = Ai.perform_main_attack,
	[300 * 3 + 30 * 5] = Ai.perform_main_attack,
	[300 * 3 + 30 * 6] = Ai.perform_main_attack,
	[300 * 3 + 30 * 7] = Ai.perform_main_attack,
	[300 * 3 + 30 * 8] = Ai.post_main_attack,
	[300 * 4] = Ai.send_near_biters_to_silo,
	[300 * 5] = Ai.wake_up_sleepy_groups,
}

local function on_tick()
	local tick = game.tick
	--if not global.freeze_players and not global.bb_game_won_by_team then --EVL patch ?
		Ai.reanimate_units()
	--end

	if not global.freeze_players and tick % 60 == 0 then --evl
		global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
		global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]
	end

	--if tick % 300 == 0 then -- EVL WAS 180
	--	Gui.refresh()
	--	diff_vote.difficulty_gui()
	--end

	
	if tick % 300 == 0 then --EVL is called at the same tick as tick_minute_functions, could be changed to : if (tick+8) % 300 == 0
		--EVL we clear corpses every 2 minutes
		if tick%7200 == 0 then clear_corpses_auto() end
		Gui.refresh() --EVL from above
		diff_vote.difficulty_gui()
		
		Gui.spy_fish()
		
		if global.reveal_init_map and (game.ticks_played > 600) then  --EVL we reveal 100x100 for reroll purpose (up to 10s delay)
			Game_over.reveal_init_map(100)
			global.reveal_init_map=false 
		end	
		
		if global.fill_starter_chests then -- EVL Fill the chests (when clicked in team manager)
			local surface = game.surfaces[global.bb_surface_name] -- is this the right way  ?
			Terrain.fill_starter_chests(surface) -- in terrain.lua
			global.fill_starter_chests = false
		end
		if global.reroll_do_it then -- EVL Reroll the map (twice MAX)
			if global.reroll_left<1 then 
				game.print(">>>>>>  BUG TOO MUCH REROLL - REROLL CANCELLED") 
			else 
				--game.print("GO FOR REROLL") 
				global.server_restart_timer = 5 --EVL Trick to instant reroll
				--Game_over.reveal_map()
				Game_over.server_restart()
				global.reroll_left=global.reroll_left-1
				global.pack_choosen = "" -- EVL Reinit Starter pack
				global.reroll_do_it=false
			end
		end
		
		--EVL but we keep possibility to reset for exceptionnal reasons 
		if global.force_map_reset_exceptional then		 
			--game.print("main-forcemapreset=true")
			if not global.server_restart_timer then 
				global.server_restart_timer=20 
			end
			Game_over.reveal_map() --EVL must be repeated
			Game_over.server_restart()
			global.reroll_left=2 --EVL Reinit #Nb reroll
			global.pack_choosen = "" --EVL Reinit Starter pack
			return
		end
		
		--EVL We dont reset after match ends (trick : global.server_restart_timer=999999)
		if global.bb_game_won_by_team then		 --EVL no restart (debrief, save etc...) 
			Game_over.reveal_map()
			Game_over.server_restart() --WILL NEVER HAPPEN (global.server_restart_timer=999999)
			return
		end


		if tick % 1200 == 0 then --EVL monitoring game times every 20s for ELO BOOST
			if global.freezed_start == 999999999 then -- players are unfreezed
				if not global.evo_boost_active then -- EVO BOOST AFTER 2H (global.tick_evo_boost=60*60*60*2)
					local real_played_time = game.ticks_played - global.freezed_time
					if real_played_time >= global.evo_boost_tick then
						-- EVL FOR TESTING/DEBUG, TO BE REMOVED***********************************************
						global.bb_evolution["north_biters"] = global.bb_evolution["north_biters"] + 0.10
						global.bb_evolution["south_biters"] = global.bb_evolution["south_biters"] + 0.15

						--Set boost for north and south
					
						local evo_north = global.bb_evolution["north_biters"]
						if evo_north<0.00001 then evo_north=0.00001 end --!DIV0
						local evo_south = global.bb_evolution["south_biters"]
						if evo_south<0.00001 then evo_south=0.0001 end --!DIV0
						
						if evo_north < evo_south then
							-- WE WANT NORTH TO GO UP TO 90% UNTIL 2H30 (PLUS NATURAL AND SENDINGS)
							local boost_north = (0.9-evo_north) / 30
							if boost_north < 0.01 then boost_north = 0.01 end -- MINIMUM SET AT 1% per MIN
							local evo_ratio = evo_south / evo_north -- NORTH KEEPS ADVANTAGE
							local evo_corr = (evo_south-evo_north)/(evo_south+evo_north) --ARBITRARY
							--game.print(">>>>>> EVO_NORTH=".. evo_north .. "BOOST=" .. boost_north .. " RATIO="..evo_ratio)
							--game.print(">>>>>> EVO_SOUTH=".. evo_south .. "BOOST=xxxxx" .. " CORR="..evo_corr)							
							local boost_south = boost_north * evo_ratio * (1 - evo_corr)
							global.evo_boost_values["north_biters"] = boost_north
							global.evo_boost_values["south_biters"] = boost_south
						else
							-- WE WANT SOUTH TO GO UP TO 90% UNTIL 2H30 (PLUS NATURAL AND SENDINGS)
							local boost_south = (0.9-evo_south) / 30
							if boost_south < 0.01 then boost_south = 0.01 end -- MINIMUM SET AT 1% per MIN
							local evo_ratio = evo_north / evo_south -- SOUTH KEEPS ADVANTAGE
							local evo_corr = (evo_north-evo_south)/(evo_south+evo_north) --ARBITRARY CORRECTION
							--game.print(">>>>>> EVO_NORTH=".. evo_north .. "BOOST=xxxxx" .. " RATIO="..evo_ratio)
							--game.print(">>>>>> EVO_SOUTH=".. evo_south .. "BOOST=" .. boost_south.. " CORR="..evo_corr)
							local boost_north = boost_south * evo_ratio * (1 - evo_corr)
							global.evo_boost_values["north_biters"] = boost_north
							global.evo_boost_values["south_biters"] = boost_south
						end
						global.evo_boost_active = true --We wont come here again
						local _b_north=math.floor(global.evo_boost_values["north_biters"]*10000)/100
						local _b_south=math.floor(global.evo_boost_values["south_biters"]*10000)/100
						game.print(">>>>> TIME HAS PASSED !!! EVOLUTION IS NOW BOOSTED !!! (%north=".._b_north.."  | %south=".._b_south..")", {r = 255, g = 77, b = 77})
					end
				end
				--game.print("UNFREEZ : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.." & FS="..global.freezed_start..")") 
			
			else -- players are freezed since global.freezed_start, and we dont care about EVO BOOST
				--game.print("FREEZED : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.."+"..(game.ticks_played-global.freezed_start).." & FS="..global.freezed_start..")") 
			end
		end
	end
	-- EVL NO EVO/THREAT OR GROUPS WHEN FREEZE
	if tick % 30 == 0 then	
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
	end
end

local function on_marked_for_deconstruction(event)
	if not event.entity.valid then return end
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	Terrain.restrict_landfill(player.surface, player, event.tiles)
end

--local function on_player_built_tile(event) --EVL why is this function double copied?
--	local player = game.players[event.player_index]
--	Terrain.restrict_landfill(player.surface, player, event.tiles)
--end

local function on_player_mined_entity(event)
	Terrain.minable_wrecks(event)
end

local function on_chunk_generated(event)
	local surface = event.surface

	-- Check if we're out of init.
	if not surface or not surface.valid then return end

	-- Necessary check to ignore nauvis surface.
	if surface.name ~= global.bb_surface_name then return end

	-- Generate structures for north only.
	local pos = event.area.left_top
	if pos.y < 0 then
		Terrain.generate(event)
	end

	-- Request chunk for opposite side, maintain the lockstep.
	-- NOTE: There is still a window where user can place down a structure
	-- and it will be mirrored. However this window is so tiny - user would
	-- need to fly in god mode and spam entities in partially generated
	-- chunks.
	local req_pos = { pos.x + 16, -pos.y + 16 }
	surface.request_to_generate_chunks(req_pos, 0)

	-- Clone from north and south. NOTE: This WILL fire 2 times
	-- for each chunk due to asynchronus nature of this event.
	-- Both sides contain arbitary amount of chunks, some positions
	-- when inverted will be still in process of generation or not
	-- generated at all. It is important to perform 2 passes to make
	-- sure everything is cloned properly. Normally we would use mutex
	-- but this is not reliable in this environment.
	Mirror_terrain.clone(event)
end

local function on_entity_cloned(event)
	local source = event.source
	local destination = event.destination

	-- In case entity dies between clone and this event we
	-- have to ensure south doesn't get additional objects.
	if not source.valid then
		if destination.valid then
			destination.destroy()
		end

		return
	end

	Mirror_terrain.invert_entity(event)
end

local function on_area_cloned(event)
	local surface = event.destination_surface

	-- Check if we're out of init and not between surface hot-swap.
	if not surface or not surface.valid then return end

	-- Event is fired only for south side.
	Mirror_terrain.invert_tiles(event)

	-- Check chunks around southen silo to remove water tiles under stone-path.
	-- Silo can be removed by picking bricks from under it in a situation where
	-- stone-path tiles were placed directly onto water tiles. This scenario does
	-- not appear for north as water is removed during silo generation.
	local position = event.destination_area.left_top
	if position.y == 64 and math.abs(position.x) <= 64 then
		Mirror_terrain.remove_hidden_tiles(event)
	end
end

local function clear_corpses(cmd) -- EVL After command /clear-corpses radius
	local player = game.player
       -- EVL not needed for BBC tournament, trust parameter is never used
		--local trusted = Session.get_trusted_table()
        local param = tonumber(cmd.parameter)

        if not player or not player.valid then
            return
        end
        local p = player.print
        --if not trusted[player.name] then
        --    if not player.admin then
        --        p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
        --        return
        --    end
        --end
        if param == nil then
            player.print('[ERROR] Must specify radius!', Color.fail)
            return
        end
        if param < 0 then
            player.print('[ERROR] Value is too low.', Color.fail)
            return
        end
        if param > 500 then
            player.print('[ERROR] Value is too big.', Color.fail)
            return
        end

	if not Ai.empty_reanim_scheduler() then
		player.print("[ERROR] Some corpses are waiting to be reanimated...")
		player.print(" => Try again in short moment")
		return
	end

        local pos = player.position

        local radius = {{x = (pos.x + -param), y = (pos.y + -param)}, {x = (pos.x + param), y = (pos.y + param)}}
        for _, entity in pairs(player.surface.find_entities_filtered {area = radius, type = 'corpse'}) do
            if entity.corpse_expires then
                entity.destroy()
            end
        end
        player.print('Cleared biter-corpses.', Color.success)
end

local function clear_corpses_auto() -- Automatic clear corpses called every 2 min
	if not Ai.empty_reanim_scheduler() then
		if global.bb_debug then game.print("Debug: Some corpses are waiting to be reanimated... Skipping this turn of clear_corpses") end
		return
	end
        local _param=500
		 local radius = {{x = (0 + -_param), y = (0 + -_param)}, {x = (0 + _param), y = (0 + _param)}}
        for _, entity in pairs(player.surface.find_entities_filtered {area = radius, type = 'corpse'}) do
            if entity.corpse_expires then
                entity.destroy()
            end
        end
	if global.bb_debug then game.print("Debug: Cleared biter-corpses.", Color.success) end
end




local function on_init()
	Init.tables()
	Init.initial_setup()
	Init.playground_surface() -- EVL We have a problem first math.random for seed of map gives always same value (since tick=0) ???
	-- EVL patch : ???
	
	Init.forces()
	Init.draw_structures()
	Init.load_spawn()
end

local Event = require 'utils.event'
Event.add(defines.events.on_area_cloned, on_area_cloned)
Event.add(defines.events.on_research_finished, Ai.unlock_satellite)			--free silo space tech
Event.add(defines.events.on_post_entity_died, Ai.schedule_reanimate)
Event.add_event_filter(defines.events.on_post_entity_died, {
	filter = "type",
	type = "unit",
})
Event.add(defines.events.on_entity_cloned, on_entity_cloned)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_console_chat, on_console_chat)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)

commands.add_command('clear-corpses', 'Clears all the biter corpses..',
		     clear_corpses)

require "maps.biter_battles_v2.spec_spy"
