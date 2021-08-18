--BITER BATTLES CONFIG--

local bb_config = {
	--Optional custom team names, can also be modified via "Team Manager"
	["north_side_team_name"] = "Team North",
	["south_side_team_name"] = "Team South",

	--TERRAIN OPTIONS--
	["border_river_width"] = 44, --EVL no PvP at all	--Approximate width of the horizontal impassable river separating the teams. (values up to 100)
	["builders_area"] = true,							--Grant each side a peaceful direction with no nests and biters?
	["random_scrap"] = true,							--Generate harvestable scrap around worms randomly?

	--BITER SETTINGS--
	["max_active_biters"] = 2048,					--Maximum total amount of attacking units per side.
	["max_group_size"] = 420,							--Maximum unit group size.
	["biter_timeout"] = 108000,						--Time it takes in ticks for an attacking unit to be deleted. This prevents permanent stuck units.
														-- EVL  Was 162000 (45min), SET to 108000 (30min)
	["bitera_area_distance"] = 512					--Distance to the biter area.
}

return bb_config
