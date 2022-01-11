-- science logs tab -- 

local Tabs = require 'comfy_panel.main'
local tables = require "maps.biter_battles_v2.tables"
local event = require 'utils.event'
local bb_config = require "maps.biter_battles_v2.config"
local food_values = tables.food_values
local food_long_and_short = tables.food_long_and_short
local food_long_to_short = tables.food_long_to_short
local forces_list = tables.forces_list
local science_list = tables.science_list
local evofilter_list = tables.evofilter_list
local food_value_table_version = tables.food_value_table_version

local function initialize_dropdown_users_choice()
		global.dropdown_users_choice_force = {}
		global.dropdown_users_choice_science = {}
		global.dropdown_users_choice_evo_filter = {}
end

local function get_science_text(food_name,food_short_name)
	return table.concat({"[img=item/", food_name, "][color=",food_values[food_name].color, "]", food_short_name, "[/color]"})
end

local function add_science_logs(player, element)
	local science_scrollpanel = element.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	science_scrollpanel.style.maximal_height = 530
	
	if global.science_logs_category_potion == nil then
		global.science_logs_category_potion = { }
		for i = 1, 7 do
			table.insert(global.science_logs_category_potion, get_science_text(food_long_and_short[i].long_name, food_long_and_short[i].short_name))
		end
	end
	if global.science_logs_total_north == nil then
		global.science_logs_total_north = { 0 }
		global.science_logs_total_south = { 0 }
		for _ = 1, 7 do
			table.insert(global.science_logs_total_north, 0)
			table.insert(global.science_logs_total_south, 0)
		end
	end
	
	local t_summary = science_scrollpanel.add { type = "table", name = "science_logs_summary_header_table", column_count = 8 }
	local width_summary_columns = tonumber(94)
	local width_summary_first_column = tonumber(110)
	local column_widths = {width_summary_first_column, width_summary_columns, width_summary_columns, width_summary_columns, width_summary_columns, width_summary_columns, width_summary_columns, width_summary_columns}
	local headersSummary = {
		[1] = "",
		[2] = global.science_logs_category_potion[1],
		[3] = global.science_logs_category_potion[2],
		[4] = global.science_logs_category_potion[3],
		[5] = global.science_logs_category_potion[4],
		[6] = global.science_logs_category_potion[5],
		[7] = global.science_logs_category_potion[6],
		[8] = global.science_logs_category_potion[7]
	}
	--HEAD LINE SUMMARY
	for _, w in ipairs(column_widths) do
		local label = t_summary.add { type = "label", caption = headersSummary[_] }
		label.style.minimal_width = w
		label.style.maximal_width = w
	end
	--NORTH SUMMARY
	summary_panel_table = science_scrollpanel.add { type = "table", column_count = 8 }
	local label = summary_panel_table.add { type = "label", name = "science_logs_total_north_header", caption = "Total sent by north" }
	label.style.minimal_width = width_summary_first_column
	label.style.maximal_width = width_summary_first_column
	for i = 1, 7 do
		local label = summary_panel_table.add { type = "label", name = "science_logs_total_north_" .. i, caption = global.science_logs_total_north[i] }
		label.style.minimal_width = width_summary_columns
		label.style.maximal_width = width_summary_columns
	end
	science_scrollpanel.add({type = "line"})
	--SOUTH SUMMARY
	summary_panel_table2 = science_scrollpanel.add { type = "table", column_count = 8 }
	local label = summary_panel_table2.add { type = "label", name = "science_logs_total_south_header", caption = "Total sent by south" }
	label.style.minimal_width = width_summary_first_column
	label.style.maximal_width = width_summary_first_column
	for i = 1, 7 do
	local label = summary_panel_table2.add { type = "label", name = "science_logs_total_south" .. i, caption = global.science_logs_total_south[i] }
		label.style.minimal_width = width_summary_columns
		label.style.maximal_width = width_summary_columns
	end
	science_scrollpanel.add({type = "line"})
	--PASSIVE FEED SUMMARY
	summary_panel_table3 = science_scrollpanel.add { type = "table", column_count = 8 }
	local label = summary_panel_table3.add { type = "label", name = "science_logs_total_passive_feed_header", caption = "Total passive feed" }
	label.style.minimal_width = width_summary_first_column
	label.style.maximal_width = width_summary_first_column
	for i = 1, 7 do
		local text_passive_feed = "0"
		if global.total_passive_feed_redpotion ~= nil then
			text_passive_feed = math.round(global.total_passive_feed_redpotion * food_value_table_version[1] / food_value_table_version[i],1)
		end
		local label = summary_panel_table3.add { type = "label", name = "science_logs_passive_feed" .. i, caption = text_passive_feed }
		label.style.minimal_width = width_summary_columns
		label.style.maximal_width = width_summary_columns
	end
	science_scrollpanel.add({type = "line"})
	
	--EVL BOOST mode infos
	local t_boost_info = "   Note : ARMAGEDDON (after ".. math.floor(global.evo_boost_tick/3600) .." minutes) does not appear here (TODO)"
	local t_boost = science_scrollpanel.add {type = "label", name = "science_logs_boost_info", caption = t_boost_info }
	t_boost.style.font_color = { r=0.66, g=0.66, b=0.66 }
	science_scrollpanel.add({type = "line"})
	--EVL END
	
	if global.dropdown_users_choice_force == nil then
		initialize_dropdown_users_choice()
	end
	if global.dropdown_users_choice_force[player.name] == nil then
		global.dropdown_users_choice_force[player.name] = 1
	end
	if global.dropdown_users_choice_science[player.name] == nil then
		global.dropdown_users_choice_science[player.name] = 1
	end
	if global.dropdown_users_choice_evo_filter[player.name] == nil then
		global.dropdown_users_choice_evo_filter[player.name] = 1
	end
	

	
	
	local t_filter = science_scrollpanel.add { type = "table", name = "science_logs_filter_table", column_count = 5 }
	
	local dropdown_force = t_filter.add { name = "dropdown-force", type = "drop-down", items = forces_list, selected_index = global.dropdown_users_choice_force[player.name] }
	local dropdown_science = t_filter.add { name = "dropdown-science", type = "drop-down", items = science_list, selected_index = global.dropdown_users_choice_science[player.name] }
	local dropdown_evofilter = t_filter.add { name = "dropdown-evofilter", type = "drop-down", items = evofilter_list, selected_index = global.dropdown_users_choice_evo_filter[player.name] }
	--EVL Add export button for simulation mode (ie pattern-training)
	t_filter.add({ type = "label", caption = "     "})
	if player.name=="everLord" or player.name=="Firerazer" then --reserved button to export sendings patterns
		local button = t_filter.add({
				type = "button",
				name = "science_logs_export_sendings",
				caption = "  Export sendings  ",
				tooltip = "Into file <<script-output/sendings_xxxx.txt>>."
			})
		button.style.font_color = {r=0.10, g=0.5, b=0.1}
		button.style.height = 20
		button.style.top_padding = -5
		button.style.horizontal_align = "center"
	end
	
	local t = science_scrollpanel.add { type = "table", name = "science_logs_header_table", column_count = 4 }
	local column_widths = {tonumber(75), tonumber(310), tonumber(165), tonumber(230)}
	local headers = {
		[1] = "Time",
		[2] = "Details",
		[3] = "Evo jump",
		[4] = "Threat jump",
	}
	for _, w in ipairs(column_widths) do
		local label = t.add { type = "label", caption = headers[_] }
		label.style.minimal_width = w
		label.style.maximal_width = w
		label.style.font = "default-bold"
		label.style.font_color = { r=0.98, g=0.66, b=0.22 }
		if _ == 1 then
			label.style.horizontal_align = "center"
		end
	end
	
	local n = bb_config.north_side_team_name
	local s = bb_config.south_side_team_name
	if global.tm_custom_name["north"] then n = global.tm_custom_name["north"] end
	if global.tm_custom_name["south"] then s = global.tm_custom_name["south"] end	
	local team_strings = {
		["north"] = table.concat({"[color=120, 120, 255]", n, "[/color]"}),
		["south"] = table.concat({"[color=255, 65, 65]", s, "[/color]"})
	}
	if global.science_logs_date then
		for i = 1, #global.science_logs_date, 1 do
			local real_force_name = global.science_logs_fed_team[i]
			local custom_force_name = team_strings[real_force_name];
			local easy_food_name = food_long_to_short[global.science_logs_food_name[i]].short_name
			
			if dropdown_force.selected_index == 1 or real_force_name:match(dropdown_force.get_item(dropdown_force.selected_index)) then
				if dropdown_science.selected_index == 1
				or (dropdown_science.selected_index == 2 and (easy_food_name:match("space") or easy_food_name:match("utility") or easy_food_name:match("production")))
				or (dropdown_science.selected_index == 3 and (easy_food_name:match("space") or easy_food_name:match("utility") or easy_food_name:match("production")or easy_food_name:match("chemical")))
				or (dropdown_science.selected_index == 4 and (easy_food_name:match("space") or easy_food_name:match("utility") or easy_food_name:match("production")or easy_food_name:match("chemical") or easy_food_name:match("military")))
				or easy_food_name:match(dropdown_science.get_item(dropdown_science.selected_index))
				then
					if dropdown_evofilter.selected_index == 1 
					or (dropdown_evofilter.selected_index == 2 and (global.science_logs_evo_jump_difference[i] > 0))
					or (dropdown_evofilter.selected_index == 3 and (global.science_logs_evo_jump_difference[i] >= 10))
					or (dropdown_evofilter.selected_index == 4 and (global.science_logs_evo_jump_difference[i] >= 5))
					or (dropdown_evofilter.selected_index == 5 and (global.science_logs_evo_jump_difference[i] >= 4))
					or (dropdown_evofilter.selected_index == 6 and (global.science_logs_evo_jump_difference[i] >= 3))
					or (dropdown_evofilter.selected_index == 7 and (global.science_logs_evo_jump_difference[i] >= 2))
					or (dropdown_evofilter.selected_index == 8 and (global.science_logs_evo_jump_difference[i] >= 1))
					then
						science_panel_table = science_scrollpanel.add { type = "table", column_count = 4 }
						local label = science_panel_table.add { type = "label", name = "science_logs_date" .. i, caption = global.science_logs_date[i] }
						label.style.minimal_width = column_widths[1]
						label.style.maximal_width = column_widths[1]
						label.style.horizontal_align = "center"
						local label = science_panel_table.add { type = "label", name = "science_logs_text" .. i, caption = global.science_logs_text[i] .. custom_force_name }
						label.style.minimal_width = column_widths[2]
						label.style.maximal_width = column_widths[2]
						local label = science_panel_table.add { type = "label", name = "science_logs_evo_jump" .. i, caption = global.science_logs_evo_jump[i].."   [color=200,200,200](+"..global.science_logs_evo_jump_difference[i]..")[/color]" }
						label.style.minimal_width = column_widths[3]
						label.style.maximal_width = column_widths[3]
						local label = science_panel_table.add { type = "label", name = "science_logs_threat" .. i, caption = global.science_logs_threat[i].."   [color=200,200,200](+"..global.science_logs_threat_jump_difference[i]..")[/color]" }
						label.style.minimal_width = column_widths[4]
						label.style.maximal_width = column_widths[4]
						science_scrollpanel.add({type = "line"})
					end
				end
			end
		end
	end
end

function comfy_panel_get_active_frame(player)
	if not player.gui.left.comfy_panel then return false end
	if not player.gui.left.comfy_panel.tabbed_pane.selected_tab_index then return player.gui.left.comfy_panel.tabbed_pane.tabs[1].content end
	return player.gui.left.comfy_panel.tabbed_pane.tabs[player.gui.left.comfy_panel.tabbed_pane.selected_tab_index].content 
end

local build_config_gui = (function (player, frame)		
	local frame_sciencelogs = comfy_panel_get_active_frame(player)
	if not frame_sciencelogs then
		return
	end
	frame_sciencelogs.clear()
	add_science_logs(player, frame_sciencelogs)
end)


local function on_gui_selection_state_changed(event)
	local player = game.players[event.player_index]	
	if not event.element.valid then return end
	local name = event.element.name
	if global.dropdown_users_choice_force == nil then
		initialize_dropdown_users_choice()
	end
	if name == "dropdown-force" then
		global.dropdown_users_choice_force[player.name] = event.element.selected_index
		build_config_gui(player, frame_sciencelogs)
	end
	if name == "dropdown-science" then
		global.dropdown_users_choice_science[player.name] = event.element.selected_index
		build_config_gui(player, frame_sciencelogs)
	end
	if name == "dropdown-evofilter" then
		global.dropdown_users_choice_evo_filter[player.name] = event.element.selected_index
		build_config_gui(player, frame_sciencelogs)
	end
end

event.add(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)

comfy_panel_tabs["MutagenLog"] = {gui = build_config_gui, admin = false}

local Public = {}
function Public.science_logs_export_sendings(event)
	
	local _exp_north = {}			-- TABLE SENDINGS FROM NORTH
	local _exp_south = {}			-- TABLE SENDINGS FROM SOUTH
	
	if global.science_logs_date and #global.science_logs_date>0 then
		_exp_north["Collect"]={}		
		_exp_north["Pattern"]={}
		_exp_south["Collect"]={}
		_exp_south["Pattern"]={}

		--COLLECT THE SENDINGS BY SIDE
		for i = 1, #global.science_logs_date, 1 do
			local _min = tonumber(string.sub(global.science_logs_date[i],0,-4))
			local _food = food_long_to_short[global.science_logs_food_name[i]].short_name
			local _qtity=global.science_logs_food_qtity[i]
			
			if global.science_logs_fed_team[i]=="south" then
				--game.print("North | ".._min.." min | Food: ".._food.." | Qtity:".._qtity.." | Text:"..global.science_logs_text[i].." | "..global.science_logs_fed_team[i])
				if not(_exp_north["Collect"][_min]) then _exp_north["Collect"][_min]={} end
				if _exp_north["Collect"][_min][_food] then
					_exp_north["Collect"][_min][_food]=_exp_north["Collect"][_min][_food]+_qtity
				else
					_exp_north["Collect"][_min][_food]=_qtity
				end

			elseif global.science_logs_fed_team[i]=="north" then
				--game.print("South | ".._min.." min | Food: ".._food.." | Qtity:".._qtity.." | Text:"..global.science_logs_text[i].." | "..global.science_logs_fed_team[i])
				if not(_exp_south["Collect"][_min]) then _exp_south["Collect"][_min]={} end
				if _exp_south["Collect"][_min][_food] then
					_exp_south["Collect"][_min][_food]=_exp_south["Collect"][_min][_food]+_qtity
				else
					_exp_south["Collect"][_min][_food]=_qtity
				end					
			else 
				game.print("WTF?? | ".._min.." min | Food: "..global.science_logs_food_name[i].." | Qtity:".._qtity.." | Text:"..global.science_logs_text[i].." | "..global.science_logs_fed_team[i])
			end
		end
		--game.print("--------------------------------------------------------------------------------------------")

		
		--CONCAT THE SENDINGS OF NORTH SIDE
		for _min,_sendings in pairs(_exp_north["Collect"]) do
			_exp_north["Pattern"][_min]=''
			for _science=1,7,1 do
				if _sendings[food_long_and_short[_science].short_name] then
					_exp_north["Pattern"][_min]=_exp_north["Pattern"][_min]..'"'..food_long_and_short[_science].short_name..'",'.._sendings[food_long_and_short[_science].short_name]..','
				end
			end
			_exp_north["Pattern"][_min]=string.sub(_exp_north["Pattern"][_min], 1, string.len(_exp_north["Pattern"][_min])-1) --remove last ","
			_exp_north["Pattern"][_min]='{'.._exp_north["Pattern"][_min]..'}'
			--game.print("North | Min ".._min.." | ".._exp_north["Pattern"][_min])
		end
		--game.print(".......................")
		
		--CONCAT THE SENDINGS OF SOUTH SIDE
		for _min,_sendings in pairs(_exp_south["Collect"]) do
			_exp_south["Pattern"][_min]=''
			for _science=1,7,1 do
				if _sendings[food_long_and_short[_science].short_name] then
					_exp_south["Pattern"][_min]=_exp_south["Pattern"][_min]..'"'..food_long_and_short[_science].short_name..'",'.._sendings[food_long_and_short[_science].short_name]..','
				end
			end
			_exp_south["Pattern"][_min]=string.sub(_exp_south["Pattern"][_min], 1, string.len(_exp_south["Pattern"][_min])-1) --remove last ","
			_exp_south["Pattern"][_min]='{'.._exp_south["Pattern"][_min]..'}'
			--game.print("South | Min ".._min.." | ".._exp_south["Pattern"][_min])
		end
		
		--EXPORT GLOBAL VALUES
		local _pack_chosen=global.pack_choosen
		if _pack_chosen=="" then _pack_chosen="pack_xx" end
		local output_north_gameid="xx+0"
		local output_south_gameid="xx+1"
		local output_file_name="sendings_xxxx"
		local output_file_append=true
		if global.game_id and global.game_id~="" then -- what is the game Id (also to determine output file name)
			if global.game_id=="training" or global.game_id=="scrim" then
				output_north_gameid=global.game_id.."#north"
				output_south_gameid=global.game_id.."#south"
				output_file_name="sendings_"..global.game_id
				
			elseif global.game_id%123==0 then
				output_north_gameid=global.game_id
				output_south_gameid=global.game_id+1
				output_file_name="sendings_"..global.game_id
				--output_file_append=false
				output_file_append=true
			else 
				game.print(">>>>> UNABLE TO EXPORT PATTERNS.", {r = 0.99, g = 0.33, b = 0.33})
				return
			end
		end
		output_file_name=output_file_name..".txt"

		--EXPORT NORTH/SOUTH SENDINGS
		local output_north_team="North"
		if global.tm_custom_name["north"] then output_north_team=global.tm_custom_name["north"] end
		local output_south_team="South"
		if global.tm_custom_name["south"] then output_south_team=global.tm_custom_name["south"] end
		
		local output_north='Public.detail_game_id['..output_north_gameid..'] = { ["Team"]="'..output_north_team..'", ["Info"]="Pattern info", ["Pack"]="'.._pack_chosen..'", ["Versus"]="'..output_south_team..'", ["Date"]="dd mon yy",\n'
		output_north=output_north..'    ["Pattern"]={\n'


		local output_south='Public.detail_game_id['..output_south_gameid..'] = { ["Team"]="'..output_south_team..'", ["Info"]="Pattern info", ["Pack"]="'.._pack_chosen..'", ["Versus"]="'..output_north_team..'", ["Date"]="dd mon yy",\n'
		output_south=output_south..'    ["Pattern"]={\n'

		-- sorting manually (don't know how to table.sort indexes)
		for _min=0,300 do -- from min 0 to min 300 meaning 5 first hours.. enough ?
			if _exp_north["Pattern"][_min] then output_north=output_north..'       ['.._min..']='.. _exp_north["Pattern"][_min]..',\n' end
			if _exp_south["Pattern"][_min] then output_south=output_south..'       ['.._min..']='.. _exp_south["Pattern"][_min]..',\n' end
		end
		
		output_north=output_north..'       [999]={"logistic",0,"military",0,"chemical",0}\n'
		output_north=output_north..'    }\n}'
		--game.print(output_north)
	
		--game.print("   ")
		
		output_south=output_south..'       [999]={"logistic",0,"military",0,"chemical",0}\n'
		output_south=output_south..'    }\n}'
		--game.print(output_south)

		game.write_file(output_file_name, output_north..'\n\n'..output_south..'\n\n__________________________________________\n\n', output_file_append)
		game.print(">>>>>Sendings exported to file "..output_file_name.. " !", {r = 0.22, g = 0.99, b = 0.55})
	else
		game.print("No data to export.")
	end
	
	
end
return Public