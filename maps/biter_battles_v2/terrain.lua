local Public = {}
local LootRaffle = require "functions.loot_raffle"
local BiterRaffle = require "maps.biter_battles_v2.biter_raffle"
local bb_config = require "maps.biter_battles_v2.config"
local Functions = require "maps.biter_battles_v2.functions"
local tables = require "maps.biter_battles_v2.tables"

local spawn_ore = tables.spawn_ore
local table_insert = table.insert
local math_floor = math.floor
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt

local GetNoise = require "utils.get_noise"
local simplex_noise = require 'utils.simplex_noise'.d2
local spawn_circle_size = bb_config.spawn_circle_size  -- 39 --EVL SIZE OF LAKE (within the islanc)
local spawn_island_size = bb_config.spawn_island_size  -- 10 --EVL SIZE OF THE ISLAND
local spawn_manager_pos = bb_config.spawn_manager_pos  -- 18 --EVL Spots for managers, must be between (spawn_island_size plus something) and (border_river_width/2)
local spawn_wall_radius = bb_config.spawn_wall_radius  -- 116 --EVL SIZE OF THE SPAWN
local ores = {"iron-ore", "copper-ore", "stone", "coal"}
-- mixed_ore_multiplier order is based on the ores variable
local mixed_ore_multiplier = {1, 1, 1, 1}
local rocks = {"rock-huge", "rock-big", "rock-big", "rock-big", "sand-rock-big"}

local chunk_tile_vectors = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		chunk_tile_vectors[#chunk_tile_vectors + 1] = {x, y}
	end
end
local size_of_chunk_tile_vectors = #chunk_tile_vectors

local loading_chunk_vectors = {}
for _, v in pairs(chunk_tile_vectors) do
	if v[1] == 0 or v[1] == 31 or v[2] == 0 or v[2] == 31 then table_insert(loading_chunk_vectors, v) end
end

local wrecks = {"crash-site-spaceship-wreck-big-1", "crash-site-spaceship-wreck-big-2", "crash-site-spaceship-wreck-medium-1", "crash-site-spaceship-wreck-medium-2", "crash-site-spaceship-wreck-medium-3"}
local size_of_wrecks = #wrecks
local valid_wrecks = {}
for _, wreck in pairs(wrecks) do valid_wrecks[wreck] = true end
local loot_blacklist = {
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true,
	["production-science-pack"] = true,
	["utility-science-pack"] = true,
	["space-science-pack"] = true,
	["loader"] = true,
	["fast-loader"] = true,
	["express-loader"] = true,		
}

--EVL INIT WE TRACK DATAS IN ORDER TO ADJUST RESOURCES IN SPAWN
--We search for spawn 
local _spawn_radius=120 -- (spawn_wall_radius=116)
local ores_spawn = {
	["iron-ore"]={["amount"]=0,["size"]=0},
	["copper-ore"]={["amount"]=0,["size"]=0},
	["coal"]={["amount"]=0,["size"]=0},
	["stone"]={["amount"]=0,["size"]=0},
	["crude-oil"]={["amount"]=0,["size"]=0}
}
--We search also for large area (crude-oil) 
local ores_large = {
	["iron-ore"]={["amount"]=0,["size"]=0},
	["copper-ore"]={["amount"]=0,["size"]=0},
	["coal"]={["amount"]=0,["size"]=0},
	["stone"]={["amount"]=0,["size"]=0},
	["crude-oil"]={["amount"]=0,["size"]=0}
}
local _large_radius=200

local search_area = {
	left_top = { -1*_large_radius, -1*_large_radius }, --EVL 200s WERE 150
	right_bottom = { _large_radius, -20 } -- was 200,0 -> bb_config["border_river_width"] = 44,
}


-- Table with info of which "chunks" are empty
local _chunk_size=20 --EVL must be a integer fraction of _spawn_radius

local _chunk_info={}

local _chunk_minmax=math.floor(_spawn_radius/_chunk_size)
local _chunk_y_max=-1  -- *math.floor(bb_config["border_river_width"]/_chunk_size)
--[[ this will be done in function check_ores	 at init and each time we force-map-reset or reroll
for _x=-1*_chunk_minmax-1,_chunk_minmax+1,1 do
	_chunk_info[_x]={}
	for _y=-1*_chunk_minmax-1,_chunk_y_max+1,1 do
		_chunk_info[_x][_y]={["ore"]=0,["ore-next"]=0}
	end
end
]]--
local _chunk_totally_empty={} -- empty chunks with neighbors and neighbors of neighbors also empty
local _chunk_very_empty={} -- empty chunks with neighbors also empty
local _chunk_almost_empty={} -- empty chunks with one or more neighbor not empty
--EVL END OF TRACK DATAS INIT



-- EVL Tracking ores in chunk (in order to know which chunk can be filled later)
local function update_chunk_info(_chunk_x,_chunk_y,amount)
	--CHUNK IS NOT EMPTY
	if _chunk_info[_chunk_x][_chunk_y] then --CENTER (weight=4)
		_chunk_info[_chunk_x][_chunk_y]["ore"]=_chunk_info[_chunk_x][_chunk_y]["ore"]+amount*4
	end
	--NEXT CHUNKS HAVE ORES NEXT TO THEM
	if _chunk_info[_chunk_x-1][_chunk_y] then --LEFT (weight=2)
		_chunk_info[_chunk_x-1][_chunk_y]["ore-next"]=_chunk_info[_chunk_x-1][_chunk_y]["ore-next"]+amount*2
	end
	if _chunk_info[_chunk_x+1][_chunk_y] then --RIGHT (weight=2)
		_chunk_info[_chunk_x+1][_chunk_y]["ore-next"]=_chunk_info[_chunk_x+1][_chunk_y]["ore-next"]+amount*2
	end
	if _chunk_info[_chunk_x][_chunk_y-1] then --TOP (weight=2)
		_chunk_info[_chunk_x][_chunk_y-1]["ore-next"]=_chunk_info[_chunk_x][_chunk_y-1]["ore-next"]+amount*2
	end
	if _chunk_info[_chunk_x][_chunk_y+1] then --BOTTOM (weight=2)
		_chunk_info[_chunk_x][_chunk_y+1]["ore-next"]=_chunk_info[_chunk_x][_chunk_y+1]["ore-next"]+amount*2
	end
	--CORNER CHUNKS HAVE ORES NEXT TO THEM
	if _chunk_info[_chunk_x-1][_chunk_y-1] then --TOP LEFT (weight=1)
		_chunk_info[_chunk_x-1][_chunk_y-1]["ore-next"]=_chunk_info[_chunk_x-1][_chunk_y-1]["ore-next"]+amount
	end
	if _chunk_info[_chunk_x+1][_chunk_y-1] then --TOP RIGHT (weight=1)
		_chunk_info[_chunk_x+1][_chunk_y-1]["ore-next"]=_chunk_info[_chunk_x+1][_chunk_y-1]["ore-next"]+amount
	end
	if _chunk_info[_chunk_x+1][_chunk_y+1] then --BOT RIGHT (weight=1)
		_chunk_info[_chunk_x+1][_chunk_y+1]["ore-next"]=_chunk_info[_chunk_x+1][_chunk_y+1]["ore-next"]+amount
	end
	if _chunk_info[_chunk_x-1][_chunk_y+1] then --BOT LEFT (weight=1)
		_chunk_info[_chunk_x-1][_chunk_y+1]["ore-next"]=_chunk_info[_chunk_x-1][_chunk_y+1]["ore-next"]+amount
	end
end

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_noise(name, pos)
	local seed = game.surfaces[global.bb_surface_name].map_gen_settings.seed
	local noise_seed_add = 25000
	if name == 1 then
		local noise = simplex_noise(pos.x * 0.0042, pos.y * 0.0042, seed)
		seed = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.031, pos.y * 0.031, seed) * 0.08
		seed  = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.1, pos.y * 0.1, seed) * 0.025
		return noise
	end

	if name == 2 then
		local noise = simplex_noise(pos.x * 0.011, pos.y * 0.011, seed)
		seed = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.08, pos.y * 0.08, seed) * 0.2
		return noise
	end

	if name == 3 then
		local noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		noise = noise + simplex_noise(pos.x * 0.02, pos.y * 0.02, seed) * 0.3
		noise = noise + simplex_noise(pos.x * 0.15, pos.y * 0.15, seed) * 0.025
		return noise
	end
end

local function create_mirrored_tile_chain(surface, tile, count, straightness)
	if not surface then return end
	if not tile then return end
	if not count then return end

	local position = {x = tile.position.x, y = tile.position.y}
	
	local modifiers = {
		{x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1},
		{x = -1, y = 1},{x = 1, y = -1},{x = 1, y = 1},{x = -1, y = -1}
	}	
	modifiers = shuffle(modifiers)
	--DEBUG-- Check why bricks are not same force
	for _ = 1, count, 1 do
		local tile_placed = false
		
		if math_random(0, 100) > straightness then modifiers = shuffle(modifiers) end
		for b = 1, 4, 1 do
			local pos = {x = position.x + modifiers[b].x, y = position.y + modifiers[b].y}
			if surface.get_tile(pos).name ~= tile.name then
				surface.set_tiles({{name = "landfill", position = pos}}, true)
				surface.set_tiles({{name = tile.name, position = pos}}, true)
				--surface.set_tiles({{name = "landfill", position = {pos.x * -1, (pos.y * -1) - 1}}}, true)
				--surface.set_tiles({{name = tile.name, position = {pos.x * -1, (pos.y * -1) - 1}}}, true)
				position = {x = pos.x, y = pos.y}
				tile_placed = true
				break
			end			
		end						
		
		if not tile_placed then
			position = {x = position.x + modifiers[1].x, y = position.y + modifiers[1].y}
		end		
	end			
end

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for _, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then
				if tile.name ~= "stone-path" then
					return tile.name
				end
			end
		end
	end
	return "grass-1"
end

local function draw_noise_ore_patch(position, name, surface, radius, richness, track_ore)
	local msg=""
	if not position then return msg end
	if not name then return msg end
	if not surface then return msg end
	if not radius then return msg end
	if not richness then return msg end
	if not track_ore then track_ore=false end
	
	local seed = game.surfaces[global.bb_surface_name].map_gen_settings.seed
	local noise_seed_add = 25000
	local richness_part = richness / radius
	local tot_amount=0 --EVL debug
	local tot_size=0 --EVL debug
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}			
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math_sqrt(x^2 + y^2)
			local _amount = math.floor(richness - richness_part * distance_to_center) --EVL rounded amount
			if distance_to_center < radius - math_abs(noise * radius * 0.85) and _amount > 1 then
				if surface.can_place_entity({name = name, position = pos, amount = _amount}) then
					surface.create_entity{name = name, position = pos, amount = _amount} --EVL should we use surface.set_tiles{{name="grass", position={1,1}}} ??? --DEBUG--
					--Track ores
					
					
					if track_ore then
						tot_amount=tot_amount+_amount --EVL debug
						tot_size=tot_size+1 --EVL debug
						ores_large[name].amount=ores_large[name].amount+_amount
						ores_large[name].size=ores_large[name].size+1
						--IF IN SPAWN 
						if math.abs(pos.x) < _spawn_radius and math.abs(pos.y) < _spawn_radius then
							ores_spawn[name].amount=ores_spawn[name].amount+_amount
							ores_spawn[name].size=ores_spawn[name].size+1
							local _chunk_x=math.floor(pos.x/_chunk_size)
							local _chunk_y=math.floor(pos.y/_chunk_size)
							update_chunk_info(_chunk_x,_chunk_y,_amount)
						end
					end
					
					--[[ EVL we let the turrets/chests/walls as they were (unless there is a bug, save some ups)
					for _, e in pairs(surface.find_entities_filtered({position = pos, name = {"wooden-chest", "stone-wall", "gun-turret"}})) do					
						e.destroy()
					end
					]]--
				end
			end
		end
	end
	 --EVL debug
	--if track_ore and global.bb_debug then game.print("Added "..tot_amount.." "..name.." ores in "..tot_size.."m²",{r = 200, g = 200, b = 200}) end
	return "Qtity="..math.floor(tot_amount/1000).."k Size="..tot_size.."m²"
end

function is_within_spawn_circle(pos)
	if math_abs(pos.x) > spawn_circle_size then return false end
	if math_abs(pos.y) > spawn_circle_size then return false end
	if math_sqrt(pos.x ^ 2 + pos.y ^ 2) > spawn_circle_size then return false end
	return true
end

local river_y_1 = bb_config.border_river_width * -1.5
local river_y_2 = bb_config.border_river_width * 1.5
local river_width_half = math_floor(bb_config.border_river_width * -0.5)
function is_horizontal_border_river(pos)
	if pos.y < river_y_1 then return false end
	if pos.y > river_y_2 then return false end
	if pos.y >= river_width_half - (math_abs(get_noise(1, pos)) * 4) then return true end
	return false
end

local function generate_starting_area(pos, distance_to_center, surface)
	-- assert(distance_to_center >= spawn_circle_size) == true
	-- local spawn_wall_radius = 116 move to top of this file (with island radius)
	local noise_multiplier = 15 
	local min_noise = -noise_multiplier * 1.25

	-- Avoid calculating noise, see comment below
	if (distance_to_center + min_noise - spawn_wall_radius) > 4.5 then
		return
	end

	local noise = get_noise(2, pos) * noise_multiplier
	local distance_from_spawn_wall = distance_to_center + noise - spawn_wall_radius
	-- distance_from_spawn_wall is the difference between the distance_to_center (with added noise) 
	-- and our spawn_wall radius (spawn_wall_radius=116), i.e. how far are we from the ring with radius spawn_wall_radius.
	-- The following shows what happens depending on distance_from_spawn_wall:
	--   	min     max
    --  	N/A     -10	    => replace water
	-- if noise_2 > -0.5:
	--      -1.75    0 	    => wall
	-- else:
	--   	-6      -3 	 	=> 1/16 chance of turret or turret-remnants
	--   	-1.95    0 	 	=> wall
	--    	 0       4.5    => chest-remnants with 1/3, chest with 1/(distance_from_spawn_wall+2)
	--
	-- => We never do anything for (distance_to_center + min_noise - spawn_wall_radius) > 4.5

	if distance_from_spawn_wall < 0 then
		if math_random(1, 100) > 23 then
			for _, tree in pairs(surface.find_entities_filtered({type = "tree", area = {{pos.x, pos.y}, {pos.x + 1, pos.y + 1}}})) do
				tree.destroy()
			end
		end
	end

	if distance_from_spawn_wall < -10 and not is_horizontal_border_river(pos) then
		local tile_name = surface.get_tile(pos).name
		if tile_name == "water" or tile_name == "deepwater" then
			surface.set_tiles({{name = get_replacement_tile(surface, pos), position = pos}}, true)
		end
		return
	end

	if surface.can_place_entity({name = "wooden-chest", position = pos}) and surface.can_place_entity({name = "coal", position = pos}) then
		local noise_2 = get_noise(3, pos)
		if noise_2 < 0.40 then
			if noise_2 > -0.40 then
				if distance_from_spawn_wall > -1.75 and distance_from_spawn_wall < 0 then				
					local e = surface.create_entity({name = "stone-wall", position = pos, force = "north"})
				end
			else
				if distance_from_spawn_wall > -1.95 and distance_from_spawn_wall < 0 then				
					local e = surface.create_entity({name = "stone-wall", position = pos, force = "north"})

				elseif distance_from_spawn_wall > 0 and distance_from_spawn_wall < 4.5 then
						local name = "wooden-chest"
						local r_max = math_floor(math.abs(distance_from_spawn_wall)) + 2
						if math_random(1,3) == 1 and not is_horizontal_border_river(pos) then name = name .. "-remnants" end
						if math_random(1,r_max) == 1 then 
							local e = surface.create_entity({name = name, position = pos, force = "north"})
						end

				elseif distance_from_spawn_wall > -6 and distance_from_spawn_wall < -3 then
					if math_random(1, 16) == 1 then
						if surface.can_place_entity({name = "gun-turret", position = pos}) then
							local e = surface.create_entity({name = "gun-turret", position = pos, force = "north"})
							e.insert({name = "firearm-magazine", count = math_random(2,16)})
							Functions.add_target_entity(e)
						end
					else
						if math_random(1, 24) == 1 and not is_horizontal_border_river(pos) then
							if surface.can_place_entity({name = "gun-turret", position = pos}) then
								surface.create_entity({name = "gun-turret-remnants", position = pos, force = "neutral"})
							end
						end
					end
				end
			end
		end
	end
end

local function generate_river(surface, left_top_x, left_top_y)
	if left_top_y ~= -32 then return end
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math_sqrt(pos.x ^ 2 + pos.y ^ 2)
			if is_horizontal_border_river(pos) and distance_to_center > spawn_circle_size - 2 then
				surface.set_tiles({{name = "deepwater", position = pos}})
				if math_random(1, 64) == 1 then 
					local e = surface.create_entity({name = "fish", position = pos}) 
				end
			end
		end
	end	
end

local scrap_vectors = {}
for x = -8, 8, 1 do
	for y = -8, 8, 1 do
		if math_sqrt(x^2 + y^2) <= 8 then
			scrap_vectors[#scrap_vectors + 1] = {x, y}
		end
	end
end
local size_of_scrap_vectors = #scrap_vectors

local function generate_extra_worm_turrets(surface, left_top)
	local chunk_distance_to_center = math_sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	if bb_config.bitera_area_distance > chunk_distance_to_center * 2 then return end -- EVL worms are closer (*2)
	
	local amount = (chunk_distance_to_center * 2 - bb_config.bitera_area_distance) * 0.0005 -- EVL worms are closer (*2)
	if amount < 0 then return end
	local floor_amount = math_floor(amount)
	local r = math.round(amount - floor_amount, 3) * 1000
	if math_random(0, 999) <= r then floor_amount = floor_amount + 1 end 
	
	if floor_amount > 64 then floor_amount = 64 end --EVL by the way there are a LOT of worms over the map !!!
	
	for _ = 1, floor_amount, 1 do	
		local worm_turret_name = BiterRaffle.roll("worm", chunk_distance_to_center * 0.00015) --EVL Never saw a big or a behemoth
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = surface.find_non_colliding_position(worm_turret_name, {left_top.x + v[1], left_top.y + v[2]}, 8, 1)
		if position then
			local worm = surface.create_entity({name = worm_turret_name, position = position, force = "north_biters"})
			
			-- add some scrap			
			for _ = 1, math_random(0, 4), 1 do
				local vector = scrap_vectors[math_random(1, size_of_scrap_vectors)]
				local position = {worm.position.x + vector[1], worm.position.y + vector[2]}
				local name = wrecks[math_random(1, size_of_wrecks)]					
				position = surface.find_non_colliding_position(name, position, 16, 1)									
				if position then
					local e = surface.create_entity({name = name, position = position, force = "neutral"})
				end
			end		
		end
	end
end

local bitera_area_distance = bb_config.bitera_area_distance * -1
local biter_area_angle = 0.45

local function is_biter_area(position)
	local a = bitera_area_distance - (math_abs(position.x) * biter_area_angle)	
	if position.y - 70 > a then return false end
	if position.y + 70 < a then return true end	
	if position.y + (get_noise(3, position) * 64) > a then return false end
	return true
end

local function draw_biter_area(surface, left_top_x, left_top_y)
	if not is_biter_area({x = left_top_x, y = left_top_y - 96}) then return end
	
	local seed = game.surfaces[global.bb_surface_name].map_gen_settings.seed
		
	local out_of_map = {}
	local tiles = {}
	local i = 1
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			if is_biter_area(position) then
				local index = math_floor(GetNoise("bb_biterland", position, seed) * 48) % 7 + 1
				out_of_map[i] = {name = "out-of-map", position = position}
				tiles[i] = {name = "dirt-" .. index, position = position}
				i = i + 1			
			end
		end
	end
	
	surface.set_tiles(out_of_map, false)
	surface.set_tiles(tiles, true)
	
	for _ = 1, 4, 1 do
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = {x = left_top_x + v[1], y = left_top_y + v[2]}
		if is_biter_area(position) and surface.can_place_entity({name = "spitter-spawner", position = position}) then
			local e
			if math_random(1, 4) == 1 then
				e = surface.create_entity({name = "spitter-spawner", position = position, force = "north_biters"})
			else
				e = surface.create_entity({name = "biter-spawner", position = position, force = "north_biters"})
			end
			table.insert(global.unit_spawners[e.force.name], e)
		end
	end

	local e = (math_abs(left_top_y) - bb_config.bitera_area_distance) * 0.0015	
	for _ = 1, math_random(5, 10), 1 do
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = {x = left_top_x + v[1], y = left_top_y + v[2]}
		local worm_turret_name = BiterRaffle.roll("worm", e)
		if is_biter_area(position) and surface.can_place_entity({name = worm_turret_name, position = position}) then			
			surface.create_entity({name = worm_turret_name, position = position, force = "north_biters"})
		end
	end
end

local function mixed_ore(surface, left_top_x, left_top_y)
	local seed = game.surfaces[global.bb_surface_name].map_gen_settings.seed
	
	local noise = GetNoise("bb_ore", {x = left_top_x + 16, y = left_top_y + 16}, seed)

	--Draw noise text values to determine which chunks are valid for mixed ore.
	--rendering.draw_text{text = noise, surface = game.surfaces.biter_battles, target = {x = left_top_x + 16, y = left_top_y + 16}, color = {255, 255, 255}, scale = 2, font = "default-game"}

	--Skip chunks that are too far off the ore noise value.
	if noise < 0.42 then return end

	--Draw the mixed ore patches.
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			if surface.can_place_entity({name = "iron-ore", position = pos}) then
				local noise = GetNoise("bb_ore", pos, seed)
				if noise > 0.72 then
					local i = math_floor(noise * 25 + math_abs(pos.x) * 0.05) % 4 + 1
					local amount = (math_random(800, 1000) + math_sqrt(pos.x ^ 2 + pos.y ^ 2) * 3) * mixed_ore_multiplier[i]
					surface.create_entity({name = ores[i], position = pos, amount = amount}) --EVL should we use surface.set_tiles{{name="grass", position={1,1}}} ???
				end
			end
		end
	end
	--DEBUG-- What  is  this ?
	if left_top_y == -32 and math_abs(left_top_x) <= 32 then
		for _, e in pairs(surface.find_entities_filtered({name = 'character', invert = true, area = {{-12, -12},{12, 12}}})) do e.destroy() end
	end
end

-- Generate structures (called for north only) see main.lua
function Public.generate(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local left_top_x = left_top.x
	local left_top_y = left_top.y

	mixed_ore(surface, left_top_x, left_top_y)
	generate_river(surface, left_top_x, left_top_y)
	draw_biter_area(surface, left_top_x, left_top_y)		
	generate_extra_worm_turrets(surface, left_top)
end

--EVL draw the island, the lake and the managers spot
function Public.draw_spawn_circle(surface) --THE ISLAND
	local spawn_circle_size_square = spawn_circle_size^2
	local spawn_island_size_square = spawn_island_size^2
	local inner_size=math.random(2,5)/2
	local spawn_inner_size_square = (spawn_island_size-inner_size)^2
	local island_tile_tab={
		[1]={
			["inner"]={"sand-1","sand-2","sand-3"},
			["outer"]="stone-path"
		},
		[2]={
			["inner"]={"grass-1","grass-2","grass-3"},
			["outer"]="concrete"
		},
		[3]={
			["inner"]={"dirt-4","dirt-5","dirt-6","dirt-7"},
			["outer"]="refined-concrete"
		},
		[4]={
			["inner"]={"dirt-1","dirt-2","dirt-3"},
			["outer"]="concrete"
		}
	}
	local this_tile_ref=math.random(1,table_size(island_tile_tab))
	local this_tile_inner_tab=island_tile_tab[this_tile_ref]["inner"]
	local this_tile_outer_name=island_tile_tab[this_tile_ref]["outer"]
	--jaune"sand-1","sand-2","sand-3",
	--jaune//"dirt-1","dirt-2","dirt-3",//rouge"dirt-4","dirt-5","dirt-6","dirt-7",
	--vert//"grass-1","grass-2","grass-3",//rouge"grass-4"
	
	local tiles = {}
	for x = spawn_circle_size * -1, 0, 1 do -- EVL was -spawn,-1,1
		for y = spawn_circle_size * -1, -1, 1 do  -- EVL was -spawn,-1,1
			local pos_left = {x = x, y = y}
			local pos_right = {x = -x, y = y}			
			--local distance_to_center = math_sqrt(pos.x ^ 2 + pos.y ^ 2)
			local distance_to_center_square = x ^ 2 + y ^ 2
			--EVL new logic, less space in table , a bit quicker
			if distance_to_center_square < spawn_inner_size_square then -- The Island, tile=sand (7²=49)
				local inner_tile=this_tile_inner_tab[math.random(1,#this_tile_inner_tab)]
				table_insert(tiles, {name = inner_tile, position = pos_left})
				inner_tile=this_tile_inner_tab[math.random(1,#this_tile_inner_tab)]
				table_insert(tiles, {name = inner_tile, position = pos_right})
			elseif distance_to_center_square < spawn_island_size_square then -- The island tile=concrete(9.5²=90.25)
				table_insert(tiles, {name = this_tile_outer_name, position = pos_left})
				table_insert(tiles, {name = this_tile_outer_name, position = pos_right})
			elseif (x==-1) and (y==-spawn_manager_pos or y==-spawn_manager_pos-1) then --The spot for manager (spy/coach/etc.)
				table_insert(tiles, {name = "hazard-concrete-left", position = pos_left})
				table_insert(tiles, {name = "hazard-concrete-left", position = pos_right})
			elseif (x==0) and (y==-spawn_manager_pos or y==-spawn_manager_pos-1) then --The spot for manager (spy/coach/etc.)
				table_insert(tiles, {name = "hazard-concrete-right", position = pos_left})				
			elseif (x==0) and (y==-spawn_manager_pos-2) then --The spot for the speaker (trolololl)
				table_insert(tiles, {name = "hazard-concrete-right", position = pos_left})				
			elseif distance_to_center_square <= spawn_circle_size_square then --The lake
				table_insert(tiles, {name = "deepwater", position = pos_left})
				table_insert(tiles, {name = "deepwater", position = pos_right})
			--else
			end
			--[[ Old version bad logic
			if distance_to_center <= spawn_circle_size then
				table_insert(tiles, {name = "deepwater", position = pos})
				if distance_to_center < 9.5 then 
					table_insert(tiles, {name = "refined-concrete", position = pos})
					if distance_to_center < 7 then 
						table_insert(tiles, {name = "sand-1", position = pos})
					end
				end			
			end
			]]--
		end
	end

	--[[ Old, moved to main loop
	for i = 1, #tiles, 1 do
		table_insert(tiles, {name = tiles[i].name, position = {tiles[i].position.x * -1 - 1, tiles[i].position.y}})
	end
	]]--
	
	surface.set_tiles(tiles, true)
	--ADD fishes (1/48 chance)
	for i = 1, #tiles, 1 do
		if tiles[i].name == "deepwater" then
			if math_random(1, 48) == 1 then --EVL we want want to change this value ?
				local e = surface.create_entity({name = "fish", position = tiles[i].position})
			end
		end
	end
end


function Public.draw_spawn_area(surface)
	local chunk_r = 5 --EVL was 4
	local r = chunk_r * 32	
	
	for x = r * -1, r, 1 do
		for y = r * -1, -4, 1 do
			local pos = {x = x, y = y}
			local distance_to_center = math_sqrt(pos.x ^ 2 + pos.y ^ 2)
			generate_starting_area(pos, distance_to_center, surface)
		end
	end
	
	surface.destroy_decoratives({})
	surface.regenerate_decorative()
end

--EVL Rewrite function for a more suitable generation of mixed ore patch in Spawn
local function draw_mixed_ore_patch(surface, left_top_x, left_top_y, size, track_ore)
	if not size then size=32 end
	if not track_ore then track_ore=false end

	local seed = game.surfaces[global.bb_surface_name].map_gen_settings.seed
	local _radius=math.floor(size/2)
	local center_x = left_top_x + _radius
	local center_y = left_top_y + _radius
	local noise_center = GetNoise("bb_ore", {x = center_x, y = center_y}, seed)
	--if track_ore and global.bb_debug then game.print("Noise="..noise_center.." Size="..size.." Seed="..seed,{r = 200, g = 200, b = 200}) end
	--Draw noise text values to determine which chunks are valid for mixed ore.
	--rendering.draw_text{text = noise, surface = game.surfaces.biter_battles, target = {x = left_top_x + 16, y = left_top_y + 16}, color = {255, 255, 255}, scale = 2, font = "default-game"}

	--Skip chunks that are too far off the ore noise value.
	--if noise < 0.42 then return -1 end

	--Draw the mixed ore patches.
	local tot_amount=0 --EVL debug
	local tot_size=0 --EVL debug
	
	local _radius_by_angle={}
	local _radius_motion=math.random(0.8,0.9)*_radius
	local _radius_sign=1
	
	--local msg=""
	for _angle=-180,180,6 do
		--msg=msg.."|"..math.floor(_radius_motion)
		_radius_by_angle[_angle]=_radius_motion
		_radius_change=math.random(2,10)*_radius/100
		_radius_motion=_radius_motion+_radius_change*_radius_sign
		
		if _radius_motion>_radius then _radius_motion=_radius end
		if _radius_motion<_radius*0.7 then _radius_motion=_radius*0.7 end
		--Do we continue the same progression (larger/thiner)?
		if math.random(1,5)==1 then _radius_sign=_radius_sign*-1 end 
		
	end
	--game.print(msg)	

	
	for y = 0, size, 1 do
		local msg=""
		for x = 0, size, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			--test is we are in the river bb_config["border_river_width"] = 44
			if pos.y<-20 and surface.can_place_entity({name = "iron-ore", position = pos}) then

				local ore_radius=math.sqrt((x-(size/2))^2 + (y-(size/2))^2)
				
				local add_this_ore=false-- Do we add this ore ?
				
				if ore_radius<=_radius*0.7 then --We are sure to place this ore
					add_this_ore=true
				else --We check if we are inside the definition of the border of the patch
					local ore_angle=math.floor(math.atan2(y-(size/2),x-(size/2))*180/math.pi)
					ore_angle=ore_angle-ore_angle%6
					--if ore_angle<-180 then ore_angle=-180 end
					if not _radius_by_angle[ore_angle] and global.bb_debug then game.print("BUG: [color=#FF0000]this angle does not exist : [/color]"..ore_angle) end
					if _radius_by_angle[ore_angle] and ore_radius<=_radius_by_angle[ore_angle] then
						add_this_ore=true
						--msg=msg.."|"..ore_angle.."=".._radius_by_angle[ore_angle]
					end
				end
				if add_this_ore then
					--msg=msg.."|[color=#00FF00]"..math.floor(ore_radius).."[/color]"
					local noise = GetNoise("bb_ore", pos, seed)
					local i = math_floor(noise * 25 + math_abs(pos.x) * 0.05) % 5 + 1 --was % 4
					if i==5 then i=1 end --we double the iron
					local _name=ores[i]
					--local _amount = math.floor((math_random(800, 1000) + math_sqrt(pos.x ^ 2 + pos.y ^ 2) * 3) * mixed_ore_multiplier[i]) --EVL was 800,1000
					local _amount = math.floor(math_random(750, 950) * mixed_ore_multiplier[i] - ore_radius*10) -- No need to add distance we're in spawn
					if _amount<250 then _amount=250 end --EVL DEBUG
					surface.create_entity({name = _name, position = pos, amount = _amount}) --EVL should we use surface.set_tiles{{name="grass", position={1,1}}} ???--TODO--
					if track_ore then
						tot_amount=tot_amount+_amount --EVL debug
						tot_size=tot_size+1 --EVL debug
						ores_large[_name].amount=ores_large[_name].amount+_amount
						ores_large[_name].size=ores_large[_name].size+1
						--IF IN SPAWN 
						if math.abs(pos.x) < _spawn_radius and math.abs(pos.y) < _spawn_radius then
							ores_spawn[_name].amount=ores_spawn[_name].amount+_amount
							ores_spawn[_name].size=ores_spawn[_name].size+1
							local _chunk_x=math.floor(pos.x/_chunk_size)
							local _chunk_y=math.floor(pos.y/_chunk_size)
							--game.print("update chunks ("..pos.x..","..pos.y..")-(".._chunk_x..",".._chunk_y..")")
							update_chunk_info(_chunk_x,_chunk_y,_amount)							
							--game.print("update chunks done ("..pos.x..","..pos.y..")-(".._chunk_x..",".._chunk_y..")")
						end

					end	
				else
					--msg=msg.."|[color=#FF0000]"..math.floor(ore_radius).."[/color]"
				end
			end
		end
		--game.print("Y"..y)--..msg)
	end
	--if track_ore and global.bb_debug then game.print("Added "..tot_amount.." mixed ores in "..tot_size.."m²",{r = 200, g = 200, b = 200}) end	
	
	--DEBUG-- What  is  this ?
	if left_top_y == -32 and math_abs(left_top_x) <= 32 then
		for _, e in pairs(surface.find_entities_filtered({name = 'character', invert = true, area = {{-12, -12},{12, 12}}})) do e.destroy() end
	end
	return tot_amount
end

--EVL Original function
local function draw_grid_ore_patch(count, grid, name, surface, size, density)
	-- Takes a random left_top coordinate from grid, removes it and draws
	-- ore patch on top of it. Grid is held by reference, so this function
	-- is reentrant.
	for i = 1, count, 1 do
		local idx = math.random(1, #grid)
		local pos = grid[idx]
		table.remove(grid, idx)

		-- The draw_noise_ore_patch expects position with x and y keys.
		pos = { x = pos[1], y = pos[2] }
		draw_noise_ore_patch(pos, name, surface, size, density, false) --EVL add false
	end
end

--Display resources from "ores_large" and "ores_spawn" (if global.bb_debug)
local function display_ores(info)
	if not(global.bb_debug) then return end
	if not info then info=" - " end
	local _tot_spawn=0
	if global.bb_debug then game.print("INFO : Resources generation in Large=200x200 and Spawn=120x120 ("..info..")",{r = 125, g = 125, b = 0}) end
	for _res, _qtity in pairs(ores_large) do
		local _name=_res
		if _name=="iron-ore" then _name="iron " end
		if _name=="copper-ore" then _name="copper" end
		if _name=="coal" then _name="coal " end
		if _name=="crude-oil" then _name="crude" end
		local _unit="m²"
		if _res=="crude-oil" then _unit="well.s" end
		
		local msg="    ".._name
		for _=string.len(msg), 12, 1 do msg=msg.."  " end -- more readable
		msg=msg.." |Large="..math.round(_qtity.amount/1000,1).."k (".._qtity.size.." ".._unit..")" --quantity (surface)
		msg=msg.." ["..math.floor(_qtity.amount/_qtity.size) .."]" -- mean density
		for _=string.len(msg), 50, 1 do msg=msg.."  " end -- more readable
		msg=msg.."|Spawn="..math.round(ores_spawn[_res].amount/1000,1).."k ("..ores_spawn[_res].size.." ".._unit..")" --quantity (surface)
		_tot_spawn=_tot_spawn+ores_spawn[_res].amount
		msg=msg.." ["..math.floor(ores_spawn[_res].amount/ores_spawn[_res].size) .."]" -- [mean density]
		if global.bb_debug then game.print(msg,{r = 125, g = 125, b = 0}) end
	end
	if global.bb_debug then game.print("       > Total in spawn = ".._tot_spawn,{r = 125, g = 125, b = 0}) end
end

--Display chunks from "_chunk_info"
local function display_chunks(info)
	if not(global.bb_debug) then return end
	if not info then info=" - " end
	local _tot_spawn=0
	for _y=-1*_chunk_minmax+1,_chunk_y_max-1,1 do --from (top+1) to (bottom-1) ie close to river
		local msg=" Line ".._y..": "
		for _x=-1*_chunk_minmax+1,_chunk_minmax-1,1 do
			--[[ DEBUG
			local _real_x=_x*_chunk_size
			local _real_y=_y*_chunk_size
			if surface.can_place_entity({name = "uranium-ore", position ={x=_real_x, y=_real_y}, amount = 9999}) then
			  	surface.create_entity({name = "uranium-ore", position = {x=_real_x, y=_real_y}, amount = 9999})
			else
				if global.bb_debug then game.print("cannot place uranium at (".._real_x..",".._real_y..")",{r = 200, g = 200, b = 200}) end
			end
			]]--
			--Print CHUNKS TABLE
			_tot_spawn=_tot_spawn+_chunk_info[_x][_y]["ore"]/4
			local _ore=math.floor(_chunk_info[_x][_y]["ore"]/4000).."k"
			if _chunk_info[_x][_y]["ore-next"]>0 then _ore=_ore.."*" end
			for _=string.len(_ore), 8, 1 do _ore=_ore.."  " end -- more readable
			msg=msg.._ore.."| "
			
		end
		if global.bb_debug then game.print(msg,{r = 200, g = 200, b = 100}) end
	end
	if global.bb_debug then game.print("Total spawn (borders excluded) = ".._tot_spawn.."   ("..info..")",{r = 200, g = 200, b = 200}) end
end

-- Add a patch in spawn if needed (after mixed patch has been drawned)
local function add_patch_in_spawn_if_needed(surface,name,need_patch,target_qtity,richness,radius)
	
	local _need_patch=need_patch
	local _name = name
	local _msg="Added ".._name.." patch in "
	local _target_qtity=math.random(target_qtity,target_qtity+100)*1000
	if ores_spawn[_name].amount < _target_qtity then _need_patch=true	end
	if _need_patch then
		local _chosen_chunk={}
		if #_chunk_very_empty>=1 then --We have a good candidate
			local _index=math.random(1,#_chunk_very_empty)
			_chosen_chunk=_chunk_very_empty[_index]
			table.remove(_chunk_very_empty,_index)
			_msg=_msg.."[color=#FFFF00]{very}[/color]"
		elseif #_chunk_almost_empty>=1 then   -- we have a not-so-good candidate
			local _index=math.random(1,#_chunk_almost_empty)
			_chosen_chunk=_chunk_almost_empty[_index]
			table.remove(_chunk_almost_empty,_index)
			_msg=_msg.."[color=#FF8800]{almost}[/color]"
		else 
			_chosen_chunk={math.random(1,9)-5,math.random(1,5)-6}	--TODO-- look closer to this, we may have a candidate (if we ever come here)		
			_msg=_msg.."[color=#FF0000]{forced}[/color]"
		end	
		
		local _delta = math.floor(_chunk_size/2) -- we center patch 
		local _pos = {x = _chosen_chunk[1]*_chunk_size+_delta, y = _chosen_chunk[2]*_chunk_size-_delta}
		--Calculate Qtity/Richness and Size/Radius
		local _set_richness=(_target_qtity-ores_spawn[_name].amount)/_target_qtity 
		if _set_richness<=0.25 then _set_richness=0.25 end -- from 0.25=25% (we're almost good) to 1=100% (we need lots of resource)
		local _richness = math.floor(richness+richness*3*_set_richness) + math.random(0,richness)
		local _radius = math.floor(9+radius*_set_richness) + math.random(1,6) --DEBUG-- Add a limit to radius ? (depending on ore...)
	
		_msg=_msg.." "..draw_noise_ore_patch(_pos,_name, surface,_radius,_richness, true).." "
		_msg=_msg.." at (".._chosen_chunk[1]..",".._chosen_chunk[2]..")=>(".._pos.x..",".._pos.y..")"
		_msg=_msg.." radius=".._radius.." richness=".._richness.." set_richness="..math.floor(_set_richness*100).."%"
		if global.bb_debug then game.print(_msg,{r = 250, g = 150, b = 150}) end
	else
		if global.bb_debug then game.print("No need for ".._name.." patch",{r = 150, g = 250, b = 150}) end
	end
end	

--EVL Checking and adjusting resources in spawn
function Public.check_ore_in_main(surface)
	--Reinit quantities (after force-map-reset or reroll)
	ores_large = {
		["iron-ore"]={["amount"]=0,["size"]=0},
		["copper-ore"]={["amount"]=0,["size"]=0},
		["coal"]={["amount"]=0,["size"]=0},
		["stone"]={["amount"]=0,["size"]=0},
		["crude-oil"]={["amount"]=0,["size"]=0}
	}
	ores_spawn = {
		["iron-ore"]={["amount"]=0,["size"]=0},
		["copper-ore"]={["amount"]=0,["size"]=0},
		["coal"]={["amount"]=0,["size"]=0},
		["stone"]={["amount"]=0,["size"]=0},
		["crude-oil"]={["amount"]=0,["size"]=0}
	}
	_chunk_info={}
	for _x=-1*_chunk_minmax-1,_chunk_minmax+1,1 do
		_chunk_info[_x]={}
		for _y=-1*_chunk_minmax-1,_chunk_y_max+1,1 do
			_chunk_info[_x][_y]={["ore"]=0,["ore-next"]=0,["water"]=0}
		end
	end	
	--End of re-init
	
	local resources = surface.find_entities_filtered {
		area = search_area,
		type = "resource"
	}

	for _, res in pairs(resources) do
		if res.name=="iron-ore" or res.name=="copper-ore" or res.name=="coal" or res.name=="stone" or res.name=="crude-oil" then
			local _x=res.position.x
			local _y=res.position.y
			--SEARCH IN LARGE (for oil)
			ores_large[res.name].amount=ores_large[res.name].amount+res.amount
			ores_large[res.name].size=ores_large[res.name].size+1
			--SEARCH IN SPAWN 
			if math.abs(_x) < _spawn_radius and math.abs(_y) < _spawn_radius then
				ores_spawn[res.name].amount=ores_spawn[res.name].amount+res.amount
				ores_spawn[res.name].size=ores_spawn[res.name].size+1
				--Set the info in _chunk_info (for later)
				local _chunk_x=math.floor(_x/_chunk_size)
				local _chunk_y=math.floor(_y/_chunk_size)
				
				if math.abs(_chunk_x)<=_chunk_minmax and math.abs(_chunk_y)<=_chunk_minmax then
					update_chunk_info(_chunk_x,_chunk_y,res.amount)
				end	
				
			end
		else 
			if global.bb_debug then game.print(res.name.." is not measured (uranium)") end
		end
	end

	--PRINT the quantities
	display_ores("Seed="..surface.map_gen_settings.seed)
		
	-- Search for candidates
	_chunk_totally_empty={} -- empty chunks with neighbors and neighbors of neighbors also empty
	_chunk_very_empty={} -- empty chunks with neighbors also empty
	_chunk_almost_empty={} -- empty chunks with one or more neighbor not empty
	--loop around spawn without borders (+1/-1)
	local _water_str="Water found in chunks : "
	for _y=-1*_chunk_minmax+1,_chunk_y_max-1,1 do --from (top+1) to (bottom-1) ie close to river
		for _x=-1*_chunk_minmax+1,_chunk_minmax-1,1 do
			--LOOK FOR WATER INSIDE CHUNKS (we check 49 tiles, see below)
			for _inY = 1,_chunk_size-1,3 do -- we check {1,4,7,10,13,16,19} assuming _chunk_size=20
				for _inX = 1,_chunk_size-1,3 do -- we check {1,4,7,10,13,16,19} assuming _chunk_size=20
					local _tile_name=surface.get_tile({x = _x*_chunk_size + _inX, y =  _y*_chunk_size + _inY}).name
					if _tile_name == "water" or _tile_name == "deepwater" then
						_chunk_info[_x][_y]["water"]=_chunk_info[_x][_y]["water"]+1
						if global.bb_debug then 
							surface.set_tiles({{name = "deepwater-green", position = {x = _x*_chunk_size + _inX, y =  _y*_chunk_size + _inY}}})
						end
					end
				end
			end

			if _chunk_info[_x][_y]["water"]<5 then 	-- If we dont have more than 5 tiles of water out of 49 (around 10%)
														-- Then we can place ore in this chunk
				if _chunk_info[_x][_y]["ore"]==0 then --we have an empty chunk
					if _chunk_info[_x][_y]["ore-next"]==0 then	-- and all neighbors are empty
						local _neighbor_of_not_empty=0
						--NEXT CHUNKS HAVE ORES ?
						if _chunk_info[_x-1][_y]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x+1][_y]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x][_y+1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x][_y-1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						--CORNER CHUNKS HAVE ORES ?
						if _chunk_info[_x-1][_y-1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x-1][_y+1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x+1][_y+1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						if _chunk_info[_x+1][_y-1]["ore-next"]>0 then _neighbor_of_not_empty=_neighbor_of_not_empty+1 end
						
						if _neighbor_of_not_empty==0 then -- and all neighbors of neighbors are  also empty
							table.insert(_chunk_totally_empty, {_x, _y})
						else 				
							table.insert(_chunk_very_empty, {_x, _y})
						end	
					else
						table.insert(_chunk_almost_empty, {_x, _y})
					end
				end
			else
				_water_str=_water_str.." [".._x..",".._y.."] "
			end
		end
	end
	if global.bb_debug then game.print(_water_str,{r = 150, g = 150, b = 250}) end
	--display_chunks(surface.map_gen_settings.seed)-- (if global.bb_debug)
	

	--[[ PRINT THE LISTS OF EMPTY CHUNKS (candidate to add ore if needed)
	local _msg="    ".._chunk_totally_empty_nb.." totally empty  : "
	for _index=1,_chunk_totally_empty_nb,1 do 
		_msg=_msg.." (".._chunk_totally_empty[_index][1]..",".._chunk_totally_empty[_index][2]..")   "
	end
	if global.bb_debug then game.print(_msg,{r = 200, g = 200, b = 100}) end
	local _msg="    ".._chunk_very_empty_nb.." very empty  : "
	for _index=1,_chunk_very_empty_nb,1 do 
		_msg=_msg.." (".._chunk_very_empty[_index][1]..",".._chunk_very_empty[_index][2]..")   "
	end
	if global.bb_debug then game.print(_msg,{r = 200, g = 200, b = 100}) end
	]]--
	
	-- First do we need to add regular ore patch (regardless need of mixed patch)
	local need_iron_patch=false
	if ores_spawn["iron-ore"].amount<200000 or ores_spawn["iron-ore"].size<750 then need_iron_patch=true end
	local need_copper_patch=false
	if ores_spawn["copper-ore"].amount<100000 or ores_spawn["copper-ore"].size<350 then need_copper_patch=true end
	local need_coal_patch=false
	if ores_spawn["coal"].amount<80000 or ores_spawn["coal"].size<300 then need_coal_patch=true end
	local need_stone_patch=false
	if ores_spawn["stone"].amount<80000 or ores_spawn["stone"].size<300 then need_stone_patch=true end
	
	-- Second do we need a mix patch (if 2 or more resources are missing)
	local not_enough_ore=0
	local _msg=" Not enough of "
	if ores_spawn["iron-ore"].amount < math.random(500000,600000) then not_enough_ore=not_enough_ore+1	_msg=_msg.."Iron | "	end
	if ores_spawn["copper-ore"].amount < math.random(250000,300000) then not_enough_ore=not_enough_ore+1  _msg=_msg.."Copper | "	end
	if ores_spawn["coal"].amount < math.random(200000,250000) then not_enough_ore=not_enough_ore+1 _msg=_msg.."Coal | " end
	if ores_spawn["stone"].amount < math.random(200000,250000) then not_enough_ore=not_enough_ore+1 	_msg=_msg.."Stone"	end

	--if global.bb_debug then game.print(_msg,{r = 200, g = 200, b = 200}) end

	local _msg_type=""
	if not_enough_ore >=2 then --Yes we need a mixed patch (happens very very often)
		
		local _chosen_chunk={}
		if (#_chunk_totally_empty>=1) then --we have a excellent candidate
			local _index=math.random(1,#_chunk_totally_empty)
			_chosen_chunk=_chunk_totally_empty[_index]
			_msg_type="[color=#FF0000]{totally}[/color]"

		elseif (#_chunk_very_empty>=1) then   -- we have a not-so-good candidate
			local _index=math.random(1,#_chunk_very_empty)
			_chosen_chunk=_chunk_very_empty[_index]
			_msg_type="[color=#FF0000]{very}[/color]"
		elseif (#_chunk_almost_empty>=1) then   -- we have a not-so-good candidate
			local _index=math.random(1,#_chunk_almost_empty)
			_chosen_chunk=_chunk_almost_empty[_index]
			_msg_type="[color=#FF0000]{almost}[/color]"
		else --we didnt find a candidate
			_chosen_chunk={math.random(1,9)-5,-5}	--TODO-- look closer to this, we may have a candidate (if we ever come here)
			_msg_type="[color=#FF0000]{forced}[/color]"
		end
	
		local _delta_x = -1*_chunk_size -- we shift patch left from center (since we know that chunk is also empty and patch will be set from top left)
		--if _chosen_chunk[1]>0 then _delta_x=-1*_delta_x end
		local _delta_y = -1*_chunk_size -- we shift patch slightly upper (farther from river)
		local _posX = _chosen_chunk[1]*_chunk_size+_delta_x
		local _posY = _chosen_chunk[2]*_chunk_size+_delta_y
		local _size=math.random(60,80)
		local _qtity_mixed_ores=draw_mixed_ore_patch(surface, _posX, _posY, _size, true)
		if global.bb_debug then game.print("Added mixed ".._msg_type.." patch at (".._chosen_chunk[1]..",".._chosen_chunk[2]..")=>(".._posX..",".._posY..") size=".._size.." QTITY=".._qtity_mixed_ores.."  (".._msg..")",{r = 250, g = 150, b = 150}) end	
		
		-- SEARCH AGAIN again for candidates now we have a mixed patch (we dont care about totally empty anymore)
		_chunk_very_empty={} -- empty chunks with neighbors also empty
		_chunk_almost_empty={} -- empty chunks with one or more neighbor not empty
		--loop around spawn without borders (+1/-1)
		for _y=-1*_chunk_minmax+1,_chunk_y_max-1,1 do --from (top+1) to (bottom-1) ie close to river
			for _x=-1*_chunk_minmax+1,_chunk_minmax-1,1 do
				if _chunk_info[_x][_y]["water"]<5 then 	-- If we dont have more than 10 tiles of water out of 49 (around 20%)
															-- Then we can place ore in this chunk			
					if _chunk_info[_x][_y]["ore"]==0 then --we have an empty chunk
						if _chunk_info[_x][_y]["ore-next"]==0 then	-- and all neighbors are empty
							table.insert(_chunk_very_empty, {_x, _y})
						else
							table.insert(_chunk_almost_empty, {_x, _y})
						end
					end
				end
			end
		end


	else
		if global.bb_debug then game.print("No need for mixed patch",{r = 150, g = 250, b = 150}) end
	end
		
	--Print the chunks very and almost empty
	--[[
	local _msg="    "..#_chunk_very_empty.." very empty  : "
	for _index=1,#_chunk_very_empty,1 do _msg=_msg.." (".._chunk_very_empty[_index][1]..",".._chunk_very_empty[_index][2]..") " end
	if global.bb_debug then game.print(_msg,{r = 200, g = 200, b = 100}) end
	local _msg="    "..#_chunk_almost_empty.." almost empty  : "
	for _index=1,#_chunk_almost_empty,1 do _msg=_msg.." (".._chunk_almost_empty[_index][1]..",".._chunk_almost_empty[_index][2]..") "	end
	if global.bb_debug then game.print(_msg,{r = 200, g = 200, b = 100}) end
	]]--
	
	display_ores("before adding new patches")-- (if global.bb_debug)
	
	-- Adding regular patches (iron, copper, coal, stone) if we had very few at the beginning or if mixed patch didnt put enough
	
	add_patch_in_spawn_if_needed(surface, "iron-ore", need_iron_patch, 500, 350, 20) 
	--500 means we target 500000 to 600000 ore in total (but we'll have less), 
	--350 is richness, depends on quantities existing, from richness to richness*4
	--20 means size/radius "range", depends on quantities existing, from 8+0+1 to 8+richness+5
	
	add_patch_in_spawn_if_needed(surface, "copper-ore", need_copper_patch, 200, 200, 12) 
	add_patch_in_spawn_if_needed(surface, "coal", need_coal_patch, 150, 200, 10) 
	add_patch_in_spawn_if_needed(surface, "stone", need_stone_patch, 150, 200, 10) 

	-- Here could add more patches if needed (above may put very few ores)
	-- But it seems it is good enough like that (randomness of spawns is nice according to EVL)
	
	-- We give a few free wells of crude-oil if there was none (or not enough) in the "large" research
	-- They will be placed somehow "close" to the river
	local _number=math.random(2,5) --2 to 5 wells in total
	if ores_large["crude-oil"].size<_number then
		_number=_number-ores_spawn["crude-oil"].size -- number left to place
		local _angle=math.random(5,30) -- in degrees
		local _distance=math.random(0,150)+150 
		
		local _posX = math.floor(_distance*math.cos(_angle*math.pi/180))
		if math.random(0,1)==1 then _posX=-1*_posX end
		local _posY = math.floor(_distance*math.sin(_angle*math.pi/180))*-1 - 30 -- -30 to be out of the river

		local _msg="Added crude-oil at "
		local _delta=0
		local _try=200 -- lets keep safe, we dont want to loop infinitly
		while _number>0 and _try>0 do
			_try=_try-1
			if surface.can_place_entity({name = "crude-oil", position = {x=_posX,y=_posY}}) then
				local _amount=math.random(100000,150000)
				surface.create_entity{name = "crude-oil", position = {x=_posX,y=_posY}, amount = _amount}
				ores_large["crude-oil"].amount=ores_large["crude-oil"].amount+_amount
				ores_large["crude-oil"].size=ores_large["crude-oil"].size+1				
				_number=_number-1
				_msg=_msg.." (".._posX..",".._posY..") "
			else -- are we in water ? if so we need to move far away
				_tile_name=surface.get_tile({x=_posX,y=_posY}).name
				if _tile_name == "water" or _tile_name== "water" then
					if global.bb_debug then game.print("Shit Oil is in water, need to move !!!",{r = 250, g = 0, b = 0})  end
					--Try to get out of water
					_posX=_posX+math.random(20,40)
					_posY=_posY-math.random(10,20)
				end
			end
			_delta=math.random(1,6)
			if _delta==1 then 
				_posX=_posX+math.random(3,5)
				_posY=_posY-math.random(2,3)
			elseif _delta==2 then 
				_posX=_posX+math.random(3,5)
				_posY=_posY+math.random(2,3)
			elseif _delta==3 then 
				_posX=_posX+math.random(2,3)
				_posY=_posY+math.random(3,5)
			elseif _delta==4 then 
				_posX=_posX-math.random(3,5)
				_posY=_posY+math.random(2,3)
			else
				_posX=_posX-math.random(3,5)
				_posY=_posY-math.random(3,5)
			end
		end
		if global.bb_debug then game.print(_msg,{r = 250, g = 150, b = 150}) end
	else
		if global.bb_debug then game.print("No need for more oil",{r = 150, g = 250, b = 150}) end
	end
	
	
	display_ores("after adding new patches")-- (if global.bb_debug)
	--display_chunks("after adding new patch")
	--[[
	if global.taming then
		local _msg="Taming chunk = "
		local _chosen_chunk={}
		if #_chunk_very_empty>=1 then --We have a good candidate
			local _index=math.random(1,#_chunk_very_empty)
			_chosen_chunk=_chunk_very_empty[_index]
			table.remove(_chunk_very_empty,_index)
			_msg=_msg.."[color=#FFFF00]{very}[/color]"
		elseif #_chunk_almost_empty>=1 then   -- we have a not-so-good candidate
			local _index=math.random(1,#_chunk_almost_empty)
			_chosen_chunk=_chunk_almost_empty[_index]
			table.remove(_chunk_almost_empty,_index)
			_msg=_msg.."[color=#FF8800]{almost}[/color]"
		else 
			_chosen_chunk={math.random(1,9)-5,math.random(1,5)-6}	--TODO-- look closer to this, we may have a candidate (if we ever come here)		
			_msg=_msg.."[color=#FF0000]{forced}[/color]"
		end	
		--find_units{area, force, condition}→ array[LuaEntity]
		--find_entity(entity, position)→ LuaEntityFind a specific entity at a specific position.
		--find_enemy_units(center, radius, force)→ array[LuaEntity] Find enemy units (entities with type "unit") of a given force within an area.
		--find_entities(area)→ array[LuaEntity]	Find entities in a given area.
		--find_entities_filtered{area, position, radius, name, type, ghost_name, ghost_type, direction, collision_mask, force, to_be_deconstructed, to_be_upgraded, limit, invert} → array[LuaEntity]

		local _size = math.random(math.floor(_chunk_size/2),_chunk_size-2)
		local _gate = math.floor(_size/2)
		_msg=_msg.." at (".._chosen_chunk[1]..",".._chosen_chunk[2]..") size=".._size
		for i=1,_size,1 do
			local _name="stone-wall"
			if i==_gate-1 or i==_gate or i==_gate+1 then _name="gate" end
			
			surface.create_entity({name = _name, position = {x=_chosen_chunk[1]+i, y=_chosen_chunk[2]}, force = "north"})		
			surface.create_entity({name = _name, position = {x=_chosen_chunk[1], y=_chosen_chunk[2]+i}, force = "north"})		
			surface.create_entity({name = _name, position = {x=_chosen_chunk[1]+i, y=_chosen_chunk[2]+size}, force = "north"})		
			surface.create_entity({name = _name, position = {x=_chosen_chunk[1]+size, y=_chosen_chunk[2]+i}, force = "north"})		
		end
		if global.taming_debug then game.print(_msg,{r = 250, g = 150, b = 150}) end
	end
	]]--
end

--EVL Clear ore in main, not used in BBChampions (used in freeBB)
function Public.clear_ore_in_main(surface)
	local search_area = {
		left_top = { -150, -150 },
		right_bottom = { 150, 0 }
	}
	local resources = surface.find_entities_filtered {
		area = search_area,
		type = "resource"
	}
	for _, res in pairs(resources) do
		res.destroy()
	end
end

--EVL Remove ore on island and manager spots (seems to happen more often with this version)
function Public.clear_ore_in_island(surface)
	--spawn_island_size = bb_config.spawn_island_size  -- 10 
	--spawn_manager_pos = bb_config.spawn_manager_pos  -- 18
	
	--Note: Ores can be generated AFTER init.lua/Public.draw_structures() -> need to inspect--TODO--
	--So island is cleared later (when map is reveald=10s), need to clear north spot, island and south spot
	
	--1/3 Clear the island
	local search_area = {
		{-spawn_island_size-2, -spawn_island_size-2},
		{ spawn_island_size+2,  spawn_island_size+2}
	}
	local resources = surface.find_entities_filtered {
		area = search_area,
		type = "resource"
	}
	if table_size(resources)>0 then
		for _, res in pairs(resources) do
			res.destroy()
		end
	end
	--2/3 Clear the north manager spot
	local search_area = {
		{-4, -spawn_manager_pos-4},
		{ 4, -spawn_manager_pos+4}
	}
	local resources = surface.find_entities_filtered {
		area = search_area,
		type = "resource"
	}
	if table_size(resources)>0 then
		for _, res in pairs(resources) do
			res.destroy()
		end
	end
	--3/3 Clear the south manager spot
	local search_area = {
		{-4, spawn_manager_pos-4},
		{ 4, spawn_manager_pos+4}
	}
	local resources = surface.find_entities_filtered {
		area = search_area,
		type = "resource"
	}
	if table_size(resources)>0 then
		for _, res in pairs(resources) do
			res.destroy()
		end
	end
end

--EVL Regenerate ore in spawn (after clear_ore_in_main), not used in BBChampions (used in freeBB)
function Public.generate_spawn_ore(surface)
	-- This array holds indicies of chunks onto which we desire to
	-- generate ore patches. It is visually representing north spawn
	-- area. One element was removed on purpose - we don't want to
	-- draw ore in the lake which overlaps with chunk [0,-1]. All ores
	-- will be mirrored to south.
	local grid = {
		{ -2, -3 }, { -1, -3 }, { 0, -3 }, { 1, -3, }, { 2, -3 },
		{ -2, -2 }, { -1, -2 }, { 0, -2 }, { 1, -2, }, { 2, -2 },
		{ -2, -1 }, { -1, -1 },            { 1, -1, }, { 2, -1 },
	}

	-- Calculate left_top position of a chunk. It will be used as origin
	-- for ore drawing. Reassigns new coordinates to the grid.
	for i, _ in ipairs(grid) do
		grid[i][1] = grid[i][1] * 32 + math.random(-12, 12)
		grid[i][2] = grid[i][2] * 32 + math.random(-24, -1)
	end

	for name, props in pairs(spawn_ore) do
		draw_grid_ore_patch(props.big_patches, grid, name, surface,
				    props.size, props.density)
		draw_grid_ore_patch(props.small_patches, grid, name, surface,
				    props.size / 2, props.density)
	end
end

function Public.generate_additional_rocks(surface)
	local r = 130
	if surface.count_entities_filtered({type = "simple-entity", area = {{r * -1, r * -1}, {r, 0}}}) >= 12 then return end		
	local position = {x = -96 + math_random(0, 192), y = -40 - math_random(0, 96)}
	for _ = 1, math_random(6, 10) do
		local name = rocks[math_random(1, 5)]
		local p = surface.find_non_colliding_position(name, {position.x + (-10 + math_random(0, 20)), position.y + (-10 + math_random(0, 20))}, 16, 1)
		if p and p.y < -16 then
			surface.create_entity({name = name, position = p})
		end
	end
end

--EVL Add compilatron and some trees on the island Why NOT ? :)
function Public.generate_trees_on_island(surface)
	-- Hello compilatron !
	local p = surface.find_non_colliding_position("compilatron", {0,0}, 2, 1)
	if p then 
		global.compi={}
		global.compi["name"]=tables.compi["names"][math.random(1,#tables.compi["names"])]
		global.compi["entity"]=surface.create_entity({name = "compilatron", position = p, force="spectator"}) 
		global.compi["render"]=rendering.draw_text({
			surface = surface,
			target = global.compi["entity"],
			text = global.compi["name"],
			font = "count-font",
			alignment = "center",
			color = {20, 200, 20},
			target_offset = {0, -1.8},
			scale_with_zoom =  false
			-- x_scale = size * 15,
			-- y_scale = size,
        })	
		global.compi["welcome"]=tables.compi["welcome"][math.random(1,#tables.compi["welcome"])]
		
		game.print(global.compi["name"]..": "..global.compi["welcome"],{r = 20, g = 200, b = 20})
	end
	
	local search_area = {
		{-spawn_island_size-2, -spawn_island_size-2},
		{ spawn_island_size+2,  spawn_island_size+2}
	}
	--Clear rocks
	local rocks = surface.find_entities_filtered {
		area = search_area,
		type = "simple-entity"
	}
	if table_size(rocks)>1 then 
		for _, res in pairs(rocks) do
			res.destroy()
		end	
	end
	
	--Clear trees
	local trees = surface.find_entities_filtered {
		area = search_area,
		type = "tree"
	}
	--if table_size(trees)>1 then return end	--already trees but awful because of symmetry
	if table_size(trees)>0 then 
		for _, res in pairs(trees) do
			res.destroy()
		end	
	end
	
	-- Add some trees
	for i=1,10,1 do
		if math.random(1,10)>7 then
			local _index=math.random(1,table_size(tables.trees))
			local _name=tables.trees[_index]
			local _angle=math.random(0,360)*math.pi/180
			local _distance=math.random(2,spawn_island_size-2)
			local x = math.floor(_distance * math.cos(_angle))
			local y = math.floor(_distance * math.sin(_angle))
			local p = surface.find_non_colliding_position("tree-01", {x,y}, 2, 1)
			if p then
				surface.create_entity({name = _name, position = p, amount=1}) --Tables.trees[_index]
			end
		end
	end
end
-- GENERATE SILO AND ITS TURRETS, AND SPEAKERS(in manager spots)
function Public.generate_silo(surface)
	--game.print("Note : Check silos and speakers please. Had a bug once (but impossible to reproduce).",{r=99, g=99, b=99}) --REMOVE-- --DEBUG--
	local pos = {x = -32 + math_random(0, 64), y = -72}
	local mirror_position = {x = pos.x * -1, y = pos.y * -1}

	for _, t in pairs(surface.find_tiles_filtered({area = {{pos.x - 6, pos.y - 6},{pos.x + 6, pos.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end
	for _, t in pairs(surface.find_tiles_filtered({area = {{mirror_position.x - 6, mirror_position.y - 6},{mirror_position.x + 6, mirror_position.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end

	local silo = surface.create_entity({
		name = "rocket-silo",
		position = pos,
		force = "north"
	})
	silo.minable = false
	silo.active = false
	global.rocket_silo[silo.force.name] = silo
	Functions.add_target_entity(global.rocket_silo[silo.force.name])

	for _ = 1, 32, 1 do
		create_mirrored_tile_chain(surface, {name = "stone-path", position = silo.position}, 32, 10)
	end
	
	--Clear entities under silo
	local p = silo.position
	for _, entity in pairs(surface.find_entities({{p.x - 4, p.y - 4}, {p.x + 4, p.y + 4}})) do
		if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
			entity.destroy()
		end
	end

	--EVL add speaker in manager spot, force is not friendly so speaker doesnt blink electric alert
	_pos = {x = 0, y = -spawn_manager_pos-2}
	local speaker = surface.create_entity({name = "programmable-speaker", position = _pos, force = "north"})
	speaker.minable = false
	speaker.active = false
	global.manager_speaker[speaker.force.name] = speaker
	
	--EVL add 3 turrets next to silo with 12 yellow magazines in each
	local _count=12 -- 12 magazines in each 3 bonus turrets	
	local turret1 = surface.create_entity({name = "gun-turret", position = {x=pos.x-3, y=pos.y-5}, force = "north"})
	turret1.insert({name = "firearm-magazine", count = _count})
	local turret2 = surface.create_entity({name = "gun-turret", position = {x=pos.x, y=pos.y-5}, force = "north"})
	turret2.insert({name = "firearm-magazine", count = _count})
	local turret3 = surface.create_entity({name = "gun-turret", position = {x=pos.x+4, y=pos.y-5}, force = "north"})
	turret3.insert({name = "firearm-magazine", count = _count})
	
	local add_turrets=false --CODING--
	if add_turrets then --EVL SOME MORE TURRETS FOR TESTING IN SOLO
		--local bullet="firearm-magazine"
		local bullet="uranium-rounds-magazine"
		local count=200
		local turret1 = surface.create_entity({name = "gun-turret", position = {x=pos.x-9, y=pos.y-5}, force = "north"})
		turret1.insert({name = bullet, count = count})
		local turret2 = surface.create_entity({name = "gun-turret", position = {x=pos.x-9, y=pos.y-8}, force = "north"})
		turret2.insert({name = bullet, count = count})
		local turret3 = surface.create_entity({name = "gun-turret", position = {x=pos.x-9, y=pos.y-11}, force = "north"})
		turret3.insert({name = bullet, count = count})

		local turret4 = surface.create_entity({name = "gun-turret", position = {x=pos.x-3, y=pos.y-8}, force = "north"})
		turret4.insert({name = bullet, count = count})
		local turret5 = surface.create_entity({name = "gun-turret", position = {x=pos.x, y=pos.y-8}, force = "north"})
		turret5.insert({name = bullet, count = count})
		local turret6 = surface.create_entity({name = "gun-turret", position = {x=pos.x+4, y=pos.y-8}, force = "north"})
		turret6.insert({name = bullet, count = count})
		local turret7 = surface.create_entity({name = "gun-turret", position = {x=pos.x-3, y=pos.y-11}, force = "north"})
		turret7.insert({name = bullet, count = count})
		local turret8 = surface.create_entity({name = "gun-turret", position = {x=pos.x, y=pos.y-11}, force = "north"})
		turret8.insert({name = bullet, count = count})
		local turret9 = surface.create_entity({name = "gun-turret", position = {x=pos.x+4, y=pos.y-11}, force = "north"})
		turret9.insert({name = bullet, count = count})

		local turret1a = surface.create_entity({name = "gun-turret", position = {x=pos.x-6, y=pos.y-5}, force = "north"})
		turret1a.insert({name = bullet, count = count})
		local turret2a = surface.create_entity({name = "gun-turret", position = {x=pos.x+7, y=pos.y-5}, force = "north"})
		turret2a.insert({name = bullet, count = count})
		local turret3a = surface.create_entity({name = "gun-turret", position = {x=pos.x+10, y=pos.y-5}, force = "north"})
		turret3a.insert({name = bullet, count = count})

		local turret4a = surface.create_entity({name = "gun-turret", position = {x=pos.x-6, y=pos.y-8}, force = "north"})
		turret4a.insert({name = bullet, count = count})
		local turret5a = surface.create_entity({name = "gun-turret", position = {x=pos.x+7, y=pos.y-8}, force = "north"})
		turret5a.insert({name = bullet, count = count})
		local turret6a = surface.create_entity({name = "gun-turret", position = {x=pos.x+10, y=pos.y-8}, force = "north"})
		turret6a.insert({name = bullet, count = count})
		local turret7a = surface.create_entity({name = "gun-turret", position = {x=pos.x-6, y=pos.y-11}, force = "north"})
		turret7a.insert({name = bullet, count = count})
		local turret8a = surface.create_entity({name = "gun-turret", position = {x=pos.x+7, y=pos.y-11}, force = "north"})
		turret8a.insert({name = bullet, count = count})
		local turret9a = surface.create_entity({name = "gun-turret", position = {x=pos.x+10, y=pos.y-11}, force = "north"})
		turret9a.insert({name = bullet, count = count})
		
		local turret1b = surface.create_entity({name = "gun-turret", position = {x=pos.x-6, y=pos.y-2}, force = "north"})
		turret1b.insert({name = bullet, count = count})
		local turret2b = surface.create_entity({name = "gun-turret", position = {x=pos.x-6, y=pos.y+1}, force = "north"})
		turret2b.insert({name = bullet, count = count})
		local turret3b = surface.create_entity({name = "gun-turret", position = {x=pos.x+7, y=pos.y-2}, force = "north"})
		turret3b.insert({name = bullet, count = count})
		local turret4b = surface.create_entity({name = "gun-turret", position = {x=pos.x+7, y=pos.y+1}, force = "north"})
		turret4b.insert({name = bullet, count = count})
		local turret1c = surface.create_entity({name = "gun-turret", position = {x=pos.x-9, y=pos.y-2}, force = "north"})
		turret1c.insert({name = bullet, count = count})
		local turret2c = surface.create_entity({name = "gun-turret", position = {x=pos.x-9, y=pos.y+1}, force = "north"})
		turret2c.insert({name = bullet, count = count})
		local turret3c = surface.create_entity({name = "gun-turret", position = {x=pos.x+10, y=pos.y-2}, force = "north"})
		turret3c.insert({name = bullet, count = count})
		local turret4c = surface.create_entity({name = "gun-turret", position = {x=pos.x+10, y=pos.y+1}, force = "north"})
		turret4c.insert({name = bullet, count = count})
	
	end

	
end

--[[function Public.generate_spawn_goodies(surface)
	local tiles = surface.find_tiles_filtered({name = "stone-path"})
	table.shuffle_table(tiles)
	local budget = 1500
	local min_roll = 30
	local max_roll = 600
	local blacklist = {
		["automation-science-pack"] = true,
		["logistic-science-pack"] = true,
		["military-science-pack"] = true,
		["chemical-science-pack"] = true,
		["production-science-pack"] = true,
		["utility-science-pack"] = true,
		["space-science-pack"] = true,
		["loader"] = true,
		["fast-loader"] = true,
		["express-loader"] = true,		
	}
	local container_names = {"wooden-chest", "wooden-chest", "iron-chest"}
	for k, tile in pairs(tiles) do
		if budget <= 0 then return end
		if surface.can_place_entity({name = "wooden-chest", position = tile.position, force = "neutral"}) then
			local v = math_random(min_roll, max_roll)
			local item_stacks = LootRaffle.roll(v, 4, blacklist)		
			local container = surface.create_entity({name = container_names[math_random(1, 3)], position = tile.position, force = "neutral"})
			for _, item_stack in pairs(item_stacks) do container.insert(item_stack)	end
			budget = budget - v
		end
	end
end
]]

function Public.minable_wrecks(event)
	local entity = event.entity
	if not entity then return end
	if not entity.valid then return end
	if not valid_wrecks[entity.name] then return end
	
	local surface = entity.surface
	local player = game.players[event.player_index]
	
	
	-- EVL ONE MORE SCRAP MINED (for exports in main.lua)
	global.scraps_mined[player.force.name] = global.scraps_mined[player.force.name] + 1
	
	--[[ EVL NO MORE RANDOM IN SCRAPS
	local loot_worth = math_floor(math_abs(entity.position.x * 0.02)) + math_random(16, 32)	
	local blacklist = LootRaffle.get_tech_blacklist(math_abs(entity.position.x * 0.0001) + 0.10)
	for k, _ in pairs(loot_blacklist) do blacklist[k] = true end
	local item_stacks = LootRaffle.roll(loot_worth, math_random(1, 3), blacklist)

	for k, stack in pairs(item_stacks) do	
		local amount = stack.count
		local name = stack.name
		
		local inserted_count = player.insert({name = name, count = amount})	
		if inserted_count ~= amount then
			local amount_to_spill = amount - inserted_count			
			surface.spill_item_stack(entity.position, {name = name, count = amount_to_spill}, true)
		end
		
		surface.create_entity({
			name = "flying-text",
			position = {entity.position.x, entity.position.y - 0.5 * k},
			text = "+" .. amount .. " [img=item/" .. name .. "]",
			color = {r=0.98, g=0.66, b=0.22}
		})	
	end
	]]--
	local item_stacks = {
		['iron-plate'] = 5,
		['copper-plate'] = 2,
		['steel-plate'] = 1,
		['iron-gear-wheel'] = 2,
		['electronic-circuit'] = 2,
		['transport-belt'] = 3,
		['inserter'] = 1,
		['coal'] = 5,
		['stone'] = 5
	}
	--EVL flourish (we show scraps in 2 columns)
	local k=1
	local _text=""
	for _item,_qty in pairs(item_stacks) do	
		local inserted_count = player.insert({name = _item, count = _qty})	
		if inserted_count ~= _qty then
			local amount_to_spill = _qty - inserted_count			
			surface.spill_item_stack(entity.position, {name = _item, count = amount_to_spill}, true)
		end
		--EVL flourish (we show scraps in 2 columns)
		if k%2==0 then
			_text = _text.."     +" .. _qty .. " [img=item/" .. _item .. "]"
			surface.create_entity({
				name = "flying-text",
				position = {entity.position.x, entity.position.y - 0.5 * k},
				text = _text,
				color = {r=0.98, g=0.66, b=0.22}
			})
			_text=""
		else
			_text = _text.."+" .. _qty .. " [img=item/" .. _item .. "]"
		end
		k=k+1
	end
end

--Landfill Restriction
function Public.restrict_landfill(surface, inventory, tiles)
	for _, t in pairs(tiles) do
		local distance_to_center = math_sqrt(t.position.x ^ 2 + t.position.y ^ 2)
		local check_position = t.position
		if check_position.y > 0 then check_position = {x = check_position.x * -1, y = (check_position.y * -1) - 1} end
		if is_horizontal_border_river(check_position) or distance_to_center < spawn_circle_size then
			surface.set_tiles({{name = t.old_tile.name, position = t.position}}, true)
			inventory.insert({name = "landfill", count = 1})
			--EVL enough sound
		end
	end
end

function Public.deny_bot_landfill(event)
    Public.restrict_landfill(event.robot.surface, event.robot.get_inventory(defines.inventory.robot_cargo), event.tiles)
end

--Construction Robot Restriction
local robot_build_restriction = {
	["north"] = function(y)
		if y >= -10 then return true end
	end,
	["south"] = function(y)
		if y <= 10 then return true end
	end
}

function Public.deny_construction_bots(event)
	if not robot_build_restriction[event.robot.force.name] then return end
	if not robot_build_restriction[event.robot.force.name](event.created_entity.position.y) then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	game.print("Team " .. event.robot.force.name .. "'s construction drone had an accident.", {r = 200, g = 50, b = 100})
	event.created_entity.destroy()
end

--EVL CREATE AND FILL CHESTS ACCORDING TO global.pack_choosen
function Public.fill_starter_chests(surface)
	if global.pack_choosen=="" then game.print(">>>>> BUG, no pack found, cant fill the chests",{r = 255, g = 10, b = 10}) return end
	if global.match_running then game.print(">>>>> BUG, game has started, cant fill the chests",{r = 255, g = 10, b = 10}) return end
	local _pack_nb=string.sub(global.pack_choosen,6,8)
	local _pack_name=tables.packs_list[global.pack_choosen]["caption"]
	game.print(">>>>> Filling up chests for STARTER PACK#".._pack_nb.. " : " .._pack_name .." .",{r = 197, g = 197, b = 17})

	--EVL CHESTS--
	local _posX = 00
	local _posY = 40
	-- LEFT
	if global.packchest1N then global.packchest1N.destroy() end
	if global.packchest1S then global.packchest1S.destroy() end
	global.packchest1N = surface.create_entity({name = "steel-chest", position = {x=_posX-2, y=-_posY}, force = "north"})
	global.packchest1S = surface.create_entity({name = "steel-chest", position = {x=_posX-2, y=_posY-1}, force = "south"})
	for _item,_qty in pairs(tables.packs_contents[global.pack_choosen]["left"]) do
		global.packchest1N.insert({name=_item, count=_qty})
		global.packchest1S.insert({name=_item, count=_qty})
	end
	-- CENTER
	if global.packchest2N then global.packchest2N.destroy() end
	if global.packchest2S then global.packchest2S.destroy() end
	global.packchest2N = surface.create_entity({name = "steel-chest", position = {x=_posX, y=-_posY}, force = "north"})
	global.packchest2S = surface.create_entity({name = "steel-chest", position = {x=_posX, y=_posY-1}, force = "south"})
	for _item,_qty in pairs(tables.packs_contents[global.pack_choosen]["center"]) do
		global.packchest2N.insert({name=_item, count=_qty})
		global.packchest2S.insert({name=_item, count=_qty})
	end
	-- RIGHT
	if global.packchest3N then global.packchest3N.destroy() end
	if global.packchest3S then global.packchest3S.destroy() end
	global.packchest3N = surface.create_entity({name = "steel-chest", position = {x=_posX+2, y=-_posY}, force = "north"})
	global.packchest3S = surface.create_entity({name = "steel-chest", position = {x=_posX+2, y=_posY-1}, force = "south"})
	for _item,_qty in pairs(tables.packs_contents[global.pack_choosen]["right"]) do
		global.packchest3N.insert({name=_item, count=_qty})
		global.packchest3S.insert({name=_item, count=_qty})
	end
	--WE GIVE FREE TECHNO FOR SOME PACK
	if global.pack_choosen == "pack_03" then --Pack Robots
		game.forces["south"].technologies['worker-robots-speed-1'].researched=true
		game.forces["south"].technologies['worker-robots-speed-2'].researched=true
		game.forces["north"].technologies['worker-robots-speed-1'].researched=true
		game.forces["north"].technologies['worker-robots-speed-2'].researched=true
		game.print(">>>>> Both teams have been granted Worker robot speed 1 & 2 technologies (since Robots Pack has been chosen).",{r = 197, g = 197, b = 17}) 
	else
		if game.forces["south"].technologies['worker-robots-speed-1'].researched then
			game.forces["south"].technologies['worker-robots-speed-1'].researched=false
			game.forces["south"].technologies['worker-robots-speed-2'].researched=false
			game.forces["north"].technologies['worker-robots-speed-1'].researched=false
			game.forces["north"].technologies['worker-robots-speed-2'].researched=false
			game.print(">>>>> Worker robot speed 1 & 2 technologies have been removed.",{r = 197, g = 197, b = 17}) 
		end
	end	
	global.fill_starter_chests = false
	global.starter_chests_are_filled = true
end

--EVL REATE AND FILL CHESTS WITH INVENTORY OF DISCONNECTED PLAYER (see team_manager)
local disco_chests_positionx={0,-1,1,-2,2,-3,3,-4,4}
function Public.fill_disconnected_chests(surface, force_name, inventory, info)
	if table_size(inventory)==0 then
		if global.bb_debug_gui then game.print("Debug: <<fill_disconnected_chests>> called witgh inventory empty. Skipping.",{r = 197, g = 197, b = 17}) end
	end
	if global.bb_debug_gui then game.print(">>>>> Filling up chests with "..info.." with "..table_size(inventory).." items.",{r = 197, g = 197, b = 17}) end
	if not(force_name=="north" or force_name=="south") then
		if global.bb_debug_gui then game.print("Debug: <<fill_disconnected_chests>> called with wrong force ("..force_name.."). Skip.",{r = 197, g = 11, b = 11}) end
		return
	end
	--EVL CHESTS--
	local _posY = -36
	if force_name=="south" then _posY = 35 end
	--global.disco_chests={["north"]={},["south"]={}} (in init.lua)
	--Get back inventories of disco chest (if any)
	local chests_inventory={}
	for _index,chest in pairs(global.disco_chests[force_name]) do
		local this_chest_inv=chest.get_inventory(defines.inventory.chest).get_contents()
		if table_size(this_chest_inv)>0 then
			for _item,_qty in pairs(this_chest_inv) do
				if chests_inventory[_item] then 
					chests_inventory[_item]=chests_inventory[_item]+_qty
				else
					chests_inventory[_item]=_qty
				end
			end
		end
		global.disco_chests[force_name][_index].destroy()
		global.disco_chests[force_name][_index]=nil
	end
	if global.bb_debug_gui then 
		game.print("Debug: Got "..table_size(chests_inventory).." different items from chests, "..force_name.." has "..table_size(global.disco_chests[force_name]).." chests left (should be 0)",{r = 197, g = 11, b = 11})
	end
	
	--Nothing in chests and nothing in inventory -> return
	if table_size(chests_inventory)==0 and table_size(inventory)==0 then
		if global.bb_debug_gui then game.print("Debug: Nothing to move, skip procedure.",{r = 197, g = 197, b = 17}) end --REMOVE--
		return
	end

	--Init : create indexes and first chest
	local chest_index=1
	local this_stack_chest=1--48 slots in each steel chest
	surface.set_tiles({{name = "landfill", position = {x=disco_chests_positionx[chest_index], y=_posY}}}, true)
	local fill_this_chest = surface.create_entity({name = "steel-chest", position = {x=disco_chests_positionx[chest_index], y=_posY}, force = force_name})
	fill_this_chest.destructible=false
	fill_this_chest.minable=false

	global.disco_chests[force_name][chest_index]=fill_this_chest

	--Refill disco_chests (before translocatind inventory)
	if table_size(chests_inventory)>0 then	
		for _item,_qty in pairs(chests_inventory) do
			--game.print("item:".._item.."=".._qty) --REMOVE--
			local _item_stack=game.item_prototypes[_item].stack_size
			local this_qtity=_qty
			--local this_str=_item.."(qtity=".._qty..") divided in stacks : " --REMOVE--
			while this_qtity>0 do
				if this_qtity>_item_stack then
					--this_str=this_str.._item_stack..", " --REMOVE--
					--add one stack
					fill_this_chest.insert({name=_item, count=_item_stack})
					this_stack_chest=this_stack_chest+1
					this_qtity=this_qtity-_item_stack
				else
					--this_str=this_str.._item_stack.."." --REMOVE--
					--add remain
					fill_this_chest.insert({name=_item, count=this_qtity})
					this_stack_chest=this_stack_chest+1
					this_qtity=0
				end
				--game.print(this_stack_chest)--REMOVE--
				if this_stack_chest==49 then --Chest is full!
					--game.print("disco_chests: chest#"..chest_index.." is full, creating chest#"..(chest_index+1))
					chest_index=chest_index+1
					if chest_index>table_size(disco_chests_positionx) then
						game.print(">>>>> Sorry "..force_name..", not enough room to relocate all item (from chests)...",{r = 197, g = 197, b = 17}) --EVL Should not happen (nonsense)
						game.play_sound{path = global.sound_error, volume_modifier = 0.8}
						return
					end					
					surface.set_tiles({{name = "landfill", position = {x=disco_chests_positionx[chest_index], y=_posY}}}, true)
					fill_this_chest = surface.create_entity({name = "steel-chest", position = {x=disco_chests_positionx[chest_index], y=_posY}, force = force_name})
					fill_this_chest.destructible=false
					fill_this_chest.minable=false
					global.disco_chests[force_name][chest_index]=fill_this_chest				
					--game.print(this_str.."\n Chest is full,  next chest...") --REMOVE--
					--this_str=_item.."(qtity left="..this_qtity..") divided in stacks : " --REMOVE--
				end
			end	 --while
			--game.print(this_str) --REMOVE--
		end	 --for
	else
		--game.print("Nothing in disco chests at the moment.") --REMOVE--
	end
	--End of refill
	--game.print("Relocating inventory in disco chests.") --REMOVE--
	--Translocating Inventory
	if table_size(inventory)>0 then
		--game.print("Got "..table_size(inventory).." different items to relocate,"..force_name.." has "..table_size(global.disco_chests[force_name]).." chests")
		for _item,_qty in pairs(inventory) do
			--game.print("item:".._item.."=".._qty) --REMOVE--
			local _item_stack=game.item_prototypes[_item].stack_size
			local this_qtity=_qty
			--local this_str=_item.."(qtity=".._qty..") divided in stacks : " --REMOVE--
			while this_qtity>0 do
				--this_str=this_str.._item_stack.."." --REMOVE--
				if this_qtity>_item_stack then
					--add one stack
					fill_this_chest.insert({name=_item, count=_item_stack})
					this_stack_chest=this_stack_chest+1
					this_qtity=this_qtity-_item_stack
				else
					--add remain
					fill_this_chest.insert({name=_item, count=this_qtity})
					this_stack_chest=this_stack_chest+1
					this_qtity=0
				end
				--game.print(this_stack_chest)--REMOVE--
				if this_stack_chest>48 then --Chest is full!
					--game.print("inventory: chest#"..chest_index.." is full, creating chest#"..(chest_index+1))
					chest_index=chest_index+1
					if chest_index>table_size(disco_chests_positionx) then
						game.print(">>>>> Sorry "..force_name..", not enough room to relocate all inventory...",{r = 197, g = 197, b = 17})
						game.play_sound{path = global.sound_error, volume_modifier = 0.8}
						return
					end
					surface.set_tiles({{name = "landfill", position = {x=disco_chests_positionx[chest_index], y=_posY}}}, true)
					fill_this_chest = surface.create_entity({name = "steel-chest", position = {x=disco_chests_positionx[chest_index], y=_posY}, force = force_name})
					fill_this_chest.destructible=false
					fill_this_chest.minable=false
					global.disco_chests[force_name][chest_index]=fill_this_chest	
					this_stack_chest=1
					--game.print(this_str.."\n Chest is full,  next chest...") --REMOVE--
					--this_str=_item.."(qtity left="..this_qtity..") divided in stacks : " --REMOVE--
				end
			end	 --while
			--game.print(this_str) --REMOVE--
		end --for
	else
		if global.bb_debug_gui then game.print("Debug: <<fill_disconnected_chests>> Inventory is empty, nothing to relocate.",{r = 197, g = 197, b = 17}) end--REMOVE--
	end	
	game.print(">>>>> Inventory has been relocated into chests.",{r = 197, g = 197, b = 17}) --REMOVE--
	game.play_sound{path = global.sound_success, volume_modifier = 0.8}
end


return Public
