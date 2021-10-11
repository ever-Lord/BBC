local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Public = {}
local viewing_inventory={}

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

--DEBUG-- Not used currently
local function on_gui_closed(event)
	-- Do we have a gui ?
	if not event.gui_type then 
		if global.bb_debug_gui then game.print("DEBUGUI : Gui missing (thats ok)       |"..math.random(100,500)) end
		return 
	end
	--Whose player is the gui that was closed ?
	local _source = game.players[event.player_index]
	
	-- What is  the index of this gui ?
	local _event_index = defines.gui_type.custom
	if global.bb_debug_gui then game.print("DEBUGUI : Event index =  ".._event_index.."        |"..math.random(100,500)) end
	
	-- What is the index of our inventory gui ?
	local screen = _source.gui.screen
	if not validate_object(screen) then game.print("DEBUGUI : Screen not valid        |"..math.random(100,500)) return end
	local inventory_gui = screen.inventory_gui	
	if not validate_object(inventory_gui) then 
		if global.bb_debug_gui then game.print("DEBUGUI : Inventory gui not valid        |"..math.random(100,500)) end
		return 
	end
	local _inventory_index=inventory_gui.index
	--local _inventory_index=111
	if global.bb_debug_gui then game.print("DEBUGUI : Inventory index =  ".._inventory_index.."        |"..math.random(100,500)) end	

	-- Are they the same ?
	if _event_index == _inventory_index then
		if global.bb_debug_gui then game.print("DEBUGUI : _inventory_index = _event_index         |"..math.random(100,500)) end
		
		if viewing_inventory[_source.name] and viewing_inventory[_source.name]~="" then
			viewing_inventory[_source.name]=""
			if global.bb_debug_gui then game.print("DEBUGUI : gui_closed : viewing_inventory updated after inventory_gui was closed.       |"..math.random(100,500)) end
		else
			if global.bb_debug_gui then game.print("DEBUGUI : gui_closed : There should be a inventory opened, cant find it...        |"..math.random(100,500))	end
		end
		-- _inventory_index.destroy() ????
	else
		if global.bb_debug_gui then game.print("DEBUGUI : _inventory_index <> _event_index         |"..math.random(100,500)) end
	end


end

-- Close the inventory via Close_button
function Public.close_inventory(player)
	if viewing_inventory[player.name] and viewing_inventory[player.name]~="" then
		--local screen = player.gui.screen
		local screen = player.gui.center
		if not validate_object(screen) then return end
		local inventory_gui = screen.inventory_gui
		if not validate_object(inventory_gui) then 
			if bb_debug_gui then game.print("DEBUGUI close_inventory : inventory_gui is not valid...") end
			return
		end
		if global.bb_debug_gui then game.print("DEBUGUI : Closing inventory.") end
		viewing_inventory[player.name]=""
		inventory_gui.destroy()	 
	else
		if global.bb_debug_gui then game.print("DEBUGUI close_inventory : There should be a inventory opened, cant find it...") end
	end
end

--Close inventory_gui before player leaves game (do we really need this ?)
local function on_pre_player_left_game(event)
    local player = game.players[event.player_index]
    if viewing_inventory[player.name] and viewing_inventory[player.name]~="" then
		close_inventory(player)
	end
end

local function draw_inventory(inventory_gui, target)
	local types = game.item_prototypes  --EVL used to show tooltip in buttons
	
	--EVL Name in title 
	inventory_gui.caption = 'Crafting & Inventory of ' .. target.name .. '    [font=default-small][color=#999999](Click [/color][color=#fa3232]X[/color][color=#999999] to close)[/color][/font]'
	-- .. '    [font=default-small][color=#aaaaaa](press E or ESC to close)[/color][/font]' --DEBUG--

	--EVL Insert Crafting list
	local crafting_list = target.crafting_queue
	local crafting_list_table = inventory_gui.add({type = 'table', column_count = 10}) 
	
	if crafting_list ~= nil then
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
					name = recipe,
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
	local cursor_stack_table = inventory_gui.add({type = 'table', column_count = 5}) 
	local cursor_stack_next = cursor_stack_table.add({type = 'label', caption='  ▲ Crafting            ▼ Inventory            '})

	--EVL Cursor_Stack
	local cursor_stack = target.cursor_stack
	local cursor_stack_info = cursor_stack_table.add({type = 'label', caption='Item in hand ► '})	
	if cursor_stack.count>0 then
		local button =
			cursor_stack_table.add({
				type = 'sprite-button',
				sprite = 'item/' .. cursor_stack.name,
				number = cursor_stack.count,
				name = cursor_stack.name,
				tooltip = types[cursor_stack.name].localised_name,
				style = 'slot_button'
			})
		button.enabled = false
	else
		local cursor_stack_info = cursor_stack_table.add({type = 'label', caption='    -    '})
	end

	--EVL CLOSE Button
	local cursor_stack_blank = cursor_stack_table.add({type = 'label', caption='               '})
	local close_inventory  = cursor_stack_table.add({type = "button", name = "inventory_close", caption = "X", tooltip = "Close this window."})
	close_inventory.style.font = "heading-2"
	close_inventory.style.font_color = {250, 50, 50}
	close_inventory.style.minimal_height = 24
	close_inventory.style.minimal_width = 24
	close_inventory.style.padding = -2
	
	--EVL Insert Main Inventory
	local main_inventory = target.get_main_inventory().get_contents()
	local main_inventory_table = inventory_gui.add({type = 'table', column_count = 10}) 
	if main_inventory ~= {} then
		for name, opts in pairs(main_inventory) do
			local flow = main_inventory_table.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					name = name,
					tooltip = types[name].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local main_inventory_info = main_inventory_table.add({type = 'label', caption='(inventory is empty)'})
	end

	--EVL Add a horizontal separator
	local line = inventory_gui.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8
	
	--

	--
	
	--Table in GUI for armor/guns/ammo
	local armor_guns_inventory_table = inventory_gui.add({type = 'table', column_count = 10}) 
	--Draw Armor (with grid in tooltip)
	local armor_inventory = target.get_inventory(defines.inventory.character_armor).get_contents()
	if armor_inventory ~= {} then
		for name, opts in pairs(armor_inventory) do
			local armor_tooltip=""
			if target.get_inventory(5)[1].grid then
				local p_armor = target.get_inventory(5)[1].grid.get_contents()
					for k, v in pairs(p_armor) do
						armor_tooltip = armor_tooltip.."[img=item."..k.."]x"..v.."   "
					end
			end
			if armor_tooltip=="" then
				armor_tooltip= types[name].localised_name
			end
			
			local flow = armor_guns_inventory_table.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					name = name,
					tooltip = armor_tooltip,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local armor_inventory_info = armor_guns_inventory_table.add({type = 'label', caption='No armor'})
	end
	--Separator
	local armor_inventory_info = armor_guns_inventory_table.add({type = 'label', caption='           '})
	--Draw Guns
	local guns_inventory = target.get_inventory(defines.inventory.character_guns).get_contents()
	if guns_inventory ~= {} then
		for name, opts in pairs(guns_inventory) do
			local flow = armor_guns_inventory_table.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					name = name,
					tooltip = types[name].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local guns_inventory_info = armor_guns_inventory_table.add({type = 'label', caption='No gun'})
	end
	--Separator
	local armor_inventory_info = armor_guns_inventory_table.add({type = 'label', caption='           '})
	--Draw Ammunition
	local ammo_inventory = target.get_inventory(defines.inventory.character_ammo).get_contents()
	if ammo_inventory ~= {} then
		for name, opts in pairs(ammo_inventory) do
			local flow = armor_guns_inventory_table.add({type = 'flow'})
			flow.style.vertical_align = 'bottom'
			local button =
				flow.add(
				{
					type = 'sprite-button',
					sprite = 'item/' .. name,
					number = opts,
					name = name,
					tooltip = types[name].localised_name,
					style = 'slot_button'
				}
			)
			button.enabled = false
		end
	else
		local ammo_inventory_info = armor_guns_inventory_table.add({type = 'label', caption='No ammo'})
	end


end

function Public.open_inventory(source, target)
	
	if not validate_player(source) then
		if global.bb_debug_gui then game.print("DEBUGUI : Source ("..source.name..") is not valid") end --EVL
        return
    end
    if not validate_player(target) then
       if global.bb_debug_gui then game.print("DEBUGUI : Target ("..target.name..") is not valid") end --EVL
		return
    end

    
	--local screen = source.gui.screen
	local screen = source.gui.center
    if not validate_object(screen) then return end
	
    local inventory_gui = screen.inventory_gui
	
	-- EVL Click again on same player will close inventory if exists and already show the same target (then return)
	if viewing_inventory[source.name] and viewing_inventory[source.name]==target.name then
		if not validate_object(inventory_gui) then 
			if global.bb_debug_gui then game.print("DEBUGUI : Can't find the inventory opened...") end
			return 
		end
		if global.bb_debug_gui then game.print("DEBUGUI : Closing inventory of " .. target.name .. " asked by "..source.name) end
		viewing_inventory[source.name]=""
		inventory_gui.destroy()		
		return 
	end
	
	-- EVL Clear inventory_gui if exists
	if validate_object(inventory_gui) then inventory_gui.destroy()	 end
	
	--EVL Add this target in the list of viewing inventory of source
	if global.bb_debug_gui then game.print("DEBUGUI : Opening inventory of " .. target.name .. " asked by "..source.name) end    
	viewing_inventory[source.name]=target.name
	
	--EVL Create new inventory
    inventory_gui = screen.add({type = 'frame', caption = 'Inventory', direction = 'vertical', name = 'inventory_gui'})
    if not validate_object(inventory_gui) then return end
    --inventory_gui.auto_center = true
    --source.opened = inventory_gui --DEBUG--  is it necessary ?
    inventory_gui.style.minimal_width = 450
    inventory_gui.style.minimal_height = 250

	draw_inventory(inventory_gui, target)
	
end

local function update_inv_gui (event)
	
	local target = game.players[event.player_index]
	for _, player in pairs(game.connected_players) do
		if viewing_inventory[player.name] and viewing_inventory[player.name]==target.name then
			--local screen = player.gui.screen
			local screen = player.gui.center
			if not validate_object(screen) then return end
			local inventory_gui = screen.inventory_gui
			
			if not validate_object(inventory_gui) then 
				if bb_debug_gui then game.print("cannot find gui for "..player.name.." viewing "..target.name.."         |"..math.random(100,500)) end
				viewing_inventory[player.name]=""
				return
			else
				--game.print("clearing gui for "..player.name.." viewing "..target.name.. "(before updating)        |"..math.random(100,500))
				inventory_gui.clear()	 
			end
			draw_inventory(inventory_gui, target)
			--game.print(">>>>>  Inventory updated #"..inventory_gui.index.."      |"..math.random(100,500))
		end
	end
end

commands.add_command(
    'inventory',
    'Opens a players inventory!',
	function(cmd)
		local player = game.player
		player.print(">>>>> Sorry, this command has been deprecated, click on a player name to open his crafts&inventory.", Color.warning) 
		return
    end
)

Event.add(defines.events.on_player_main_inventory_changed, update_inv_gui)
Event.add(defines.events.on_player_crafted_item, update_inv_gui)
Event.add(defines.events.on_player_cursor_stack_changed, update_inv_gui)
--Event.add(defines.events.on_gui_closed, on_gui_closed) --DEBUG-- using gui.screen gives weird auto closing inv_gui
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

return Public