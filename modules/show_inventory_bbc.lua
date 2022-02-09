local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Functions = require "maps.biter_battles_v2.functions" --EVL (none) used to find real number of players (ie removing manager if global.managers_in_team=true)
local Public = {}

global.sorting_inventory={ --Sorting important/primordial items in inventories (so they dont go in tooltip or too far in the list)
	--Actually this table reached the max #items (column*2-1=19)
	["grenade"]=true,
	["poison-capsule"]=true,
	["slowdown-capsule"]=true,
	["raw-fish"]=true,
	["stone-wall"]=true,
	["stone-brick"]=true,
	["radar"]=true,
	["gun-turret"]=true,
	["flamethrower-turret"]=true,
	["coal"]=true,
	["iron-plate"]=true,
	["copper-plate"]=true,
	["steel-plate"]=true,
	["iron-gear-wheel"]=true,
	["electronic-circuit"]=true,
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true--,
	--["production-science-pack"] = true,
	--["utility-science-pack"] = true,
	--["space-science-pack"] = true
}

--[[global.viewing_inventories={ --Cumulatives GUI :  target(player) + north(team) + south(team), (init.lua for initialisation)
	["sourcename"]={
						["target"]={ ["name"]="target_name", ["position"]={pos.x,pos.y} }, 
						["north"] ={ ["active"]=true/false, ["inventory"]=true/false, ["position"]={pos.x,pos.y} },
						["south"] ={ ["active"]=true/false, ["inventory"]=true/false, ["position"]={pos.x,pos.y} }
					},
}]]--

local function validate_object(obj)
    if not obj then return false end
    if not obj.valid then return false end
    return true
end

local function validate_player(player)
    --EVL Patch for viewing inventory from spec_god mode (see spectator_zoom.lua)
	if player.force.name == "spec_god" then return true end
	
	if not player then return false end
    if not player.valid then return false end
    if not player.character then return false end
    if not player.connected then return false end
    if not game.players[player.index] then return false end
	--EVL REMOVED (target is not admin)
	--if not player.admin then 
	--	player.print("Only admins can open inventory.", {r = 175, g = 0, b = 0}) 
	--	return false 
	--end
    return true
end

--EVL Check if global.viewing_inventories[source][target][mode] exists : target="target/north/south", mode="target/position  or  active/inventory/position"
local function validate_viewing_inv(source,target,mode)
	if not global.viewing_inventories[source] then
		--if global.bb_debug_gui then game.print("DEBUGUI validate_viewing_inv return FALSE (no source) ["..source.."]["..target.."]["..mode.."]") end
		return false
	end
	if not global.viewing_inventories[source][target] then
		--if global.bb_debug_gui then game.print("DEBUGUI validate_viewing_inv return FALSE (no target) ["..source.."]["..target.."]["..mode.."]") end
		return false
	end
	if target=="target" and mode=="name" then
		if not global.viewing_inventories[source][target]["name"] then -- or global.viewing_inventories[source][target]["name"]=="" then 
			return false
		else
			return true
		end
	elseif target=="target" and mode=="position" then
		if not global.viewing_inventories[source][target]["position"] then 
			return false
		else
			return true
		end
	elseif (target=="north" or target=="south") and mode=="active" then
		if not global.viewing_inventories[source][target]["active"] then 
			return false
		else
			return true
		end
	elseif (target=="north" or target=="south") and mode=="inventory" then
		if not global.viewing_inventories[source][target]["inventory"] then 
			return false
		else
			return true
		end
	elseif (target=="north" or target=="south") and mode=="position" then
		if not global.viewing_inventories[source][target]["position"] then 
			return false
		else
			return true
		end
	end
	if global.bb_debug_gui then game.print("DEBUGUI validate_viewing_inv ["..source.."]["..target.."]["..mode.."]  FAILED !!!") end
	return false
end

--EVL Check if global.viewing_inventories[source][target][mode] exists and set the _value for target="target/north/south", mode="target/position  or  active/inventory/position"
local function set_viewing_inv(source,target,mode,_value)
	if not global.viewing_inventories[source] then 
		global.viewing_inventories[source]={} 
	end
	if not global.viewing_inventories[source][target] then
		global.viewing_inventories[source][target]={} 
	end
	if not global.viewing_inventories[source][target][mode] then
		global.viewing_inventories[source][target][mode]=_value
	else
		global.viewing_inventories[source][target][mode]=_value
	end
end
--EVL Check if global.viewing_inventories exists and get a value for player,target="target/north/south",mode="target/position  or  active/inventory/position"
local function get_viewing_inv(source,target,mode) --global.viewing_inventories[source.name][force]["active"]=true
	if not global.viewing_inventories[source] then 
		if global.bb_debug_gui then game.print("DEBUGUI get_viewing_inv : ["..source.."] does not exist... IS THAT OK ?????????") end
		return false
	end
	if not global.viewing_inventories[source][target] then 
		if global.bb_debug_gui then game.print("DEBUGUI get_viewing_inv : ["..source.."]["..target.."] does not exist... IS THAT OK ?????????") end
		return false
	end
	if not global.viewing_inventories[source][target][mode] then
		if global.bb_debug_gui then game.print("DEBUGUI get_viewing_inv : ["..source.."]["..target.."]["..mode.."]=nil ... IS THAT OK ?????????") end
		return false
	else
		return global.viewing_inventories[source][target][mode]
	end
	if global.bb_debug_gui then game.print("DEBUGUI get_viewing_inv : ["..source.."]["..target.."]["..mode.."]... FAILED !!!!!") end
end

--EVL Clear/Destroy all inventories (on_pre_player_left & on force-map-reset & on starting sequence // but not needed on reroll)
function Public.destroy_all_inventories()
	for _source,_ in pairs(global.viewing_inventories) do
		local source=game.players[_source]
		if not validate_player(source) then
			if global.bb_debug_gui then game.print("DEBUGUI : <<on_pre_player_left_game>> Source (".._source..") is not valid") end --EVL
		else
			local screen = source.gui.screen
			if not validate_object(screen) then
				if global.bb_debug_gui then game.print("DEBUGUI : <<on_pre_player_left_game>> gui.screen is not valid") end --EVL
			else
				--is source viewing a player inventory ?
				local inventory_gui = screen.inventory_gui
				if inventory_gui then
					if global.bb_debug_gui then game.print("DEBUGUI : <<on_pre_player_left_game>>  destroy player inventory.") end --EVL
					inventory_gui.destroy()
					set_viewing_inv(_source,"target","name",nil)
				end
				--is source viewing north inventory ?
				local north_inv_gui = screen["north_inv_gui"]
				if north_inv_gui then
					if global.bb_debug_gui then game.print("DEBUGUI : <<on_pre_player_left_game>>  destroy north inventory.") end --EVL
					north_inv_gui.destroy()
					set_viewing_inv(_source,"north","active",nil)
				end
				--is source viewing south inventory ?
				local south_inv_gui = screen["south_inv_gui"]
				if south_inv_gui then
					if global.bb_debug_gui then game.print("DEBUGUI : <<on_pre_player_left_game>>  destroy south inventory.") end --EVL
					south_inv_gui.destroy()
					set_viewing_inv(_source,"south","active",nil)
				end
			end--validate screen
		end--validate player
	end--for each player
end

--EVL Close the inventory via Close_button
function Public.close_inventory(source,target)
	local source_name=source.name
	if global.bb_debug_gui then game.print("DEBUGUI entering close_inventory") end
	if target=="target" then --Closing player inventory
		if validate_viewing_inv(source_name,"target","name") then
			local screen = source.gui.screen
			if not validate_object(screen) then 
				if global.bb_debug_gui then game.print("DEBUGUI close_inventory screen is not valid for "..source_name) end
				return 
			end
			local inventory_gui = screen.inventory_gui
			if not validate_object(inventory_gui) then 
				if global.bb_debug_gui then game.print("DEBUGUI close_inventory : inventory_gui is not valid for "..source_name) end
				return
			end
			local target_name=get_viewing_inv(source.name,"target","name")
			set_viewing_inv(source_name,"target","name",nil)
			inventory_gui.destroy()	 
		else
			if global.bb_debug_gui then game.print("DEBUGUI close_inventory : validate_viewing_inv("..source_name..",'target',name) is FALSE...") end
		end
	elseif target=="north" or target=="south" then --Closing team inventory
		if validate_viewing_inv(source_name,target,"active") then
			local screen = source.gui.screen
			if not validate_object(screen) then 
				if global.bb_debug_gui then game.print("DEBUGUI close_inventory (team "..target..") screen is not valid for "..source_name) end
				return 
			end
			local gui_name=target.."_inv_gui"
			local force_inv_gui = screen[gui_name]
			if not validate_object(force_inv_gui) then 
				if global.bb_debug_gui then game.print("DEBUGUI close_inventory : "..target.."_inv_gui is not valid for "..source_name) end
				return
			end
			set_viewing_inv(source_name,target,"active",nil)
			force_inv_gui.destroy()	 
		else
			if global.bb_debug_gui then game.print("DEBUGUI close_inventory : validate_viewing_inv("..source_name..","..target..",'active') is FALSE...") end
		end
	else
		if global.bb_debug_gui then game.print("DEBUGUI close_inventory("..source_name..") has wrong target="..tostring(target)) end
	end
end

--EVL Draw Cursor_Stack in gui
local function draw_cursor_stack(gui,target)
	local cursor_stack = target.cursor_stack
	local cursor_stack_info = gui.add({type = 'label', caption='Hand\n►'})
	cursor_stack_info.style.font_color = {r=0.4, g=0.9, b=0.4}
	cursor_stack_info.style.horizontal_align="center"
	cursor_stack_info.style.minimal_width=35
	cursor_stack_info.style.maximal_width=35
	cursor_stack_info.style.single_line = false
	if cursor_stack.count>0 then
		local button =
			gui.add({
				type = 'sprite-button',
				sprite = 'item/' .. cursor_stack.name,
				number = cursor_stack.count,
				--name = cursor_stack.name,
				tooltip = game.item_prototypes[cursor_stack.name].localised_name,
				style = 'slot_button'
			})
		button.enabled = false
	else
		local cursor_stack = gui.add({type = 'label', caption=' Θ ', tooltip=target.name.." has nothing in hand(cursor)."})--№  ʘ Θ Ѳ Θ
		cursor_stack.style.font = "default-large-bold"
		cursor_stack.style.font_color = {r=0.9, g=0.4, b=0.4}
		cursor_stack.style.horizontal_align="center"
		cursor_stack.style.single_line = false
		cursor_stack.style.minimal_width=30
		cursor_stack.style.maximal_width=30
	end
end

--EVL Draw Armor in gui (with grid in tooltip)	
local function draw_armor(gui,target)
	local armor_inventory = target.get_inventory(defines.inventory.character_armor).get_contents()
	if table_size(armor_inventory)>0 then
		--THIS LOOP IS DONE ONLY ONCE (cant have two armors)
		for name, opts in pairs(armor_inventory) do
			local armor_tooltip=""
			--SO WE DONT CARE TO PUT THE GRID THING HERE
			if target.get_inventory(5)[1].grid then
				local equipment_grid=target.get_inventory(5)[1].grid
				local battery_charge=math.floor(equipment_grid.available_in_batteries/100000)/10
				local battery_capacity=math.floor(equipment_grid.battery_capacity/100000)/10
				--game.print(tostring(target.get_inventory(5)[1].grid.object_name))
				local p_armor = equipment_grid.get_contents()
				local p_grid = equipment_grid.equipment
				local robotport_charge=0
				local robotport_capacity=0
				local robotportmk2_charge=0
				local robotportmk2_capacity=0
				for _index,_equipment in  pairs(p_grid) do
					--game.print(_index.."  ".._equipment.name)
					if _equipment.name=="personal-roboport-equipment" then
						robotport_charge=robotport_charge+_equipment.energy
						robotport_capacity=robotport_capacity+_equipment.max_energy
					elseif _equipment.name=="personal-roboport-mk2-equipment" then
						robotportmk2_charge=robotportmk2_charge+_equipment.energy
						robotportmk2_capacity=robotportmk2_capacity+_equipment.max_energy
					end
				end
				robotport_charge=math.floor(robotport_charge/100000)/10 --formatting in Mega Joule
				robotport_capacity=math.floor(robotport_capacity/100000)/10
				robotportmk2_charge=math.floor(robotportmk2_charge/100000)/10
				robotportmk2_capacity=math.floor(robotportmk2_capacity/100000)/10
				for k, v in pairs(p_armor) do
					if k=="battery-equipment" then
						armor_tooltip = armor_tooltip.."[img=item."..k.."]x"..v.."  [color=#AAAAAA]("..battery_charge.."/"..battery_capacity.." MJ)[/color]\n"
					elseif k=="personal-roboport-equipment" then
						armor_tooltip = armor_tooltip.."[img=item."..k.."]x"..v.."  [color=#AAAAAA]("..robotport_charge.."/"..robotport_capacity.." MJ)[/color]\n"
					elseif k=="personal-roboport-mk2-equipment" then
						armor_tooltip = armor_tooltip.."[img=item."..k.."]x"..v.."  [color=#AAAAAA]("..robotportmk2_charge.."/"..robotportmk2_capacity.." MJ)[/color]\n"
					else
						armor_tooltip = armor_tooltip.."[img=item."..k.."]x"..v.."\n"
					end
				end
			end
			if armor_tooltip=="" then
				armor_tooltip= game.item_prototypes[name].localised_name
			else
				armor_tooltip=string.sub(armor_tooltip,1,string.len(armor_tooltip)-1)
			end
			
			local flow = gui.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					--name = name,
					tooltip = armor_tooltip,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local armor_inventory_info = gui.add({type = 'label', caption='No\narmor'})
		armor_inventory_info.style.single_line = false
		armor_inventory_info.style.horizontal_align="center"
		armor_inventory_info.style.font_color = {r=0.8, g=0.1, b=0.1}		
	end
end

--EVL Draw Guns in gui
local function draw_guns(gui,target)
	local guns_inventory = target.get_inventory(defines.inventory.character_guns).get_contents()
	if table_size(guns_inventory)>0 then
		for name, opts in pairs(guns_inventory) do
			local flow = gui.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					--name = name,
					tooltip = game.item_prototypes[name].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local guns_inventory_info = gui.add({type = 'label', caption='No\n  gun  '})
		guns_inventory_info.style.single_line = false
		guns_inventory_info.style.horizontal_align="center"
		guns_inventory_info.style.font_color = {r=0.8, g=0.1, b=0.1}		
	end
end

--EVL Draw Ammunition in gui
local function draw_ammo(gui,target)
	local ammo_inventory = target.get_inventory(defines.inventory.character_ammo).get_contents()
	if table_size(ammo_inventory)>0 then
		for name, opts in pairs(ammo_inventory) do
			local flow = gui.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					--name = name,
					tooltip = game.item_prototypes[name].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local ammo_inventory_info = gui.add({type = 'label', caption='No\nammo'})
		ammo_inventory_info.style.single_line = false
		ammo_inventory_info.style.horizontal_align="center"
		ammo_inventory_info.style.font_color = {r=0.8, g=0.1, b=0.1}		
	end
end



--EVL Filling frame force_inv_gui  (team)
local function draw_team_inventory(force_inv_gui, force, inventory_mode)
	local types = game.item_prototypes  --EVL used to show tooltip in buttons
	
	--TTTLE CAPTION : Team name + Switch show/hide
	local _caption = "Team "..force.." [font=default][color=#999999] - "
	if global.tm_custom_name[force] then 
		_caption = global.tm_custom_name[force].." [font=default][color=#999999]("..force..") - "
	end	
	local switch_str="[/color][/font] [font=default-large-bold][color=#88EE88]¡[/color][/font] [font=default][color=#999999]to show"
	if inventory_mode then switch_str="[/color][/font] [font=default-large-bold][color=#CC7777]![/color][/font] [font=default][color=#999999]to hide" end
	_caption = _caption.."Click on "..switch_str.." inventories (right to team name).[/color][/font]"
	force_inv_gui.caption=_caption
	
	--LIST OF PLAYERS IN TEAM
	local target_list={}
	for _,target in pairs(game.forces[force].connected_players) do
		if target.character then -- to be sure, probably needed when player died
			if global.viewing_technology_gui_players[target.name] or (global.manager_table[force] and target.name==global.manager_table[force]) then
				--Skip player (not really in the team, just viewing technology tree gui or manager)
			else
				table.insert(target_list,target.name)
			end
		end
	end
	if table_size(target_list)==0 then
		local noplayer_line=force_inv_gui.add({type = 'table', column_count = 3})
		--EVL NO PLAYER AT THE MOMENT
		local _caption="     No more players to look at ..."
		local _info=noplayer_line.add({type = 'label', caption=_caption})  --Name+HP
		_info.style.single_line = false
		_info.style.font = "heading-1"
		_info.style.font_color = {250, 50, 50}
		_info.style.width = 350
		--EVL REFRESH Button
		local refresh_inventory  = noplayer_line.add({type = "button", name = "team_inventory_refresh_"..force, caption = "®", tooltip = "Refresh inventories."})
		refresh_inventory.style.font = "heading-1"
		refresh_inventory.style.font_color = {50, 250, 50}
		refresh_inventory.style.height = 24
		--refresh_inventory.style.vertical_align="center"
		refresh_inventory.style.width = 24
		refresh_inventory.style.padding = -4
		--EVL CLOSE Button
		local close_inventory  = noplayer_line.add({type = "button", name = "team_inventory_close_"..force, caption = "X", tooltip = "Close inventories."})
		close_inventory.style.font = "heading-2"
		close_inventory.style.font_color = {250, 50, 50}
		close_inventory.style.height = 24
		--close_inventory.style.vertical_align="center"
		close_inventory.style.width = 24
		close_inventory.style.padding = -4	
		return
	end
	--DRAWING OF CRAFTS/INFOS(name, hp, armor, guns, ammos, cursor, etc.)/INVENTORIES
	local _columns=10 --maximum 2 lines ie (10*2-1) crafts/inventory
	if table_size(global.sorting_inventory)>(_columns*2-1) then --#global.sorting_inventory is limited by (_columns*2-1) because of tooltip
		--We may loose some items in inventory (very unlikely but still can happen)
		if global.bb_debug_gui then game.print("DEBUGUI draw_team_inventory : global.sorting_inventory has too much items...") end
	end
	
	for _index,target_name in pairs(target_list) do
		local target=game.players[target_name]
		
		--First: Insert Crafting list (2 lines max)
		local crafting_list = target.crafting_queue
		local crafting_list_table = force_inv_gui.add({type = 'table', column_count = _columns})
		local crafting_tooltip=false -- If too much crafts, add remaining  in tooltip
		local crafting_tooltip_str=""
		local more_craft
		if crafting_list and table_size(crafting_list)>0 then
			local index_craft=0
			local index_tooltip_craft=0
			for _,item in pairs(crafting_list) do
				index_craft=index_craft+1
				if index_craft==_columns*2 then 
					more_craft=crafting_list_table.add({type = 'label', caption='[color=#99FF99]and\nmore[/color]'})
					more_craft.style.horizontal_align="center"
					more_craft.style.single_line = false
					crafting_tooltip=true
				end
				local recipe=item["recipe"]
				local count=item["count"]
				if crafting_tooltip then
					--if count>9 then count="  "..count end
					crafting_tooltip_str=crafting_tooltip_str..count..'x [item='..recipe..']        '
					index_tooltip_craft=index_tooltip_craft+1
					if index_tooltip_craft==3 then
						index_tooltip_craft=0
						crafting_tooltip_str=crafting_tooltip_str.."\n"
					end
				else
					local flow = crafting_list_table.add({type = 'flow'})
					flow.style.vertical_align = 'bottom'
					local button =
						flow.add(
						{
							type = 'sprite-button',
							sprite = 'item/' .. recipe,
							number = count,
							name = recipe,
							tooltip = types[recipe].localised_name,
							style = 'slot_button'
						}
					)
					button.enabled = false
				end
			end	
			if crafting_tooltip then more_craft.tooltip=crafting_tooltip_str end
		else
			local crafting_list_info = crafting_list_table.add({type = 'label', caption='[font=default][color=#FF9999](not crafting)[/color][/font]'})
		end

		--Second: (name, HP, armor, guns, ammo, cursor=item in hand)
		local info_line=force_inv_gui.add({type = 'table', column_count = _columns+3})
		--info_line.vertical_centering=false
		--info_line.style.vertical_align="center"
		--Name (colored) & HP 
		local r = math.floor((target.color.r * 0.6 + 0.4)*255)
		local g = math.floor((target.color.g * 0.6 + 0.4)*255)
		local b = math.floor((target.color.b * 0.6 + 0.4)*255)
		local target_color = r..','..g..','..b
		target_health=999
		if target.character then
			target_health=math.floor(target.character.health)
		else
			game.print("Debug : "..target_name.." is not a character (in draw_team_inventory).")
		end
		if target_health<50 then
			target_health='[font=default-bold][color=#DD0000]'..target_health..'HP[/color][/font]'
		elseif target_health<150 then
			target_health='[font=default-bold][color=#DDDD00]'..target_health..'HP[/color][/font]'
		else
			target_health='[font=default-bold][color=#00DD00]'..target_health..'HP[/color][/font]'
		end
		local _caption="[font=default][color="..target_color.."]"..target_name.."[/color][/font]\n"..target_health
		local info_name=info_line.add({type = 'label', caption=_caption})  --Name+HP
		info_name.style.single_line = false
		info_name.style.minimal_width=50
		info_name.style.maximal_width=120
		info_name.style.horizontal_align = "right"

		--Draw Armor (with grid in tooltip)
		draw_armor(info_line,target)
		--Draw Guns
		draw_guns(info_line,target)
		--Draw Ammunition
		draw_ammo(info_line,target)
		--Separator
		--info_line.add({type = 'label', caption=' '})
		--Cursor_Stack
		draw_cursor_stack(info_line,target)
		--Separator
		--info_line.add({type = 'label', caption=' '})
		
		--EVL place buttons on first line then label "Craft▲\nInv▼" on other lines
		if _index==1 then
			--EVL REFRESH Button
			local refresh_inventory  = info_line.add({type = "button", name = "team_inventory_refresh_"..force, caption = "®",
				tooltip = "Refresh inventories.\n[color=#888888]May not work manually...[/color]"})
			refresh_inventory.style.font = "heading-1"
			refresh_inventory.style.font_color = {50, 250, 50}
			refresh_inventory.style.height = 24
			--refresh_inventory.style.vertical_align="center"
			refresh_inventory.style.width = 24
			refresh_inventory.style.padding = -4
			--EVL CLOSE Button
			local close_inventory  = info_line.add({type = "button", name = "team_inventory_close_"..force, caption = "X",
				tooltip = "Supposed to close inventories :/ [color=#888888]Debug in progress...[/color]\n"
					.."[color=#BB8888]Click again on team name to close.[/color]\n"
					.."[color=#FF8888]Type command <</close-screens>> in last resort.[/color]"
			})
			close_inventory.style.font = "heading-2"
			close_inventory.style.font_color = {250, 50, 50}
			close_inventory.style.height = 24
			--close_inventory.style.vertical_align="center"
			close_inventory.style.width = 24
			close_inventory.style.padding = -4
		else
			local info_inv = info_line.add({type = 'label', caption='Craft▲\nInv▼'})
			info_inv.style.font_color = {r=0.4, g=0.9, b=0.4}
			info_inv.style.horizontal_align="right"
			info_inv.style.single_line = false
			info_inv.style.minimal_width=50
			info_inv.style.maximal_width=50			
		end


		--Third: Main Inventory (2 lines max)  only in inventory_mode==true
		if inventory_mode then
			local main_inventory = target.get_main_inventory().get_contents()
			local main_inventory_table = force_inv_gui.add({type = 'table', column_count = _columns})
			local inventory_tooltip=false -- If too much crafts, add remaining  in tooltip
			local inventory_tooltip_str=""
			local more_inv
			if table_size(main_inventory)>0 then
				local index_inv=0
				local index_tooltip_inv=0
				--First items ordered
				for recipe,_ in pairs(global.sorting_inventory) do
					if main_inventory[recipe] then --and main_inventory_table[recipe]>0 then
						index_inv=index_inv+1 --table_size of global.sorting_inventory is limited by (_columns*2-1)
						local flow = main_inventory_table.add({type = 'flow'})
						flow.style.vertical_align = 'bottom'
						local button =
							flow.add(
							{
								type = 'sprite-button',
								sprite = 'item/' .. recipe,
								number = main_inventory[recipe],
								--name = recipe,
								tooltip = types[recipe].localised_name,
								style = 'slot_button'
							}
						)
						button.enabled = false
					end
				end
				--Remaining items				
				for recipe, count in pairs(main_inventory) do
					if not global.sorting_inventory[recipe] then
						index_inv=index_inv+1
						if index_inv==_columns*2 then 
							more_inv=main_inventory_table.add({type = 'label', caption='[color=#99FF99]and\nmore[/color]'})
							more_inv.style.horizontal_align="center"
							more_inv.style.single_line = false
							inventory_tooltip = true
						end				
						if inventory_tooltip then
							--if count>9 then count="  "..count end
							inventory_tooltip_str=inventory_tooltip_str..count..'x [item='..recipe..']        '
							index_tooltip_inv=index_tooltip_inv+1
							if index_tooltip_inv==3 then
								index_tooltip_inv=0
								inventory_tooltip_str=inventory_tooltip_str.."\n"
							end
						else
							local flow = main_inventory_table.add({type = 'flow'})
							flow.style.vertical_align = 'bottom'
							local button =
								flow.add(
								{
									type = 'sprite-button',
									sprite = 'item/' .. recipe,
									number = count,
									name = recipe,
									tooltip = types[recipe].localised_name,
									style = 'slot_button'
								}
							)
							button.enabled = false
						end
					end
				end
				if inventory_tooltip then more_inv.tooltip=inventory_tooltip_str end
			else
				local main_inventory_info = main_inventory_table.add({type = 'label', caption='[font=default-small][color=#999999](inventory is empty)[/color][/font]'})
				main_inventory_info.style.height= 25
				main_inventory_info.style.width= 400
				main_inventory_info.style.horizontal_align= "center"
				main_inventory_info.style.vertical_align= "center"
			end
		end
		
		--SPEARATORS
		if _index<#target_list then
			force_inv_gui.add({type = "line", direction = "horizontal" })
			force_inv_gui.add({type = "line", direction = "horizontal" })
		end
	end
end


--EVL Filling frame inventory_gui of player
local function draw_inventory(inventory_gui, target)
	local types = game.item_prototypes  --EVL used to show tooltip in buttons
	--EVL Name (colored) & HP in title 
	local r = math.floor((target.color.r * 0.6 + 0.4)*255)
	local g = math.floor((target.color.g * 0.6 + 0.4)*255)
	local b = math.floor((target.color.b * 0.6 + 0.4)*255)
	local target_color = r..','..g..','..b
	local target_health=math.floor(target.character.health)
	if target_health<50 then
		target_health='[font=default-bold][color=#DD0000]'..target_health..'HP[/color][/font]'
	elseif target_health<150 then
		target_health='[font=default-bold][color=#DDDD00]'..target_health..'HP[/color][/font]'
	else
		target_health='[font=default-bold][color=#00DD00]'..target_health..'HP[/color][/font]'
	end
	inventory_gui.caption = 'Crafting & Inventory of [color='..target_color..']'..target.name..'[/color] : '..target_health
		.. '    [font=default-small][color=#999999](Click [/color][color=#FA3232]X[/color][color=#999999] to close)[/color][/font]'

	--EVL Insert Crafting list
	local crafting_list = target.crafting_queue
	local crafting_list_table = inventory_gui.add({type = 'table', column_count = 10}) 
	
	--if crafting_list ~= nil then
	if crafting_list and table_size(crafting_list)>0 then
		for _,item in pairs(crafting_list) do
			local recipe=item["recipe"]
			local count=item["count"]
			local flow = crafting_list_table.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. recipe,
					number = count,
					--name = recipe,
					tooltip = types[recipe].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end	
	else
		local crafting_list_info = crafting_list_table.add({type = 'label', caption='[font=default-small][color=#999999](not crafting)[/color][/font]'})
	end

	--EVL Section titles : Creafting / Inventory /  Cursor_stack   / Close
	local cursor_stack_table = inventory_gui.add({type = 'table', column_count = 7}) 
	local cursor_stack_next = cursor_stack_table.add({type = 'label', caption='  ▲ Crafting          ▼ Inventory          '})

	--EVL Cursor_Stack
	draw_cursor_stack(cursor_stack_table,target)

	cursor_stack_table.add({type = 'label', caption='          '})--Separator
	--EVL REFRESH Button
	local refresh_inventory  = cursor_stack_table.add({type = "button", name = "inventory_refresh", caption = "®",
		tooltip = "Refresh inventory.\n[color=#888888]May not work manually...[/color]"})
	refresh_inventory.style.font = "heading-1"
	refresh_inventory.style.font_color = {50, 250, 50}
	refresh_inventory.style.height = 24
	refresh_inventory.style.width = 24
	refresh_inventory.style.padding = -4
	cursor_stack_table.add({type = 'label', caption=' '})--Separator
	--EVL CLOSE Button
	local close_inventory  = cursor_stack_table.add({type = "button", name = "inventory_close", caption = "X",
		tooltip = "Supposed to close inventory :/ [color=#888888]Investigation in progress...[/color]\n"
			.."[color=#BB8888]Try to click again on the player name.[/color]\n"
			.."[color=#FF8888]Type command <</close-screens>> in last resort.[/color]"
	})
	close_inventory.style.font = "heading-2"
	close_inventory.style.font_color = {250, 50, 50}
	close_inventory.style.height = 24
	close_inventory.style.width = 24
	close_inventory.style.padding = -4

	--EVL Insert Main Inventory
	local main_inventory = target.get_main_inventory().get_contents()
	local main_inventory_table = inventory_gui.add({type = 'table', column_count = 10}) 
	if table_size(main_inventory)>0 then
		--First items ordered
		for recipe,_ in pairs(global.sorting_inventory) do
			if main_inventory[recipe] then
				local flow = main_inventory_table.add({type = 'flow'})
				flow.style.vertical_align = 'bottom'
				local button =
					flow.add(
					{
						type = 'sprite-button',
						sprite = 'item/' .. recipe,
						number = main_inventory[recipe],
						--name = recipe,
						tooltip = types[recipe].localised_name,
						style = 'slot_button'
					}
				)
				button.enabled = false
			end
		end
		--Remaining items
		for recipe, count in pairs(main_inventory) do
			if not global.sorting_inventory[recipe] then
				local flow = main_inventory_table.add({type = 'flow'})
				flow.style.vertical_align = 'bottom'
				local button =
					flow.add(
					{
						type = 'sprite-button',
						sprite = 'item/' .. recipe,
						number = count,
						--name = recipe,
						tooltip = types[recipe].localised_name,
						style = 'slot_button'
					}
				)
				button.enabled = false
			end
		end
	else
		local main_inventory_info = main_inventory_table.add({type = 'label', caption='[font=default-small][color=#999999](inventory is empty)[/color][/font]'})
		main_inventory_info.style.height= 75
		main_inventory_info.style.width= 400
		main_inventory_info.style.horizontal_align= "center"
		main_inventory_info.style.vertical_align= "center"
	end

	--EVL Add a horizontal separator
	local line = inventory_gui.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8
	
	--Table in GUI for armor/guns/ammo
	local armor_guns_inventory_table = inventory_gui.add({type = 'table', column_count = 10}) 
	--Draw Armor (with grid in tooltip)
	draw_armor(armor_guns_inventory_table, target)
	--Separator
	armor_guns_inventory_table.add({type = 'label', caption='           '})
	--Draw Guns
	draw_guns(armor_guns_inventory_table,target)
	--Separator
	armor_guns_inventory_table.add({type = 'label', caption='           '})
	--Draw Ammunition
	draw_ammo(armor_guns_inventory_table,target)

end

--EVL Create/Destroy frame force_inv_gui --force can be "north" or "south"
local function inventory_force(source, force)
	if Functions.get_nb_players(force)==0 then
		source.print(">>>>> No player found in force "..force..".", {r = 175, g = 0, b = 0})
		source.play_sound{path = global.sound_error, volume_modifier = 0.8}			
		return
	end
	--searching and testing gui.screen
	local screen = source.gui.screen
    if not validate_object(screen) then
		if global.bb_debug_gui then game.print("DEBUGUI : gui.screen is not valid in inventory_force ("..source.name..","..force..")") end --EVL
		return 
	end
	local source_name=source.name
	local gui_name=force.."_inv_gui"
	local force_inv_gui = screen[gui_name]
	
	-- EVL Clear force_inv_gui if exists (but should not happen)
	if validate_object(force_inv_gui) then 
		if global.bb_debug_gui then game.print("DEBUGUI : Closing <<force_inv_gui>> via open_close_inv_"..force.." for "..source_name) end
		force_inv_gui.destroy()
		set_viewing_inv(source_name,force,"active",nil)
		return
	end
	--EVL OK good to create force_inv_gui
	--force_inv_pane = screen.add({type = "scroll-pane", name = force.."_inv_pane", caption = "Inventories of team "..force, direction = "vertical", horizontal_scroll_policy="always", vertical_scroll_policy="always"})
	--force_inv_gui = force_inv_pane.add({type = "frame", name = gui_name, caption = "Inventories of team "..force})--DEBUG-- could change these to scroll-panes
	force_inv_gui = screen.add({type = "frame", name = gui_name, caption = "Inventories of team "..force, direction = "vertical"})	
	force_inv_gui.style.minimal_width = 460
	--force_inv_gui.style.maximal_width = 460
	force_inv_gui.style.minimal_height = 250
	force_inv_gui.style.maximal_height = 1250
	if not validate_object(force_inv_gui) then 
		if global.bb_debug_gui then game.print("DEBUGUI : Failed to create "..force.."_inv_gui for "..source_name..".") end
		return 
	end
	--Store info for source>force
	set_viewing_inv(source_name,force,"active",true) --global.viewing_inventories[source_name][force]["active"]=true
	--EVL Always show inventory_gui at the last position that source had chosen see on_gui_location_changed(event)
	if validate_viewing_inv(source_name,force,"position") then
		force_inv_gui.location=global.viewing_inventories[source_name][force]["position"]
	else
		--default location
		local display_x=source.display_resolution.width-600
		if display_x<0 then display_x=0 end
		local display_y=source.display_resolution.height-925
		if display_y<0 then display_y=0 end
		--game.print("screen=("..display_x..","..display_y..")")-- gui=("..force_inv_gui.style.natural_width..","..force_inv_gui.style.natural_height..")")
		if force=="north" then
			force_inv_gui.location={10,display_y}
		else
			force_inv_gui.location={display_x,display_y}
		end
	end
	--game.print("calling draw_team")
	local inventory_mode=false
	if validate_viewing_inv(source_name,force,"inventory") then
		inventory_mode=true
	end
	draw_team_inventory(force_inv_gui, force, inventory_mode)
	source.play_sound{path = global.sound_low_bip, volume_modifier = 0.8}
end

--EVL Create/Destroy frame inventory_gui --Target can be "player_name" or "north" or "south"
function Public.open_inventory(source, target)
	if not validate_player(source) then
		if global.bb_debug_gui then game.print("DEBUGUI : Source ("..source.name..") is not valid") end --EVL
		return
    end
	local source_name=source.name
	if not(global.match_running) then
		source.print(">>>>> Match has not started ;-)", {r = 175, g = 0, b = 0})
		source.play_sound{path = global.sound_error, volume_modifier = 0.8}			
		return
	end
	--Go to team inventory if target==north or south
	if target=="north" or target=="south" then
		--Open team inventory
		inventory_force(source, target)
		return
	end
	if not(validate_player(target)) then
		if global.bb_debug_gui then game.print("DEBUGUI : Target ("..target.name..") is not valid") end --EVL
		return
    end
	local screen = source.gui.screen
    if not validate_object(screen) then
		if global.bb_debug_gui then game.print("DEBUGUI : gui.screen is not valid") end --EVL
		return 
	end
	local inventory_gui = screen.inventory_gui
	
	-- EVL Click again on same player will close inventory if exists and already show the same target (then return)
	if validate_viewing_inv(source_name,"target","name") then
		local this_target_name=get_viewing_inv(source_name,"target","name")
		if this_target_name==target.name then
			if not validate_object(inventory_gui) then 
				if global.bb_debug_gui then game.print("DEBUGUI : Can't find the inventory opened...") end
				return 
			end
			set_viewing_inv(source_name,"target","name",nil)
			inventory_gui.destroy()
			source.play_sound{path = global.sound_low_bip, volume_modifier = 1}		
			return 
		end
	end
	-- EVL Clear inventory_gui if exists
	if validate_object(inventory_gui) then inventory_gui.destroy() end

	--EVL Create new inventory
	inventory_gui = screen.add({type = 'frame', name = 'inventory_gui', caption = 'Inventory', direction = 'vertical'})
	if not validate_object(inventory_gui) then 
		if global.bb_debug_gui then game.print("DEBUGUI : Failed to create inventory.") end
		return 
	end
	--EVL Add this target in the list of viewing inventory of source
	set_viewing_inv(source_name,"target","name",target.name)
	--EVL Always show inventory_gui at the last position that source had chosen, see on_gui_location_changed(event)
	if validate_viewing_inv(source_name,"target","position") then
		inventory_gui.location=get_viewing_inv(source_name,"target","position")
	else
		inventory_gui.location={250,50}
	end
    inventory_gui.style.minimal_width = 450
    inventory_gui.style.minimal_height = 250
	draw_inventory(inventory_gui, target)
	global.gui=inventory_gui
	source.play_sound{path = global.sound_low_bip, volume_modifier = 0.8}
end

--EVL Update inventory on cursor/inv/craft change
local function update_inventory_gui(event)
	-- This is UPS consumming... tried to limit impact
	--global.inventory_timeout=29 --EVL dont update inventories more than every 29/60
	--global.inventory_last_tick=0 --EVL store last tick that inventories were drawn
	--global.inventory_select="player" -- or "north" or "south" --Draw only one of 3 kind of inventories at a time
	
	if game.tick-global.inventory_last_tick<=0 then return end --dont update too often
	global.inventory_last_tick=game.tick+global.inventory_timeout
	
	if table_size(global.viewing_inventories)==0 then return end
	local target = game.players[event.player_index]
	local target_name=target.name
	local target_force=target.force.name
	for _source,_ in pairs(global.viewing_inventories) do
		--if global.inventory_select=="player" then
			--is source viewing target inventory ?
			if validate_viewing_inv(_source,"target","name") then
				local this_target_name=get_viewing_inv(_source,"target","name")
				if this_target_name==target_name then
					this_source=game.players[_source]
					if not(validate_player(this_source)) then
						if global.bb_debug_gui then game.print("DEBUGUI update_inventory : Source (".._source..") is not valid") end
						return
					end				
					local screen = this_source.gui.screen
					if not validate_object(screen) then return end
					local inventory_gui = screen.inventory_gui
					if not validate_object(inventory_gui) then 
						if global.bb_debug_gui then game.print("DEBUGUI : update_inv : Cannot find player_inventory for ".._source.." viewing "..target_name) end
						set_viewing_inv(_source,"target","name",nil)
						return
					end
					
					inventory_gui.clear() 
					draw_inventory(inventory_gui,target)
				end
			end
		--end

		--if global.inventory_select==target_force then
			--is source viewing force inventory ?
			if validate_viewing_inv(_source,target_force,"active") then		
				this_source=game.players[_source]
				if not(validate_player(this_source)) then
					if global.bb_debug_gui then game.print("DEBUGUI update_inventory : Source (".._source..") is not valid") end
					return
				end	
				local screen = this_source.gui.screen
				if not validate_object(screen) then return end
				local force_inventory_gui = screen[target_force.."_inv_gui"]
				if not validate_object(force_inventory_gui) then 
					if global.bb_debug_gui then game.print("DEBUGUI : Cannot find force_inventory for ".._source.." viewing force "..target_force) end
					set_viewing_inv(_source,target_force,"active",nil)
					return
				end
				local inventory_mode=false
				if validate_viewing_inv(_source,target_force,"inventory") then
					inventory_mode=true
				end
				force_inventory_gui.clear()
				draw_team_inventory(force_inventory_gui, target_force, inventory_mode)
			end
		--end
	end
	--Next time, change kind of inventory
	--if global.inventory_select=="player" then global.inventory_select="north"
	--elseif global.inventory_select=="north" then global.inventory_select="south"
	--else global.inventory_select="player"
	--end
end

--EVL Store last inventory_gui/north_inv_gui/south_inv_gui locations
local function on_gui_location_changed(event)
	local gui_name=event.element.name
	local source=game.players[event.player_index]
	local source_name=source.name
	local location=event.element.location
	if gui_name=="inventory_gui" then
		set_viewing_inv(source_name,"target","position",location)
	elseif gui_name=="north_inv_gui" then
		set_viewing_inv(source_name,"north","position",location)
	elseif gui_name=="south_inv_gui" then 
		set_viewing_inv(source_name,"south","position",location)
	end
end

--EVL Refresh the inventory via Refresh_button
function Public.refresh_inventory(source,target)
	local source_name=source.name
	if global.bb_debug_gui then game.print("DEBUGUI entering refresh_inventory") end
	local screen = source.gui.screen
	if not validate_object(screen) then
		if global.bb_debug_gui then game.print("DEBUGUI : Refresh inventory : can't find gui.screen for "..source_name) end
		return 
	end
	if target=="target" then
		local inventory_gui = screen.inventory_gui
		if not validate_object(inventory_gui) then 
			if global.bb_debug_gui then game.print("DEBUGUI refresh_inventory : inventory_gui is not valid...") end
			return
		end
		if not validate_viewing_inv(source_name,"target","name") then
			if global.bb_debug_gui then game.print("DEBUGUI refresh_inventory : cannot find inventory of "..source_name.." viewing "..this_target_name..".") end
			return
		end
		local this_target_name=get_viewing_inv(source_name,"target","name")
		this_target=game.players[this_target_name]
		if not(validate_player(this_target)) then
			if global.bb_debug_gui then game.print("DEBUGUI refresh_inventory : Target ("..this_target_name..") is not valid") end
			return
		end
		--OK we're good
		inventory_gui.clear()
		draw_inventory(inventory_gui, this_target)

	elseif target=="north" or target=="south" then
		local gui_name=target.."_inv_gui"
		local force_inv_gui = screen[gui_name]
		if not validate_object(force_inv_gui) then 
			if global.bb_debug_gui then game.print("DEBUGUI Refreshing inventory : "..target.."_inv_gui is not valid for "..source_name) end
			return
		end
		if not validate_viewing_inv(source_name,target,"active") then
			if global.bb_debug_gui then game.print("DEBUGUI refresh_inventory : cannot find inventory of "..source_name.." viewing "..target..".") end
			return
		end
		--OK we're good
		local inventory_mode=false
		if validate_viewing_inv(source_name,target,"inventory") then
			inventory_mode=true
		end		
		force_inv_gui.clear()
		draw_team_inventory(force_inv_gui, target, inventory_mode)
	else
		if global.bb_debug_gui then game.print("DEBUGUI : Refresh inventory : target is not valid ("..tostring(target)..").") end
	end
	if global.bb_debug_gui then game.print("DEBUGUI end of refresh_inventory()") end
end

--EVL Clearing all screen.guiS of LUAplayer
local function close_player_all_screens(source)
	if global.bb_debug_gui then 
			game.print("DEBUGUI: entering close_all_player_screens.", {r=0.98, g=0.66, b=0.22})
		end
	if not source.valid then 
		if global.bb_debug_gui then 
			game.print("DEBUGUI: in close_all_player_screens >> Source is not valid.", {r=0.98, g=0.66, b=0.22})
		end
		return "error     "
	end
	local _str_close=""
	local source_name=source.name
	for _, child in pairs(source.gui.screen.children) do
		local child_name=child.name
		if child_name=="inventory_gui" then
			if validate_viewing_inv(source_name,"target","name") then
				_str_close=_str_close..source_name.."(T):"..child_name.." killed    | "
				set_viewing_inv(source_name,"target","name",nil)
				child.destroy()
			else
				_str_close=_str_close..source_name.."(T):"..child_name.." killed(not rgst)    | "
				child.destroy()
			end
		elseif child_name=="north_inv_gui" then
			if validate_viewing_inv(source_name,"north","active") then
				_str_close=_str_close..source_name.."(N):"..child_name.." killed    | "
				set_viewing_inv(source_name,"north","active",nil)
				child.destroy()
			else
				_str_close=_str_close..source_name.."(N):"..child_name.." killed(not rgst)    | "
				child.destroy()
			end
		elseif child_name=="south_inv_gui" then
			if validate_viewing_inv(source_name,"south","active") then
				_str_close=_str_close..source_name.."(S):"..child_name.." killed    | "
				set_viewing_inv(source_name,"south","active",nil)
				child.destroy()
			else
				_str_close=_str_close..source_name.."(S):"..child_name.." killed(not rgst)    | "
				child.destroy()
			end
		else
			_str_close=_str_close..source_name.."(?):"..child_name.."(?)killed    | "
			child.destroy()
		end
	end
	return _str_close
end

--EVL Close all guis in player.gui.screen (until bug is fixed)
function Public.close_all_screens(target_name)
	local _str_close=""
	local _target_name=""
	if target_name and target_name~="" then _target_name=target_name end
	
	if _target_name=="all" then --1/ Clear all screen.guiS for all players
		for _, source in pairs(game.players) do
			_str_close=_str_close..close_player_all_screens(source).."\n"
		end
		return _str_close
	elseif game.players[_target_name].valid then --2/ Clear all screen.guiS for this players
		_str_close=_str_close..close_player_all_screens(game.players[_target_name])
		return _str_close
	else
		if global.bb_debug_gui then 
			game.play_sound{path = global.sound_error, volume_modifier = 0.8}
			game.print("DEBUGUI: in close_all_screens >> Player ".._target_name.."/"..target_name.." does not exist.", {r=0.98, g=0.66, b=0.22})
		end
		return "error    "
	end
	return "wtf !   "
end

--EVL Close ALL INVENTORIES before player leaves game (do we really need this ? desync ???)
--Also saves force of disconnected player and send back spec-god to spectator (island)
local function on_pre_player_left_game(event)
	if global.bb_debug_gui then game.print("DEBUGUI: entering <<on_pre_player_left_game>>") end
	local player = game.players[event.player_index]
	local player_name=player.name
	
	--EVL Close all inventories of that source player (up to 3)
	if global.viewing_inventories[player_name] then
		if global.bb_debug_gui then game.print("DEBUGUI: Player "..player_name.." is leaving, closing his inventories") end
		local _msg=close_player_all_screens(player)
		--global.viewing_inventories[player_name]=nil
		if global.bb_debug_gui then game.print("DEBUGUI <<on_pre_player_left_game>> closing inventories opened by "..player_name..", result=".._msg..".") end
	end

	--EVL Store that one player has disconnected (so we can get his inventory back)
	if player.force.name=="north" or player.force.name=="south" then
		if global.disconnected[player.name] then
			if global.bb_debug_gui then game.print("DEBUGUI <<on_pre_player_left_game>> "..player.name.."already in disconnected players (force="..player.force.name..")")  end
			global.disconnected[player.name]=player.force.name
		else
			global.disconnected[player.name]=player.force.name
			if global.bb_debug_gui then game.print("DEBUGUI <<on_pre_player_left_game>> add "..player.name.." in disconnected players (force="..player.force.name..")")  end
		end
	end		
	
	--EVL switch back spec/god to spec/real before leaving
	if global.god_players[player_name] and global.god_players[player_name] == true then
		player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))
		player.create_character()
		player.force = game.forces["spectator"]
		player.zoom=0.30
		player.show_on_map=true  -- EVL restore dots on map view for players and spectators (new in 1.1.47)
		global.god_players[player_name] = nil
		if global.bb_debug_gui then game.print("DEBUGUI: <<on_pre_player_left_game>> " ..player_name .. " is leaving, switches back to real mode.") end
	end
end

commands.add_command('close-screens','Closes player or all screen.guiS (parameter = none or <<all>>).',
	function(cmd) 
		local _player_index = cmd.player_index
		local _player = game.players[_player_index] --EVL enough of testing player, it must be ok all the time :)
		local _param
		if cmd.parameter then _param=cmd.parameter end
		if not(_param) or _param=="" then --Clear player screen GUIs
			_msg=Public.close_all_screens(_player.name)
			_player.print(">>>>> Cleared only your screen.guiS.", {r = 250, g = 250, b = 50})
			_player.play_sound{path = global.sound_success, volume_modifier = 0.8}
		elseif string.lower(cmd.parameter)=="all" then --Clear all screen GUIs(ifadmin, if not clear only player guis)
			if _player.admin then 
				_msg=Public.close_all_screens("all")
				--game.print(">>>>> Cleared all screen.guiS, result : \n".._msg, {r = 250, g = 250, b = 50})
				game.print(">>>>> Cleared all screen.guiS.", {r = 250, g = 250, b = 50})
			else
				_msg=Public.close_all_screens(_player.name)
				_player.print(">>>>> Only admins can clear all screen.guiS. Clearing only yours.", {r = 250, g = 50, b = 50})
			end
		else --Clear player GUIs
			_msg=Public.close_all_screens(_player.name)
			_player.print(">>>> Parameter is not accurate, assuming you wanted to clear only your screen.guiS !", {r = 250, g = 50, b = 50})
			_player.play_sound{path = global.sound_error, volume_modifier = 0.8}
		end
	end
)

commands.add_command('inventory','Opens a players inventory (deprecated).',
	function(cmd)
		local player = game.player
		player.print(">>>>> Sorry, this command has been deprecated, click on a player or team name to open crafts & inventory.", Color.warning) 
		return
    end
)

Event.add(defines.events.on_player_main_inventory_changed, update_inventory_gui)
--Event.add(defines.events.on_player_crafted_item, update_inventory_gui) --EVL mostly useless since a craft will change inventory
Event.add(defines.events.on_player_cursor_stack_changed, update_inventory_gui)
--Event.add(defines.events.on_gui_closed, on_gui_closed) --DEBUG-- using gui.screen gives weird auto closing inv_gui
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game) --EVL switch back spec/god to spec/real before leaving, close all inventories, store force of disco player
Event.add(defines.events.on_gui_location_changed, on_gui_location_changed)


return Public