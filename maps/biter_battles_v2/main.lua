-- Biter Battles v2 -- by MewMew

local Ai = require "maps.biter_battles_v2.ai"
local Functions = require "maps.biter_battles_v2.functions"
local Game_over = require "maps.biter_battles_v2.game_over"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Tables = require "maps.biter_battles_v2.tables" --EVL (none)
local Score = require "comfy_panel.score" --EVL (none)
local Mirror_terrain = require "maps.biter_battles_v2.mirror_terrain"
require 'modules.simple_tags' -- is this used ?
local Team_manager = require "maps.biter_battles_v2.team_manager"
	
local Terrain = require "maps.biter_battles_v2.terrain"
local Session = require 'utils.datastore.session_data'
local Color = require 'utils.color_presets'
local diff_vote = require "maps.biter_battles_v2.difficulty_vote"

require "maps.biter_battles_v2.sciencelogs_tab"
-- require 'maps.biter_battles_v2.commands' --EVL no need (other way to restart : use /force_map_reset instead)
require "modules.spawners_contain_biters" -- is this used ?

--require 'spectator_zoom' -- EVL Zoom for spectators -> Moved to GUI.LEFT

--EVL A BEAUTIFUL COUNTDOWN (WAS IN ASCII ART) (limited to 9 -> 1)
local function show_countdown(_second)
	if not _second or _second<1 then return end
	if _second>9 then 
		game.print(">>>>> ".._second.."s remaining", {r = 77, g = 192, b = 77})
		return 
	end
	for _, player in pairs(game.players) do
		--EVL close all gui.center frames
		for _, gui_names in pairs (player.gui.center.children_names) do 
			player.gui.center[gui_names].destroy()
		end

		local _sprite="file/png/".._second..".png" 
		player.gui.center.add{name = "bbc_cdf", type = "sprite", sprite = _sprite} -- EVL cdf for countdown_frame
		--[[ THAT WAS SO NICE ASCII ART
		local bbc_frame = player.gui.center.add({type = "frame", name = "bbc_cdf", caption = "Starting in "})
		local _caption="\n"
		for _line=1,#Tables.bbc_countdowns[_second],1 do
		 _caption=_caption.."            "..Tables.bbc_countdowns[_second][_line].."\n"
		end
		local bbc_count = bbc_frame.add({type = "label", name = "bbc_cdb", caption = _caption, tooltip="This is what you get when you cant display a .png"})
		bbc_count.style.single_line = false
		bbc_count.style.font="default-large-bold"
		bbc_count.style.font_color = {r=0.66, g=0.66, b=0.66}
		if global.match_countdown<=6 then bbc_count.style.font_color = {r=0.78, g=0.44, b=0.44} end
		if global.match_countdown<=3 then bbc_count.style.font_color = {r=0.98, g=0.22, b=0.22} end
		bbc_count.style.minimal_width = 250
		bbc_count.style.minimal_height = 225
		--local bbc_image = bbc_frame.add({type = "sprite", name = "bbc_png", sprite = "01.png"}) --EVL WHY??? PLEASE....
		]]--
	end	
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
	elseif countdown ==18 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_150.png"}
	elseif countdown ==17 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_200.png"}
	elseif countdown ==16 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_300.png"}
	elseif countdown ==15 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		local _png = player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_1000.png"}
	elseif countdown ==9 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		player.gui.center.add{name = "show_anim_png", type = "sprite", sprite = "file/png/logo_bbc.png"}
	elseif countdown ==1 then
		if player.gui.center["show_anim_png"] then player.gui.center["show_anim_png"].destroy() end
		Functions.show_intro(player)
	end

end
--EVL EXPORTING DATAS TO FRAME AND TO JSON FILE
--local _stats_are_set = false --First we set the datas moved to init global.export_stats_are_set
local _guit = ""	--_GUI_TITLE FULL WIDTH
local _guil = ""	--_GUI_LEFT
local _guin = ""	--_GUI_NORTH
local _guis = ""	--_GUI_SOUTH
local _guib = ""	--_GUI_BOTTOM
local _jsont = {}	-- JSON TITLE TABLE
local _jsonl = {}	-- JSON LEFT TABLE
local _jsonn = {}	-- JSON NORTH TABLE
local _jsons = {}	-- JSON SOUTH TABLE
local _jsonb = {}	-- JSON RIGHT TABLE

--SETTINGS STATS ONCE FOR ALL TO USE IN EXPORT JSON AND DRAW RESULTS
local function set_stats_title() --fill up string "local _guit" and table "local _jsont"
	
	--_guit=_guit.."                   [font=default-large-bold][color=#FF5555] --- THANKS FOR PLAYING [/color][color=#5555FF]BITER[/color]  [color=#55FF55]BATTLES[/color]  [color=#FF5555]CHAMPIONSHIPS ---[/color][/font]\n" 
	_guit=_guit.."[font=default-large-bold][color=#FF5555] --- THANKS FOR PLAYING [/color][color=#5555FF]BITER[/color]  [color=#55FF55]BATTLES[/color]  [color=#FF5555]CHAMPIONSHIPS ---[/color][/font]\n" 
	_guit=_guit.."see all results at [color=#DDDDDD]https://www.bbchampions.org[/color] , follow us on twitter [color=#DDDDDD]@BiterBattles[/color]\n"
	_guit=_guit.."[font=default-bold][color=#77DD77]ADD the result [/color][color=#999999](gameId)[/color][color=#77DD77] to the website [/color][color=#999999](referee)[/color]"
	_guit=_guit.."[color=#77DD77] & SET url of the replays [/color][color=#999999](players & streamers)[/color][color=#77DD77] ASAP ![/color][/font]\n"
	_guit=_guit.."[font=default-small][color=#999999]Note: Referee/Admins need to re-allocate permissions as they were before this game.[/color][/font]\n"
	_guit=_guit.."[font=default-large-bold][color=#FF5555]--- [color=#55FF55]RESULTS[/color] and [color=#5555FF]STATISTICS[/color]  ---[/color][/font]"

end
local function set_stats_bottom() --fill up string "local _guib" and table "local _jsonb"

		local fmr_nb=table_size(global.force_map_reset_export_reason) --EVL number of frece-map-reset
		if fmr_nb>0 then
			_guib=_guib.."\n[font=default-bold][color=#FF9740]>>FORCE MAP RESETS>>[/color][/font] [font=default-small][color=#999999]"
			_guib=_guib.."   (organisators will double check this match)[/color][/font]\n"
			for _index=1,fmr_nb,1 do _guib=_guib.." [".._index.."] "..global.force_map_reset_export_reason[_index].."\n" end
			_guib=string.sub(_guib, 1, string.len(_guib)-2)
		end
end
local function set_stats_left() --fill up string "local _guil" and table "local _jsonl"
	
	
	--GUI_LEFT, LEFT COLUMN
	
	
	local biters = {'small-biter','medium-biter','big-biter','behemoth-biter','small-spitter','medium-spitter','big-spitter','behemoth-spitter'}
	local worms =  {'small-worm-turret','medium-worm-turret','big-worm-turret'} --remove behemoth ,'behemoth-worm-turret'}
	local spawners = {'biter-spawner', 'spitter-spawner'}
	--
	--GLOBAL STATS
	--
	_guil=_guil.."[font=default-bold][color=#FF9740]>>GLOBAL>>[/color][/font]\n"
	_guil=_guil.."     GAME_ID="..global.game_id.."\n"
	_guil=_guil.."     REFEREE=".."tbd".."\n"
	_guil=_guil.."     TEAM_ATHOME=".."tbd".."  [Outside: ".."tbd".."]\n"
	_guil=_guil.."     DIFFICULTY="..global.difficulty_vote_index..":"..diff_vote.difficulties[global.difficulty_vote_index].name.." ("..diff_vote.difficulties[global.difficulty_vote_index].str..")\n"
	_guil=_guil.."     REROLL="..(global.reroll_max-global.reroll_left).."\n"
	_guil=_guil.."     DURATION="..math.floor((game.ticks_played-global.freezed_time)/3600).."m | Paused="..math.floor(global.freezed_time/60).."s\n"
	local _bb_game_won_by_team=global.bb_game_won_by_team
	local _bb_game_loss_by_team = Tables.enemy_team_of[_bb_game_won_by_team]
	_guil=_guil.."     WINNER=".._bb_game_won_by_team.."  |  LOOSER=".._bb_game_loss_by_team.."\n"


	for i=1,2,1 do
		--NORTH SIDE --
		local team_name = "Team North"
		if global.tm_custom_name["north"] then team_name = global.tm_custom_name["north"]	end
		local biter_name = "north_biters"
		local force_name = "north"
		local total_science_of_force  = global.science_logs_total_north
		if i==2 then --SOUTH SIDE --
			team_name = "Team South"
			if global.tm_custom_name["south"] then team_name = global.tm_custom_name["south"]	end
			biter_name = "south_biters"
			force_name = "south"
			total_science_of_force  = global.science_logs_total_south
		end



		_guil=_guil.."[font=default-bold][color=#FF9740]>>"..string.upper(force_name).." STATS>>[/color][/font]\n"
		--local north_name = "Team North"
		--if global.tm_custom_name["north"] then north_name = global.tm_custom_name["north"]	end
		_guil=_guil.."     TEAM_NAME="..team_name.."\n"
		local team_evo = math.floor(1000 * global.bb_evolution[biter_name]) * 0.1
		local team_threat = math.floor(global.bb_threat[biter_name])
		_guil=_guil.."     EVOLUTION="..team_evo.." | THREAT="..team_threat.."\n"
		_guil=_guil.."     ROCKETS LAUNCHED="..game.forces[force_name].rockets_launched.."\n"
		
		--BITERS WITH DETAILS --EVL DOING SOME FIORITURES
		local _b = 0 
		local _b_details = {["small-biter"]=0,["medium-biter"]=0,["big-biter"]=0,["behemoth-biter"]=0}
		for _, _biter in pairs(biters) do 
			_b = _b + game.forces[force_name].kill_count_statistics.get_input_count(_biter) 
			--local _bshort=string.sub(biter, 1, string.find(biter,"-")-1)
			--if _bshort=="medium" then _bshort="med" end
			--if _bshort=="behemoth" then _bshort="behe" end
			local biter=_biter
			if biter=="small-spitter" then biter="small-biter" end
			if biter=="medium-spitter" then biter="medium-biter" end
			if biter=="big-spitter" then biter="big-biter" end
			if biter=="behemoth-spitter" then biter="behemoth-biter" end
			_b_details[biter]=_b_details[biter]+game.forces[force_name].kill_count_statistics.get_input_count(_biter)
		end
		_guil=_guil.."     BITERS: ".._b
		--adding details if exist
		if _b > 0 then 
			local _b_str="\n     "
			--USE Kilos when > 800
			for _biter,_count in pairs(_b_details) do 
				local count=_count
				if count > 800 then count=math.floor(count/1000).."k"..math.floor((count%1000)/100,0) end --USE Kilos when > 800 ie 800->0k8 but 990 -> 0k9 TODO
				_b_str=_b_str..count.." [entity=".._biter.."], " 
			end
			
			_b_str=string.sub(_b_str, 1, string.len(_b_str)-2)
			_guil=_guil.._b_str
		end
		_guil=_guil.."\n"

		--WORMS WITH DETAILS
		local _w = 0
		local _w_details = ""
		for _, worm in pairs(worms) do
			local _count = game.forces[force_name].kill_count_statistics.get_input_count(worm) 
			_w = _w + _count
			_w_details = _w_details.._count.." [entity="..worm.."], "
		end
		_w_details=string.sub(_w_details, 1, string.len(_w_details)-2)
		_guil=_guil.."     WORMS: ".._w
		if _w > 0 then _guil=_guil.." ► ".._w_details end
		_guil=_guil.."\n"
		
		--SCRAPS
		_guil=_guil.."     SCRAPS: "..global.scraps_mined[force_name].."\n"

		--SPAWNERS WITH DETAILS
		local _s = 0
		local _s_details = ""
		for _, spawner in pairs(spawners) do
			local _count = game.forces[force_name].kill_count_statistics.get_input_count(spawner) 
			_s = _s + _count
			_s_details = _s_details.._count.." [entity="..spawner.."], "
		end
		_s_details=string.sub(_s_details, 1, string.len(_s_details)-2)
		_guil=_guil.."     SPAWNERS: ".._s
		if _w > 0 then _guil=_guil.." ► ".._s_details end
		_guil=_guil.."\n"

		--SCIENCE
		if total_science_of_force then
			local _science=""
			for i = 1, 7 do 
				local _this_science=total_science_of_force[i]
				if _this_science > 800 then _this_science=math.floor(_this_science/1000).."k"..math.floor((_this_science%1000)/100,0) end --USE Kilos when > 800 ie 800->0k8 but 990 -> 0k9 TODO
				_science=_science.._this_science.."[item="..Tables.food_long_and_short[i].long_name.."]"..", "
				if i==3 then _science=_science.."\n     " end
			end
			_science=string.sub(_science, 1, string.len(_science)-2)
			_guil=_guil.."     SCIENCE: ".._science.."\n"
		else
			_guil=_guil.."     NO SCIENCE SENT\n"
		end
	end
		
	--OTHER DATAS
	
end
local function set_stats_north_and_south() --fill up string "local _guir" and table "local _jsonr"
	
	
	--GUI_RIGHT, RIGHT COLUMN
	
	local get_score = Score.get_table().score_table
	--game.print("get_score:"..serpent.block(get_score))
    if not get_score then 
		_guin=_guin.."[font=default-small][color=#999999][Unable to get scores at all][/color][/font]\n"
		_guis=_guis.."[font=default-small][color=#999999][Unable to get scores at all][/color][/font]\n"
		if global.bb_debug then game.print(">>>>> Unable to get score table.", {r = 0.88, g = 0.22, b = 0.22}) end
		return
	end
	local _score = { ["north"]={}, ["south"]={}}
	--we'll have to check if player were in a force at some time
	
	if not get_score["north"] then 
		_guin=_guin.."[font=default-small][color=#999999][Unable to get scores at north][/color][/font]\n"
		if global.bb_debug then game.print(">>>>> Unable to get score table for north.", {r = 0.88, g = 0.22, b = 0.22}) end
	else
		_score["north"] = get_score["north"]
	end
	if not get_score["south"] then 
		_guis=_guis.."[font=default-small][color=#999999][Unable to get scores at south][/color][/font]\n"
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
		local _walls = 0
		local _chests = 0
		local _belts = 0
		local _pipes = 0
		local _powers = 0
		local _inserters = 0
		local _miners = 0
		local _furnaces = 0
		local _machines = 0
		local _labs = 0
		local _turrets = 0

		-- IF PLAYER WAS IN A TEAM AND BUILT BEFORE MOVED TO SPEC
		if (_force=="spectator" or _force=="spec_god") then
			if _score["north"] and _score["north"].players and _score["north"].players[_name] then _force="north" end
			if _score["south"] and _score["south"].players and _score["south"].players[_name] then _force="south" end
		end

		-- GRAB DATAS IF WE HAVE SOME
		if (_force=="north" or _force=="south") then
			if _score[_force].players and _score[_force].players[_name] then 
				local score_player= _score[_force].players[_name]

				_killscore = score_player.killscore
				_deaths = score_player.deaths
				_entities = score_player.built_entities
				_mined = score_player.mined_entities
				-- EVL MORE STATS !
				_walls = score_player.built_walls
				_chests = score_player.built_chests
				_belts = score_player.built_belts
				_pipes = score_player.built_pipes
				_powers = score_player.built_powers
				_inserters = score_player.built_inserters
				_miners = score_player.built_miners
				_furnaces = score_player.built_furnaces
				_machines = score_player.built_machines
				_labs = score_player.built_labs
				_turrets = score_player.built_turrets
				--EVL EVEN MORE STATS !
				_smalls = score_player.kills_small
				_mediums = score_player.kills_medium
				_bigs = score_player.kills_big
				_behemoths = score_player.kills_behemoth
				_spawners = score_player.kills_spawner
				_worms = score_player.kills_worm
			end
		end
		--WHICH PLAYER
		local _guif="" --we dont specify force for now
		_guif=_guif.."[font=default-bold][color=#FF9740]>>"..string.upper(_name)..">>[/color][/font]"
		_guif=_guif.."  (".._force
		if player.admin then _guif=_guif..":Admin" end
		_guif=_guif..")\n"
		
		--SHOW THE DATAS
		if _force=="spectator" or _force=="spec_god" then
			_guif=_guif.."     NO STATISTICS\n"
		else
			_guif=_guif.."     [font=default][color=#FF9999]DEATHS=".._deaths.."[/color] | [color=#99FF99]KILLSCORE=".._killscore.."[/color][/font]\n"
			_guif=_guif.."     ".._entities.."[item=blueprint], ".._mined.."[item=deconstruction-planner], ".._turrets.."[item=gun-turret], ".._walls.."[item=stone-wall]\n"
			_guif=_guif.."     ".._belts.."[item=transport-belt], ".._pipes.."[item=pipe], ".._inserters.."[item=inserter], ".._powers.."[item=steam-engine]\n"
			_guif=_guif.."     ".._miners.."[item=electric-mining-drill], ".._furnaces.."[item=stone-furnace], ".._machines.."[item=assembling-machine-1], ".._labs.."[item=lab]\n"
			-- (Not used : chests)
			_guif=_guif.."     ".._worms.."[entity=small-worm-turret], ".._spawners.."[entity=biter-spawner], ".._smalls.."[entity=small-biter]\n"
			_guif=_guif.."     ".._mediums.."[entity=medium-biter], ".._bigs.."[entity=big-biter], ".._behemoths.."[entity=behemoth-biter]\n"		


			
		end
	
		--SCIENCE
		if global.science_per_player[player.name] then
			local _science=""
			--local _crlf=0
			for _index = 1, 7 do 
				local _this_science=0
				if global.science_per_player[player.name][_index] then _this_science = global.science_per_player[player.name][_index] end
				if _this_science > 0 then 
					--_crlf=_crlf+1 
					if _this_science > 800 then _this_science=math.floor(_this_science/1000).."k"..math.floor((_this_science%1000)/100,0) end --USE Kilos when > 800 ie 800->0k8 but 999->0k9 TODO
					_science=_science.._this_science.."[item="..Tables.food_long_and_short[_index].long_name.."]"..", "
				end
				--if _index==3 then _science=_science.."\n     " end
				--if _crlf==3 then _science=_science.."\n" end
			end
			_science=string.sub(_science, 1, string.len(_science)-2)
			_guif=_guif.."     ".._science.."\n"
		else
			_guif=_guif.."     NO SCIENCE SENT\n"
		end
		if _force=="north" then _guin=_guin.._guif 
		elseif _force=="south" then _guis=_guis.._guif
		end --if force = spec or god, we forget (they did nothing, if they had they would be switched to north (in prio) or south, see above
			

	end		
	--OTHER DATAS
	local _s=""
	if #game.forces["north"].connected_players > 1 then _s="S" end
	_guin=_guin.."[font=default-bold][color=#FF9740]<<"..#game.forces["north"].connected_players.." PLAYER".._s.." ONLINE<<[/color][/font]"	
	_s=""	
	if #game.forces["south"].connected_players > 1 then _s="S" end
	_guis=_guis.."[font=default-bold][color=#FF9740]<<"..#game.forces["south"].connected_players.." PLAYER".._s.." ONLINE<<[/color][/font]"	
end

--DRAWING EXPORT FRAME (Global / North / South)
local function draw_results(player)
	
	if player.gui.center["bb_export_frame"] then player.gui.center["bb_export_frame"].destroy() end
	
	local frame = player.gui.center.add {type = "frame", name = "bb_export_frame", direction = "vertical"}
	--Some infos about what icons are meaning
	local _tooltip="[color=#CCCCCC]Killscore[/color] [color=#999999]is your score at fighting biters\n"
	.."[item=blueprint] entities built, [item=deconstruction-planner] entities mined\n"
	.."[item=gun-turret] include gun, flame, laser and radars\n"
	.."[item=stone-wall] include gates\n" -- and paths of bricks/concrete\n" TODO
	.."[item=steam-engine] include offshore, boiler, steam, solar, accu\n"
	.."[item=electric-mining-drill] include elec and burners\n"
	.."[item=assembling-machine-1] also include oil refining, beacon etc.[/color]"

	--TOP / TITLE
	--LOGO AND FIRST PART
	local t= frame.add {type = "table", name = "bb_export_top", column_count = 2}
	t.vertical_centering=false

	local t1 = t.add {type = "sprite", name = "bb_export_top_left", sprite = "file/png/logo_100.png"}
	t1.style.minimal_width = 125
	t1.style.maximal_width = 125
	local t2 = t.add {type = "label", name = "bb_export_top_right", caption = _guit, tooltip=_tooltip}
	t2.style.single_line = false
	t2.style.horizontal_align = 'center'
	t2.style.font = "default"
	t2.style.font_color = {r=0.7, g=0.6, b=0.99}
	
	--CENTER
	local _table = frame.add {type = "table", name = "bb_export_table", column_count = 5}
	--CENTER LEFT : GLOBAL
	_table.vertical_centering=false
	--_table.style.vertical_align = "top"		
	local ll = _table.add {type = "label", caption = _guil, name = "bb_export_left"}
	ll.style.single_line = false
	ll.style.font = "default"
	ll.style.font_color = {r=0.7, g=0.6, b=0.99}
	ll.style.minimal_width = 250
	ll.style.maximal_width = 500
	local sep = _table.add {type = "label", caption = "   "} --EVL SEPARATOR
	--CENTER MID : NORTH
	local ln = _table.add {type = "label", caption = _guin, name = "bb_export_north"}
	ln.style.single_line = false
	ln.style.font = "default"
	ln.style.font_color = {r=0.7, g=0.6, b=0.99}
	ln.style.minimal_width = 250
	ln.style.maximal_width = 500
	local sep = _table.add {type = "label", caption = "   "} --EVL SEPARATOR
	--CENTER RIGHT : SOUTH
	local ls = _table.add {type = "label", caption = _guis, name = "bb_export_south"}
	ls.style.single_line = false
	ls.style.font = "default"
	ls.style.font_color = {r=0.7, g=0.6, b=0.99}
	ls.style.minimal_width = 250
	ls.style.maximal_width = 500

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
		_guit = ""	--_GUI_TITLE FULL WIDTH
		_guil = ""	--_GUI_LEFT
		_guin = ""	--_GUI_RIGHT
		_guis = ""	--_GUI_RIGHT
		_guib = ""	--_GUI_RIGHT
		_jsont = {}	-- JSON TITLE TABLE
		_jsonl = {}	-- JSON LEFT TABLE
		_jsonn = {}	-- JSON RIGHT TABLE
		_jsons = {}	-- JSON RIGHT TABLE
		_jsonb = {}	-- JSON RIGHT TABLE
		if global.bb_debug then game.print(">>>>> Setting results and stats.", {r = 0.22, g = 0.22, b = 0.22}) end
		set_stats_title()	--Will fill up string "local _guit" and table "local _jsont"
		set_stats_left()	--Will fill up string "local _guil" and table "local _jsonl"
		set_stats_north_and_south()	--Will fill up string "local _guin and guis" and table "local _jsonr???"
		set_stats_bottom()	--Will fill up string "local _guib" and table "local _jsonb"
		global.export_stats_are_set=true		
	else 
		if global.bb_debug then game.print(">>>>> Results and stats are already set.", {r = 0.22, g = 0.22, b = 0.22}) end
	end
	-- get_input_count(string) get_output_count(string) (prototype)
	--game.print(serpent.block(game.forces["north"].kill_count_statistics.input_counts))
	--game.print(serpent.block(game.forces["north"].kill_count_statistics.output_counts))

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
		if global.bb_debug then game.print(">>>>> TODO : export results and stats to json.") end
	else
		if global.bb_debug then game.print(">>>>> Results and stats have already been exported.") end
	end
end
--LITTLE THING TO CLOSE EXPORT GUI (above)
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
	--EVL close export frame when clicked
	local _bb_export=string.sub(element.name,1,10) -- EVL we keep "bb_export_"
	
	if _bb_export == "bb_export_" then player.gui.center["bb_export_frame"].destroy() return end	

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
--EVL AUTO CLEAR CORPSES
local function clear_corpses_auto(radius) -- EVL - Automatic clear corpses called every 5 min
	if not Ai.empty_reanim_scheduler() then
		if global.bb_debug then game.print("Debug: Some corpses are waiting to be reanimated... Skipping this turn of clear_corpses") end
		return
	end
	local _param = tonumber(radius)
	local _radius = {{x = (0 + -_param), y = (0 + -_param)}, {x = (0 + _param), y = (0 + _param)}}
	local _surface = game.surfaces[global.bb_surface_name]
	for _, entity in pairs(_surface.find_entities_filtered {area = _radius, type = 'corpse'}) do
		if entity.corpse_expires then
			entity.destroy()
		end
	end
	if global.bb_debug then game.print("Debug: Cleared corpses (dead biters and destroyed entities).", Color.success) 
	else game.print("Cleared corpses.", Color.success) end --EVL we could count the biters (and only the biters?)
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
	
	--EVL SET the countdown for intro animation
	global.player_anim[player.name]=20
	
	local msg_freeze = "unfrozen" --EVL not so useful (think about player disconnected then join again)
	if global.freeze_players then msg_freeze="frozen" end
	player.print(">>>>> WELCOME TO BBC ! Tournament mode is active, Players are "..msg_freeze..", Referee has to open [color=#FF9740]TEAM MANAGER[/color]",{r = 00, g = 225, b = 00})
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end
	--Do we need to see the clicks ?
	if false and global.bb_debug then game.print("      ON GUI CLICK : elem="..element.name.."       parent="..element.parent.name, {r = 0.22, g = 0.22, b = 0.22}) end
	--EVL Not beautiful but it works
	if element.parent.name == "bb_export_frame" or element.parent.name == "bb_export_table" or element.name == "bb_export_button" then 
		frame_export_click(player, element)
		return
	end	
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
--EVL Trying to slowdown sending groups (easier for potatoes to keep up)
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

	if not global.freeze_players and tick % 60 == 0 then --evl
		global.bb_threat["north_biters"] = global.bb_threat["north_biters"] + global.bb_threat_income["north_biters"]
		global.bb_threat["south_biters"] = global.bb_threat["south_biters"] + global.bb_threat_income["south_biters"]
	end

	--if tick % 300 == 0 then -- EVL WAS 180
	--	Gui.refresh()
	--	diff_vote.difficulty_gui()
	--end

	
	if tick % 300 == 0 then --EVL this is called at the same tick as tick_minute_functions, could be changed to : if (tick+8) % 300 == 0

		Gui.refresh() --EVL from above
		--EVL Do not update ~Vote~ button once game has started
		if not global.match_running then 
			diff_vote.difficulty_gui()	
		else
			if global.match_running and tick % 18000 == 0 and not(global.bb_game_won_by_team) then clear_corpses_auto(500) end --EVL we clear corpses every 5 minutes
			--Still players should be able to use /clear-corpses <radius> from their position
		end
		
		
		Gui.spy_fish() -- EVL check the time of reveal, should be perfect (new chart just when last chart fade out)
		
		if global.reveal_init_map and (game.ticks_played > 600) then  --EVL we reveal 127*127 for reroll purpose (up to 10s delay)
			Game_over.reveal_init_map(127)
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
			if not global.server_restart_timer then 
				global.server_restart_timer=20
			end
			Game_over.reveal_map() --EVL must be repeated
			Game_over.server_restart()
			global.reroll_left=global.reroll_max --EVL Reinit #Nb reroll
			global.pack_choosen = "" --EVL Reinit Starter pack
			return
		end
		
		--EVL We dont reset after match ends (trick : global.server_restart_timer=999999)
		if global.bb_game_won_by_team then		 --EVL no restart (debrief, save etc...) 
			-- EVL Threat keep growing up even if match is over xd TODO ?
			
			--EVL EXPORTING RESULTS AND STATS
			if not global.export_stats_done then
				game.print(">>>>> MATCH IS OVER ! Exporting results and statistics ...", {r = 77, g = 192, b = 77})
				global.way_points_table = {["north"]={},["south"]={}} --EVL Reinit
				export_results(true) --true means its the first time we draw the results -> we need to export json too
				global.export_stats_done=true
			end
			Game_over.reveal_map() --EVL timing seems perfect
			Game_over.server_restart() -- EVL WILL NEVER HAPPEN (global.server_restart_timer=999999)
			return
		end


		if tick % 1200 == 0 then --EVL monitoring game times every 20s for EVO BOOST/ARMAGEDDON
			-- Check for AFK players 
			
			if global.freezed_start == 999999999 then -- players are unfreezed
				if not global.evo_boost_active then -- EVO BOOST AFTER 2H (global.tick_evo_boost=60*60*60*2)
					local real_played_time = game.ticks_played - global.freezed_time
					if real_played_time >= global.evo_boost_tick then
						-- EVL FOR TESTING/DEBUG, TO BE REMOVED --CODING--
						--global.bb_evolution["north_biters"] = global.bb_evolution["north_biters"] + 0.05
						--global.bb_evolution["south_biters"] = global.bb_evolution["south_biters"] + 0.10

						--EVL Set boosts for north and south
						local evo_north = global.bb_evolution["north_biters"]
						if evo_north<0.001 then evo_north=0.001 end --!DIV0
						local evo_south = global.bb_evolution["south_biters"]
						if evo_south<0.001 then evo_south=0.001 end --!DIV0
						
						if evo_north < evo_south then
							-- WE WANT NORTH TO GO UP TO 90% UNTIL global.evo_boost_active+30min (PLUS NATURAL AND SENDINGS)
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
							-- WE WANT SOUTH TO GO UP TO 90% UNTIL global.evo_boost_active+30min (PLUS NATURAL AND SENDINGS)
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
						game.print(">>>>> TIME HAS PASSED !!! EVOLUTION IS NOW BOOSTED !!! [font=default-large-bold][color=#FF0000]ARMAGEDDON[/color][/font] IS PROCLAIMED !!! (%n=".._b_north.."  | %s=".._b_south..")", {r = 192, g = 77, b = 77})
					end
				end
				--game.print("UNFREEZ : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.." & FS="..global.freezed_start..")") 
			
			else -- players are freezed since global.freezed_start, and we dont care about EVO BOOST
				--game.print("FREEZED : ticks="..tick.." | played="..game.ticks_played.." (freezed="..global.freezed_time.."+"..(game.ticks_played-global.freezed_start).." & FS="..global.freezed_start..")") 
			end
		end
	end
	-- EVL COUNTDOWN FOR STARTING GAME (UNFREEZE AND SOME INITS)
	if global.match_countdown >=0 and global.match_running and tick % 60 == 0 then
		show_countdown(global.match_countdown)
		global.match_countdown = global.match_countdown - 1
		--CLOSE THE FRAMES WHEN DONE
		if global.match_countdown < 0 then
			for _, player in pairs(game.players) do		
				if player.gui.center["bbc_cdf"] then	player.gui.center["bbc_cdf"].destroy() end
			end
			-- EVL SET global.next_attack = "north" / "south" and global.main_attack_wave_amount=0 --CODING--
			Team_manager.unfreeze_players()
			game.print(">>>>> Players & Biters have been unfrozen !", {r = 255, g = 77, b = 77})
		end
	end

	-- EVL NO EVO/THREAT OR GROUPS WHEN FREEZE (look inside ai.lua)
	
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

local function on_init()
	Init.tables()
	Init.initial_setup()
	Init.playground_surface()
	-- EVL patch : ???
	
	Init.forces()
	Init.draw_structures()
	Init.load_spawn()
	--EVL Looking why always south gets attacked first <- not true
	local whoisattackedfirst=math.random(1,2)
	--if global.bb_debug then game.print("DEBUG: wiaf="..whoisattackedfirst.."  before "..global.next_attack) end 
	if whoisattackedfirst == 1 then global.next_attack = "south" end
	--if global.bb_debug then game.print("DEBUG: wiaf="..whoisattackedfirst.."  after "..global.next_attack) end 
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

commands.add_command('clear-corpses', 'Clears all the corpses and remnants in the ~radius~ around you',clear_corpses)

require "maps.biter_battles_v2.spec_spy"
