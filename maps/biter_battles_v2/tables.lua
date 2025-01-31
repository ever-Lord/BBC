local Public = {}

-- List of forces that will be affected by ammo modifier
Public.ammo_modified_forces_list = {"north", "south", "spectator"}

-- Ammo modifiers via set_ammo_damage_modifier
-- [ammo_category] = value
-- ammo_modifier_dmg = base_damage * base_ammo_modifiers
-- damage = base_damage + ammo_modifier_dmg
Public.base_ammo_modifiers = {
	["bullet"] = 0.16,
	["shotgun-shell"] = 1,
	["flamethrower"] = -0.6,
	["landmine"] = -0.9
}

-- turret attack modifier via set_turret_attack_modifier
Public.base_turret_attack_modifiers = {
	["flamethrower-turret"] = -0.8,
	["laser-turret"] = 0.0
}

Public.upgrade_modifiers = {
	["flamethrower"] = 0.02,
	["flamethrower-turret"] = 0.02,
	["laser-turret"] = 0.3,
	["shotgun-shell"] = 0.6,
	["grenade"] = 0.48,
	["landmine"] = 0.04
}

Public.food_values = {
	["automation-science-pack"] =		{value = 0.0010, name = "automation science", color = "255, 50, 50"},
	["logistic-science-pack"] =		{value = 0.0025, name = "logistic science", color = "50, 255, 50"},
	["military-science-pack"] =		{value = 0.0080, name = "military science", color = "105, 105, 105"},
	["chemical-science-pack"] = 		{value = 0.0225, name = "chemical science", color = "100, 200, 255"},
	["production-science-pack"] =		{value = 0.1050, name = "production science", color = "150, 25, 255"},
	["utility-science-pack"] =		{value = 0.1200, name = "utility science", color = "210, 210, 60"},
	["space-science-pack"] = 		{value = 0.5000, name = "space science", color = "255, 255, 255"},
}

Public.gui_foods = {}
for k, v in pairs(Public.food_values) do
	Public.gui_foods[k] = math.floor(v.value * 10000) .. " Mutagen strength"
end
Public.gui_foods["raw-fish"] = "Send a fish to spy for 45 seconds.\nLeft Mouse Button: Send one fish.\nRMB: Sends 5 fish.\nShift+LMB: Send all fish.\nShift+RMB: Send half of all fish."

Public.force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

Public.enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

Public.wait_messages = {
	"Once upon a dreary night...",
	"Nevermore.",
	"go and grab a drink.",
	"take a short healthy break.",
	"go and stretch your legs.",
	"please pet the cat.",
	"time to get a bowl of snacks :3",
}

Public.food_names = {
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true,
	["production-science-pack"] = true,
	["utility-science-pack"] = true,
	["space-science-pack"] = true
}

Public.food_long_and_short = {
	[1] = {short_name= "automation", long_name = "automation-science-pack"},
	[2] = {short_name= "logistic", long_name = "logistic-science-pack"},
	[3] = {short_name= "military", long_name = "military-science-pack"},
	[4] = {short_name= "chemical", long_name = "chemical-science-pack"},
	[5] = {short_name= "production", long_name = "production-science-pack"},
	[6] = {short_name= "utility", long_name = "utility-science-pack"},
	[7] = {short_name= "space", long_name = "space-science-pack"}
}

Public.food_long_to_short = {
	["automation-science-pack"] = {short_name= "automation", indexScience = 1},
	["logistic-science-pack"] = {short_name= "logistic", indexScience = 2},
	["military-science-pack"] = {short_name= "military", indexScience = 3},
	["chemical-science-pack"] = {short_name= "chemical", indexScience = 4},
	["production-science-pack"] = {short_name= "production", indexScience = 5},
	["utility-science-pack"] = {short_name= "utility", indexScience = 6},
	["space-science-pack"] = {short_name= "space", indexScience = 7}
}
Public.food_short_to_long = {
	["automation"] = "automation-science-pack",
	["logistic"] = "logistic-science-pack",
	["military"] = "military-science-pack",
	["chemical"] = "chemical-science-pack",
	["production"] = "production-science-pack",
	["utility"] = "utility-science-pack",
	["space"] = "space-science-pack"
}
--EVL config training tables of science/qtity/timing for drop-down (see team_manager)
Public.food_config_training = { 
	"[color=#444444]Select science pack[/color]",
	"[color=#880000]  none (off)[/color]",
	"[item=automation-science-pack]   Automation", 
	"[item=logistic-science-pack]   Logistic",
	"[item=military-science-pack]   Military",
	"[item=chemical-science-pack]   Chemical",
	"[item=production-science-pack]   Production",
	"[item=utility-science-pack]   Utility",
	"[item=space-science-pack]   Space" 
}
Public.qtity_config_training = {
	"[color=#444444]select quantity[/color]",
	"[color=#880000]none (off)[/color]",
	10,
	25,
	50,
	75,
	100,
	150,
	200,
	300,
	500,
}
Public.timing_config_training = {
	"[color=#444444]select frequency[/color]",
	"[color=#880000]never (off)[/color]",
	"  1 min",
	"  2 min",
	"  3 min",
	"  4 min",
	"  5 min",
	"  6 min",
	"  7 min",
	"  8 min",
	"  9 min",
	"10 min",
}
Public.waves_config_training = {
	" [color=#880000]off (random)[/color]",
	" 0 (no attack)",
	" 1 group",
	" 2 groups",
	" 3 groups",
	" 4 groups",
	" 5 groups",
	" 6 groups",
	" 7 (maximum)"
}
--EVL end

-- This array contains parameters for spawn area ore patches.
-- These are non-standard units and they do not map to values used in factorio
-- map generation. They are only used internally by scenario logic.
Public.spawn_ore = {
	-- Value "size" is a parameter used as coefficient for simplex noise
	-- function that is applied to shape of an ore patch. You can think of it
	-- as size of a patch on average. Recomended range is from 1 up to 50.

	-- Value "density" controls the amount of resource in a single tile.
	-- The center of an ore patch contains specified amount and is decreased
	-- proportionally to distance from center of the patch.

	-- Value "big_patches" and "small_patches" represents a number of an ore
	-- patches of given type. The "density" is applied with the same rule
	-- regardless of the patch size.
	--[[ freeBB values
	["iron-ore"] = {
		size = 23,
		density = 3500,
		big_patches = 2,
		small_patches = 1
	},
	["copper-ore"] = {
		size = 21,
		density = 3000,
		big_patches = 1,
		small_patches = 2
	},
	["coal"] = {
		size = 22,
		density = 2500,
		big_patches = 1,
		small_patches = 1
	},
	["stone"] = {
		size = 20,
		density = 2000,
		big_patches = 1,
		small_patches = 0
	}
	--]]
	--BBC Values
	["iron-ore"] = {
		size = 18,
		density = 1500,
		big_patches = 2,
		small_patches = 1
	},
	["copper-ore"] = {
		size = 16,
		density = 1250,
		big_patches = 1,
		small_patches = 2
	},
	["coal"] = {
		size = 17,
		density = 1250,
		big_patches = 1,
		small_patches = 1
	},
	["stone"] = {
		size = 15,
		density = 1000,
		big_patches = 1,
		small_patches = 0
	}
}

Public.forces_list = { "all teams", "north", "south" }
Public.science_list = { "all science", "very high tier (space, utility, production)", "high tier (space, utility, production, chemical)", "mid+ tier (space, utility, production, chemical, military)","space","utility","production","chemical","military", "logistic", "automation" }
Public.evofilter_list = { "all evo jump", "no 0 evo jump", "10+ only","5+ only","4+ only","3+ only","2+ only","1+ only" }
Public.food_value_table_version = { 
	Public.food_values["automation-science-pack"].value,
	Public.food_values["logistic-science-pack"].value,
	Public.food_values["military-science-pack"].value,
	Public.food_values["chemical-science-pack"].value,
	Public.food_values["production-science-pack"].value,
	Public.food_values["utility-science-pack"].value,
	Public.food_values["space-science-pack"].value
}

--EVL Trees
Public.trees={"tree-01","tree-02","tree-02-red","tree-03","tree-04","tree-05","tree-06","tree-06-brown","tree-07","tree-08","tree-08-brown","tree-08-red","tree-09","tree-09-brown","tree-09-red"}

-- EVL PACKS LIST
Public.packs_list = {
	["pack_01"] = {name = "pack_01", title = "Regular", button="[img=item.iron-gear-wheel]", caption = "[img=item.iron-gear-wheel] Regular", tooltip = "Raw materials, free for crafting", item_list=nil },
	["pack_02"] = {name = "pack_02", title = "Science", button="[img=item.lab]", caption = "[img=item.lab] Science", tooltip = "Labs, red potions & power", item_list=nil },
	["pack_03"] = {name = "pack_03", title = "Robots", button="[img=item.construction-robot]", caption = "[img=item.construction-robot] Robots", tooltip = "One personal robotport", item_list=nil }, -- THIS PACK HAS BONUS (bot speed x2) -see terrain.lua-
	["pack_04"] = {name = "pack_04", title = "Combat", button="[img=item.grenade]", caption = "[img=item.grenade] Combat", tooltip = "One heavy armor, fishes, grenades...", item_list=nil } --,
	--["pack_05"] = {name = "pack_05", title = "Advanced", caption = "[img=item.assembling-machine-2] Advanced", tooltip = "Electric miners & machines MK2", item_list=nil }
}
Public.packs_total_nb = table_size(Public.packs_list)
	
Public.packs_contents= {
	["pack_01"] =  --REGULAR
		{
			["left"] = {
				["raw-fish"]=10,
				["burner-mining-drill"]=15,
				["stone-furnace"]=15,
				["iron-ore"]=100,
				["iron-plate"]=900,
				["copper-plate"]=100,
				["coal"]=150,
				["iron-gear-wheel"]=400,
				["electronic-circuit"]=300,
				["small-electric-pole"]=20,
				["pistol"]=1,
				["firearm-magazine"]=10
				
			},
			["center"] = {
				["raw-fish"]=10,
				["burner-mining-drill"]=15,
				["stone-furnace"]=15,
				["iron-ore"]=100,
				["iron-plate"]=900,
				["copper-plate"]=100,
				["coal"]=150,
				["iron-gear-wheel"]=300,
				["electronic-circuit"]=200,
				["small-electric-pole"]=15,
				["pistol"]=1,
				["firearm-magazine"]=10
				
			},
			["right"] = {
				["raw-fish"]=10,
				["burner-mining-drill"]=15,
				["stone-furnace"]=30,
				["iron-ore"]=800,
				["iron-plate"]=200,
				["copper-plate"]=50,
				["coal"]=200,
				["pipe"]=100,
				["iron-gear-wheel"]=300,
				["electronic-circuit"]=200,
				["small-electric-pole"]=15,
				["pistol"]=1,
				["firearm-magazine"]=10
			}
		},
	["pack_02"] =  --SCIENCE
		{--Z-EM VARIATION
			["left"] = {
				["raw-fish"]=15,
				["burner-mining-drill"]=20,				
				["stone-furnace"]=20,
				["small-electric-pole"]=30,
				["transport-belt"]=100,
				["inserter"]=60,
				["assembling-machine-1"]=15,
				["lab"]=20,
				["automation-science-pack"]=50, --was 50
				--["logistic-science-pack"]=10, --EVL for testing 
				--["military-science-pack"]=20,
				--["chemical-science-pack"]=30,
				--["production-science-pack"]=40,
				--["utility-science-pack"]=50,
				--["space-science-pack"]=1000, --EVL for testing
				["pistol"]=1,
				["firearm-magazine"]=10
			},
			["center"] = {
				["raw-fish"]=15,
				["burner-mining-drill"]=30,
				["stone-furnace"]=30,
				["small-electric-pole"]=40,
				["transport-belt"]=50,
				["inserter"]=40,
				["underground-belt"]=4,
				["splitter"]=2,
				["assembling-machine-1"]=15,
				["pistol"]=1,
				["firearm-magazine"]=10
			},
			["right"] = {
				["raw-fish"]=20,
				["burner-mining-drill"]=30,
				["stone-furnace"]=30,
				["small-electric-pole"]=30,				
				["transport-belt"]=50,
				["inserter"]=40,
				["underground-belt"]=4,
				["splitter"]=2,
				["assembling-machine-2"]=20,
				["solar-panel"]=20,
				["pistol"]=1,
				["firearm-magazine"]=10
			}
		},
	["pack_03"] =  --ROBOTS
		{
			["left"] = {
				["burner-mining-drill"]=10,
				["stone-furnace"]=10,
				["iron-plate"]=100,
				["copper-plate"]=50,
				["coal"]=30,
				["iron-gear-wheel"]=10,
				["lab"]=1,
				["pistol"]=1,
				["firearm-magazine"]=40
			},
			["center"] = {
				["burner-mining-drill"]=10,
				["iron-plate"]=50,
				["coal"]=40,
				["pipe"]=10,
				["pipe-to-ground"]=2,
				["iron-gear-wheel"]=10,
				["burner-inserter"]=1,
				["boiler"]=1,
				["offshore-pump"]=1,
				["steam-engine"]=1,
				["small-electric-pole"]=2,
				["pistol"]=1,
				["firearm-magazine"]=40
			},
			["right"] = {
				["burner-mining-drill"]=20,
				["stone-furnace"]=20,
				["iron-plate"]=50,
				["coal"]=30,
				["iron-gear-wheel"]=10,
				["pistol"]=1,
				["firearm-magazine"]=20,
				
				["modular-armor"]=1, --EVL for testing --CODING--
				--["power-armor"]=2, --EVL for testing
				--["power-armor-mk2"]=2, --EVL for testing
				["solar-panel-equipment"]=10,
				["battery-equipment"]=1,
				["personal-roboport-equipment"]=1,
				["construction-robot"]=10
			}
		},	
	["pack_04"] =  -- COMBAT
		{ --Z-EM VARIATION
			["left"] = {
				["raw-fish"]=50,
				["burner-mining-drill"]=20,
				["stone-furnace"]=20,
				["iron-plate"]=50, --CODING--
				--["iron-plate"]=500,
				["copper-plate"]=50, --CODING--
				--["copper-plate"]=500,
				["coal"]=50,
				["stone-brick"]=100,
				["iron-gear-wheel"]=15,
				["small-electric-pole"]=5,
				["gun-turret"]=4,
				["firearm-magazine"]=100,
				["shotgun"]=1,
				["shotgun-shell"]=10,
				["light-armor"]=1,
				["radar"]=1,
				["grenade"]=10
			},
			["center"] = {
				["raw-fish"]=50,
				["burner-mining-drill"]=10,
				["iron-plate"]=50,
				["coal"]=50,
				["stone-brick"]=100,
				["iron-gear-wheel"]=15,
				["small-electric-pole"]=10,
				["gun-turret"]=4,
				["firearm-magazine"]=100,
				["submachine-gun"]=1,
				["piercing-rounds-magazine"]=50,
				["light-armor"]=1,
				["radar"]=1,
				["grenade"]=10
			},
			["right"] = {
				["raw-fish"]=100,
				["iron-plate"]=50,
				["stone-brick"]=400,
				["small-electric-pole"]=5,
				["repair-pack"]=10,
				["inserter"]=16,
				["solar-panel"]=1,
				["gun-turret"]=10,
				["firearm-magazine"]=220,
				["shotgun"]=1,
				["shotgun-shell"]=10,
				["heavy-armor"]=1,
				["radar"]=1,				
				--["power-armor-mk2"]=1,  --EVL for testing 
				--["fusion-reactor-equipment"]=2,
				---["exoskeleton-equipment"]=2,
				--["energy-shield-mk2-equipment"]=5,
				--["battery-mk2-equipment"]=2,
				--["personal-laser-defense-equipment"]=7, --EVL for testing 
				["stone-wall"]=120,				
				["grenade"]=30
			}
		}
	--[[["pack_05"] = 
		{
			["left"] = {
				["raw-fish"]=10,
				["burner-mining-drill"]=20,	
				["stone-furnace"]=20,
				["small-electric-pole"]=10,
				["inserter"]=10,
				["fast-inserter"]=15,
				["pipe"]=90,
				["pipe-to-ground"]=20,
				["pumpjack"]=4,
				["oil-refinery"]=2,
				["chemical-plant"]=3,
				["assembling-machine-2"]=10,
				["pistol"]=1,
				["firearm-magazine"]=30,
				["car"]=1
			},
			["center"] = {
				["raw-fish"]=20,
				["boiler"]=5,
				["offshore-pump"]=1,
				["steam-engine"]=10,
				["pipe"]=10,
				["burner-inserter"]=5,
				["small-electric-pole"]=20,
				["electric-mining-drill"]=15,
				["transport-belt"]=40,
				["inserter"]=10,
				["fast-inserter"]=20,
				["underground-belt"]=5,
				["splitter"]=5,
				["assembling-machine-2"]=20,
				["pistol"]=1,
				["firearm-magazine"]=30
			},
			["right"] = {
				["raw-fish"]=20,
				["burner-mining-drill"]=10,	
				["small-electric-pole"]=20,
				["electric-mining-drill"]=30,
				["transport-belt"]=60,
				["inserter"]=30,
				["fast-inserter"]=15,				
				["underground-belt"]=5,
				["splitter"]=5,
				["assembling-machine-2"]=20,
				["pistol"]=1,
				["firearm-magazine"]=30
			}
		}]]--		
	}	
Public.packs_item_value = {
	["raw-fish"]=1.4,
	["lab"]=73.0,
	["automation-science-pack"]=8.5,
	["logistic-science-pack"]=8.5*2.5, --EVL for testing 
	["military-science-pack"]=8.5*8,
	["chemical-science-pack"]=8.5*22.5,
	["production-science-pack"]=8.5*105,
	["utility-science-pack"]=8.5*120,
	["space-science-pack"]=8.5*500, --EVL for testing
	["electric-mining-drill"]=35.7,
	["burner-mining-drill"]=18.0,
	["repair-pack"]=13.0,
	["boiler"]=12.0,
	["offshore-pump"]=12.0,
	["steam-engine"]=38,
	["stone-furnace"]=5.5,
	["iron-gear-wheel"]=2.5,
	["electronic-circuit"]=5.2,
	["inserter"]=7.7,
	["burner-inserter"]=4.0,
	["fast-inserter"]=17.7,
	["transport-belt"]=2.0,
	["underground-belt"]=21.0,
	["splitter"]=32.7,
	["small-electric-pole"]=1.5,
	["stone-brick"]=2.0,
	["pipe-to-ground"]=10.25,
	["pipe"]=1.5,
	["storage-tank"]=48.0,
	["iron-ore"]=0.5,
	["coal"]=1.0,
	["iron-plate"]=1.0,
	["copper-plate"]=1.0,	
	["assembling-machine-1"]=33.2,	
	["gun-turret"]=63.0,
	["stone-wall"]=10.5,
	["light-armor"]=43.0,
	["radar"]=41.7,
	["pistol"]=15.0,
	["submachine-gun"]=50.0,
	["shotgun"]=53.0,
	["firearm-magazine"]=5.0,
	["piercing-rounds-magazine"]=17.0,
	["shotgun-shell"]=7.0,
	["heavy-armor"]=358.0,
	["grenade"]=23.0,
	["assembling-machine-2"]=67.4,
	["pumpjack"]=88.5,
	["oil-refinery"]=181.0,
	["chemical-plant"]=68.5,
	["modular-armor"]=1105.0,
	["solar-panel"]=96.5,
	["solar-panel-equipment"]=187.5,
	["battery-equipment"]=390.0,
	["personal-roboport-equipment"]=3450.0,
	["car"]=215.0,
	["construction-robot"]=139.3,
	["power-armor-mk2"]=9999, --EVL for testing, values tbd
	["fusion-reactor-equipment"]=999,
	["exoskeleton-equipment"]=999,
	["energy-shield-mk2-equipment"]=999,
	["battery-mk2-equipment"]=999,
	["personal-laser-defense-equipment"]=999,
	["landfill"]=999, 
	["concrete"]=999,
	["refined-concrete"]=999,
	["hazard-concrete"]=999,
	["refined-hazard-concrete"]=999,
	["modular-armor"]=2, 
	["power-armor"]=2, 
	["power-armor-mk2"]=2 --EVL for testing end

}		
--EVL FIN

Public.compi={
	["names"]={"Charlie the compi","Larry the compi","Larry the compi","Leon the compilatron","Gaston the compilatron"},
	["welcome"]={"Welcome guys!","Hey you ! Welcome on my island !","Welcome visitors !","I bet one silo will vanish !","Trees are my friend, I can't let you harm them !",
				"Clever people don't go around in circles !", "Smart people don't go around in circles !", "Streamers that are not playing BBChampions are weak !", "Streamers that are not playing BBChampions are fragile !"},--feeble
	["revenges"]={"Stop bullying me!","Stop bugging me!","Stop bothering me!","You pissed me off","Bunch of idiots"},
	["taunts"]={"Ha Ha !","My sincere condolences to your family.","My deepest sympathy and prayers are being sent your way.","Praying for peace that passes understanding to settle in your hearts.","Your soul will live on in my heart.","With love and friendship, i am sharing in your sorrow.","It doesn’t matter who you were; it matters who I remember you were.","The pain passes, but the beauty remains.","Please tell me what I can do for you.","I know that you went through a lot and fought so hard. Your journey here has ended.","I will  light a candle.","Did you underestimate me ?","Maybe you tried to give me a hug ?"}
	
}

--EVL MAXIMS--
Public.maxim_players = {

	["20"]="tbd",
	["99joneg"]="tbd",
	["anb505"]="tbd",
	["AntiElitz"]="tbd",
	["Antipatience"]="I'm here for a good time, not a bad time",
	["bev"]="tbd",
	["bits-orio"]="tbd",
	["bloke14"]="tbd",
	["BumbleBeeeRider"]="Its me Again.",
	["Castinar"]="tbd",
	["Clutch331"]="tbd",
	["Cobai"]="tbd",
	["DaarkToM"]="tbd",
	["Ermite"]="tbd",
	["everLord"]="Crusty bread is for those who know how to look for it.",
	["Firerazer"]="What are we escaping from?",
	["Gamemodefr"]="tbd",
	["Grob."]="Parce que le dire, c'est bien, mais le fer, c'est mieux...",
	["heihaa"]="tbd",
	["Keithy1980"]="BRAIIIIIIIIIIIINS",
	["kenOger"]="tbd",
	["KlingonIAG"]="Ce n'est pas un bon jour pour mourir! Quelle odeur!?",
	["Kohonen"]="tbd",
	["Krono"]="tbd",
	["Lumis31"]="tbd",
	["Megafrot"]="Metafrog, Megafort, Megarofl? Megafrot!",
	["Monkey Butt Gamer"]="tbd",
	["mysticamber"]="tbd",
	["Nefa35"]="tbd",
	["Nefrums"]="tbd",
	["ness056"]="tbd",
	["neuro666"]="tbd",
	["Phoenix27833"]="tbd",
	["pompouspercival"]="tbd",
	["PunkSkeleton"]="Never imitate others, always find your own way.",
	["RoronoaJedi"]="tbd",
	["Slapocreeper"]="schmoovin' n' groovin'",
	["thePiedPiper"]="tbd",
	["Timin8ore"]="tbd",
	["typical_guy"]="tbd",
	["Ugh"]="The biter population must shrink!",
	["UnknownMurder"]="tbd",
	["VorceShard"]="tbd",
	["Warger"]="tbd",
	["WavePusher"]="tbd",
	["Wibbert"]="tbd",
	["XenoCyber"]="tbd",
	["ximoltus"]="tbd",
	["z-em"]="Mixed enthousiast",
	["Zaspar"]="tbd",
	["zebrajaeger"]="tbd"

}
Public.maxim_teams = {
	["Baguette"]="Who gives the bread lays down the authority.",
	["Burner City"]="tbd",
	["C4"]="The early bird catches the worm.",
	["Croissant"]="T'as la rondeur d'un croissant au beurre.",
	["Fromage"]="tbd",
	["Green Science Dutch"]="De fabriek moet groeien",
	["MysticlutchPipenator"]="tbd",
	["SteelAxe"]="Praise the Steelaxe",
	["Steelaxe Mafia"]="What Iron? I didn't take any Iron!",
	["Team of Misfits"]="tbd",
	["The Old Guard"]="Play to win, not to not lose.",
	["Zombie Horde"]="tbd"
}
--EVL FIN
--EVL TEAM LOGOS
Public.logo_teams = {
	["North"]="north.png",
	["north"]="north.png",
	["South"]="south.png",
	["south"]="south.png",
	["Baguette"]="baguette.png",
	["Burner City"]="burnercity.png",
	["C4"]="c4.png",
	["Croissant"]="croissant.png",
	["Fromage"]="fromage.png",
	["Green Science Dutch"]="gsd.png",
	["MysticlutchPipenator"]="mcp.png",
	["SteelAxe"]="steelaxe.png",
	["Steelaxe Mafia"]="steelaxemafia.png",
	["The Old Guard"]="theoldguard.png",
	["Zombie Horde"]="zombiehorde.png"
}
--EVL FIN


return Public
