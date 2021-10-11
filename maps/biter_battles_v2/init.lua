local Terrain = require "maps.biter_battles_v2.terrain"
local Score = require "comfy_panel.score"
local Tables = require "maps.biter_battles_v2.tables"
local fifo = require "maps.biter_battles_v2.fifo"
local team_manager = require "maps.biter_battles_v2.team_manager"

local Public = {}

function Public.initial_setup() --EVL init freeze and tournament mode
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	game.map_settings.enemy_expansion.enabled = false

	global.bb_debug = false --EVL BE CAREFUL, OTHER SETTINGS ARE SET TO DEBUG MODE (search for --CODING--)
	global.bb_biters_debug = false --EVL ADD MUCH VERBOSE TO BITERS AI
	global.bb_biters_debug2 = false --EVL ADD EVEN MUCH VERBOSE TO BITERS AI
	global.bb_debug_gui=false --EVL working on GUI inventory
	
	-- EVL change for map restart (/force-map-reset)
	local _first_init=true --EVL for disabling nauvis (below)
	if not game.forces["north"] then 
		game.create_force("north")
		--game.print(">>>>> WELCOME TO BBC ! Tournament mode is active, Players are frozen, Referee has to open [color=#FF9740]TEAM MANAGER[/color] <<<<<",{r = 00, g = 175, b = 00}) --EVL double message --DEBUG-- ?
	else
		if global.bb_debug then game.print("Debug : Executing initial setup (again)",{r = 00, g = 175, b = 00}) end
		--game.print(">>>>> You may need to refresh [color=#FF9740]TEAM MANAGER[/color] GUI manually",{r = 127, g = 127, b = 127})
		for _, player in pairs(game.players) do
			if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
		end
		--DEBUG-- REINIT SCORE ? NOT NEEDED IT SEEMS
		_first_init=false
	end
	if not game.forces["south"] then game.create_force("south") end
	if not game.forces["north_biters"] then game.create_force("north_biters") end
	if not game.forces["south_biters"] then game.create_force("south_biters") end
	if not game.forces["spectator"] then game.create_force("spectator") end


	game.forces.spectator.research_all_technologies()
	--EVL since biter league is set by default, we authorize blueprint library and import
	game.permissions.get_group("Default").set_allows_action(defines.input_action.open_blueprint_library_gui, true)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, true)

	local p = game.permissions.create_group("spectator")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], false)
	end

	local defs = {
		defines.input_action.activate_copy,
		defines.input_action.activate_cut,
		defines.input_action.activate_paste,
		defines.input_action.change_active_quick_bar,
		defines.input_action.clear_cursor,
		defines.input_action.edit_permission_group,
		defines.input_action.gui_click,
		defines.input_action.gui_confirmed,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_location_changed,
		defines.input_action.gui_selected_tab_changed,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_switch_state_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		--defines.input_action.open_character_gui,-- EVL remove possibility to open inventory
		defines.input_action.open_kills_gui,
		defines.input_action.quick_bar_set_selected_page,
		defines.input_action.quick_bar_set_slot,
		defines.input_action.rotate_entity,
		--defines.input_action.set_filter, -- EVL remove possibility to set quick bar filters (equity)
		defines.input_action.set_player_color,
		defines.input_action.start_walking,
		defines.input_action.toggle_show_entity_info,
		defines.input_action.write_to_console,
	}
	for _, d in pairs(defs) do p.set_allows_action(d, true) end

	global.gui_refresh_delay = 0
	global.game_lobby_active = true
	
	global.bb_settings = {
		--TEAM SETTINGS--
		["team_balancing"] = true,	--EVL dont care	--Should players only be able to join a team that has less or equal members than the opposing team?
		["only_admins_vote"] = true, --EVL YES			--Are only admins able to vote on the global difficulty? --EVL YES
	}

	
	--Disable Nauvis during first init only
	if _first_init then
		local surface = game.surfaces[1]
		local map_gen_settings = surface.map_gen_settings
		map_gen_settings.height = 3
		map_gen_settings.width = 3
		surface.map_gen_settings = map_gen_settings
		for chunk in surface.get_chunks() do
			surface.delete_chunk({chunk.x, chunk.y})
		end
	end

	global.tournament_mode = true -- EVL (none)
	global.training_mode  = false -- EVL (none)
	
	--global.freezed_start = 999999999 --EVL will be set to actual ticks_played game.ticks_played
	--global.freeze_players = true -- EVL (none)
	--team_manager.freeze_players() -- EVL (none) do we care about biters ?
	
	if global.freeze_players then --We are already frozen
		global.freezed_time=0 --EVL (none)
		--EVL we save tick when players started to be frozen (none)
		global.freezed_start=game.ticks_played
		--do nothing
		if global.bb_debug then game.print("Debug : Initial setup, players are already frozen",{r = 00, g = 175, b = 00}) end		
	else
		global.freezed_time=0
		global.freezed_start=999999999 -- EVL Will be set to game.ticks_played
		global.freeze_players = true -- EVL (none)
		team_manager.freeze_players() -- EVL (none) do we care about biters ?
		if global.bb_debug then game.print("Debug : Initial setup, players are set to frozen",{r = 00, g = 175, b = 00}) end		
	end	
	
end

--Terrain Playground Surface
function Public.playground_surface()
	local map_gen_settings = {}
	local int_max = 2 ^ 31
	map_gen_settings.seed = math.random(1, int_max) --EVL first math.random send always same value (since tick=0) ???
	--map_gen_settings.seed = 996357343 --CODING--
	--[[ SEEDS TO BE VERIFIED
		996357343
		1354075952
		1497223384
		1152708049
		1407416735 (ugh)
		1304692754 (copper in water)
	]]--
	map_gen_settings.water = math.random(15, 60) * 0.01 --EVL was 15,65
	map_gen_settings.starting_area = 2.5
	map_gen_settings.terrain_segmentation = math.random(30, 40) * 0.1
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 6.5, size = 0.4, richness = 0.40},
		["stone"] = {frequency = 6, size = 0.4, richness = 0.35},
		["copper-ore"] = {frequency = 7, size = 0.5, richness = 0.45},
		["iron-ore"] = {frequency = 8.5, size = 0.7, richness = 0.50}, 
		--["coal"] = {frequency = 6.5, size = 0.34, richness = 0.24}, --Values from Mewmew
		--["stone"] = {frequency = 6, size = 0.35, richness = 0.25},
		--["copper-ore"] = {frequency = 7, size = 0.32, richness = 0.35},
		--["iron-ore"] = {frequency = 8.5, size = 0.8, richness = 0.23}, 		
		["uranium-ore"] = {frequency = 2, size = 1, richness = 1},
		["crude-oil"] = {frequency = 8, size = 1.4, richness = 0.45},
		["trees"] = {frequency = math.random(8, 28) * 0.1, size = math.random(6, 14) * 0.1, richness = math.random(2, 4) * 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}
	}
	local surface = game.create_surface(global.bb_surface_name, map_gen_settings)
	surface.request_to_generate_chunks({x = 0, y = -256}, 7)
	surface.force_generate_chunk_requests()
end

function Public.draw_structures()
	local surface = game.surfaces[global.bb_surface_name]
	Terrain.draw_spawn_area(surface)
	--Terrain.clear_ore_in_main(surface)
	--Terrain.generate_spawn_ore(surface)

	Terrain.generate_additional_rocks(surface)
	Terrain.draw_spawn_circle(surface)
	Terrain.check_ore_in_main(surface)
	Terrain.generate_silo(surface)	
	
	--Terrain.generate_spawn_goodies(surface)
end

function Public.tables()
	local get_score = Score.get_table()
	get_score.score_table = {}
	global.science_logs_text = nil
	global.science_logs_total_north = nil
	global.science_logs_total_south = nil
	-- Name of main BB surface within game.surfaces
	-- We hot-swap here between 2 surfaces.
	if global.bb_surface_name == 'bb0' then
		global.bb_surface_name = "bb1"
	else
		global.bb_surface_name = "bb0"
	end

	global.active_biters = {}
	global.bb_evolution = {}
	global.bb_game_won_by_team = nil
	global.bb_threat = {}
	global.bb_threat_income = {}
	global.chosen_team = {}
	global.combat_balance = {}
	global.difficulty_player_votes = {}
	global.evo_raise_counter = 1
	global.force_area = {}
	global.map_pregen_message_counter = {} --EVL never used ?
	global.rocket_silo = {}
	global.spectator_rejoin_delay = {}
	global.spy_fish_timeout = {}
	global.target_entities = {}
	global.tm_custom_name = {}
	global.total_passive_feed_redpotion = 0
	global.unit_groups = {}
	global.unit_spawners = {}
	global.unit_spawners.north_biters = {}
	global.unit_spawners.south_biters = {}
	global.biter_spawn_unseen = {
		["north"] = {
			["medium-spitter"] = true, ["medium-biter"] = true, ["big-spitter"] = true, ["big-biter"] = true, ["behemoth-spitter"] = true, ["behemoth-biter"] = true
		},
		["south"] = {
			["medium-spitter"] = true, ["medium-biter"] = true, ["big-spitter"] = true, ["big-biter"] = true, ["behemoth-spitter"] = true, ["behemoth-biter"] = true
		}
	}
	global.difficulty_vote_value = 1
	global.difficulty_vote_index = 1 --EVL We set to biter_league by default

	global.difficulty_votes_timeout = 216000 -- EVL 60 minutes before vote close (choose difficulty)

	-- A FIFO that holds dead unit positions. It is used by unit
	-- reanimation logic. This container is to be accessed by force index.
	global.dead_units = {}

	-- A size of pre-allocated pool memory to be used in every FIFO.
	-- Higher value = higher memory footprint, faster I/O.
	-- Lower value = more resize cycles during push, dynamic memory footprint.
	global.bb_fifo_size = 1024

	-- A balancer threshold that instructs reanimation logic to increase
	-- number of API calls to LuaSurface::create_entity. This cycle threshold
	-- is representing amount of nodes within dead_units list. If it exceeds
	-- a multiplication of this value, additional call is made.
	--  * 50 = 1 additional call
	--  * 2250 = 45 additional call(s)
	-- This threshold is mainly used to protect against overflowing of
	-- reanimation requests at 100% reanimation chance. Additional benefit
	-- of it is to quickly revive a critical mass of biters in case defenses
	-- of attacked team are overpowered.
	global.reanim_balancer = 50

	-- Maximum evolution threshold after which biters have 100% chance
	-- to reanimate. The reanimation starts after evolution factor reaches
	-- 100, so this value starts having an effect only at that point.
	-- To reach 100% reanimation chance at 200% evolution, set it to 100.
	-- To reach 100% reanimation chance at 350% evolution, set it to 250.
	global.max_reanim_thresh = 250

	-- Container for storing chance of reanimation. The stored value
	-- is a range between [0, 100], accessed by key with force's index.
	global.reanim_chance = {}

	fifo.init()
	game.reset_time_played()
	
	global.main_attack_wave_amount = 0
	global.next_attack = "north" --EVL Coinflip moved to main.lua (and game_over.lua after reroll/reset) 
	--EVL Need a patch so first attack goes to team OUTSIDE (give an advantage top team ATHOME) not sure its an advantage though
	--EVL well, not even working since waves (with no group in them) are built during lobby time 
	--We need to set global.next_attack when match starts

	--Ai.lua BASE OF WAY POINTS
	global.way_point_radius = 512
	global.way_points_base = {}
	global.way_points_base.north = {}
	global.way_points_base.south = {}

	--AI.lua DEFAULT WAY  POINTS
	global.default_way_points_nb = 5	-- number of  default way points
	global.default_way_points  = {}	-- table of  default waypoints, 80% chance to be used

	--AI.lua RANDOM WAY  POINTS
	global.way_points_table = {  --Store way_points to use them on the other side (equity/balance)
		["north"]={},
		["south"]={}
	}
	global.way_points_max=15 -- limit to the number of way_points stored

	
	global.scraps_mined = {  --We save #scraps that were mined by force
		["north"]=0,
		["south"]=0
	}
	
	
	global.game_id=nil --EVL Game Identificator from website (via lobby?)
	--global.game_id=12546 --CODING--
	
	global.player_init_timer=20 -- 20 half seconds for intro animation
	--global.player_init_timer=0 --CODING--
	global.player_anim={} -- each player has his countdown when joined in

	global.reroll_max=2 --EVL Maximum # of rerolls (only used in export stats, see main.lua)
	--global.reroll_max=100 --EVL TO be removed  --CODING-- 2 or 3 ???????
	global.reroll_left=global.reroll_max --EVL = global.reroll_max as we init (will be set to real value after a reroll has been asked)
	global.reroll_do_it=false --EVL (none)

	global.bbc_pack_details = "" -- EVL USED IN functions.lua FOR listing of packs details
	global.pack_choosen = ""	--EVL starter pack choosen
	global.fill_starter_chests = false  --EVL 
	global.starter_chests_are_filled = false  --EVL (none)
	global.match_countdown = 9 --EVL time of the countdown in seconds before match starts (unpause will have a 3 seconds countdown)
	--global.match_countdown = 1 --CODING--
	
	global.match_running = false  --EVL determine if this is first unfreeze (start match) or nexts (pause/unpause)

	global.freezed_time=0 --EVL (none)
	global.freezed_start=game.ticks_played --EVL we save tick when players started to be frozen (none)
	global.reveal_init_map=true --EVL (none)
	global.evo_boost_tick=2*60*60*60 --EVL ARMAGEDDON We boost evo starting at 2h=120m 
	--global.evo_boost_tick=2*60*60 --EVL  --CODING--
	global.evo_boost_duration=30 -- Duration before evo goes to 90 (in minutes)
	global.evo_boost_active=false --EVL we dont need to check that too often, once its done its done
	global.evo_boost_values={ 	-- EVL set to boost values after global.evo_boost_tick (1%=0.01)
		["north_biters"]=0.00, 
		["south_biters"]=0.00
	}	
	
	global.force_map_reset_exceptional=false -- set to true if a map reset is called via chat command
	global.force_map_reset_export_reason={} -- we save infos about force-map-resets
	
	global.export_stats_are_set = false -- first : At the end of the match we first we set the datas
	global.export_stats_done=nil -- then : Set to true after match is over and stats are exported
	global.science_per_player = {} -- table for total science sent per player -> global.science_per_player[player.name][indexScience]
	
	
	--global.server_restart_timer = 20 -- EVL see main.lua, need to be nil
	global.god_players={} -- EVL List of players in spec_god force/mode : we have 2 kinds of specs (see spectator_zoom.lua)
	
	global.auto_training  = {
		["north"]={["player"]="",["active"]=false,["qtity"]=0,["science"]="",["timing"]=0},
		["south"]={["player"]="",["active"]=false,["qtity"]=0,["science"]="",["timing"]=0}	
	}

end

function Public.load_spawn()
	local surface = game.surfaces[global.bb_surface_name]
	surface.request_to_generate_chunks({x = 0, y = 0}, 1)
	surface.force_generate_chunk_requests()

	surface.request_to_generate_chunks({x = 0, y = 0}, 2)
	surface.force_generate_chunk_requests()

	for y = 0, 576, 32 do
		surface.request_to_generate_chunks({x = 80, y = y + 16}, 0)
		surface.request_to_generate_chunks({x = 48, y = y + 16}, 0)
		surface.request_to_generate_chunks({x = 16, y = y + 16}, 0)
		surface.request_to_generate_chunks({x = -16, y = y - 16}, 0)
		surface.request_to_generate_chunks({x = -48, y = y - 16}, 0)
		surface.request_to_generate_chunks({x = -80, y = y - 16}, 0)

		surface.request_to_generate_chunks({x = 80, y = y * -1 + 16}, 0)
		surface.request_to_generate_chunks({x = 48, y = y * -1 + 16}, 0)
		surface.request_to_generate_chunks({x = 16, y = y * -1 + 16}, 0)
		surface.request_to_generate_chunks({x = -16, y = y * -1 - 16}, 0)
		surface.request_to_generate_chunks({x = -48, y = y * -1 - 16}, 0)
		surface.request_to_generate_chunks({x = -80, y = y * -1 - 16}, 0)
	end
end

--Initialize base of way_points_base and default waypoints (from on_init() in main.lua, to use in ai.lua)
function Public.init_waypoints()
	-- FIRST BASE OF WAYPOINTS
	local p=0.49
	local _step=0.05
	--EVL the waypoints are p=0.49 0.44 0.38 0.31 0.23 0.14 0.04
	-- (slightly more chance to come vertically than horizontally)
	while p>0 do
		local a = math.pi * p
		local x = math.floor(global.way_point_radius * math.cos(a))
		local y = math.floor(global.way_point_radius * math.sin(a))
		global.way_points_base.north[#global.way_points_base.north + 1] = {x, y * -1}
		global.way_points_base.south[#global.way_points_base.south + 1] = {x, y}
		p=p-_step
		_step=_step+0.01
	end
	--ADD one vertical waypoint at p=0.47, so biters have slightly more chance to come from vertical axe
		p=0.47
		local a = math.pi * p
		local x = math.floor(global.way_point_radius * math.cos(a))
		local y = math.floor(global.way_point_radius * math.sin(a))
		global.way_points_base.north[#global.way_points_base.north + 1] = {x, y * -1}
		global.way_points_base.south[#global.way_points_base.south + 1] = {x, y}
	--PRINT BASE WP
	local base_str="          Base waypoints: "
	for _index=1,#global.way_points_base.south,1 do
		base_str=base_str.." ("..global.way_points_base.south[_index][1]..","..global.way_points_base.south[_index][2]..")"
	end
	if global.bb_biters_debug then game.print(base_str,{r = 200, g = 200, b = 250}) end	
	
	--SECOND SELECT POINTS FROM BASE TO FILL DEFAULT_WAYPOINTS
	-- Initialize table with default way points to be used frequently (and rarely we'll send to random waypoint)
	local _dft_wp_str="          Default way_points: "
	local _last_way_pt=0
	for _dwp= 1,global.default_way_points_nb,1 do
		local _way_pt=math.random(1,#global.way_points_base.north)
		--DEBUG--if _way_pt==_last_way_pt then _way_pt=math.random(1,#global.way_points_base.north) end -- we slighlty avoid duplicate waypoints
		_last_way_pt=_way_pt
		local _wayPoint=global.way_points_base.north[_way_pt]
		--Randomize X axis
		--DEBUG--if math.random(0,1)==1 then  _wayPoint[1]=-1*_wayPoint[1] end
		if _way_pt%2==0 then _wayPoint[1]=-1*_wayPoint[1] end
		global.default_way_points[#global.default_way_points + 1]=_wayPoint
		_dft_wp_str = _dft_wp_str .. " (".._wayPoint[1]..",".._wayPoint[2]..") "
	end
	--PRINT DEFAULT WP
	if global.bb_biters_debug then game.print(_dft_wp_str,{r = 200, g = 200, b = 250}) end

end

function Public.forces()
	for _, force in pairs(game.forces) do
		if force.name ~= "spectator" then
			force.reset()
			force.reset_evolution()
		end
	end

	local surface = game.surfaces[global.bb_surface_name]

	local f = game.forces["north"]
	f.set_spawn_position({0, -44}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("south_biters", true)
	f.share_chart = true

	local f = game.forces["south"]
	f.set_spawn_position({0, 44}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("north_biters", true)
	f.share_chart = true

	local f = game.forces["north_biters"]
	f.set_friend("south_biters", true)
	f.set_friend("south", true)
	f.set_friend("player", true)
	f.set_friend("spectator", true)
	f.share_chart = false
	global.dead_units[f.index] = fifo.create(global.bb_fifo_size)

	local f = game.forces["south_biters"]
	f.set_friend("north_biters", true)
	f.set_friend("north", true)
	f.set_friend("player", true)
	f.set_friend("spectator", true)
	f.share_chart = false
	global.dead_units[f.index] = fifo.create(global.bb_fifo_size)

	local f = game.forces["spectator"]
	f.set_spawn_position({0,0},surface)
	f.technologies["toolbelt"].researched = true
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_friend("north", true)
	f.set_friend("south", true)
	f.set_cease_fire("player", true)
	f.share_chart = true

	local f = game.forces["player"]
	f.set_spawn_position({0,0},surface)
	f.set_cease_fire('spectator', true)
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_cease_fire('north', true)
	f.set_cease_fire('south', true)
	f.share_chart = false

	for _, force in pairs(game.forces) do
		game.forces[force.name].technologies["artillery"].enabled = false
		game.forces[force.name].technologies["artillery-shell-range-1"].enabled = false
		game.forces[force.name].technologies["artillery-shell-speed-1"].enabled = false
		game.forces[force.name].technologies["atomic-bomb"].enabled = false
		game.forces[force.name].technologies["cliff-explosives"].enabled = false
		game.forces[force.name].technologies["land-mine"].enabled = false
		game.forces[force.name].research_queue_enabled = true
		global.target_entities[force.index] = {}
		global.spy_fish_timeout[force.name] = 0
		global.active_biters[force.name] = {}
		global.bb_evolution[force.name] = 0
		global.reanim_chance[force.index] = 0
		global.bb_threat_income[force.name] = 0
		global.bb_threat[force.name] = 0
	end
	for _, force in pairs(Tables.ammo_modified_forces_list) do
		for ammo_category, value in pairs(Tables.base_ammo_modifiers) do
			game.forces[force]
				.set_ammo_damage_modifier(ammo_category, value)
		end
	end

	for _, force in pairs(Tables.ammo_modified_forces_list) do
		for turret_category, value in pairs(Tables.base_turret_attack_modifiers) do
			game.forces[force]
				.set_turret_attack_modifier(turret_category, value)
		end
	end

end

return Public
