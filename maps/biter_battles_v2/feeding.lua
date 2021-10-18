local bb_config = require "maps.biter_battles_v2.config"
local Functions = require "maps.biter_battles_v2.functions"
local Server = require 'utils.server'

local tables = require "maps.biter_battles_v2.tables"
local food_values = tables.food_values
local force_translation = tables.force_translation
local enemy_team_of = tables.enemy_team_of

local minimum_modifier = 125
local maximum_modifier = 250
local player_amount_for_maximum_threat_gain = 20

function get_instant_threat_player_count_modifier()
	local current_player_count = #game.forces.north.connected_players + #game.forces.south.connected_players
	local gain_per_player = (maximum_modifier - minimum_modifier) / player_amount_for_maximum_threat_gain
	local m = minimum_modifier + gain_per_player * current_player_count
	if m > maximum_modifier then m = maximum_modifier end
	return m
end

local function set_biter_endgame_modifiers(force)
	if force.evolution_factor ~= 1 then return end

	-- Calculates reanimation chance. This value is normalized onto
	-- maximum re-animation threshold. For example if real evolution is 150
	-- and max is 350, then 150 / 350 = 42% chance.
	local threshold = global.bb_evolution[force.name]
	threshold = math.floor((threshold - 1.0) * 100.0)
	threshold = threshold / global.max_reanim_thresh * 100
	threshold = math.floor(threshold)
	global.reanim_chance[force.index] = threshold

	local damage_mod = math.round((global.bb_evolution[force.name] - 1) * 1.0, 3)
	force.set_ammo_damage_modifier("melee", damage_mod)
	force.set_ammo_damage_modifier("biological", damage_mod)
	force.set_ammo_damage_modifier("artillery-shell", damage_mod)
	force.set_ammo_damage_modifier("flamethrower", damage_mod)
end

local function get_enemy_team_of(team)
	if global.training_mode then
		return team
	else
		return enemy_team_of[team]
	end
end

local function print_feeding_msg(player, food, flask_amount)
	if not get_enemy_team_of(player.force.name) then return end
	
	local n = bb_config.north_side_team_name
	local s = bb_config.south_side_team_name
	if global.tm_custom_name["north"] then n = global.tm_custom_name["north"] end
	if global.tm_custom_name["south"] then s = global.tm_custom_name["south"] end	
	local team_strings = {
		["north"] = table.concat({"[color=120, 120, 255]", n, "'s[/color]"}),
		["south"] = table.concat({"[color=255, 65, 65]", s, "'s[/color]"})
	}
	
	local colored_player_name = table.concat({"[color=", player.color.r * 0.6 + 0.35, ",", player.color.g * 0.6 + 0.35, ",", player.color.b * 0.6 + 0.35, "]", player.name, "[/color]"})
	local formatted_food = table.concat({"[color=", food_values[food].color, "]", food_values[food].name, " juice[/color]", "[img=item/", food, "]"})
	local formatted_amount = table.concat({"[font=heading-1][color=255,255,255]" .. flask_amount .. "[/color][/font]"})
	
	if flask_amount >= 20 then
		local enemy = get_enemy_team_of(player.force.name)
		game.print(table.concat({colored_player_name, " fed ", formatted_amount, " flasks of ", formatted_food, " to team ", team_strings[enemy], " biters!"}), {r = 0.9, g = 0.9, b = 0.9})
		Server.to_discord_bold(table.concat({player.name, " fed ", flask_amount, " flasks of ", food_values[food].name, " to team ", enemy, " biters!"}))
	else
		local target_team_text = "the enemy"
		if global.training_mode then
			target_team_text = "your own"
		end
		if flask_amount == 1 then
			player.print("You fed one flask of " .. formatted_food .. " to " .. target_team_text .. " team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		else
			player.print("You fed " .. formatted_amount .. " flasks of " .. formatted_food .. " to " .. target_team_text .. " team's biters.", {r = 0.98, g = 0.66, b = 0.22})
		end				
	end	
end

local function add_stats(player, food, flask_amount,biter_force_name,evo_before_science_feed,threat_before_science_feed)
	local colored_player_name = table.concat({"[color=", player.color.r * 0.6 + 0.35, ",", player.color.g * 0.6 + 0.35, ",", player.color.b * 0.6 + 0.35, "]", player.name, "[/color]"})
	local formatted_food = table.concat({"[color=", food_values[food].color, "][/color]", "[img=item/", food, "]"})
	local formatted_amount = table.concat({"[font=heading-1][color=255,255,255]" .. flask_amount .. "[/color][/font]"})	
	local n = bb_config.north_side_team_name
	local s = bb_config.south_side_team_name
	if global.tm_custom_name["north"] then n = global.tm_custom_name["north"] end
	if global.tm_custom_name["south"] then s = global.tm_custom_name["south"] end
	local team_strings = {
		["north"] = table.concat({"[color=120, 120, 255]", n, "[/color]"}),
		["south"] = table.concat({"[color=255, 65, 65]", s, "[/color]"})
	}
	if flask_amount > 0 then
		local tick = game.ticks_played - global.freezed_time --EVL correction to science sendings timing
		local feed_time_mins = math.round(tick / (60*60), 0)
		local minute_unit = ""
		if feed_time_mins <= 1 then
			minute_unit = "min"
		else
			minute_unit = "mins"
		end

		
		
		local shown_feed_time_hours = ""
		local shown_feed_time_mins = ""
		shown_feed_time_mins = feed_time_mins .. minute_unit
		local formatted_feed_time = shown_feed_time_hours .. shown_feed_time_mins
		evo_before_science_feed = math.round(evo_before_science_feed*100,1) 
		threat_before_science_feed = math.round(threat_before_science_feed,0) 
		local formatted_evo_after_feed = math.round(global.bb_evolution[biter_force_name]*100,1)
		local formatted_threat_after_feed = math.round(global.bb_threat[biter_force_name],0)
		local evo_jump = table.concat({evo_before_science_feed .. " to " .. formatted_evo_after_feed})
		local threat_jump = table.concat({threat_before_science_feed .. " to ".. formatted_threat_after_feed})
		local evo_jump_difference =  math.round(formatted_evo_after_feed - evo_before_science_feed,1)
		local threat_jump_difference =  math.round(formatted_threat_after_feed - threat_before_science_feed,0)
		local line_log_stats_to_add = table.concat({ formatted_amount .. " " .. formatted_food .. " by " .. colored_player_name .. " to " })
		local team_name_fed_by_science = get_enemy_team_of(player.force.name)
		
		if global.science_logs_total_north == nil then
			global.science_logs_total_north = { 0 }
			global.science_logs_total_south = { 0 }
			for _ = 1, 7 do
				table.insert(global.science_logs_total_north, 0)
				table.insert(global.science_logs_total_south, 0)
			end
		end
		
		local total_science_of_player_force = nil
		if player.force.name == "north" then
			total_science_of_player_force  = global.science_logs_total_north
		else
			total_science_of_player_force  = global.science_logs_total_south
		end
		
		local indexScience = tables.food_long_to_short[food].indexScience
		total_science_of_player_force[indexScience] = total_science_of_player_force[indexScience] + flask_amount
		
		if not global.science_per_player[player.name] then
			global.science_per_player[player.name]={}
			for _index = 1, 7 do
				table.insert(global.science_per_player[player.name], 0)
			end
		end
		global.science_per_player[player.name][indexScience] = global.science_per_player[player.name][indexScience] + flask_amount
		
		
		if global.science_logs_text then
			table.insert(global.science_logs_date,1, formatted_feed_time)
			table.insert(global.science_logs_text,1, line_log_stats_to_add)
			table.insert(global.science_logs_evo_jump,1, evo_jump)
			table.insert(global.science_logs_evo_jump_difference,1, evo_jump_difference)
			table.insert(global.science_logs_threat,1, threat_jump)
			table.insert(global.science_logs_threat_jump_difference,1, threat_jump_difference)
			table.insert(global.science_logs_fed_team,1, team_name_fed_by_science)
			table.insert(global.science_logs_food_name,1, food)
		else
			global.science_logs_date = { formatted_feed_time }
			global.science_logs_text = { line_log_stats_to_add }
			global.science_logs_evo_jump = { evo_jump }
			global.science_logs_evo_jump_difference = { evo_jump_difference }
			global.science_logs_threat = { threat_jump }
			global.science_logs_threat_jump_difference = { threat_jump_difference }
			global.science_logs_fed_team = { team_name_fed_by_science }
			global.science_logs_food_name = { food }
		end
	end
end

function set_evo_and_threat(flask_amount, food, biter_force_name)
	local decimals = 9
	local math_round = math.round
	
	local instant_threat_player_count_modifier = get_instant_threat_player_count_modifier()
	
	local food_value = food_values[food].value * global.difficulty_vote_value
	
	for _ = 1, flask_amount, 1 do
		---SET EVOLUTION
		local e2 = (game.forces[biter_force_name].evolution_factor * 100) + 1
		local diminishing_modifier = (1 / (10 ^ (e2 * 0.015))) / (e2 * 0.5)
		local evo_gain = (food_value * diminishing_modifier)
		global.bb_evolution[biter_force_name] = global.bb_evolution[biter_force_name] + evo_gain
		global.bb_evolution[biter_force_name] = math_round(global.bb_evolution[biter_force_name], decimals)
		if global.bb_evolution[biter_force_name] <= 1 then
			game.forces[biter_force_name].evolution_factor = global.bb_evolution[biter_force_name]
		else
			game.forces[biter_force_name].evolution_factor = 1
		end
		
		--ADD INSTANT THREAT
		local diminishing_modifier = 1 / (0.2 + (e2 * 0.016))
		global.bb_threat[biter_force_name] = global.bb_threat[biter_force_name] + (food_value * instant_threat_player_count_modifier * diminishing_modifier)
		global.bb_threat[biter_force_name] = math_round(global.bb_threat[biter_force_name], decimals)		
	end
	
	--SET THREAT INCOME
	global.bb_threat_income[biter_force_name] = global.bb_evolution[biter_force_name] * 25
	
	set_biter_endgame_modifiers(game.forces[biter_force_name])
end

local function feed_biters(player, food, mode)	
	--EVL NOPE (science pack cand send science right at the beginning)
	--if game.ticks_played < global.difficulty_votes_timeout then
	--	player.print("Please wait for voting to finish before feeding")
	--	return
	--end
	local enemy_force_name = ""
	local biter_force_name = ""
	local flask_amount = 0

	if mode == "regular" then --Regular sending (now we have also auto-sendings with /training command
		enemy_force_name = get_enemy_team_of(player.force.name)  --return opponent unless training mode
		biter_force_name = enemy_force_name .. "_biters"
		local i = player.get_main_inventory()
		flask_amount = i.get_item_count(food)
		if flask_amount == 0 then
			player.print("You have no [color="..food_values[food].color.."]" .. food_values[food].name .. "[/color] flask [img=item/".. food.. "] in your inventory.", {r = 0.98, g = 0.66, b = 0.22})
			return
		end
		i.remove({name = food, count = flask_amount})
		print_feeding_msg(player, food, flask_amount)	
	--Auto-training mode for north
	elseif mode=="north" then
		enemy_force_name = "north"
		biter_force_name = enemy_force_name .. "_biters"
		flask_amount = global.auto_training["north"]["qtity"]
	--Auto-training mode for south
	elseif mode=="south" then
		enemy_force_name = "south"
		biter_force_name = enemy_force_name .. "_biters"
		flask_amount = global.auto_training["south"]["qtity"]		
	--Oups
	else
		if global.bb_debug then game.print(">>>>> feed_biters (from feeding.lua) was called with inappropriate arguments. Skipping...", {r = 0.98, g = 0.66, b = 0.22}) end
		return
	end
	
	local evolution_before_feed = global.bb_evolution[biter_force_name]
	local threat_before_feed = global.bb_threat[biter_force_name]	
	set_evo_and_threat(flask_amount, food, biter_force_name)
	add_stats(player, food, flask_amount ,biter_force_name, evolution_before_feed, threat_before_feed)
end

commands.add_command( --/training qty-science-delay
    'training',
    ' command :\n'
	..'     Auto-sending science. Format : [color=#AAFFAA]/training [QTITY]-[SCIENCE]-[DELAY][/color] [color=#999999]([qtity] [science] flasks every [delay] in minutes).[/color]\n'
	..'     Ex: [color=#999999]/training 100-chem-10[/color] (auto|logi|mili|chem|prod|util|spac).\n'
	..'     Use [color=#999999]/training off[/color] to cancel sendings.',
	function(cmd)
		local _player = cmd.player_index
		if not game.players[_player] then game.print("OUPS that should not happen (in <</training>> command)", {r = 175, g = 100, b = 100}) return end
		if not global.training_mode then
			game.players[_player].print("/training command can only be used in training mode...", {r = 175, g = 100, b = 100})
			return
		end

		local _force = game.players[_player].force.name
		if _force~="north" and _force~="south" then
			game.players[_player].print("You can only use /training command when playing on one side...", {r = 175, g = 100, b = 100})
			return
		end
		local _param1= tostring(cmd.parameter)
		--Sets off the auto training command
		if _param1=="off" or _param1=="OFF" then
			global.auto_training[_force]={["player"]="",["active"]=false,["qtity"]=0,["science"]="",["timing"]=0}
			game.print(">>>>> Auto-training mode canceled/deactivated by [color=#FFFFFF]"..game.players[_player].name.."[/color] for ".._force.." side", {r = 77, g = 192, b = 192})			
			return
		end
		--Tests & Find parameters (qtity,science,timing)
		if string.len(_param1)<7 then
			game.players[_player].print("Please type [color=#FFFFFF]/training X-YYYY-Z[/color] with X=quantity | YYYY=(auto|logi|mili|chem|prod|util|spac) | Z=delay (in minutes)", {r = 175, g = 100, b = 100})
			return
		end
		--Find the first param (quantity)
		local _index1=string.find(_param1,"-")
		if not _index1 or _index1<2 or _index1>5 then
			game.players[_player].print("Quantity is not valid, should be in 1..9999 range,please retry.", {r = 175, g = 100, b = 100})
			return
		end
		local _qtity = tonumber(string.sub(_param1,1,_index1-1))
		if not _qtity or _qtity<=0 or _qtity>9999 then
			game.players[_player].print("Quantity is not valid, must be in 1..9999 range, please retry.", {r = 175, g = 100, b = 100})
			return
		end
		--We stay with the right part of the pama
		local _param2 = string.sub(_param1,_index1+1)
		--Find the second param (science in 4 chars)
		local _index2 = string.find(_param2,"-")
		if not _index2 or _index2~=5 then
			game.players[_player].print("Science is not valid, please retry with (auto|logi|mili|chem|prod|util|spac).", {r = 175, g = 100, b = 100})
			return
		end

		local _science = tostring(string.sub(_param2,1,_index2-1))
		if string.len(_science)~=4 then
			game.players[_player].print("Science is not acceptable, please retry with (auto|logi|mili|chem|prod|util|spac).", {r = 175, g = 100, b = 100})
			return
		end
		local _science_long=""
		if _science=="auto" or _science=="AUTO" then _science_long="automation-science-pack"
		elseif _science=="logi" or _science=="LOGI" then _science_long="logistic-science-pack"
		elseif _science=="mili" or _science=="MILI" then _science_long="military-science-pack"
		elseif _science=="chem" or _science=="CHEM" then _science_long="chemical-science-pack"
		elseif _science=="prod" or _science=="PROD" then _science_long="production-science-pack"
		elseif _science=="util" or _science=="UTIL" then _science_long="utility-science-pack"
		elseif _science=="spac" or _science=="SPAC" then _science_long="space-science-pack"
		else
			game.players[_player].print("Science is not valid, please retry with (auto|logi|mili|chem|prod|util|spac).", {r = 175, g = 100, b = 100})
			return
		end
		--We stay with the third param (Timing)
		local _timing = tonumber(string.sub(_param2,_index2+1))
		if not _timing or _timing<=0 or _timing>99 then
			game.players[_player].print("Timing is not valid, must be in 1..99 range, please retry.", {r = 175, g = 100, b = 100})
			return
		end
		--OK WE HAVE ALL WE NEED
		global.auto_training[_force]={["player"]=game.players[_player].name,["active"]=true,["qtity"]=_qtity,["science"]=_science_long,["timing"]=_timing}
		
		-- print
		game.print(">>>>> Auto-training mode activated by [color=#FFFFFF]"..game.players[_player].name.."[/color] for [color=#FFFFFF]".._force.."[/color] side : [color=#FFFFFF]"
				.._qtity.."[/color] flasks of [color="..food_values[_science_long].color.."]".._science_long.."[/color] will be sent every [color=#FFFFFF]".._timing.."[/color] minute(s)", {r = 77, g = 192, b = 192})
		return
    end
)
commands.add_command( --/wavetrain number
    'wavetrain',
    ' command :\n'
	..'     choose how many waves (0..7) of biters that will attack your side every two minutes, instead of random(3,6).'
	..'     Ex: [color=#999999]/wavetrain 5[/color].\n'
	..'     Use [color=#999999]/wavetrain off[/color] to go back to random(3,6).',
	function(cmd)
		local _player = cmd.player_index
		if not game.players[_player] then game.print("OUPS that should not happen (in <</wavetrain>> command)", {r = 175, g = 100, b = 100}) return end
		if not global.training_mode then
			game.players[_player].print("/wavetrain command can only be used in training mode...", {r = 175, g = 100, b = 100})
			return
		end

		local _force = game.players[_player].force.name
		if _force~="north" and _force~="south" then
			game.players[_player].print("You can only use /wavetrain when playing on one side...", {r = 175, g = 100, b = 100})
			return
		end
		local _param1= tostring(cmd.parameter)
		--Sets off the auto training command
		if _param1=="off" or _param1=="OFF" then
			global.wave_training[_force]={["player"]="",["active"]=false,["number"]=0}
			game.print(">>>>> Wave-training mode canceled/deactivated by [color=#FFFFFF]"..game.players[_player].name.."[/color] for ".._force.." side. Back to random(3,6).", {r = 77, g = 192, b = 192})			
			return
		end
		local _number = tonumber(cmd.parameter)
		if not _number or _number<0 or _number>7 then
			game.players[_player].print("Number (of waves) is not valid, must be in 0..7 range, please retry.", {r = 175, g = 100, b = 100})
			return
		end
		--OK WE HAVE ALL WE NEED
		global.wave_training[_force]={["player"]=game.players[_player].name,["active"]=true,["number"]=_number}
		
		-- print
		game.print(">>>>> Wave-training mode activated by [color=#FFFFFF]"..game.players[_player].name.."[/color] : [color=#FFFFFF]"
				.._number.."[/color] wave(s) of biters will attack [color=#FFFFFF]".._force.."[/color] side every two minutes.", {r = 77, g = 192, b = 192})
		return
    end
)

return feed_biters
