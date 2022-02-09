-- Biter Battles v2 -- by MewMew

local Ai = require "maps.biter_battles_v2.ai"
local Functions = require "maps.biter_battles_v2.functions"
local Game_over = require "maps.biter_battles_v2.game_over"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Sendings_Patterns = require "maps.biter_battles_v2.sendings_tab" --EVL for simulation of previous game sendings
local Score = require "comfy_panel.score" --EVL (none)
local bb_config = require "maps.biter_battles_v2.config" --EVL need  bb_config.border_river_width to manage fishing  (see on_marked_for_deconstruction)
local Mirror_terrain = require "maps.biter_battles_v2.mirror_terrain"
require 'modules.simple_tags' -- is this used ?
require "maps.biter_battles_v2.spec_spy" --for tech button (open tech tree for admins+specs)
local Team_manager = require "maps.biter_battles_v2.team_manager"
	
local Terrain = require "maps.biter_battles_v2.terrain"
local Session = require 'utils.datastore.session_data'
local Color = require 'utils.color_presets'
local diff_vote = require "maps.biter_battles_v2.difficulty_vote"

local feed_the_biters = require "maps.biter_battles_v2.feeding" --EVL to use with /training command 

local Science_logs = require "maps.biter_battles_v2.sciencelogs_tab"
-- require 'maps.biter_battles_v2.commands' --EVL no need (other way to restart : use /force_map_reset instead)
require "modules.spawners_contain_biters" -- is this used ?

--require 'spectator_zoom' -- EVL Zoom for spectators -> Moved to GUI.LEFT

--EVL A BEAUTIFUL COUNTDOWN (WAS IN ASCII ART) (game.print 10+ then images from 9 -> 1)
local function show_countdown(_second)
	if not _second or _second<0 then return end
	if _second==0 then
		--for _, player in pairs(game.connected_players) do
		game.play_sound{path = "utility/new_objective", volume_modifier = 1}
			--sounds : console_message
		--end
		return
	end
	if _second>9 then 
		game.print(">>>>> ".._second.."s remaining", {r = 77, g = 192, b = 77})
		--for _, player in pairs(game.connected_players) do
		game.play_sound{path = "utility/gui_click", volume_modifier = 0.2}
		--end
		return 
	end
	for _, player in pairs(game.connected_players) do
		--EVL close all gui.center frames
		for _, gui_names in pairs(player.gui.center.children_names) do 
			player.gui.center[gui_names].destroy()
		end
		local _sprite="file/png/".._second..".png" 
		player.gui.center.add{name = "bbc_cdf", type = "sprite", sprite = _sprite} -- EVL cdf for countdown_frame
	end	
	game.play_sound{path = "utility/list_box_click", volume_modifier = math.min(1,2/_second)}  --other sounds crafting_finished ? inventory_move? smart_pipette? blueprint_selection_ended?
end
--EVL SOME IMAGES TO INTRODUCE WHEN PLAYER JOINS
local function show_anim_player(player,countdown)
	--Close all GUI.CENTER except show_anim_png
	for _, gui_name in pairs (player.gui.center.children_names) do -- :: array[string] [R]	Names of all the children of this element.
		if gui_name ~= "show_anim_png" then player.gui.center[gui_name].destroy() end
	end

	--Simple way to show the anims (countdown is measured in half seconds)
	if countdown ==19 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_100.png"}
		player.play_sound{path = global.sound_intro, volume_modifier = 0.4}
	elseif countdown ==18 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_150.png"}
		player.play_sound{path = global.sound_intro, volume_modifier = 0.5}
	elseif countdown ==17 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_200.png"}
		player.play_sound{path = global.sound_intro, volume_modifier = 0.6}
	elseif countdown ==16 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_300.png"}
		player.play_sound{path = global.sound_intro, volume_modifier = 0.7}
	elseif countdown ==15 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		local _png = player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_1000.png"}
		player.play_sound{path = global.sound_intro, volume_modifier = 0.9}
	elseif countdown ==9 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_bbc.png"}
		player.play_sound{path = "utility/new_objective", volume_modifier = 0.8}
	elseif countdown ==1 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		Functions.show_intro(player)
	end

end

--EVL EXPORTING DATAS TO FRAME AND TO JSON FILE
--dependance : global.export_stats_are_set = false
local _guit = ""				--_GUI_TITLE FULL WIDTH
local _guitl = ""				--_GUI_TOP_LEFT	(Global)
local _json_global = {}		-- JSON GLOBAL STATS (+ force-map-reset)
local _guitm = ""				--_GUI_TOP_MID	(North recap)
local _json_north = {}			-- JSON NORTH STATS (North recap)
local _guitr = ""				--_GUI_TOP_RIGHT	(South recap)
local _json_south = {}			-- JSON SOUTH STATS	(South recap)
local _json_players_north = {}	-- JSON NORTH PLAYERS STATS
local _json_players_south = {}	-- JSON SOUTH PLAYERS STATS
local _guib = ""				--_GUI_BOTTOM

--SETTINGS STATS ONCE FOR ALL TO USE IN EXPORT JSON AND DRAW RESULTS
local function set_stats_title() 				--fill up string "_guit" and table "_json_global"
	
	_guit=_guit.."[font=default-large-bold][color=#FF5555] --- THANKS FOR PLAYING [/color][color=#5555FF]BITER[/color]  "
	_guit=_guit.."[color=#55FF55]BATTLES[/color]  [color=#FF5555]CHAMPIONSHIPS ---[/color][/font]      "..global.version.."\n"
	_guit=_guit.."see all results at [color=#DDDDDD]https://bbchampions.org[/color] , follow us on twitter [color=#DDDDDD]@BiterBattles[/color]\n"
	--_guit=_guit.."[font=default-bold][color=#77DD77]ADD the result [/color][color=#999999](gameId)[/color][color=#77DD77] to the website [/color][color=#999999](referee)[/color]"--TODO--
	--_guit=_guit.."[color=#77DD77] & SET url of the replays [/color][color=#999999](players & streamers)[/color][color=#77DD77] ASAP ![/color][/font]\n"--TODO--
	_guit=_guit.."[font=default-small][color=#999999]Note: Referee/Admins need to re-allocate permissions as they were before this game.[/color][/font]\n\n"
	_guit=_guit.."[font=default-large-bold][color=#FF5555]--- [color=#55FF55]RESULTS[/color] and [color=#5555FF]STATISTICS[/color]  ---[/color][/font]"

end
local function set_stats_force_map_reset()	--fill up string "_guib" and table "_json_global["MAP_RESET"]"
		local fmr_nb=table_size(global.force_map_reset_export_reason) --EVL number of force-map-reset
		_json_global["MAP_RESET"]={}
		if global.way_points_max_reached then  --We announce that some waypoints were forgotten in stats.json
			_guib=_guib.."\n[font=default-bold][color=#FF9740]>>MAX WAYPOINTS REACHED>>[/color][/font] [font=default-small][color=#999999]"
			_guib=_guib.." (this match reached "..global.way_points_max.." waypoints, ie forgot some of them)[/color][/font]\n"
		end
		if fmr_nb>0 then
			_guib=_guib.."\n[font=default-bold][color=#FF9740]>>FORCE MAP RESETS>>[/color][/font] [font=default-small][color=#999999]"
			_guib=_guib.."   (organisators will double check this)[/color][/font]\n"
			for _index=1,fmr_nb,1 do 
				_guib=_guib.." [".._index.."] "..global.force_map_reset_export_reason[_index].."\n" 
				table.insert(_json_global["MAP_RESET"],global.force_map_reset_export_reason[_index])
			end
			_guib=string.sub(_guib, 1, string.len(_guib)-1)
		end
end
local function set_stats_team()				--fill up string "_guitl & _guitm & _guitr" and tables "json_global & json_north & json_south"
	local biters = {'small-biter','medium-biter','big-biter','behemoth-biter','small-spitter','medium-spitter','big-spitter','behemoth-spitter'}
	local worms =  {'small-worm-turret','medium-worm-turret','big-worm-turret'} --remove behemoth ,'behemoth-worm-turret'}
	local spawners = {'biter-spawner', 'spitter-spawner'}
	--
	--GLOBAL STATS (GUI_LEFT, LEFT COLUMN)
	--
	_guitl=_guitl.."[font=default-bold][color=#FF9740]>>GLOBAL>>[/color][/font]\n"
	_guitl=_guitl.."     GAME_ID="..global.game_id.."\n"
	_guitl=_guitl.."     REFEREE: ".."tbd".."\n"
	_guitl=_guitl.."     ATHOME: ".."tbd".."\n"
	_guitl=_guitl.."     REROLL: "..(global.reroll_max-global.reroll_left).."\n"
	_guitl=_guitl.."     STARTER PACK  "..Tables.packs_list[global.pack_choosen]["caption"].."\n"
	_guitl=_guitl.."     DIFFICULTY  "..global.difficulty_vote_index..": [color="..diff_vote.difficulties[global.difficulty_vote_index].short_color.."]"
			..diff_vote.difficulties[global.difficulty_vote_index].name.." ("..diff_vote.difficulties[global.difficulty_vote_index].str..")[/color]\n"
	_guitl=_guitl.."     DURATION: "..math.floor((game.ticks_played-global.freezed_time)/3600).."m | Lobby: "..math.floor(global.freezed_time/60).."s\n"
	local _bb_game_won_by_team=global.bb_game_won_by_team
	local _bb_game_loss_by_team = Tables.enemy_team_of[_bb_game_won_by_team]
	if global.tm_custom_name[_bb_game_won_by_team] then _bb_game_won_by_team = global.tm_custom_name[_bb_game_won_by_team].." (".._bb_game_won_by_team..")"	end
	if global.tm_custom_name[_bb_game_loss_by_team] then _bb_game_loss_by_team = global.tm_custom_name[_bb_game_loss_by_team].." (".._bb_game_loss_by_team..")"	end
	_guitl=_guitl.."     [color=#97FF40]WINNER: ".._bb_game_won_by_team.."[/color]\n"
	_guitl=_guitl.."     [color=#FF4040]LOSER: ".._bb_game_loss_by_team.."[/color]\n"

	_json_global={ 		--THE JSON GLOBAL STATS (topleft)
		["GAME_ID"]	= global.game_id, 
		["TICK"]		= game.tick, 
		["REFEREE"]	= "tbd", 
		["ATHOME"]		= "tbd", 
		["REROLL"]		= global.reroll_max-global.reroll_left, 
		["DIFFICULTY"]= diff_vote.difficulties[global.difficulty_vote_index].name, 
		["PACK"]		= Tables.packs_list[global.pack_choosen]["title"],
		["DURATION"]	= game.ticks_played-global.freezed_time,
		["PAUSED"]		= global.freezed_time, 
		["WINNER"]		= _bb_game_won_by_team, 
		["LOSER"]		= _bb_game_loss_by_team
	}
	--
	--TEAM GLOBAL STATS (GUI_LEFT, LEFT COLUMN)
	--	
	for _side=1,2,1 do
		local _guit=""
		--NORTH SIDE --
		local team_name = "Team North"
		if global.tm_custom_name["north"] then team_name = global.tm_custom_name["north"]	end
		local biter_name = "north_biters"
		local force_name = "north"
		local total_science_of_force  = global.science_logs_total_north
		if _side==2 then --SOUTH SIDE --
			team_name = "Team South"
			if global.tm_custom_name["south"] then team_name = global.tm_custom_name["south"]	end
			biter_name = "south_biters"
			force_name = "south"
			total_science_of_force  = global.science_logs_total_south
		end
		local team_evo = math.floor(1000 * global.bb_evolution[biter_name]) / 10 --BUG in exports 2,3 -> 2,2999999999999999 (1+16 digits)
		local team_threat = math.floor(global.bb_threat[biter_name])
		_json_team = { --THE JSON FORCE/TEAM STATS (topleft) side/force is not know yet
			["FORCE"]=force_name,
			["NAME"]=team_name,
			["CONNECTED"]=Functions.get_nb_players(force_name),
			["MANAGER"]="-none-", --NEW (ANB)--
			["EVO"]=team_evo,
			["THREAT"]=team_threat,
			["ROCKETS"]=game.forces[force_name].rockets_launched,
			["BITER_WALLS"]=global.biters_kills[biter_name]["walls"], --NEW (ANB)--
			["BITER_FURNACES"]=global.biters_kills[biter_name]["furnaces"], --NEW (ANB)--
			["BITER_ENTITIES"]=global.biters_kills[biter_name]["entities"], --NEW (ANB)--
			["BITERS"]={["small-biter"]=0,["medium-biter"]=0,["big-biter"]=0,["behemoth-biter"]=0},
			["WORMS"]={["small-worm-turret"]=0,["medium-worm-turret"]=0,["big-worm-turret"]=0}, --remove behemoth ,'behemoth-worm-turret'},
			["SCRAPS"]=0,
			["SPAWNERS"]={["biter-spawner"]=0, ["spitter-spawner"]=0},
			["SCIENCE"]={["automation"]=0,["logistic"]=0,["military"]=0,["chemical"]=0,["production"]=0,["utility"]=0,["space"]=0},
			["SCIENCE_SCORE"]=0,
			["DEATH_SCORE"]=0,
			["KILLSCORE"]=0,
			["BUILT"]=0,
			["WALLS"]=0,
			["MINED"]=0
		}
		if global.manager_table[force_name] and game.players[global.manager_table[force_name]] then  --EVL in this mode manager are set to team
			_json_team["MANAGER"]=global.manager_table[force_name]
		end
		local get_score = Score.get_table().score_table
		if not get_score then 
			if global.bb_debug then game.print(">>>>> Unable to get score table.", {r = 0.88, g = 0.22, b = 0.22}) end
			return
		end
		if not get_score[force_name] then 
			if global.bb_debug then game.print(">>>>> Unable to get score table for "..force_name..".", {r = 0.88, g = 0.22, b = 0.22}) end
		--else
		--	local _score = get_score[force_name]
		--	if _score and _score.players and _score.players[_json_team["MANAGER"]] then --has he played ?
		--		--game.print("Yes, Keep value for ".._json_team["MANAGER"])
		--		--Yes, Keep value
		--	else
		--		--game.print("No, Remove him for ".._json_team["MANAGER"])
		--		--No, Remove him
		--		_json_team["CONNECTED"]=_json_team["CONNECTED"]-1
		--	end
		end
		_guit=_guit.."[font=default-bold][color=#FF9740]>>"..string.upper(_json_team["NAME"]).." STATS[/color][/font]\n"
		_guit=_guit.."     ".._json_team["CONNECTED"].." players with ".._json_team["MANAGER"].." as manager.\n"
		_guit=_guit.."     EVO=".._json_team["EVO"].." | THREAT=".._json_team["THREAT"].." | ROCKETS=".._json_team["ROCKETS"].."\n"

		
		--BITERS WITH DETAILS --EVL DOING SOME FIORITURES
		local _b = 0 
		local _b_details = {["small-biter"]=0,["medium-biter"]=0,["big-biter"]=0,["behemoth-biter"]=0}
		for _, _biter in pairs(biters) do 
			local _count = game.forces[force_name].kill_count_statistics.get_input_count(_biter) 
			_b = _b + _count
			local biter=_biter
			if biter=="small-spitter" then biter="small-biter"
			elseif biter=="medium-spitter" then biter="medium-biter"
			elseif biter=="big-spitter" then biter="big-biter"
			elseif biter=="behemoth-spitter" then biter="behemoth-biter"
			end
			_b_details[biter]=_b_details[biter]+_count
		end
		_guit=_guit.."     [color=#FF9999]BITERS: ".._b
		--walls/furnaces/entities killed by biters
		_guit=_guit.."  | [item=stone-wall] ".._json_team["BITER_WALLS"] --NEW (ANB)
		_guit=_guit.."  | [item=stone-furnace] ".._json_team["BITER_FURNACES"] --NEW (ANB)--
		_guit=_guit.."  | [item=deconstruction-planner] ".._json_team["BITER_ENTITIES"] --NEW (ANB)--

		--formatting and adding details if exist
		if _b > 0 then 
			local _b_str="\n     "
			for _biter,_count in pairs(_b_details) do 
				local count=_count
				--JSON ADD KILLS FOR EACH TIER OF BITER 
				_json_team["BITERS"][_biter]= _count
				_b_str=_b_str..Functions.inkilos(count).." [entity=".._biter.."], " 
			end
			_b_str=string.sub(_b_str, 1, string.len(_b_str)-2)
			_guit=_guit.._b_str
		end
		
		
		
		
		_guit=_guit.."\n"
		--WORMS WITH DETAILS
		local _w = 0
		local _w_details = ""
		for _, worm in pairs(worms) do
			local _count = game.forces[force_name].kill_count_statistics.get_input_count(worm) 
			_w = _w + _count
			_w_details = _w_details.._count.." [entity="..worm.."], "
			--JSON ADD EACH WORM
			_json_team["WORMS"][worm]= _count 
		end
		_w_details=string.sub(_w_details, 1, string.len(_w_details)-2)
		_guit=_guit.."     WORMS: ".._w
		if _w > 0 then _guit=_guit.." ► ".._w_details end
		_guit=_guit.."\n"
		

		--SPAWNERS WITH DETAILS
		local _s = 0
		local _s_details = ""
		for _, spawner in pairs(spawners) do
			local _count = game.forces[force_name].kill_count_statistics.get_input_count(spawner) 
			_s = _s + _count
			_s_details = _s_details.._count.." [entity="..spawner.."], "
			--JSON ADD EACH SPAWNER
			_json_team["SPAWNERS"][spawner]= _count 
		end
		_s_details=string.sub(_s_details, 1, string.len(_s_details)-2)
		_guit=_guit.."     SPAWNERS: ".._s
		if _w > 0 then _guit=_guit.." ► ".._s_details end
		--SCRAPS
		_guit=_guit.." [/color]| SCRAPS: "..global.scraps_mined[force_name].."\n"
		_json_team["SCRAPS"]= global.scraps_mined[force_name] 


		--SCIENCE
		if total_science_of_force then
			local _science=""
			local _science_score=0 -- Science score (Qtity *  value)
			for _science_nb = 1, 7 do 
				local _this_science=total_science_of_force[_science_nb]
				_science_score=_science_score+_this_science*Tables.food_values[Tables.food_long_and_short[_science_nb].long_name].value*1000
				----JSON ADD EACH SCIENCE
				_json_team["SCIENCE"][Tables.food_long_and_short[_science_nb].short_name]= _this_science
				_science=_science..Functions.inkilos(_this_science).."[item="..Tables.food_long_and_short[_science_nb].long_name.."]"..", "
				if _science_nb==3 then _science=_science.."\n     " end
				
			end
			_science=string.sub(_science, 1, string.len(_science)-2)
			_guit=_guit.."     SCIENCE: ".._science.."\n"
			----JSON ADD SCIENCE SCORE
			_json_team["SCIENCE_SCORE"]=_science_score
			_guit=_guit.."     SCIENCE SCORE: ".._science_score.."\n"
		else
			_guit=_guit.."     NO SCIENCE SENT\n"
			_guit=_guit.."     SCIENCE SCORE: -\n"
		end

		--put the gui and the json_team into the correct side
		if _side==1 then --NORTH SIDE --
			_guitm = _guit	--_GUI_TOP_MID	(North recap)
			-- PUT _JSON_TEAM IN THE NORTH TABLE
			_json_north=_json_team
		elseif _side==2 then --SOUTH SIDE --
			_guitr = _guit	--_GUI_TOP_RIGHT	(South recap)
			-- PUT _JSON_TEAM IN THE SOUTH TABLE
			_json_south=_json_team
		else
			game.print(">>>>> WTF HOW CAN THIS HAPPEN ? in set_stats_team")
		end		
	end
		
	--OTHER DATAS
	
end
local function set_stats_players() 			--fill up tables "json_players_north & json_players_south"
	
	local get_score = Score.get_table().score_table

    if not get_score then 
		if global.bb_debug then game.print(">>>>> Unable to get score table.", {r = 0.88, g = 0.22, b = 0.22}) end
		return
	end
	local _score = { ["north"]={}, ["south"]={}}
	

	if not get_score["north"] then 
		if global.bb_debug then game.print(">>>>> Unable to get score table for north.", {r = 0.88, g = 0.22, b = 0.22}) end
	else
		_score["north"] = get_score["north"]
	end
	if not get_score["south"] then 
		--_guis=_guis.."[font=default-small][color=#999999][Unable to get scores at south][/color][/font]\n"
		if global.bb_debug then game.print(">>>>> Unable to get score table for south.", {r = 0.88, g = 0.22, b = 0.22}) end
	else
		_score["south"] = get_score["south"]
	end
	
	local biters = {'small-biter','medium-biter','big-biter','behemoth-biter','small-spitter','medium-spitter','big-spitter','behemoth-spitter'}
	local worms =  {'small-worm-turret','medium-worm-turret','big-worm-turret','behemoth-worm-turret'}
	local spawners = {}
	--
	--PLAYER STATS
	--
	for _, player in pairs(game.players) do
		local _force=player.force.name
		local _name=player.name
		--INITIALIZE DATAS
		local _killscore = 0
		local _deaths =  0
		local _entities = 0
		local _mined = 0

		local _turrets = 0
		local _walls = 0
		local _killed_walls = 0
		local _damaged_walls = 0
		local _paths = 0
		--add chests ?
		local _belts = 0 
		local _pipes = 0
		local _powers = 0
		local _inserters = 0
		local _miners = 0
		local _furnaces = 0
		local _machines = 0
		local _labs = 0

		local _smalls = 0
		local _mediums = 0
		local _bigs = 0
		local _behemoths = 0
		local _spawners = 0
		local _worms = 0
		
		

		-- IF PLAYER WAS IN A TEAM AND BUILT BEFORE MOVED TO SPEC
		if (_force=="spectator" or _force=="spec_god") then
			if _score["north"] and _score["north"].players and _score["north"].players[_name] then 
				_force="north"
				if global.bb_debug then game.print(">>>>> Player ".._name.." is in spec and HAS played in north -> Keep.", {r = 0.88, g = 0.22, b = 0.22}) end
			end
			if _score["south"] and _score["south"].players and _score["south"].players[_name] then 
				_force="south" 
				if global.bb_debug then game.print(">>>>> Player ".._name.." is in spec and HAS played in south -> Keep.", {r = 0.88, g = 0.22, b = 0.22}) end
			end
		end
		--EVL in this mode manager are set to team, DONT ADD HIM TO STATS (UNLESS HE PLAYED)
		if global.managers_in_team then
			if _force=="north" and global.manager_table["north"] and game.players[global.manager_table["north"]] and _name==game.players[global.manager_table["north"]].name then --We have a manager, has he played ?
				local north_manager_name=global.manager_table["north"]
				if _score["north"] and _score["north"].players and _score["north"].players[north_manager_name] then 
					--_force="north" 
				else
					_force="nil" --Dont add him to stats
				end
			elseif _force=="south" and global.manager_table["south"] and game.players[global.manager_table["south"]] and _name==game.players[global.manager_table["south"]].name then --We have a manager, has he played ?
				local south_manager_name=global.manager_table["south"]
				if _score["south"] and _score["south"].players and _score["south"].players[south_manager_name] then 
					--_force="south"
				else
					_force="nil" --Dont add him to stats
				end
			--else
				--Not a manager
			end
		end
		-- GRAB DATAS IF WE HAVE SOME
		if (_force=="north" or _force=="south") then
			if _score[_force].players and _score[_force].players[_name] then 
				local score_player= _score[_force].players[_name]
				_killscore = score_player.killscore
				_deaths = score_player.deaths
				_entities = score_player.built_entities-score_player.built_walls --  we deduce walls from built entities
				_mined = score_player.mined_entities
				-- EVL MORE STATS !
				_walls = score_player.built_walls
				_killed_walls = score_player.killed_own_walls
				_damaged_walls = math.floor(score_player.damaged_own_walls)
				_paths = score_player.placed_path
				_turrets = score_player.built_turrets
				
				_belts = score_player.built_belts
				_pipes = score_player.built_pipes
				_powers = score_player.built_powers
				_inserters = score_player.built_inserters
				_miners = score_player.built_miners
				_furnaces = score_player.built_furnaces
				_machines = score_player.built_machines
				_labs = score_player.built_labs

				--EVL EVEN MORE STATS !
				_smalls = score_player.kills_small
				_mediums = score_player.kills_medium
				_bigs = score_player.kills_big
				_behemoths = score_player.kills_behemoth
				_spawners = score_player.kills_spawner
				_worms = score_player.kills_worm
			end
		end

		local _json_player={
			["NAME"] =_name,
			["ADMIN"] = player.admin,
			["FORCE"] = _force,
			
			["KILLSCORE"] = _killscore,
			["DEATHS"] = _deaths,
			["BUILT"] = _entities,
			["MINED"] = _mined,
			
			["TURRETS"] = _turrets,			
			["WALLS"] = _walls,
			["KILLED_WALLS"] = _killed_walls, --NEW (ANB)--
			["DAMAGED_WALLS"] = _damaged_walls, --NEW (ANB)--
			["PATHS"] = _paths,
			
			--["CHESTS"] = _chests,
			["BELTS"] = _belts,
			["PIPES"] = _pipes,
			["POWERS"] = _powers,
			["INSERTERS"] = _inserters,
			["MINERS"] = _miners,
			["FURNACES"] = _furnaces,
			["MACHINES"] = _machines,
			["LABS"] = _labs,

			["SMALLS"] = _smalls,
			["MEDIUMS"] = _mediums,
			["BIGS"] = _bigs,
			["BEHEMOTHS"] = _behemoths,
			["SPAWNERS"] = _spawners,
			["WORMS"] = _worms,
			
			["SCIENCE"]={["automation"]=0,["logistic"]=0,["military"]=0,["chemical"]=0,["production"]=0,["utility"]=0,["space"]=0}
		}
		--SCIENCE
		if (_force=="north" or _force=="south") then
			if global.science_per_player and global.science_per_player[_name] then
				for _science_nb = 1, 7 do 
					local _this_science=0
					if global.science_per_player[player.name][_science_nb] then _this_science = global.science_per_player[player.name][_science_nb] end
					if _this_science > 0 then 
						_json_player["SCIENCE"][Tables.food_long_and_short[_science_nb].short_name]=_this_science
					end
				end
			--else
				--No science
			end
		end
		--FILL to the correct side
		if _force=="north" then 
			table.insert(_json_players_north,_json_player)
		elseif _force=="south" then 
			table.insert(_json_players_south,_json_player)
		end --if force = spec or god, we forget (they did nothing, if they had they would be switched to north (in prio) or south, see above
	end		
	--OTHER DATAS
end
local function set_stats_team_addendum()		--Addendum to tables "json_north & json_south" (sum of deaths|killscore|built|walls|mined)
	
	
	-- Addendum NORTH : Get  the sums of Deaths/KillScore/Built/WallsBuilt/Mined
	local _sum_deaths=0
	local _sum_killscore=0
	local _sum_built_entities=0
	local _sum_built_walls=0
	local _sum_mined_entities=0
	if table_size(_json_players_north)>0 then 
		for _index,_player in pairs(_json_players_north) do
			_sum_deaths=_sum_deaths+_player["DEATHS"]
			_sum_killscore=_sum_killscore+_player["KILLSCORE"]
			_sum_built_entities=_sum_built_entities+_player["BUILT"]
			_sum_built_walls=_sum_built_walls+_player["WALLS"]
			_sum_mined_entities=_sum_mined_entities+_player["MINED"]
		end
	end
	--Add them to North stats
	_json_north["DEATH_SCORE"]=_sum_deaths
	_json_north["KILLSCORE"]=_sum_killscore
	_json_north["BUILT"]=_sum_built_entities
	_json_north["WALLS"]=_sum_built_walls
	_json_north["MINED"]=_sum_mined_entities
	_guitm=_guitm.."     [color=#FF9999]DEATHS: ".._sum_deaths.." [/color]| [color=#99FF99]KILLSCORE: ".._sum_killscore.."[/color]\n"
	_guitm=_guitm.."     [item=blueprint]: ".._sum_built_entities.." | [item=stone-wall]: ".._sum_built_walls.." | [item=deconstruction-planner]: ".._sum_mined_entities.."\n"
	

	-- Addendum SOUTH : Get the sums of Deaths/KillScore/Built/WallsBuilt/Mined
	_sum_deaths=0
	_sum_killscore=0
	_sum_built_entities=0
	_sum_built_walls=0
	_sum_mined_entities=0
	if table_size(_json_players_south)>0 then 
		for _index,_player in pairs(_json_players_south) do
			_sum_deaths=_sum_deaths+_player["DEATHS"]
			_sum_killscore=_sum_killscore+_player["KILLSCORE"]
			_sum_built_entities=_sum_built_entities+_player["BUILT"]
			_sum_built_walls=_sum_built_walls+_player["WALLS"]
			_sum_mined_entities=_sum_mined_entities+_player["MINED"]
		end
	end
	--Add them to South stats
	_json_south["DEATH_SCORE"]=_sum_deaths
	_json_south["KILLSCORE"]=_sum_killscore
	_json_south["BUILT"]=_sum_built_entities
	_json_south["WALLS"]=_sum_built_walls
	_json_south["MINED"]=_sum_mined_entities
	_guitr=_guitr.."     [color=#FF9999]DEATHS: ".._sum_deaths.." [/color]| [color=#99FF99]KILLSCORE: ".._sum_killscore.."[/color]\n"
	_guitr=_guitr.."     [item=blueprint]: ".._sum_built_entities.." | [item=stone-wall]: ".._sum_built_walls.." | [item=deconstruction-planner]: ".._sum_mined_entities.."\n"	
end

--DRAWING EXPORT FRAME (Global / North / South)
local function draw_results(player)
	if player.gui.center["bb_export_frame"] then player.gui.center["bb_export_frame"].destroy() end
	if player.gui.center["team_has_won"] then player.gui.center["team_has_won"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "bb_export_frame", direction = "vertical"}
	--Some infos about what icons are meaning
	local _tooltip="[color=#99FF99]score[/color] [color=#999999] at fighting biters\n"
	.."[item=blueprint] entities built (walls are deduced)\n [item=deconstruction-planner] entities mined\n"
	.."[item=gun-turret] include gun, flame, laser and radars\n"
	.."[item=stone-wall] include gates, [color=#FF5555]-(self-killed&damaged)[/color]\n"
	.."[item=concrete] include paths and landfill\n"
	.."[item=steam-engine] include offshore, boiler, steam, solar, accu\n"
	.."[item=electric-mining-drill] include elec and burners\n"
	.."[item=assembling-machine-1] also include oil refining, beacon etc.[/color]\n\n"
	.."[color=#999999]Note: [/color][color=#FF9999]Walls/Furnaces/Other entities killed by biters[/color]"
	--TITLE
	--LOGO AND FIRST PART
	local _title= frame.add {type = "table", name = "bb_export_title", column_count = 2}
	_title.vertical_centering=false

	local t1 = _title.add {type = "sprite", name = "bb_export_title_left", sprite = "file/png/logo_100.png"}
	t1.style.minimal_width = 125
	t1.style.maximal_width = 125
	local t2 = _title.add {type = "label", name = "bb_export_title_right", caption = _guit, tooltip=_tooltip}
	t2.style.single_line = false
	t2.style.horizontal_align = 'center'
	t2.style.font = "default"
	t2.style.font_color = {r=0.7, g=0.6, b=0.99}
	
	--TOP (GLOBAL/NORTH/SOUTH)
	local _tabletop = frame.add {type = "table", name = "bb_export_top", column_count = 5}
	_tabletop.vertical_centering=false

	-- TOPLEFT:GLOBAL STATS
	local _ttl = _tabletop.add {type = "label", name = "bb_export_topleft", caption = _guitl}
	_ttl.style.single_line = false
	_ttl.style.font = "default"
	_ttl.style.font_color = {r=0.7, g=0.6, b=0.99}

	local sep = _tabletop.add {type = "label", caption = "   "} --EVL SEPARATOR

	-- TOPMIDDLE:NORTH STATS
	local _ttm = _tabletop.add {type = "label", name = "bb_export_topmid", caption = _guitm, tooltip=_tooltip_force}
	_ttm.style.single_line = false
	_ttm.style.font = "default"
	_ttm.style.font_color = {r=0.7, g=0.6, b=0.99}
	--ttm.style.minimal_width = 250
	--ttm.style.maximal_width = 500
	local sep = _tabletop.add {type = "label", caption = "   "} --EVL SEPARATOR

	-- TOPRIGHT:SOUTH STATS
	local _ttr = _tabletop.add {type = "label", name = "bb_export_topright", caption = _guitr, tooltip=_tooltip_force}
	_ttr.style.single_line = false
	_ttr.style.font = "default"
	_ttr.style.font_color = {r=0.7, g=0.6, b=0.99}
	--ttr.style.minimal_width = 250
	--ttr.style.maximal_width = 500

	frame.add { type = "line", caption = "this line", direction = "horizontal" }
	
	--#####OK THE BIG UGLY TABLE TO SCREEN##############
	local _tp = frame.add {type = "table", name = "bb_export_players", column_count = 28} --_tp for table players
	_tp.vertical_centering=false
	
	-- TITLE LINE
	local _col_name="\n[font=default-bold][color=#5555FF]NORTH[/color][/font]\n"
	local _col_death="[font=default-small][color=#FF9999]Death[/color][/font]\n\n"
	local _col_score="[font=default-small][color=#99FF99]  Score[/color][/font]\n\n"
	local _col_built="[item=blueprint]\n\n"
	local _col_mined="[item=deconstruction-planner]\n\n"
	local _col_wall="[item=stone-wall]\n\n"
	local _col_killed_wall="[color=#FF5555]X[/color]\n\n"
	local _col_damaged_wall="[color=#AA1111](HP)[/color]\n\n"
	local _col_path="[item=concrete]\n\n"
	local _col_belt="[item=transport-belt]\n\n"
	local _col_pipe="[item=pipe]\n\n"
	local _col_power="[item=steam-engine]\n\n"
	local _col_inserter="[item=inserter]\n\n"
	local _col_miner="[item=electric-mining-drill]\n\n"
	local _col_furnace="[item=stone-furnace]\n\n"
	local _col_machine="[item=assembling-machine-1]\n\n"
	local _col_lab="[item=lab]\n\n"
	local _col_turret="[item=gun-turret]\n\n"
	local _col_small="[entity=small-biter]\n\n"
	local _col_medium="[entity=medium-biter]\n\n"
	local _col_big="[entity=big-biter]\n\n"
	local _col_behemoth="[entity=behemoth-biter]\n\n"
	local _col_spawner="[entity=biter-spawner]\n\n"
	local _col_worm="[entity=small-worm-turret]\n\n"
	local _col_science="[font=default-bold][color=#FF9740]Science[/color][/font]\n\n"
	
	--NORTH
	if table_size(_json_players_north)>0 then 
		for _index,_player in pairs(_json_players_north) do
			--SPECIAL CASE FOR NAME (we want to see if admin)
			local _p = game.players[_player["NAME"]]
			local r = math.floor((_p.color.r * 0.6 + 0.4)*255)
			local g = math.floor((_p.color.g * 0.6 + 0.4)*255)
			local b = math.floor((_p.color.b * 0.6 + 0.4)*255)
			local _player_color = r..","..g..","..b
			_col_name=_col_name.."[color=".._player_color.."]".._player["NAME"].."[/color]"
			if _player["ADMIN"] then _col_name=_col_name..":A" end
			_col_name=_col_name.."\n"

			--DEATH AND KILLSCORE
			_col_death=_col_death.."[color=#FF9999]".._player["DEATHS"].."[/color]\n"
			_col_score=_col_score.."[color=#99FF99]".._player["KILLSCORE"].."[/color]\n"
			--BUILT AND MINED
			_col_built=_col_built.."[color=#88CCFF]"..(Functions.inkilos(_player["BUILT"])).."[/color]\n"
			_col_mined=_col_mined.."[color=#FF7777]"..(Functions.inkilos(_player["MINED"])).."[/color]\n"
			--TURRETS, WALLS AND PATHS/TILES
			_col_turret=_col_turret.._player["TURRETS"].."\n" --NO KILOS
			_col_wall=_col_wall.."[color=#CCCCCC]"..(Functions.inkilos(_player["WALLS"])).."[/color]\n"
			_col_killed_wall=_col_killed_wall.."[color=#FF5555]-"..(Functions.inkilos(_player["KILLED_WALLS"])).."[/color]\n"
			_col_damaged_wall=_col_damaged_wall.."[color=#AA1111]("..(Functions.inkilos(_player["DAMAGED_WALLS"]))..")[/color]\n"
			_col_path=_col_path..(Functions.inkilos(_player["PATHS"])).."\n"
			--OTHER ENTITIES
			_col_belt=_col_belt..(Functions.inkilos(_player["BELTS"])).."\n"
			_col_pipe=_col_pipe.."[color=#CCCCCC]"..(Functions.inkilos(_player["PIPES"])).."[/color]\n"
			_col_power=_col_power..(Functions.inkilos(_player["POWERS"])).."\n"
			_col_inserter=_col_inserter.."[color=#CCCCCC]"..(Functions.inkilos(_player["INSERTERS"])).."[/color]\n"
			_col_miner=_col_miner..(Functions.inkilos(_player["MINERS"])).."\n"
			_col_furnace=_col_furnace.."[color=#CCCCCC]"..(Functions.inkilos(_player["FURNACES"])).."[/color]\n"
			_col_machine=_col_machine..(Functions.inkilos(_player["MACHINES"])).."\n"
			_col_lab=_col_lab.."[color=#CCCCCC]".._player["LABS"].."[/color]\n"	--NO KILOS
			--BITERS
			_col_small=_col_small..(Functions.inkilos(_player["SMALLS"])).."\n"
			_col_medium=_col_medium.."[color=#CCCCCC]"..(Functions.inkilos(_player["MEDIUMS"])).."[/color]\n"
			_col_big=_col_big..(Functions.inkilos(_player["BIGS"])).."\n"
			_col_behemoth=_col_behemoth.."[color=#CCCCCC]".._player["BEHEMOTHS"].."[/color]\n"	--NO KILOS
			_col_spawner=_col_spawner.._player["SPAWNERS"].."\n"	--NO KILOS
			_col_worm=_col_worm.."[color=#CCCCCC]".._player["WORMS"].."[/color]\n"	--NO KILOS
			--SPECIAL CASE FOR SCIENCE
			local _science=""
			local _has_science=false
			for _science_nb = 1, 7 do 
				local _this_science=_player["SCIENCE"][Tables.food_long_and_short[_science_nb].short_name]
				if _this_science>0 then 
					_has_science=true
					_science=_science..Functions.inkilos(_this_science).."[item="..Tables.food_long_and_short[_science_nb].long_name.."]"..", "
				end
			end
			if _has_science then
				_science=string.sub(_science, 1, string.len(_science)-2)
			else
				_science="-"
			end			
			_col_science=_col_science.._science.."\n"
			
		end
	end
	--SOUTH
	_col_name=_col_name.."[font=default-bold][color=#CC2222]SOUTH[/color][/font]\n"
	_col_death=_col_death.."\n"
	_col_score=_col_score.."\n"
	_col_built=_col_built.."\n"
	_col_mined=_col_mined.."\n"
	_col_wall=_col_wall.."\n"
	_col_killed_wall=_col_killed_wall.."\n"
	_col_damaged_wall=_col_damaged_wall.."\n"
	_col_path=_col_path.."\n"
	_col_belt=_col_belt.."\n"
	_col_pipe=_col_pipe.."\n"
	_col_power=_col_power.."\n"
	_col_inserter=_col_inserter.."\n"
	_col_miner=_col_miner.."\n"
	_col_furnace=_col_furnace.."\n"
	_col_machine=_col_machine.."\n"
	_col_lab=_col_lab.."\n"
	_col_turret=_col_turret.."\n"
	_col_small=_col_small.."\n"
	_col_medium=_col_medium.."\n"
	_col_big=_col_big.."\n"
	_col_behemoth=_col_behemoth.."\n"
	_col_spawner=_col_spawner.."\n"
	_col_worm=_col_worm.."\n"
	_col_science=_col_science.."\n"			
	if table_size(_json_players_south)>0 then 
		for _index,_player in pairs(_json_players_south) do
			--SPECIAL CASE FOR NAME (we want to see if admin)
			local _p = game.players[_player["NAME"]]
			local r = math.floor((_p.color.r * 0.6 + 0.4)*255)
			local g = math.floor((_p.color.g * 0.6 + 0.4)*255)
			local b = math.floor((_p.color.b * 0.6 + 0.4)*255)
			local _player_color = r..","..g..","..b
			_col_name=_col_name.."[color=".._player_color.."]".._player["NAME"].."[/color]"
			if _player["ADMIN"] then _col_name=_col_name..":A" end
			_col_name=_col_name.."\n"

			--DEATH AND KILLSCORE
			_col_death=_col_death.."[color=#FF9999]".._player["DEATHS"].."[/color]\n"
			_col_score=_col_score.."[color=#99FF99]".._player["KILLSCORE"].."[/color]\n"
			--BUILT AND MINED

			_col_built=_col_built.."[color=#88CCFF]"..(Functions.inkilos(_player["BUILT"])).."[/color]\n"
			_col_mined=_col_mined.."[color=#FF7777]"..(Functions.inkilos(_player["MINED"])).."[/color]\n"

			--TURRETS , WALLS AND PATHS/TILES
			_col_turret=_col_turret.._player["TURRETS"].."\n" --NO KILOS
			_col_wall=_col_wall.."[color=#CCCCCC]"..(Functions.inkilos(_player["WALLS"])).."[/color]\n"			
			_col_killed_wall=_col_killed_wall.."[color=#FF5555]-"..(Functions.inkilos(_player["KILLED_WALLS"])).."[/color]\n"
			_col_damaged_wall=_col_damaged_wall.."[color=#AA1111]("..(Functions.inkilos(_player["DAMAGED_WALLS"]))..")[/color]\n"
			_col_path=_col_path..(Functions.inkilos(_player["PATHS"])).."\n"

			--THINGS
			_col_belt=_col_belt..(Functions.inkilos(_player["BELTS"])).."\n"
			_col_pipe=_col_pipe.."[color=#CCCCCC]"..(Functions.inkilos(_player["PIPES"])).."[/color]\n"
			_col_power=_col_power..(Functions.inkilos(_player["POWERS"])).."\n"
			_col_inserter=_col_inserter.."[color=#CCCCCC]"..(Functions.inkilos(_player["INSERTERS"])).."[/color]\n"

			_col_miner=_col_miner..(Functions.inkilos(_player["MINERS"])).."\n"
			_col_furnace=_col_furnace.."[color=#CCCCCC]"..(Functions.inkilos(_player["FURNACES"])).."[/color]\n"
			_col_machine=_col_machine..(Functions.inkilos(_player["MACHINES"])).."\n"
			_col_lab=_col_lab.."[color=#CCCCCC]".._player["LABS"].."[/color]\n"	--NO KILOS

			--BITERS
			_col_small=_col_small..(Functions.inkilos(_player["SMALLS"])).."\n"
			_col_medium=_col_medium.."[color=#CCCCCC]"..(Functions.inkilos(_player["MEDIUMS"])).."[/color]\n"
			_col_big=_col_big..(Functions.inkilos(_player["BIGS"])).."\n"
			_col_behemoth=_col_behemoth.."[color=#CCCCCC]".._player["BEHEMOTHS"].."[/color]\n"	--NO KILOS
			_col_spawner=_col_spawner.._player["SPAWNERS"].."\n"	--NO KILOS
			_col_worm=_col_worm.."[color=#CCCCCC]".._player["WORMS"].."[/color]\n"	--NO KILOS

			--SPECIAL CASE FOR SCIENCE
			local _science=""
			local _has_science=false
			for _science_nb = 1, 7 do 
				local _this_science=_player["SCIENCE"][Tables.food_long_and_short[_science_nb].short_name]
				if _this_science>0 then 
					_has_science=true
					_science=_science..Functions.inkilos(_this_science).."[item="..Tables.food_long_and_short[_science_nb].long_name.."]"..", "
				end
			end
			if _has_science then
				_science=string.sub(_science, 1, string.len(_science)-2)
			else
				_science="-"
			end			
			_col_science=_col_science.._science.."\n"
			
		end
	end
	--insert the columns
	local _tp_name		= _tp.add {type = "label", caption = _col_name, name = "tp_name"}
	_tp_name.style.single_line = false
	local _tp_death	= _tp.add {type = "label", caption = _col_death, name = "tp_death", tooltip="Number of deaths"}
	_tp_death.style.single_line = false
	_tp_death.style.horizontal_align="center"
	local _tp_score	= _tp.add {type = "label", caption = _col_score, name = "tp_score", tooltip="Kill score"}
	_tp_score.style.single_line = false
	_tp_score.style.horizontal_align="right"
	local _tp_built	= _tp.add {type = "label", caption = _col_built, name = "tp_built", tooltip="Built entities minus walls"}
	_tp_built.style.single_line = false
	_tp_built.style.horizontal_align="right"
	local _tp_mined	= _tp.add {type = "label", caption = _col_mined, name = "tp_mined", tooltip="Mined entities"}
	_tp_mined.style.single_line = false
	_tp_mined.style.horizontal_align="right"
	local _tp_turret	= _tp.add {type = "label", caption = _col_turret, name = "tp_turret", tooltip="Turrets and radar"}
	_tp_turret.style.single_line = false	
	_tp_turret.style.horizontal_align="right"
	local _tp_wall		= _tp.add {type = "label", caption = _col_wall, name = "tp_wall", tooltip="Built walls and gates"}
	_tp_wall.style.single_line = false
	_tp_wall.style.horizontal_align="right"
	local _tp_killed_wall		= _tp.add {type = "label", caption = _col_killed_wall, name = "tp_killed_wall", tooltip="Killed own walls\n[color=#FF5555]Aim better your grenades![/color]"}
	_tp_killed_wall.style.single_line = false
	_tp_killed_wall.style.horizontal_align="right"
	local _tp_damaged_wall		= _tp.add {type = "label", caption = _col_damaged_wall, name = "tp_damaged_wall", tooltip="Own walls damage\n[color=#FF5555]Aim better your grenades![/color]"}
	_tp_damaged_wall.style.single_line = false
	_tp_damaged_wall.style.horizontal_align="right"
	
	local _tp_path		= _tp.add {type = "label", caption = _col_path, name = "tp_path", tooltip="Paths and landfill"}
	_tp_path.style.single_line = false
	_tp_path.style.horizontal_align="right"		

	local _separation = _tp.add {type = "label", caption = "   "}

	local _tp_science	= _tp.add {type = "label", caption = _col_science, name = "tp_science", tooltip="Science sent"}
	_tp_science.style.single_line = false

	local _separation = _tp.add {type = "label", caption = "   "}

	local _tp_small	= _tp.add {type = "label", caption = _col_small, name = "tp_small", tooltip="Smalls"}
	_tp_small.style.single_line = false
	_tp_small.style.horizontal_align="right"	
	local _tp_medium	= _tp.add {type = "label", caption = _col_medium, name = "tp_medium", tooltip="Mediums"}
	_tp_medium.style.single_line = false
	_tp_medium.style.horizontal_align="right"	
	local _tp_big		= _tp.add {type = "label", caption = _col_big, name = "tp_big", tooltip="Bigs"}
	_tp_big.style.single_line = false
	_tp_big.style.horizontal_align="right"	
	local _tp_behemoth	= _tp.add {type = "label", caption = _col_behemoth, name = "tp_behemoth", tooltip="Behemoths"}
	_tp_behemoth.style.single_line = false
	_tp_behemoth.style.horizontal_align="right"	
	local _tp_spawner	= _tp.add {type = "label", caption = _col_spawner, name = "tp_spawner", tooltip="Spawners"}
	_tp_spawner.style.single_line = false
	_tp_spawner.style.horizontal_align="right"	
	local _tp_worm		= _tp.add {type = "label", caption = _col_worm, name = "tp_worm", tooltip="Worms"}
	_tp_worm.style.single_line = false
	_tp_worm.style.horizontal_align="right"	
	
	local _separation = _tp.add {type = "label", caption = "   "}

	local _tp_belt		= _tp.add {type = "label", caption = _col_belt, name = "tp_belt", tooltip="Belts\nUndergrounds\nSplitters"}
	_tp_belt.style.single_line = false
	_tp_belt.style.horizontal_align="right"	
	local _tp_pipe		= _tp.add {type = "label", caption = _col_pipe, name = "tp_pipe", tooltip="Pipes\nTanks\nPumps"}
	_tp_pipe.style.single_line = false
	_tp_pipe.style.horizontal_align="right"		
	local _tp_power	= _tp.add {type = "label", caption = _col_power, name = "tp_power", tooltip="Offshore\nBoilers\nSteam\nSolar\nAccus"}
	_tp_power.style.single_line = false
	_tp_power.style.horizontal_align="right"		
	local _tp_inserter	= _tp.add {type = "label", caption = _col_inserter, name = "tp_inserter", tooltip="Inserters"}
	_tp_inserter.style.single_line = false
	_tp_inserter.style.horizontal_align="right"		
	local _tp_miner	= _tp.add {type = "label", caption = _col_miner, name = "tp_miner", tooltip="Burners\nElectric"}
	_tp_miner.style.single_line = false
	_tp_miner.style.horizontal_align="right"		
	local _tp_furnace	= _tp.add {type = "label", caption = _col_furnace, name = "tp_furnace", tooltip="Furnaces"}
	_tp_furnace.style.single_line = false
	_tp_furnace.style.horizontal_align="right"		
	local _tp_machine	= _tp.add {type = "label", caption = _col_machine, name = "tp_machine", tooltip="Machines\nPumpJacks\nRefining\nBeacon etc."}
	_tp_machine.style.single_line = false
	_tp_machine.style.horizontal_align="right"		
	local _tp_lab		= _tp.add {type = "label", caption = _col_lab, name = "tp_lab"}
	_tp_lab.style.single_line = false
	_tp_lab.style.horizontal_align="right"	
	--BOTTOM
	local lb = frame.add {type = "label", caption = _guib, name = "bb_export_bottom"}
	lb.style.single_line = false
	lb.style.font = "default"
	lb.style.font_color = {r=0.7, g=0.6, b=0.99}
	lb.style.minimal_width = 250
	lb.style.maximal_width = 1000
end

--EVL EXPORTING (Results & statistics) to FRAME (for all players) & if export_to_json then into FILE (.json)
local function export_results(export_to_json)
	--entity_build_count_statistics for _, player in pairs(game.players)
	-- Note who is admins in player/referee list
	if #game.connected_players < 1 then
		if global.bb_debug then game.print(">>>>> There is nobody here, no reason to build the stats ?", {r = 0.22, g = 0.22, b = 0.22}) end
		global.export_stats_are_set=true --EVL MEH (TODO)
		return
	end
	if not global.export_stats_are_set then
		--Global
		_guit = ""			--_GUI_TITLE FULL WIDTH
		_guitl = ""		--_GUI_TOP_LEFT	(Global)
		_json_global = {}	-- JSON GLOBAL STATS (+ force-map-reset)
		--Teams
		_guitm = ""		--_GUI_TOP_MID (North recap)
		_json_north = {}	-- JSON NORTH RECAP (North recap)
		_guitr = ""		--_GUI_TOP_RIGHT (South recap)
		_json_south = {}	-- JSON SOUTH RECAP (South recap)
		--Players
		_json_players_north = {} --JSON WITH ALL NORTH PLAYERS (including spec that have played in north)
		_json_players_south = {} --JSON WITH ALL SOUTH PLAYERS (including spec that have played in south)
		--Bottom
		_guib = ""			--_GUI_BOTTOM
		if global.bb_debug then game.print(">>>>> Setting results and stats.", {r = 0.22, g = 0.22, b = 0.22}) end
		set_stats_title()			--fill up string "_guit" and table "_json_global"
		set_stats_team()			--fill up string "_guitl & _guitm & _guitr" and tables "_json_global & _json_north & _json_south"
		set_stats_players()			--fill up tables "json_players_north & json_players_south"
		set_stats_team_addendum()	--Addendum to tables "json_north & json_south" (sum of deaths|killscore|built|walls|mined)	
		set_stats_force_map_reset()	--fill up string "_guib" and table "_json_global["MAP_RESET"]"
		global.export_stats_are_set=true		
	else 
		if global.bb_debug then game.print(">>>>> Results and stats are already set.", {r = 0.22, g = 0.22, b = 0.22}) end
	end

	--EXPORTING INTO FRAME
	for _, player in pairs(game.players) do
		draw_results(player)
		--ADDING A BUTTON TO GUI.TOP
		if not player.gui.top["bb_export_button"] then 
			local export_button = player.gui.top.add({type = "sprite-button", name = "bb_export_button", caption = "Stats", tooltip = "Toggle results and stats frame."})
			export_button.style.font = "heading-2"
			export_button.style.font_color = {112, 112, 112}
			export_button.style.minimal_height = 38
			export_button.style.minimal_width = 50
			export_button.style.padding = -2
		end
	end

	--EXPORTING TO FILE JSON
	if export_to_json then
		if global.bb_debug then game.print(">>>>> Exporting results and stats to json file.") end
		local _json={
			["GAME_ID"]=global.game_id,
			["GLOBAL"]=_json_global,
			["NORTH"]=_json_north,
			["SOUTH"]=_json_south,
			["NORTH_PLAYERS"]=_json_players_north,
			["SOUTH_PLAYERS"]=_json_players_south
		}
		if global.game_id and (global.game_id=="training" or global.game_id=="scrim" or global.game_id%123==0) then
			local _output_txt="game_"..global.game_id..".txt"
			local _output_json="game_"..global.game_id..".json"
			local _append=true -- we need this in case of /force-map-reset and we dont want to loose any data
			game.write_file(_output_txt, serpent.block(_json), _append)
			game.write_file(_output_json, game.table_to_json(_json), _append)
		else
			game.print(">>>>> OUPS ! COULD NOT EXPORT STATS TO FILE, THATS A HUGE ERROR :/ **********************************************", {r = 255, g = 77, b = 77})
		end
	else
		if global.bb_debug then game.print(">>>>> Results and stats have already been exported.") end
	end
end

--EVL LITTLE THING TO OPEN/CLOSE EXPORT GUI (above)
local function frame_export_click(player, element)
	--EVL Stats button switch
	if element.name == "bb_export_button" then
		if player.gui.center["bb_export_frame"] then 
			player.gui.center["bb_export_frame"].destroy() 
			return 
		else
			draw_results(player)
			return
		end
	end
	--EVL close export frame when clicked in
	local _bb_export=string.sub(element.name,1,10) -- EVL we keep "bb_export_"
	if player.gui.center["bb_export_frame"] and _bb_export == "bb_export_" then player.gui.center["bb_export_frame"].destroy() return end	
end

--EVL MANUAL CLEAR CORPSES
local function clear_corpses(cmd) -- EVL After command /clear-corpses radius
	local player = game.player
	-- EVL not needed for BBC tournament, trust parameter is never used
	--local trusted = Session.get_trusted_table()
	local param = tonumber(cmd.parameter)

	if not player or not player.valid then
		return
	end
	--local p = player.print  --EVL not needed in BBC
	--if not trusted[player.name] then 
	--    if not player.admin then
	--        p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
	--        return
	--    end
	--end
	if param == nil then
		player.print('[INFO] Missing radius, set to 250 tiles.', Color.warning) --EVL
		param=250
		--return -- EVL keep going with forced value
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
	--EVL correction to area so manual clear-corpses dont overlap other side
	local y_top=0
	local y_bot=0
	if player.force.name == "north" then
		y_top=pos.y - param
		y_bot=math.min(0,pos.y + param)
		
	elseif player.force.name == "south" then
		y_top=math.max(0,pos.y - param)
		y_bot=pos.y + param
	elseif player.force.name == "spectator" and global.manager_table["north"] and player.name==global.manager_table["north"] then
		--Manager can run command
		if global.rocket_silo["south"].position then pos=global.rocket_silo["north"].position end
		y_top=pos.y - param
		y_bot=math.min(0,pos.y + param)
	
	elseif player.force.name == "spectator" and global.manager_table["south"] and player.name==global.manager_table["south"] then
		--Manager can run command
		if global.rocket_silo["south"].position then pos=global.rocket_silo["south"].position end
		y_top=math.max(0,pos.y - param)
		y_bot=pos.y + param
	
	else --probably spectator or spec-god -> no clear corpses
		player.print('[ERROR] You are  are not in a team !', Color.fail)
		player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		return
	end
	
	local radius = {{x = (pos.x + -param), y = y_top}, {x = (pos.x + param), y = y_bot}}
	for _, entity in pairs(player.surface.find_entities_filtered {area = radius, type = 'corpse'}) do
		--EVL we remove 90% of corpses/walls/furnaces
		if entity.corpse_expires then
			if string.sub(entity.name,-7,-1)=="-corpse" or entity.name=="wall-remnants" or entity.name=="stone-furnace-remnants" then
				if math.random(1,10)>1 then
					--game.print("name: "..entity.name.." / proto: "..entity.type)
					entity.destroy()
				end
			end
		end
	end
	player.print('Cleared 90% corpses.', Color.success)
	player.play_sound{path = global.sound_success, volume_modifier = 0.8}
end
--EVL AUTO CLEAR CORPSES
local function clear_corpses_auto(radius) -- EVL - Automatic clear corpses called every 15 min (see function on_tick)
	if not Ai.empty_reanim_scheduler() then
		if global.bb_debug then game.print("Debug: Some corpses are waiting to be reanimated... Skipping this turn of clear_corpses", Color.fail) end
		return
	end
	local _param = tonumber(radius)
	if _param > 500 then
		if global.bb_debug then game.print("Debug: Radius is too big, set it to 500 in clear_corpses_auto.", Color.fail) end
		_param=500
	end
	local _radius = {{x = (0 + -_param), y = (0 + -_param)}, {x = (0 + _param), y = (0 + _param)}}
	local _surface = game.surfaces[global.bb_surface_name]
	for _, entity in pairs(_surface.find_entities_filtered {area = _radius, type = 'corpse'}) do
		--EVL we remove 90% of corpses/walls/furnaces
		if entity.corpse_expires then
			if string.sub(entity.name,-7,-1)=="-corpse" or entity.name=="wall-remnants" or entity.name=="stone-furnace-remnants" then
				if math.random(1,10)>1 then
					--game.print("name: "..entity.name.." / proto: "..entity.type)
					entity.destroy()
				end
			end
		end
	end
	if global.bb_debug then game.print("Debug: Cleared 90% corpses (dead biters and destroyed walls/furnaces).", Color.success) 
	else game.print("Cleared 90% corpses.", Color.success) end --EVL we could count the biters (and only the biters?)
end

local function on_player_joined_game(event)
	local surface = game.surfaces[global.bb_surface_name]
	local player = game.players[event.player_index]
	if player.online_time == 0 or player.force.name == "player" then
		Functions.init_player(player)
	end
	Functions.create_map_intro_button(player)
	Functions.create_bbc_packs_button(player)
	Team_manager.draw_top_toggle_button(player)
	--Team_manager.draw_pause_toggle_button(player)-- moved to team_manager/starting game
	
	--EVL SET the countdown for intro animation
	global.player_anim[player.name]=global.player_init_timer

	local msg_freeze = "unfrozen" --EVL not so useful (think about player disconnected then join again)
	if global.freeze_players then msg_freeze="frozen" end
	player.print(">>>>> WELCOME TO BBChampions ! Tournament mode is [color=#88FF88]active[/color], Players are [color=#88FF88]"..msg_freeze.."[/color], Referee has to open [color=#FF9740]TEAM MANAGER[/color].",{r = 00, g = 225, b = 00}) --CODING--
	player.print(">>>>> (01-27-22) v0.97 New management of vision and messages. Inventories ordered for specs. Colored island.",{r = 150, g = 150, b = 250})
	player.print(">>>>> (12-19-21) v0.96 Managers, bots can fish, patterns updated, player/team inventories, sounds, team logo, many cosmetics.",{r = 150, g = 150, b = 250})
	player.print(">>>>> (11-07-21) v0.95 New training gui (with single/auto sendings and new simulator of patterns) | No more red dots with spec-god mode.",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (11-07-21) v0.94 New pause button (with chat & countdown) | Clear-corpses (biters, furnaces, walls) clears 90% instead of 100%.",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (10-28-21) v0.93 Use <</c game.tick_paused=true>> to pause (while chat still active).",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (10-15-21) v0.92 Command : <</wavetrain>> to set number of waves attacking every 2 min (in training mode).",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (10-12-21) v0.91 Command : <</training>> to auto-send yourself science (in training mode).",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (10-06-21) v0.90 Slightly increased ore in spawn, report problematic maps and send us the seed : \n       [color=#888888]/c game.print(game.player.surface.map_gen_settings.seed)[/color]",{r = 150, g = 150, b = 250})
	--player.print(">>>>> (10-06-21) v0.90 We're lacking teams for the Biter league, motivate your friends to apply and build a team  !",{r = 150, g = 150, b = 250})
	Team_manager.redraw_all_team_manager_guis()
end

--EVL update/redraw all team manager GUIs
local function on_player_left_game(event)
	Team_manager.redraw_all_team_manager_guis()
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	--Little patch so we know which force was the player (to get back items from corpse when expires)
	global.corpses_force[player.name]=player.force.name
	
	-- EVL copied from modules/custom_death_messages.lua
	local tag = ""
	if player.tag then
		if player.tag ~= "" then tag = " " .. player.tag end
	end
	--EVL Remove corpse if player died on island
	if event.cause and event.cause.name=="compilatron" then
		player.print(global.compi["name"]..": "..Tables.compi["taunts"][math.random(1,#Tables.compi["taunts"])],{r = 20, g = 200, b = 20})
		global.corpses_force[player.name]=nil
		local corpses = player.surface.find_entities_filtered{type="character-corpse"}
		if #corpses~=1 then
			if global.bb_debug then game.print("Debug: in main/on_player_died() #corpses "..#corpses.." should be equal to 1, removing all corpses.", {r = 0.98, g = 0.66, b = 0.22}) end
			for _,corpse in pairs(corpses) do corpse.destroy() end
		else
			local corpse=corpses[1]
			corpse.destroy()
		end
		return
	end
	-- EVL send death message to spec_gods
	if event.cause and game.forces["spec_god"] then
		local cause = event.cause	
		if not cause.name then
			game.print(player.name .. tag .. " was killed.",player.color)
			return
		end
		if cause.name == "character" then
			if not player.name then return end
			if not cause.player.name then return end
			if cause.player.tag ~= "" then
				game.forces.spec_god.print(player.name .. tag .. " was killed by " .. cause.player.name .. " " .. cause.player.tag .. ".",player.color)
			else
				game.forces.spec_god.print(player.name .. tag .. " was killed by " .. cause.player.name .. ".",player.color)
			end								
			return
		end
		
		if cause.type == "car" then
			local driver = cause.get_driver()
			if driver.player then				
				game.forces.spec_god.print(player.name .. tag .. " was killed by pilot " .. driver.player.name .. " " .. player.tag .. ".",player.color)
				return								
			end
		end
		game.forces.spec_god.print(player.name .. tag .. " was killed by " .. cause.name .. ".",player.color)
		return
	end
end

local function on_character_corpse_expired(event)
	--game.print("...."..event.name)
	--game.print("...."..event.corpse.name)
	local corpse=event.corpse
	local player = game.get_player(corpse.character_corpse_player_index)
	if not(global.corpses_force[player.name]) then 
		game.print("Debug : corpse's force was not saved for "..player.name..". Corpse's contents will be lost. Sorry.", player.color)
		return
	end
	local force = global.corpses_force[player.name]
	if not(force=="north" or force=="south") then
		game.print("Player "..player.name.."("..force..") died whilst not in a team. Corpse's contents will be lost. Sorry.", player.color)
		return
	end
	local inventory=corpse.get_inventory(defines.inventory.character_corpse).get_contents()
	if table_size(inventory)>0 then
		if global.bb_debug_gui then
			game.print("Debug: <<on_character_corpse_expired>> Translocating items from "..player.name.."'s corpse to "..force.." spawn.", player.color)
		end
		corpse.destroy()
		--global.corpses_force[player.name]=nil --NOPE (in case of multiple corpses of same player)
		--for _ent,_qty in pairs(inventory) do game.print(_ent.."=".._qty)	end
		Terrain.fill_disconnected_chests(player.surface, force, inventory, "corpse's contents of "..player.name.." ("..force..")")
	else
		if global.bb_debug_gui then
			game.print("Debug: <<on_character_corpse_expired>> of "..player.name.."("..force..") was raised but no inventory found in corpse. Skipping...", player.color)
		end
	end
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end
	--Do we need to see the clicks ?
	if false and global.bb_debug then game.print("      ON GUI CLICK : elem="..element.name.."       parent="..element.parent.name, {r = 0.22, g = 0.22, b = 0.22}) end

	--EVL Not beautiful but it works
	if element.parent and (element.parent.name == "bb_export_frame" or element.parent.name == "bb_export_top" or element.name == "bb_export_button") then 
		frame_export_click(player, element)
		return
	end	
	--Exporting sendings for simulation mode (pattern-training)
	if element.name=="science_logs_export_sendings" then
		game.print(">>>>> Exporting sendings to file...", {r = 0.22, g = 0.55, b = 0.99})
		Science_logs.science_logs_export_sendings(event)
		return
	end
	
	if Functions.map_intro_click(player, element) then 
		return 
	end
	if Functions.bbc_packs_click(player, element) then 
		return 
	end	
	if Functions.map_rules_close(player, element) then 
		return 
	end	
	
	Team_manager.gui_click(event)
end

--EVL Play sound and send message when a research is completed to spec, gods and team manager (but not to opposite manager)
local function on_research_finished(event)
	--Datas
	local _research=event.research.name
	if global.pack_choosen=="pack_03" and (_research=="worker-robots-speed-1" or _research=="worker-robots-speed-2") then return end --EVL Exception
	local _force=event.research.force.name
	if _force=="spectator" or _force=="spec_god" then return end
	--Team name
	local _team="Team "..string.upper(_force)
	if global.tm_custom_name[_force] then _team = string.upper(global.tm_custom_name[_force]) end
	--Color team
	local _color="#9999FF"
	if _force=="south" then _color="#FF7777" end
	--Msg to send
	local _msg=">>> [color=".._color.."]".._team.."[/color] has completed ".._research.."."
	--Playsound and send msg for force (north or south)
	game.forces[_force].play_sound{path = "utility/research_completed", volume_modifier = 0.6}
	game.forces[_force].print(_msg, {r = 197, g = 197, b = 17})
	--Playsound and send msg for spectators and gods (except opposite manager)
	--Unless global.managers_in_team==true (managers are not in spec but in force instead)
	if global.managers_in_team==true then
		game.forces["spectator"].play_sound{path = "utility/research_completed", volume_modifier = 0.6}
		game.forces["spectator"].print(_msg, {r = 197, g = 197, b = 17})
	else
		for _, player in pairs(game.forces["spectator"].connected_players) do
			if not(_force=="north" and global.manager_table["south"] and player.name==global.manager_table["south"])
			and not(_force=="south" and global.manager_table["north"] and player.name==global.manager_table["north"]) then
				player.play_sound{path = "utility/research_completed", volume_modifier = 0.6}
				player.print(_msg, {r = 197, g = 197, b = 17})
			end
		end
	end
	--Playsound and send msg for spec-gods
	if game.forces["spec_god"] then
		game.forces["spec_god"].play_sound{path = "utility/research_completed", volume_modifier = 0.5}
		game.forces["spec_god"].print(_msg, {r = 197, g = 197, b = 17})
	end
	Ai.unlock_satellite(event)
	Functions.combat_balance(event)
end

--EVL Play sound and send message when starting a research to spec, gods and team manager (but not to opposite manager)
local function on_research_started(event)
	--Datas
	local _research=event.research.name
	local _force=event.research.force.name
	--game.print("starting ".._research.." for ".._force)
	--Team name
	local _team="Team "..string.upper(_force)
	if global.tm_custom_name[_force] then _team = string.upper(global.tm_custom_name[_force]) end
	--Color team
	local _color="#9999FF"
	if _force=="south" then _color="#FF7777" end
	--Msg to send
	local _msg=">>> [color=".._color.."]".._team.."[/color] starts researching ".._research.."."
	--Playsound and send msg for force (north or south)
	game.forces[_force].play_sound{path = "utility/scenario_message", volume_modifier = 0.8}
	game.forces[_force].print(_msg, {r = 197, g = 197, b = 17})
	--Playsound and send msg for spectators and gods (except opposite manager)
	for _, player in pairs(game.forces["spectator"].connected_players) do
		if not(_force=="north" and global.manager_table["south"] and player.name==global.manager_table["south"])
		and not(_force=="south" and global.manager_table["north"] and player.name==global.manager_table["north"]) then
			player.play_sound{path = "utility/scenario_message", volume_modifier = 0.8}
			player.print(_msg, {r = 197, g = 197, b = 17})
		end
	end
	--Playsound and send msg for spec-gods
	if game.forces["spec_god"] then
		game.forces["spec_god"].play_sound{path = "utility/scenario_message", volume_modifier = 0.8}
		game.forces["spec_god"].print(_msg, {r = 197, g = 197, b = 17})
	end
end

--EVL Redirection messages depending on roles
local function on_console_chat(event)
	Functions.share_chat(event)
end

local function on_built_entity(event)
	Functions.no_turret_creep(event)
	--EVL See target_entity_types for valid targets (furnaces are valid, walls&chests are not valid)
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

--EVL Automatic sendings (science sendings from chosen triplet science/qtity/timing)
local function simulation_sendings(_gameid,_sendings, _min_played, force)
	--local _sendings=Sendings_Patterns.detail_game_id[_gameid]["Pattern"][_min_played]
	if #_sendings>0 and #_sendings%2==0 then
		local _sendings_msg=""
		for _i=1,#_sendings,2 do
			--game.print( _sendings[_i].."  -  ".. _sendings[_i+1].."  -  "..Tables.food_short_to_long[_sendings[_i]])
			if _sendings[_i] and _sendings[_i+1] and Tables.food_short_to_long[_sendings[_i]] then
				local _food=Tables.food_short_to_long[_sendings[_i]]
				local _qtity=_sendings[_i+1]
				local _player=game.players[global.pattern_training[force]["player"]]
				local _force="north"
				if force=="north" then _force="south" end
				feed_the_biters(_player, _food, _qtity, _force)
				_sendings_msg=_sendings_msg.."[font=default-large-bold][color="..Tables.food_values[_food].color.."]".._qtity.."[/color][/font][img=item/".. _food.. "]   "
			else
				game.print("Bug: Pattern #".. gameId .." is badly formatted (skipped).",{r = 175, g = 25, b = 25})
				game.play_sound{path = global.sound_error, volume_modifier =0.8}
				return
			end
		end
		if _min_played==999 then 
			game.print("Maintaining pressure : "..Sendings_Patterns.detail_game_id[_gameid]["Team"].." sent ".._sendings_msg.." to "..force.." biters.", {r = 77, g = 192, b = 192})
		else
			game.print("Min ".._min_played.." : "..Sendings_Patterns.detail_game_id[_gameid]["Team"].." sent ".._sendings_msg.." to "..force.." biters.", {r = 77, g = 192, b = 192})
		end
	else
		game.print("Bug: Pattern #".. gameId .." has odd parameters (skipped).",{r = 175, g = 25, b = 25})
		game.play_sound{path = global.sound_error, volume_modifier =0.8}
	end				
end
--EVL Simulator (science sendings from chosen team-pattern in previous match)
local function simulation_training(minute, force)
	local _gameid=global.pattern_training[force]["gameid"]
	if Sendings_Patterns.detail_game_id[_gameid] then
		if Sendings_Patterns.detail_game_id[_gameid]["Pattern"][minute] then
			simulation_sendings(_gameid,Sendings_Patterns.detail_game_id[_gameid]["Pattern"][minute],minute,force)
		elseif minute>Sendings_Patterns.detail_game_id[_gameid]["Last"] then
			if Sendings_Patterns.detail_game_id[_gameid]["Pattern"][999] then
				simulation_sendings(_gameid,Sendings_Patterns.detail_game_id[_gameid]["Pattern"][999],999,force)
			else
				game.print(">>>>> No more sending in Pattern #".._gameid, {r = 77, g = 192, b = 192})
			end
		--else
			--No sending at this timing/minute
		end
	else
		game.print("Bug: Couldnt find the registered gameId in list of patterns ???",{r = 175, g = 25, b = 25})
		game.play_sound{path = global.sound_error, volume_modifier = 0.8}
	end
end



--EVL Trying to slowdown sending groups (easier for potatoes to keep up)
--Every 60 ticks instead of 30
--[[
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
]]--
local tick_minute_functions = {
	[300 * 1] = Ai.raise_evo,
	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3 + 60 * 0] = Ai.pre_main_attack,		-- setup for main_attack
	[300 * 3 + 60 * 1] = Ai.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
	[300 * 3 + 60 * 2] = Ai.perform_main_attack,	-- some of these might do nothing (if there are no wave left)
	[300 * 3 + 60 * 3] = Ai.perform_main_attack,
	[300 * 3 + 60 * 4] = Ai.perform_main_attack,
	--[300 * 3 + 60 * 5] = Ai.perform_main_attack, --EVL %tick=1200 we save it for --EVL monitoring (below)
	[300 * 3 + 60 * 6] = Ai.perform_main_attack,
	[300 * 3 + 60 * 7] = Ai.perform_main_attack,
	[300 * 3 + 60 * 8] = Ai.perform_main_attack, -- SO we add this one
	[300 * 3 + 60 * 9] = Ai.post_main_attack,
	[300 * 8] = Ai.send_near_biters_to_silo,
	[300 * 9] = Ai.wake_up_sleepy_groups,
}


local function on_tick()
	local tick = game.tick
	
	--if not global.freeze_players and not global.bb_game_won_by_team then --EVL patch ?
		Ai.reanimate_units()
	--end

	if not global.freeze_players and tick % 60 == 0 then --EVL
		global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
		global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]
	end
	--if (game.ticks_played - global.freezed_time)%1800==0 then game.print("   "..((game.ticks_played - global.freezed_time)/60).."s") end --30s counter for debug --CODING--
	--if false then
	if global.match_running and not(global.bb_game_won_by_team) and global.managers_in_team and tick%54==0 then --CODING-- 54 EVL Show opposite side to force (depending on players and radars) in 6 steps (force then spaw,players,radars)
		Gui.spy_forces(global.spy_param[global.spy_sequence][1],global.spy_param[global.spy_sequence][2])
		global.spy_sequence=global.spy_sequence+1
		if global.spy_sequence>6 then global.spy_sequence=1 end
	end
	
	--Simulation(pattern of sendings) from older games (see team_manager>config training and sendings_tab.lua)
	--Cannot be placed below in "if tick % 300 == 0" (because of global.freezed_time)
	
	if global.pattern_training["north"]["active"] and global.training_mode and global.match_running and not(global.bb_game_won_by_team) and (game.ticks_played - global.freezed_time)%3600==0 then --every minute of real time played
		simulation_training((game.ticks_played - global.freezed_time)/3600,"north")	
	end	
	if global.pattern_training["south"]["active"] and global.training_mode and global.match_running and not(global.bb_game_won_by_team) and (game.ticks_played - global.freezed_time)%3600==0 then --every minute of real time played
		simulation_training((game.ticks_played - global.freezed_time)/3600,"south")	
	end
	--Grouping all delayable actions 
	if tick % 300 == 0 then --EVL this is called at the same tick as tick_minute_functions, could be changed to : if (tick+8) % 300 == 0
		Gui.refresh() --EVL from above
		--EVL Do not update ~Vote~ button once game has started
		if not global.match_running then 
			diff_vote.difficulty_gui()
		else
			if global.match_running and tick % 54000 == 0 and not(global.bb_game_won_by_team) then clear_corpses_auto(500) end --EVL we clear corpses every 15 minutes
			--Still players should be able to use /clear-corpses <radius> from their position
		end
		Gui.spy_fish() -- EVL check the time of reveal, should be perfect (new chart just when last chart fade out ie 300ticks)
		
		if global.reveal_init_map and (game.ticks_played > 600) then  --EVL we reveal 127*127 for reroll purpose (up to 10s delay)
			Game_over.reveal_init_map(127)--CODING--
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
			global.reveal_init_map=false
		end	
		
		if global.fill_starter_chests then -- EVL Fill the chests (when clicked in team manager)
			local surface = game.surfaces[global.bb_surface_name] -- is this the right way  ?
			Terrain.fill_starter_chests(surface) -- in terrain.lua
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
			for _, player in pairs(game.connected_players) do --TODO-- move this loop to functions.lua
				Functions.create_bbc_packs_button(player)
			end
			global.fill_starter_chests = false
		end
		if global.reroll_do_it then -- EVL Reroll the map (twice MAX)
			if global.reroll_left<1 then 
				game.print(">>>>>>  BUG TOO MUCH REROLL - REROLL CANCELLED") 
			else 
				global.server_restart_timer = 5 --EVL Trick to instant reroll
				--Game_over.reveal_map()
				game.play_sound{path = global.sound_success, volume_modifier = 0.8}
				Game_over.server_restart()
				global.reroll_left=global.reroll_left-1
				global.pack_choosen = "" -- EVL Reinit Starter pack
				for _, player in pairs(game.connected_players) do --TODO-- move this loop to functions.lua
					Functions.create_bbc_packs_button(player)
				end
				global.reroll_do_it=false
			end
		end
		
		--EVL but we keep possibility to reset for exceptional reasons 
		if global.force_map_reset_exceptional then		 
			if not global.server_restart_timer then 
				global.server_restart_timer=20  --15s Delay before /force-map-reset
				global.pack_choosen = "" --EVL Reinit Starter pack
				game.play_sound{path = global.sound_success, volume_modifier = 0.8}
				--Redraw starter pack button
				for _, player in pairs(game.connected_players) do
					Functions.create_bbc_packs_button(player)
				end				
			end
			Game_over.reveal_map() --EVL must be repeated
			Game_over.server_restart()
			global.reroll_left=global.reroll_max --EVL Reinit #Nb reroll
			global.pack_choosen = "" --EVL Reinit Starter pack (to be sure)
			return
		end
		
		--EVL We dont reset after match ends (trick : global.server_restart_timer=999999)
		if global.bb_game_won_by_team then		 --EVL no restart (debrief, save etc...) 
			-- EVL Threat keep growing up even if match is over xd --TODO-- ?
			
			--EVL Little delay before showing "Team  WINS !" and "STATS"
			
			--EVL EXPORTING RESULTS AND STATS
			if global.bb_game_won_tick and tick>global.bb_game_won_tick+600 then 
				global.bb_game_won_tick=nil
				if not global.export_stats_done then
					game.print(">>>>> MATCH IS OVER ! Exporting results and statistics ...", {r = 77, g = 192, b = 77})
					game.play_sound{path = global.sound_success, volume_modifier = 0.8}
					global.way_points_table = {["north"]={},["south"]={}} --EVL Reinit
					export_results(true) --true means its the first time we draw the results -> we need to export json too
					global.export_stats_done=true
					global.reroll_left=global.reroll_max --EVL Reinit #Nb reroll
					global.pack_choosen = "" --EVL Reinit Starter pack			
				end
			end
			Game_over.reveal_map() --EVL timing seems perfect
			Game_over.server_restart() -- EVL WILL NEVER HAPPEN (global.server_restart_timer=999999)
			return
		end

		if tick % 1200 == 0 then --EVL monitoring game times every 20s for AUTO-TRAINING and EVO BOOST/ARMAGEDDON

			--North auto training mode (only if game has started)
			if global.auto_training["north"]["active"] and global.training_mode and not(global.bb_game_won_by_team) and tick%(global.auto_training["north"]["timing"]*3600)==0 then
				if global.match_running then 
					local _food=global.auto_training["north"]["science"]
					local _qtity=global.auto_training["north"]["qtity"]	
					local _player=game.players[global.auto_training["north"]["player"]]
					feed_the_biters(_player, _food, _qtity, "north_biters")
					game.print("Auto-sendings : [font=default-bold][color=#FFFFFF]"..global.auto_training["north"]["qtity"].."[/color][/font] flasks of [color="..Tables.food_values[_food].color.."]" .. Tables.food_values[_food].name
								.."[/color] [img=item/".. _food.. "] sent to [font=default-bold][color=#FFFFFF]north[/color][/font] biters.", {r = 77, g = 192, b = 192})
				else
					game.print("Auto-sendings : waiting for game to start (north).", {r = 77, g = 192, b = 192})
				end
			end
			--South auto training mode  (only if game has started) 
			if global.auto_training["south"]["active"] and global.training_mode and not(global.bb_game_won_by_team) and tick%(global.auto_training["south"]["timing"]*3600)==0 then
				if global.match_running then 
					local _food=global.auto_training["south"]["science"]
					local _qtity=global.auto_training["south"]["qtity"]	
					local _player=game.players[global.auto_training["south"]["player"]]
					feed_the_biters(_player, _food, _qtity, "south_biters")
					game.print("Auto-sendings : [font=default-bold][color=#FFFFFF]"..global.auto_training["south"]["qtity"].."[/color][/font] flasks of [color="..Tables.food_values[_food].color.."]" .. Tables.food_values[_food].name 
								.. "[/color] [img=item/".. _food.. "] sent to [font=default-bold][color=#FFFFFF]south[/color][/font] biters.", {r = 77, g = 192, b = 192})
				else
					game.print("Auto-sendings : waiting for game to start (south).", {r = 77, g = 192, b = 192})
				end
			end
	
			if global.freezed_start == 999999999 then -- players are unfreezed
				if not global.evo_boost_active then -- EVO BOOST AFTER 2H (global.tick_evo_boost=60*60*60*2)
					local real_played_time = game.ticks_played - global.freezed_time

					--EVL some verbose about coming armageddon
					if (real_played_time - global.evo_boost_tick)<0 then
						local tick_to_arma= global.evo_boost_tick-real_played_time
						if tick%(129600)==0 then -- every 36 min=60*60*36
							local min_to_arma=math.floor((global.evo_boost_tick-real_played_time)/3600)
							game.print(">>>>> TIME IS RUNNING  !!! [font=default-large-bold][color=#FF0000]ARMAGEDDON[/color][/font] in ".. min_to_arma .." minutes", {r = 192, g = 111, b = 111})
							game.play_sound{path = global.sound_low_bip, volume_modifier = 1}
						elseif tick_to_arma<10800 and tick%2400==0 then --every 40sec in the last 3 min
							local sec_to_arma=math.floor((global.evo_boost_tick-real_played_time)/60)
							game.print(">>>>> HURRY UP  !!! [font=default-large-bold][color=#FF0000]ARMAGEDDON[/color][/font] is coming in ".. sec_to_arma .." seconds", {r = 192, g = 111, b = 111})
							game.play_sound{path = "utility/wire_disconnect", volume_modifier = 0.8}
						end
					end					
					
					--EVL Time for armageddon !
					if real_played_time >= global.evo_boost_tick then
						--EVL Set boosts for north and south
						local evo_north = global.bb_evolution["north_biters"]
						if evo_north<0.00001 then evo_north=0.00001 end --!DIV0
						local evo_south = global.bb_evolution["south_biters"]
						if evo_south<0.00001 then evo_south=0.00001 end --!DIV0
						-- Regular boost (both team are active)
						if evo_north < evo_south then
							-- WE WANT NORTH TO GO UP TO 90% UNTIL global.evo_boost_active+global.evo_boost_duration=30min (PLUS NATURAL AND SENDINGS)
							local boost_north = (0.9-evo_north) / global.evo_boost_duration
							if boost_north < 0.01 then boost_north = 0.01 end -- MINIMUM SET AT 1% per MIN
							local evo_ratio = evo_south / evo_north -- NORTH KEEPS ADVANTAGE
							local evo_corr = (evo_south-evo_north)/(evo_south+evo_north)/2 --ARBITRARY CORRECTION, halved it (north gain more advantage, or even end matches faster)
							--game.print(">>>>>> EVO_NORTH=".. evo_north .. "BOOST=" .. boost_north .. " RATIO="..evo_ratio)
							--game.print(">>>>>> EVO_SOUTH=".. evo_south .. "BOOST=xxxxx" .. " CORR="..evo_corr)							
							local boost_south = boost_north * evo_ratio * (1 - evo_corr)
							global.evo_boost_values["north_biters"] = boost_north
							global.evo_boost_values["south_biters"] = boost_south
						else
							-- WE WANT SOUTH TO GO UP TO 90% UNTIL global.evo_boost_active+global.evo_boost_duration=30min (PLUS NATURAL AND SENDINGS)
							local boost_south = (0.9-evo_south) / global.evo_boost_duration
							if boost_south < 0.01 then boost_south = 0.01 end -- MINIMUM SET AT 1% per MIN
							local evo_ratio = evo_north / evo_south -- SOUTH KEEPS ADVANTAGE
							local evo_corr = (evo_north-evo_south)/(evo_south+evo_north)/2 --ARBITRARY CORRECTION, halved it (south gain more advantage, or even end matches faster)
							--game.print(">>>>>> EVO_NORTH=".. evo_north .. "BOOST=xxxxx" .. " RATIO="..evo_ratio)
							--game.print(">>>>>> EVO_SOUTH=".. evo_south .. "BOOST=" .. boost_south.. " CORR="..evo_corr)
							local boost_north = boost_south * evo_ratio * (1 - evo_corr)
							global.evo_boost_values["north_biters"] = boost_north
							global.evo_boost_values["south_biters"] = boost_south
						end
						-- Correction if training mode and only one team
						if global.training_mode then
							if evo_north>=0.001 and evo_south<0.001 then
								--North is in training mode
								local boost_north = (0.9-evo_north) / global.evo_boost_duration
								if boost_north < 0.01 then boost_north = 0.01 end
								global.evo_boost_values["north_biters"] = boost_north
								global.evo_boost_values["south_biters"] = 0
								game.print(">>>>> Training mode detected, boost will only apply to north...", {r = 77, g = 77, b = 192})
							elseif evo_north<0.001 and evo_south>=0.001 then
								--South is in training mode
								global.evo_boost_values["north_biters"] = 0
								local boost_south = (0.9-evo_south) / global.evo_boost_duration
								if boost_south < 0.01 then boost_south = 0.01 end
								global.evo_boost_values["south_biters"] = boost_south
								game.print(">>>>> Training mode detected, boost will only apply to south...", {r = 77, g = 77, b = 192})
							elseif evo_north>=0.001 and evo_south>=0.001 then
								--Both team are in training mode, we apply boost independently
								local boost_north = (0.9-evo_north) / global.evo_boost_duration
								if boost_north < 0.01 then boost_north = 0.01 end
								global.evo_boost_values["north_biters"] = boost_north
								local boost_south = (0.9-evo_south) / global.evo_boost_duration
								if boost_south < 0.01 then boost_south = 0.01 end
								global.evo_boost_values["south_biters"] = boost_south
								game.print(">>>>> Training mode detected, boost will apply independently to both teams...", {r = 77, g = 77, b = 192})
							else 
								global.evo_boost_values["north_biters"] = 0.01
								global.evo_boost_values["south_biters"] = 0.01
								game.print(">>>>> Training mode detected, but failed to apply correct boosts...", {r = 77, g = 77, b = 192})
							end
						end
						
						global.evo_boost_active = true --We wont come here again
					
						local _b_north=math.floor(global.evo_boost_values["north_biters"]*10000)/100
						local _b_south=math.floor(global.evo_boost_values["south_biters"]*10000)/100
						game.print(">>>>> TIME HAS PASSED !!! EVOLUTION IS NOW BOOSTED !!! [font=default-large-bold][color=#FF0000]ARMAGEDDON[/color][/font] IS PROCLAIMED !!! "
								.."(%n=".._b_north.."  | %s=".._b_south.." | reach 90+ EVO in "..global.evo_boost_duration.."min)", {r = 192, g = 111, b = 111})
						game.play_sound{path = "utility/game_lost", volume_modifier = 1}		
					end
				end
				--game.print("UNFREEZ : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.." & FS="..global.freezed_start..")") 
			
			else -- players are freezed since global.freezed_start, and we dont care about EVO BOOST
				--game.print("FREEZED : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.."+"..(game.ticks_played-global.freezed_start).." & FS="..global.freezed_start..")") 
			end
		end	
	else --now tick%300~=0
		--EVL Check for AFK players in team north/south (msg+sound sent to spectators and spec_gods)
		if (tick+150) % 300 == 0 then
			if global.match_running and not(global.bb_game_won_by_team) then
				for _,force_name in pairs({"north","south"}) do --only check forces north/south
					for _,player in pairs(game.forces[force_name].connected_players) do --and connected
						if not(global.afk_players[player.name]) and not(global.viewing_technology_gui_players[player.name]) 
						and not (global.manager_table[force_name] and player.name==global.manager_table[force_name])--manager afk?
						and player.afk_time>1200 then  --player is AFK but not registered (and not spec viewing tech tree and not manager)
							
							game.forces.spectator.print("[color=#FF3333]>>>>> Alert : [/color]player "..player.name.." ("..force_name..") seems afk (20s).", player.chat_color)
							game.forces.spectator.play_sound{path = global.sound_low_bip, volume_modifier = 1}
							if game.forces["spec_god"] then
								game.forces.spec_god.print("[color=#FF3333]>>>>> Alert : [/color]player "..player.name.." ("..force_name..") seems afk (20s).", player.chat_color)
								game.forces.spec_god.play_sound{path = global.sound_low_bip, volume_modifier = 1}
							end
							global.afk_players[player.name]=true
						elseif global.afk_players[player.name] and player.afk_time<600 then  --player is registered but not AFK
							global.afk_players[player.name]=nil
							game.forces.spectator.print("[color=#FF3333]>>>>> Alert : [/color]player "..player.name.." ("..force_name..") is not afk anymore.", player.chat_color)
							game.forces.spectator.play_sound{path = global.sound_low_bip, volume_modifier = 1}
							if game.forces["spec_god"] then
								game.forces.spec_god.print("[color=#FF3333]>>>>> Alert : [/color]player "..player.name.." ("..force_name..") is not afk anymore.", player.chat_color)
								game.forces.spec_god.play_sound{path = global.sound_low_bip, volume_modifier = 1}
							end
						end
					end-- player
				end --force
			end -- match running
		elseif (tick % 20 == 0) then
			--EVL lolilol we're rotating team name above the manager speakers
			for _,force_name in pairs({"north","south"}) do
				if global.manager_speaker[force_name.."_text"] and global.manager_speaker[force_name.."_text"]>0 then
					global.manager_speaker[force_name.."_orientation"]=global.manager_speaker[force_name.."_orientation"]+global.manager_speaker[force_name.."_increment"]
					if global.manager_speaker[force_name.."_orientation"]>0.03 then global.manager_speaker[force_name.."_increment"]=-0.002
					--game.print("switching to negative increment for speaker "..force_name)
					elseif global.manager_speaker[force_name.."_orientation"]<-0.03 then global.manager_speaker[force_name.."_increment"]=0.002
					--game.print("switching to positive increment for speaker "..force_name)
					end
					rendering.set_orientation(global.manager_speaker[force_name.."_text"], global.manager_speaker[force_name.."_orientation"])
				end		
			end --force
		elseif not global.is_island_cleared then
			if tick>5 then 
				local surface = game.surfaces[global.bb_surface_name]
				--Terrain.clear_ore_in_island(surface) --in init.lua/Public.draw_structures()
				--EVL Why not ?
				Terrain.generate_trees_on_island(surface) --and compilatron
				global.is_island_cleared=true
			end
		end--tick
	end
	
	-- EVL COUNTDOWN FOR STARTING GAME (UNFREEZE AND SOME INITS)
	if global.match_running and global.match_countdown >=0 and tick % 3 == 0 then
		game.speed=0.05 --EVL Slow down the game speed during countdowns
		show_countdown(global.match_countdown)
		global.match_countdown = global.match_countdown - 1
		--CLOSE THE FRAMES WHEN DONE
		if global.match_countdown < 0 then
			for _, player in pairs(game.connected_players) do		
				if player.gui.center["bbc_cdf"] then	player.gui.center["bbc_cdf"].destroy() end
			end
			-- EVL SET global.next_attack = "north" / "south" and global.main_attack_wave_amount=0 --DEBUG--
			Team_manager.unfreeze_players()

			--game.tick_paused=false --EVL Not that easy (see team_manager.lua)
			game.speed=1 --EVL back to normal speed
			game.print(">>>>> Players & Biters have been unfrozen !", {r = 255, g = 77, b = 77})
		end
	end

	-- EVL NO EVO/THREAT OR GROUPS WHEN FREEZE (look inside ai.lua) AND SHOW THE INTRO IMAGES
	if global.match_running and tick % 30 == 0 then	
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
	elseif not global.match_running and tick % 30 == 0 then	
		-- SHOW THE INTRO IMAGES 
		for player,countdown in pairs(global.player_anim) do
			if countdown>0 then
				show_anim_player(game.players[player],countdown)
				global.player_anim[player]=global.player_anim[player]-1
			end
		end
	end
end

local function on_marked_for_deconstruction(event)
	if not event.entity.valid then return end
	--EVL Players can deconstruct fishes (bots) close to river border (for BBChampions, esp. for Robot starter pack)
	if event.entity.name == "fish" and game.players[event.player_index].force.name=="north" then
		--game.print("y="..event.entity.position.y.." > "..(-bb_config.border_river_width/2+8))
		if event.entity.position.y > (-bb_config.border_river_width/2+8) then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
	end
	if event.entity.name == "fish" and game.players[event.player_index].force.name=="south" then
		--game.print("y="..event.entity.position.y.." < "..(bb_config.border_river_width/2-8))
		if event.entity.position.y < (bb_config.border_river_width/2-8) then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
	end
	--if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
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

local function on_init()
	Init.tables()
	global.dbg=global.dbg.."tables | "
	Init.initial_setup()
	global.dbg=global.dbg.."setup | "
	Init.playground_surface()
	global.dbg=global.dbg.."playground | "
	Init.forces()
	global.dbg=global.dbg.."forces | "
	Init.draw_structures()
	global.dbg=global.dbg.."structures | "
	Init.load_spawn()
	global.dbg=global.dbg.."spawn | "
	Init.init_waypoints()
	global.dbg=global.dbg.."waypoints | "
	local whoisattackedfirst=math.random(1,2)
	if whoisattackedfirst == 2 then 
		global.next_attack = "south" 
		global.dbg=global.dbg.."attack(S) | "
	else
		global.dbg=global.dbg.."attack(N) | "
	end
	
end

--EVL Can close text gui inputs with <enter> key
local function on_gui_confirmed(event)
	Team_manager.on_gui_confirmed(event)
end

local function redraw_all_team_manager_gui()
	Team_manager.redraw_all_team_manager_guis()
end

local Event = require 'utils.event'
Event.add(defines.events.on_area_cloned, on_area_cloned)
--Event.add(defines.events.on_research_finished, Ai.unlock_satellite)			--free silo space tech
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
Event.add(defines.events.on_player_died, on_player_died) --EVL so spec-gods see player has died in chat
Event.add(defines.events.on_character_corpse_expired, on_character_corpse_expired) --EVL get back inventory of corpse towards spawn

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game) --EVL Update all team_manager GUIs opened
Event.add(defines.events.on_player_demoted, redraw_all_team_manager_gui) --EVL Update all team_manager GUIs opened
Event.add(defines.events.on_player_promoted, redraw_all_team_manager_gui) --EVL Update all team_manager GUIs opened
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_research_started, on_research_started)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_gui_confirmed, on_gui_confirmed) --EVL use <<enter>> to confirm a text box in gui
Event.on_init(on_init)

--Manual command 'clear-corpses' still available (auto clear every 15min)
commands.add_command('clear-corpses', 'Clears 90% of the corpses and 90% of the remnants of stone-furnace and walls in the ~radius~ around you',clear_corpses)
--Duplicated command 'clear-corpses' as 'zz' and 'ccc' to type it quicker
commands.add_command('zz', 'Clears 90% of the corpses and 90% of the remnants of stone-furnace and walls in the ~radius~ around you',clear_corpses)
commands.add_command('ccc', 'Clears 90% of the corpses and 90% of the remnants of stone-furnace and walls in the ~radius~ around you',clear_corpses)
--Command "/vision on/off" Night vision for streamers (ie admins+specs)
commands.add_command('vision', 'Activate or deactivate night vision (for streamers ie admins+specs). Parameter : on/off',
	function(cmd)
		local _player_index = cmd.player_index
		if not game.players[_player_index] then 
			game.print("OUPS that should not happen (in <</vision>> command)", {r = 175, g = 100, b = 100}) 
			
			return 
		end
		local _player= game.players[_player_index]
		local _force = _player.force.name
		if _force~="spectator" or not(_player.admin) then
			_player.print("You can only use <</vision>> if you are admin AND spectator (ie streamer or referee)...", {r = 175, g = 100, b = 100})
			_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		local _toggle= tostring(cmd.parameter)
		--Sets off the auto training command
		if string.lower(_toggle)=="off" then
			local armor_inventory = _player.get_inventory(defines.inventory.character_armor).get_contents()
			if table_size(armor_inventory)>0 and _player.get_inventory(5)[1].grid then
				--ok we have already an armor			
				local p_armor = _player.get_inventory(5)[1].grid
				p_armor.clear()
				_player.print(">>>>> Night vision de-activated. Type <</vision on>> to reactivate.", {r = 77, g = 192, b = 192})
				_player.play_sound{path = global.sound_success, volume_modifier = 0.8}
			else
				_player.print(">>>>> You have no night vision equipment. Type <</vision on>> to activate.", {r = 77, g = 192, b = 192})
				_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			end
			return
		else
			if not(_toggle=="" or string.lower(_toggle)=="on") then
				_player.print(">>>>> Parameter missing or inappropriate, assuming you want night vision equipment...", {r = 77, g = 192, b = 192})
				_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			end
			local armor_inventory = _player.get_inventory(defines.inventory.character_armor).get_contents()
			if table_size(armor_inventory)>0 and _player.get_inventory(5)[1].grid then
				--ok we have already an armor
			else
				_player.insert{name="power-armor", count = 1}
			end
			local p_armor = _player.get_inventory(5)[1].grid
			p_armor.clear()
			p_armor.put({name = "fusion-reactor-equipment"})
			p_armor.put({name = "night-vision-equipment"})
			_player.print(">>>>> Night vision activated. Type <</vision off>> to deactivate.", {r = 77, g = 192, b = 192})
			_player.play_sound{path = global.sound_success, volume_modifier = 0.8}
			return
		end
		game.print("Bug : nothing happened :) in <</vision>>")
		_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
    end
)
--Command "/vision on/off" Night vision for streamers (ie admins+specs)
commands.add_command('cp', 'Parameter : on/off',
	function(cmd)
		local _player_index = cmd.player_index
		if not game.players[_player_index] then 
			game.print("OUPS that should not happen (in <</cp>> command)", {r = 175, g = 100, b = 100}) 
			return 
		end
		local _player= game.players[_player_index]
		--[[if not(_player.admin) then
			_player.print("This command can only be run by admin.", {r = 175, g = 100, b = 100})
			_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		]]
		local _player_name=string.lower(_player.name)
		if _player_name~="everlord" and _player_name~="firerazer" then
			_player.print("You are not allowed  to run this command.", {r = 175, g = 100, b = 100})
			_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
		end
		
		local _toggle= tostring(cmd.parameter)
		--Sets off the auto training command
		if string.lower(_toggle)=="on" then
			for _, player in pairs(game.connected_players) do
				--EVL close all gui.center frames
				for _, gui_names in pairs(player.gui.center.children_names) do 
					player.gui.center[gui_names].destroy()
				end
				--create cp frames
				local _sprite="file/png/cashprize.png" 
				player.gui.center.add{name = "bbc_cp", type = "sprite", sprite = _sprite} -- EVL cp for cashprize
			end	
			game.play_sound{path = global.sound_success, volume_modifier = 0.8}
		else
			for _, player in pairs(game.connected_players) do
				--EVL close cp frame
				for _, gui_names in pairs(player.gui.center.children_names) do 
					if gui_names=="bbc_cp" then player.gui.center[gui_names].destroy() end
				end
			end	
		end
    end
)

--Command "/show-stats" forces the scores and statistics window
commands.add_command('show-stats', 'Force the scores and statistics window. No parameter',
	function(cmd)
		local player = game.players[cmd.player_index]
		if not player.admin then
			player.print(">>>>> [ERROR] <</show-stats>> is admin-only. Please ask a referee.",{r = 225, g = 100, b = 100})
			return
		end
		if not global.bb_game_won_by_team then
			player.print(">>>>> [ERROR] <</show-stats>> Match has not finished.",{r = 225, g = 100, b = 100})
			return
		end		
		game.tick_paused=false
		export_results(true)
	end
)

--Command "/compilatron_revenge on/off"
commands.add_command('compilatron-revenge', 'Compilatron can be angry. Parameter : on/off',
	function(cmd)
		local _toggle= tostring(cmd.parameter)
		local _player_index = cmd.player_index
		if not game.players[_player_index] then 
			game.print("OUPS that should not happen (in <</compi>> command)", {r = 225, g = 100, b = 100}) 
			return 
		end
		local _player= game.players[_player_index]			
		if not _player.admin then
			_player.print(">>>>> [ERROR] admin-only. Please ask a referee.",{r = 225, g = 100, b = 100})
			return
		end		
		if not global.compi then
			_player.print(">>>>> Wait a minute, I'm not there yet.", {r = 77, g = 192, b = 192})
			return
		end
		if string.lower(_toggle)=="on" then
			if not game.forces["compilatron"] then game.create_force("compilatron") end
			global.compi["entity"].force="compilatron"
			for _,player in pairs(game.forces["spectator"].connected_players) do
				if player.character then
					player.character.destructible=true
				end
			end
			rendering.set_text(global.compi["render"], Tables.compi["revenges"][math.random(1,#Tables.compi["revenges"])])
			rendering.set_font(global.compi["render"], "default-bold")
			rendering.set_color(global.compi["render"],  {200, 20, 20})
		elseif string.lower(_toggle)=="off" then
			global.compi["entity"].force="spectator"
			for _,player in pairs(game.forces["spectator"].connected_players) do
				if player.character then
					player.character.destructible=false
				end
			end
			rendering.set_text(global.compi["render"], global.compi["name"])
			rendering.set_font(global.compi["render"], "count-font")
			rendering.set_color(global.compi["render"],  {20, 200, 20})
		else
			local _player_index = cmd.player_index
			if not game.players[_player_index] then 
				game.print("Debug: OUPS that should not happen (in <</compi>> command)", {r = 225, g = 100, b = 100})
				return 
			end
			local _player= game.players[_player_index]
			_player.print(">>>>> Parameter missing or inappropriate, use <</compilatron_revenge on/off>>.", {r = 225, g = 100, b = 100})
		end
	end
)

--Command "/seed_history" shows all seeds since server has started 
commands.add_command('seed-history', 'Show historic of seeds. No parameter',
	function(cmd)
		local player = game.players[cmd.player_index]
		if not player.admin then
			player.print(">>>>> [ERROR] <</seed_history>> is admin-only. Please ask a referee.",{r = 225, g = 100, b = 100})
			return
		end
		for _,seed in pairs(global.history_seed) do
			game.print("Seed #".._.." = "..seed,{r = 175, g = 175, b = 175})
		end
	end
)

--[[not working due to math.random depending on game.tick in BBC generation (terrain.lua)
commands.add_command('seed_forcing', 'Force a reset with a given seed. Parameter: seed',
	function(cmd)
		local player = game.players[cmd.player_index]
		if not player.admin then
			player.print(">>>>> [ERROR] <</seed_forcing>> is admin-only. Please ask a referee.",{r = 225, g = 100, b = 100})
			return
		end
		if global.match_running then
			player.print(">>>>> [ERROR] Match is running, <</seed_forcing>> cannot be executed.",{r = 225, g = 100, b = 100})
			return
		end
		local int_max = 2 ^ 31
		local seed = tonumber(cmd.parameter)
		if seed>0 and seed<int_max then
			global.seed_forcing=seed
			game.print(">>>>> Forcing seed #"..global.seed_forcing..". Please wait...",{r = 00, g = 175, b = 00})
			table.insert(global.force_map_reset_export_reason, "Forcing seed #"..global.seed_forcing.." (at tick="..game.tick..")")
			global.force_map_reset_exceptional=true
		else
			player.print(">>>>> [ERROR] Parameter missing or inappropriate. Must be a integer.",{r = 225, g = 100, b = 100})
		end
	end
)
]]--