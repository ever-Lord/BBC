--BITER BATTLES CONFIG--

local bb_config = {
	--Optional custom team names, can also/should be modified via "Team Manager"
	["north_side_team_name"] = "Team North",
	["south_side_team_name"] = "Team South",

	--TERRAIN OPTIONS--
	["border_river_width"] = 44, --EVL no PvP at all	--Approximate width of the horizontal impassable river separating the teams. (values up to 100)
	["spawn_circle_size"] = 39, -- 39 --EVL SIZE OF LAKE (within the islanc)
	["spawn_island_size"] = 9.5, -- 9.5 --EVL SIZE OF THE ISLAND
	["spawn_manager_pos"] = 18, -- 18 --EVL Spots for managers, must be between (spawn_island_size plus something) and (border_river_width/2)
	["spawn_wall_radius"] = 116, --EVL SIZE OF THE SPAWN


	["builders_area"] = true,	--Grant each side a peaceful direction with no nests and biters?
	["random_scrap"] = true,		--Generate harvestable scrap around worms randomly?

	--BITER SETTINGS--
	["max_active_biters"] = 2048,	--Maximum total amount of attacking units per side.
	["max_group_size"] = 420,		--Maximum unit group size.
	["biter_timeout"] = 108000,		--Time it takes in ticks for an attacking unit to be deleted. This prevents permanent stuck units.
										-- EVL  Was 162000 (45min), SET to 108000 (30min),FreeBB is 5min woot :)
	["bitera_area_distance"] = 512	--Distance to the biter area.
}

return bb_config
