--scoreboard by mewmew

local Event = require 'utils.event'
local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'
local Functions = require "maps.biter_battles_v2.functions"--EVL (none)
local Public = {}
local this = {
    score_table = {},
    sort_by = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local sorting_symbol = {ascending = '▲', descending = '▼'}
local building_and_mining_blacklist = {
    ['tile-ghost'] = true,
    ['entity-ghost'] = true,
    ['item-entity'] = true
}

function Public.get_table()
    return this
end

function Public.init_player_table(player)
	if not player then	return	end
	--EVL we dont need score for spectators or god mode, only north and south
	if player.force.name~="north" and player.force.name~="south" then return end
	if not this.score_table[player.force.name] then
		this.score_table[player.force.name] = {}
	end
	if not this.score_table[player.force.name].players then
		this.score_table[player.force.name].players = {}
	end
	if not this.score_table[player.force.name].players[player.name] then
		if global.bb_debug_gui then game.print("Debug: init score_table for "..player.name) end --EVL
		this.score_table[player.force.name].players[player.name] = {
			built_entities = 0,
			built_walls = 0, --EVL more stats !
			built_chests = 0,
			built_belts = 0,
			built_pipes = 0,
			built_powers = 0,
			built_inserters = 0,
			built_miners = 0,
			built_furnaces = 0,
			built_machines = 0,
			built_labs = 0,
			built_turrets = 0, --EVL
			deaths = 0,
			killscore = 0,
			kills_small = 0, --EVL even more stats !
			kills_medium = 0,
			kills_big = 0,
			kills_behemoth = 0,
			kills_spawner = 0,
			kills_worm = 0, --EVL
			mined_entities = 0,
			placed_path = 0, --EVL the # of tiles (concrete, stone brick, landfill) placed
			killed_own_walls= 0, --EVL track the # of own walls killed (aim better your grenades)
			damaged_own_walls= 0, --EVL track the # of damaged dealt on own walls (aim better your grenades)
			killed_own_furnaces= 0, --EVL track the # of own furnaces killed (aim better your grenades)
			killed_own_entities= 0 --EVL track the # of own entities killed (dont let biters inside)
		}
		return
	end
end

local function get_score_list(force)
	local score_force = this.score_table[force]
	local score_list = {}
	for _, p in pairs(game.players) do --EVL need stats from substitute & deco player 
	--for _, p in pairs(game.connected_players) do 
		if score_force.players[p.name] then
			local score = score_force.players[p.name]
			table.insert(
				score_list,
				{
					name = p.name,
					killscore = score.killscore or 0,
					deaths = score.deaths or 0,
					built_entities = score.built_entities or 0,
					mined_entities = score.mined_entities or 0,
					killed_own_entities = score.killed_own_entities or 0,
					killed_own_walls = score.killed_own_walls or 0,
					damaged_own_walls = score.damaged_own_walls or 0,
					killed_own_furnaces = score.killed_own_furnaces or 0
				}
			)
		end
	end
	return score_list
end

local function get_sorted_list(method, column_name, score_list)
    local comparators = {
        ['ascending'] = function(a, b)
            return a[column_name] < b[column_name]
        end,
        ['descending'] = function(a, b)
            return a[column_name] > b[column_name]
        end
    }
    table.sort(score_list, comparators[method])
    return score_list
end

local biters = {
    'small-biter',
    'medium-biter',
    'big-biter',
    'behemoth-biter',
    'small-spitter',
    'medium-spitter',
    'big-spitter',
    'behemoth-spitter'
}
local function get_total_biter_killcount(force)
    local count = 0
    for _, biter in pairs(biters) do
        count = count + force.kill_count_statistics.get_input_count(biter)
    end
    return count
end

local function add_global_stats(frame, player)
    local score = this.score_table[player.force.name]
    local t = frame.add {type = 'table', column_count = 5}

    local l = t.add {type = 'label', caption = 'Rockets launched: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 175, g = 75, b = 255}
    l.style.minimal_width = 140

    local l = t.add {type = 'label', caption = player.force.rockets_launched}
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 123

    local l = t.add {type = 'label', caption = 'Dead bugs: '}
    l.style.font = 'default-game'
    l.style.font_color = {r = 0.90, g = 0.3, b = 0.3}
    l.style.minimal_width = 100

    local l = t.add {type = 'label', caption = tostring(get_total_biter_killcount(player.force))}
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.9, g = 0.9, b = 0.9}
    l.style.minimal_width = 145

    local l =
        t.add {
        type = 'checkbox',
        caption = 'Show floating numbers',
        state = global.show_floating_killscore[player.name],
        name = 'show_floating_killscore_texts'
    }
    l.style.font_color = {r = 0.8, g = 0.8, b = 0.8}
end

local show_score = (function(player, frame)
    frame.clear()
	--[[ --EVL dont need those global stats anymore 
		--Public.init_player_table(player) --EVL Totally useless now
		-- Global stats : rockets, biters kills
		add_global_stats(frame, player)  
		-- Separator
		local line = frame.add {type = 'line'}
		line.style.top_margin = 8
		line.style.bottom_margin = 8
	]]--

	local default_color = {r = 0.9, g = 0.9, b = 0.9}

	local column_width = {
		[1]=90,
		[2]=90,
		[3]=65,
		[4]=65,
		[5]=65,
		[6]=80,
		[7]=90,
		[8]=150,
		[9]=50
	}
	local t = frame.add {type = 'table', column_count = #column_width}

    -- Score headers
    local headers = {
        {name = 'score_player', caption = 'Player', tooltip="Player name", width=column_width[1]},
        {column = 'killscore', name = 'score_killscore', caption = 'Killscore', tooltip="Total score of this player killing biters, worms and spawners.", width=column_width[2]},
        {column = 'deaths', name = 'score_deaths', caption = 'Deaths', tooltip="Number of times this player died.", width=column_width[3]},
        {column = 'built_entities', name = 'score_built_entities', caption = 'Built', tooltip="Entities built by player (including walls).", width=column_width[4]},
        {column = 'mined_entities', name = 'score_mined_entities', caption = 'Mined', tooltip="Entities mined by player (including walls).", width=column_width[5]},
        {column = 'killed_entities', name = 'score_killed_entities', caption = 'Kill struct.', tooltip="Own structures killed by player\n(minus walls & furnaces).", width=column_width[6]},
        {column = 'killed_furnaces', name = 'score_killed_furnaces', caption = 'Kill furnace', tooltip="Own stone-furnaces killed by player.", width=column_width[7]},
        {column = 'killed_walls', name = 'score_killed_walls', caption = 'Kill wall', tooltip="Own walls killed [color=#AA5555](total damage dealt)[/color] by player.", width=column_width[8]},
        {column = 'ratio_wall_biter', name = 'score_ratio', caption = 'Ratio', tooltip="Ratio: damage own walls / damage on biters\n  Lower the better.", width=column_width[9]}
    }

	--INIT PART : HEADERS
	local sorting_pref = this.sort_by[player.name]
    for _, header in ipairs(headers) do
        local cap = header.caption
        -- Add sorting symbol if any
        if header.column and sorting_pref.column == header.column then
            local symbol = sorting_symbol[sorting_pref.method]
            cap = cap..symbol
        end
        -- Header
		local label =
			t.add {
			type = 'label',
			caption = cap,
			name = header.name,
			tooltip=header.tooltip
		}
		label.style.font = 'default-listbox'
		label.style.font_color = {r = 0.98, g = 0.66, b = 0.22} -- yellow
		label.style.minimal_width = header.width
		label.style.maximal_width = header.width
		if header.column=='killed_walls' then --EVL Exception for walls
			label.style.horizontal_align = 'center'
		else
			label.style.horizontal_align = 'right'
		end
    end

    -- New pane for scores (while keeping headers at same position)
    local scroll_pane = frame.add(
        {
            type = 'scroll-pane',
            name = 'score_scroll_pane',
            direction = 'vertical',
            horizontal_scroll_policy = 'never',
            vertical_scroll_policy = 'auto'
        }
    )
    scroll_pane.style.maximal_height = 400
    local t = scroll_pane.add {type = 'table', column_count = #column_width}

	--MAIN LOOP (north then south)
	for _,_force in pairs({"north","south"}) do --We want score from both forces (esp. to know how many deaths)
		--Biter force (see third part) and color force (blue/red)
		local biter_force="North" 
		local color_force = {r =100 , g = 100, b = 255}
		if _force=="south" then 
			biter_force="South" 
			color_force = {r = 255, g = 75, b = 75}
		end
		-- Init score list per force
		if not(this.score_table[_force]) then 
			--game.print("debug: no stat for force=".._force)
			goto skip_this_force 
		end
		-- Init ccore list per player in force
		score_list = get_score_list(game.forces[_force].name)
		if #game.connected_players > 1 then
			score_list = get_sorted_list(sorting_pref.method, sorting_pref.column, score_list)
		end
		
		--FIRST PART : SIDE TITLE/SEPARATOR
		local line = {
			{caption = "Team", color = color_force, width=column_width[1]},
			{caption = " ".._force..":", color = color_force, width=column_width[2]},
			{caption = "", width=column_width[3]},
			{caption = "", width=column_width[4]},
			{caption = "", width=column_width[5]},
			{caption = "", width=column_width[6]},
			{caption = "", width=column_width[7]},
			{caption = "", width=column_width[8]},
			{caption = "", width=column_width[9]}
		}
		for _, column in ipairs(line) do
			local label =
				t.add {
				type = 'label',
				caption = column.caption
			}
			label.style.font = 'default-large-bold'
			label.style.font_color = column.color or default_color
			label.style.minimal_width = column.width
			label.style.maximal_width = column.width
			if _==1 then --Exception
				label.style.horizontal_align = 'right'
			else 
				label.style.horizontal_align = 'left'
			end
		end -- foreach column	

		--SECOND PART: SCORE ENTRIES BY PLAYER
		for _, entry in pairs(score_list) do
			local p = game.players[entry.name]
			local special_color = {
				r = p.color.r * 0.6 + 0.4,
				g = p.color.g * 0.6 + 0.4,
				b = p.color.b * 0.6 + 0.4,
				a = 1
			}
			if entry.killscore <1 then entry.killscore=1 end --DIV!0
			local insidious_ratio=math.floor(100*entry.damaged_own_walls/entry.killscore)/100
			local string_ratio=""
			if insidious_ratio<10 then
				string_ratio="[color=#55AA55]"..tostring(insidious_ratio).."[/color]"
			elseif insidious_ratio<100 then
				insidious_ratio=math.floor(insidious_ratio)
				string_ratio="[color=#888855]"..tostring(insidious_ratio).."[/color]"
			else
				insidious_ratio=math.floor(insidious_ratio)
				string_ratio="[color=#AA5555]"..tostring(insidious_ratio).."[/color]"
			end
			local line = {
				{caption = entry.name, color = special_color, width=column_width[1]},
				{caption = tostring(entry.killscore), width=column_width[2]},
				{caption = tostring(entry.deaths), width=column_width[3]},
				{caption = tostring(entry.built_entities), width=column_width[4]},
				{caption = tostring(entry.mined_entities), width=column_width[5]},
				{caption = tostring(entry.killed_own_entities), width=column_width[6]},
				{caption = tostring(entry.killed_own_furnaces), width=column_width[7]},
				{caption = tostring(entry.killed_own_walls).."  [color=#AA5555]("
							..Functions.inkilos(math.floor(entry.damaged_own_walls)).." HP)[/color]", width=column_width[8]},
				{caption = string_ratio, width=column_width[9]}
			}
			for _, column in ipairs(line) do
				local label =
					t.add {
					type = 'label',
					caption = column.caption--,
					--color = column.color or default_color
				}
				label.style.font = 'default'
				label.style.font_color = column.color or default_color
				label.style.minimal_width = column.width
				label.style.maximal_width = column.width
				label.style.horizontal_align = 'right'
			end -- foreach column
		end -- foreach entry

		--THIRD PART: FORCE_BITERS DEAD and KILLS
		local line = {
			{caption = biter_force.."  biters", width=column_width[1]},
			{caption = "that died :", width=column_width[2]},
			{caption = tostring(get_total_biter_killcount(game.forces[_force])), width=column_width[3]},
			{caption = "", width=column_width[4]},
			{caption = "they killed:", width=column_width[5]},
			{caption = tostring(global.biters_kills[_force.."_biters"]["entities"]), width=column_width[6]},
			{caption = tostring(global.biters_kills[_force.."_biters"]["furnaces"]), width=column_width[7]},
			{caption = tostring(global.biters_kills[_force.."_biters"]["walls"]), width=column_width[8]},
			{caption = "", width=column_width[9]}
		}		
		for _, column in ipairs(line) do
			local label =
				t.add {
				type = 'label',
				caption = column.caption
			}
			label.style.font = 'default'
			label.style.font_color = color_force
			label.style.minimal_width = column.width
			label.style.maximal_width = column.width
			if _==8 then --Exception
				label.style.horizontal_align = 'center'
			else
				label.style.horizontal_align = 'right'
			end
		end -- foreach column

		::skip_this_force::
	end --	EVL 2 forces
	
end) -- show_score

local function refresh_score_full()
    for _, player in pairs(game.connected_players) do
        local frame = Tabs.comfy_panel_get_active_frame(player)
        if frame then
            if frame.name == 'Scoreboard' then
                show_score(player, frame)
            end
        end
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    --Public.init_player_table(player) --EVL done in team manager
    if not this.sort_by[player.name] then
        this.sort_by[player.name] = {method = 'descending', column = 'killscore'}
    end
    if not global.show_floating_killscore then
        global.show_floating_killscore = {}
    end
    if not global.show_floating_killscore[player.name] then
        global.show_floating_killscore[player.name] = false
    end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	local frame = Tabs.comfy_panel_get_active_frame(player)
	if not frame then return end
	if frame.name ~= 'Scoreboard' then return end
	local name = event.element.name
    --[[EVL not  used anymore Handles click on the checkbox, for floating score
    if name == 'show_floating_killscore_texts' then
        global.show_floating_killscore[player.name] = event.element.state
        return
    end
	]]--
	-- Handles click on a score header
	local element_to_column = {
		['score_killscore'] = 'killscore',
		['score_deaths'] = 'deaths',
		['score_built_entities'] = 'built_entities',
		['score_mined_entities'] = 'mined_entities',
		['score_killed_entities'] = 'killed_entities',
		['score_killed_walls'] = 'killed_walls',
		['score_killed_furnaces'] = 'killed_furnaces'
	}
	local column = element_to_column[name]
	if column then
		local sorting_pref = this.sort_by[player.name]
		if sorting_pref.column == column and sorting_pref.method == 'descending' then
			sorting_pref.method = 'ascending'
		else
			sorting_pref.method = 'descending'
			sorting_pref.column = column
		end
		show_score(player, frame)
		return
	end
    -- No more to handle
end

local function on_rocket_launched(event)
    refresh_score_full()
end

local entity_score_values = {
    ['behemoth-biter'] = 100,
    ['behemoth-spitter'] = 100,
    ['behemoth-worm-turret'] = 300,
    ['big-biter'] = 30,
    ['big-spitter'] = 30,
    ['big-worm-turret'] = 300,
    ['biter-spawner'] = 200,
    ['medium-biter'] = 15,
    ['medium-spitter'] = 15,
    ['medium-worm-turret'] = 150,
    ['character'] = 1000,
    ['small-biter'] = 5,
    ['small-spitter'] = 5,
    ['small-worm-turret'] = 50,
    ['spitter-spawner'] = 200,
    ['gun-turret'] = 50,
    ['laser-turret'] = 150,
    ['flamethrower-turret'] = 300
}

local function train_type_cause(event)
    local players = {}
    if event.cause.train.passengers then
        for _, player in pairs(event.cause.train.passengers) do
            players[#players + 1] = player
        end
    end
    return players
end

local kill_causes = {
    ['character'] = function(event)
        if not event.cause.player then
            return
        end
        return {event.cause.player}
    end,
    ['combat-robot'] = function(event)
        if not event.cause.last_user then
            return
        end
        if not game.players[event.cause.last_user.index] then
            return
        end
        return {game.players[event.cause.last_user.index]}
    end,
    ['car'] = function(event)
        local players = {}
        local driver = event.cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = event.cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['locomotive'] = train_type_cause,
    ['cargo-wagon'] = train_type_cause,
    ['artillery-wagon'] = train_type_cause,
    ['fluid-wagon'] = train_type_cause
}

local function on_entity_died(event)
    if not event.entity.valid then return end
    if not event.cause then return end
    if not event.cause.valid then return end
	local _ent=event.entity.name
	local _typ=event.entity.type
	local _cause=event.cause
	--game.print("entity ".._cause.name.." (force=".._cause.force.name..") destroyed ".._ent.." (".._typ..")")

	--EVL FIRST PART : A PLAYER HAS KILLED OWN STRUCTURE
	if _cause.name=="character" then --Track own walls and own entities killed by player
		local _player=_cause.player
		--Public.init_player_table(_player) --EVL done in team manager
		local score = this.score_table[_player.force.name].players[_player.name]		
		--game.print("character ".._player.name.." (force=".._player.force.name..") destroyed ".._ent.." (".._typ..")") 
		
		--Walls and stone furnaces (since they are used for defense)--> Don't grenade your own walls !
		if _ent=="stone-wall" or _ent=="gate" then score.killed_own_walls = 1 + score.killed_own_walls return end
		if _ent=="stone-furnace" then score.killed_own_furnaces = 1 + score.killed_own_furnaces return end
		
		--Other entities  --> Don't let them in !
		if _typ=="transport-belt" or _typ=="underground-belt" or _typ=="splitter" or _typ=="electric-pole" or _typ=="inserter" 
			or _ent=="gun-turret" or _ent=="flamethrower-turret" or _ent=="laser-turret" or _ent=="radar" 			
			or _ent=="steam-engine" or _ent=="solar-panel" or _ent=="accumulator" or _ent=="electric-mining-drill" or _ent=="burner-mining-drill"
			or _ent=="pipe" or _ent=="pipe-to-ground" or _ent=="storage-tank" or _ent=="pump" or _ent=="offshore-pump" or _ent=="boiler" 
			or _typ=="furnace" or _typ=="assembling-machine" or _ent=="pumpjack" or _ent=="beacon" or _ent=="lab"
			or _typ=="container" or _typ=="logistic-container" then
				score.killed_own_entities = 1 + score.killed_own_entities 
				return 
		end	
		if global.bb_debug then game.print("DEBUG: this entity is not tracked : proto=".._typ.." entity=".._ent.." (killed by player)", {r = 0.55, g = 0.55, b = 0.55}) end
	end
	
	--EVL SECOND PART : A BITER HAS KILLED A STRUCTURE (global.biters_kills)
	local _force=_cause.force.name
	if _force =="north_biters" or _force=="south_biters" then
		if _typ=="rock" or _typ=="tree" then
			--nothing
		elseif _ent=="stone-wall" or _ent=="gate" then 
			global.biters_kills[_force]["walls"]=global.biters_kills[_force]["walls"]+1
			--game.print(_force.." killed wall entity=".._ent.." (proto=".._typ..") at "..event.entity.force.name..".")
		elseif _ent=="stone-furnace" then 
			global.biters_kills[_force]["furnaces"]=global.biters_kills[_force]["furnaces"]+1
			--game.print(_force.." killed furnace entity=".._ent.." (proto=".._typ..") at "..event.entity.force.name..".")
		else
			global.biters_kills[_force]["entities"]=global.biters_kills[_force]["entities"]+1
			--game.print(_force.." killed entity=".._ent.." (proto=".._typ..") at "..event.entity.force.name..".")
		end
		return
	end
	
	--EVL THIRD PART : A PLAYER HAS KILLED A BITER/WORM/SPAWNER
    if event.entity.force.index == event.cause.force.index then return end
    if not entity_score_values[event.entity.name] then return end
    if not kill_causes[event.cause.type] then return end
    local players_to_reward = kill_causes[event.cause.type](event)
    if not players_to_reward then return end
    if #players_to_reward == 0 then return end
	--if global.bb_debug then game.print("died : proto=".._typ.." entity=".._ent, {r = 0.55, g = 0.55, b = 0.55}) end
	--EVL THIRD PART (suite) : ADD STAT TO PLAYER KILLS STATS --
	for _, player in pairs(players_to_reward) do
		--Public.init_player_table(player) --EVL done in team manager
		local score = this.score_table[player.force.name].players[player.name]
		score.killscore = score.killscore + entity_score_values[event.entity.name]
		--EVL MORE STATS -- (see main.lua)
		if _ent=="small-biter" or _ent=="small-spitter" then score.kills_small = score.kills_small + 1
		elseif _ent=="medium-biter" or _ent=="medium-spitter" then score.kills_medium = score.kills_medium + 1
		elseif _ent=="big-biter" or _ent=="big-spitter" then score.kills_big = score.kills_big + 1
		elseif _ent=="behemoth-biter" or _ent=="behemoth-spitter" then score.kills_behemoth = score.kills_behemoth + 1
		elseif _ent=="biter-spawner" or _ent=="spitter-spawner" then score.kills_spawner = score.kills_spawner + 1
		elseif _ent=="small-worm-turret" or _ent=="medium-worm-turret" or _ent=="big-worm-turret" or _ent=="behemoth-worm-turret" then score.kills_worm = score.kills_worm + 1 
		else
			if global.bb_debug then game.print("Debug: killed entity ".._ent.." (by "..player.name..") is not tracked.", {r = 0.55, g = 0.55, b = 0.55}) end
		end
  
		--[[ EVL : No floating text
		if global.show_floating_killscore[player.name] then
			event.entity.surface.create_entity(
				{
					name = 'flying-text',
					position = event.entity.position,
					text = tostring(entity_score_values[event.entity.name]),
					color = player.chat_color
				}
			)
		end
		]]--
    end
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	--Public.init_player_table(player) --EVL done in team manager
	local score = this.score_table[player.force.name].players[player.name]
	score.deaths = 1 + (score.deaths or 0)
	--EVL Noisy boy :)
	game.forces[player.force.name].play_sound{path = global.sound_died, volume_modifier = 1}
	game.forces.spectator.play_sound{path = global.sound_died, volume_modifier = 1}
	if game.forces["spec_god"] then 
		game.forces.spec_god.play_sound{path = global.sound_died, volume_modifier = 1}
		--EVL Also share chat with gods
		game.forces.spec_god.print(player.name.."("..player.force.name..") was killed.")
	end
end

local function on_player_mined_entity(event)
	if not event.entity.valid then
		return
	end
	if building_and_mining_blacklist[event.entity.type] then
		return
    end
	local _ent=event.entity.name
	local _typ=event.entity.type
	--if global.bb_debug then game.print("mined : proto=".._typ.." entity=".._ent, {r = 0.55, g = 0.55, b = 0.55}) end
	--game.print("mined : proto=".._typ.." entity=".._ent, {r = 0.55, g = 0.55, b = 0.55})
    local player = game.players[event.player_index]
    --Public.init_player_table(player) --EVL done in team manager
    local score = this.score_table[player.force.name].players[player.name]
    score.mined_entities = 1 + (score.mined_entities or 0)
end

local function on_built_entity(event)
    if not event.created_entity.valid then
        return
    end
    if building_and_mining_blacklist[event.created_entity.type] then
        return
    end
    local player = game.players[event.player_index]
    --Public.init_player_table(player) --EVL done in team manager
    local score = this.score_table[player.force.name].players[player.name]
    score.built_entities = 1 + (score.built_entities or 0)
	
	--EVL YES WE WANT STATS
	local _ent=event.created_entity.name
	local _typ=event.created_entity.type
	--game.print("proto=".._typ.." entity=".._ent)	
	if _ent=="stone-wall" or _ent=="gate" 													then score.built_walls = 1 + (score.built_walls or 0) return end
	if _typ=="container" or _typ=="logistic-container" 				 					then score.built_chests = 1 + (score.built_chests or 0) return end
	if _typ=="transport-belt" or _typ=="underground-belt" or _typ=="splitter" 			then score.built_belts = 1 + (score.built_belts or 0) return end
	if _ent=="pipe" or _ent=="pipe-to-ground" or _ent=="storage-tank" or _ent=="pump"	then score.built_pipes = 1 + (score.built_pipes or 0) return end
	if _ent=="offshore-pump" or _ent=="boiler" or _ent=="steam-engine" or _ent=="solar-panel" or _ent=="accumulator" then score.built_powers = 1 + (score.built_powers or 0) return end
	if _typ=="inserter" 													 					then score.built_inserters = 1 + (score.built_inserters or 0) return end
	if _ent=="electric-mining-drill" or _ent=="burner-mining-drill" 					then score.built_miners = 1 + (score.built_miners or 0) return end
	if _typ=="furnace" 													 					then score.built_furnaces = 1 + (score.built_furnaces or 0) return end
	if _typ=="assembling-machine" or _ent=="pumpjack" or _ent=="beacon"		 			then score.built_machines = 1 + (score.built_machines or 0) return end
	if _ent=="lab"							 													then score.built_labs = 1 + (score.built_labs or 0) return end
	if _ent=="gun-turret" or _ent=="flamethrower-turret" or _ent=="laser-turret" or _ent=="radar" then score.built_turrets = 1 + (score.built_turrets or 0) return end	
	if _typ=="electric-pole"																	then return end -- do not track electric pole
	if global.bb_debug then game.print("DEBUG: this entity is not tracked : proto=".._typ.." entity=".._ent.." (built by player)", {r = 0.55, g = 0.55, b = 0.55}) end
end

local function on_player_built_tile(event)
	--if not event.created_entity.valid then
	 --   return
	--end
	local player = game.players[event.player_index]
	--Public.init_player_table(player) --EVL done in team manager
	local score = this.score_table[player.force.name].players[player.name]
	--EVL YES WE WANT STATS
	local _ent=event.item.name
	local _typ=event.tile.name
	local _count=0
	for _x,_y in pairs(event.tiles) do --We go down one level
		for _pos_old,_data in pairs(_y) do --we count #position (but there is also .old_tile)
			if _pos_old=="position" then _count=_count+1 end
		end
	end
	--game.print("   proto=".._typ.." entity=".._ent.." count=".._count)
	
	if _ent=="stone-brick" or _ent=="concrete" or _ent=="hazard-concrete" or _ent=="refined-concrete" 
		or _ent=="refined-hazard-concrete" or _ent=="landfill" then 
		score.placed_path = _count + (score.placed_path or 0) 
		--game.print("placed_path="..score.placed_path.."   proto=".._typ.." entity=".._ent.." count=".._count)
		return
	end
	if global.bb_debug then game.print("DEBUG: this tile is not tracked : proto=".._typ.." tile=".._ent, {r = 0.55, g = 0.55, b = 0.55}) end
end

local function on_entity_damaged(event)
	local _dmg=event.final_damage_amount
	if event.cause.name=="character" then --Track own walls damaged by player, sum of damage dealt
		_player=event.cause.player
		--Public.init_player_table(player) --EVL done in team manager
		local score = this.score_table[_player.force.name].players[_player.name]
		score.damaged_own_walls = event.final_damage_amount + score.damaged_own_walls		
		--game.print("player:".._player.name.."(".._player.force.name..") --> entity:"..event.entity.name.."  dmg="..event.final_damage_amount.."  cause="..event.cause.name.."/force="..event.force.name)
		return
	--else --EVL dont track damage dealt by biters or anything else
	end
	--game.print("entity:"..event.entity.name.."  dmg="..event.final_damage_amount.." by cause="..event.cause.name.."   force="..event.force.name)
	
end


comfy_panel_tabs['Scoreboard'] = {gui = show_score, admin = false}

Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add_event_filter(defines.events.on_entity_damaged, {
	filter = "name",
	name = "stone-wall",
})
return Public
