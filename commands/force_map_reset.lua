local Server = require 'utils.server'
local Functions = require "maps.biter_battles_v2.functions"
local show_inventory = require 'modules.show_inventory_bbc'
--EVL some changes for BBC, only used for exceptionnal reasons
local function force_map_reset(reason)
    local player = game.player
	--EVL we want to confirm action
	if not global.confirm_map_reset_exceptional then global.confirm_map_reset_exceptional=false end
	if game.tick_paused then
		player.print(">>>>> [ERROR] /force-map-reset cannot be asked while game is paused",{r = 175, g = 100, b = 100})
	end
    if player and player ~= nil then
        if not player.admin then
			player.print(">>>>> [ERROR] /force-map-reset is admin-only. Please ask an admin.",{r = 175, g = 100, b = 100})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
        elseif not reason or string.len(reason) <= 5 then
           player.print(">>>>> [ERROR] Please enter reason for /force-map-reset, min length of 6", {r = 175, g = 100, b = 100})
			player.play_sound{path = global.sound_error, volume_modifier = 0.8}
			return
        else
			if not global.confirm_map_reset_exceptional then
				player.print(">>>>> Please repeat command to confirm [color=#FFAAAA]exceptional[/color] map reset. Reason: "..reason, {r = 100, g = 175, b = 175})
				player.play_sound{path = "utility/console_message", volume_modifier = 0.8}
				global.confirm_map_reset_exceptional=true
				return
			end
			if not global.rocket_silo["north"].valid or not global.rocket_silo["south"].valid then
				--EVL game has ended, we can even so ask for reset (but what for : rematch ? training ?)
				msg = ">>>>> Admin/Referee " .. player.name .. " initiated [color=#FFAAAA]exceptional[/color] map reset (after end). Reason: " .. reason --EVL shouldnt be used in BBC
				msg_gui = player.name .. " initiated [color=#FF9740]exceptional[/color]  map reset (after end). Reason: " .. reason --EVL remember (manual validation on website ?)
				game.print(msg,{r = 175, g = 100, b = 100})
				Server.to_discord_embed(msg)
				global.force_map_reset_exceptional=true
				global.confirm_map_reset_exceptional=false
				global.server_restart_timer=nil --EVL see main.lua (will be set to 20)
				--EVL WE ADD TO EXPORT DATAS THAT A FORCE-MAP-RESET HAS BEEN CALLED (after match ends so its fine (datas are already exported), we just write it down)
				table.insert(global.force_map_reset_export_reason, msg_gui .. " (at tick="..game.tick..")")
				return
			end
			--EVL game has not ended, we can even so ask for reset (but what for ?)
			msg =">>>>> Admin/Referee " .. player.name .. " initiated [color=#FFAAAA]exceptional[/color] map reset (before end). Reason: " .. reason --EVL shouldnt be used in BBC
			msg_gui= player.name .. " initiated [color=#FF9740]exceptional[/color] map reset (before end). Reason: " .. reason --EVL remember (manual validation on website ?)
			game.print(msg, {r = 175, g = 100, b = 100})
			Server.to_discord_embed(msg)
			global.force_map_reset_exceptional=true
			global.confirm_map_reset_exceptional=false
			global.server_restart_timer=nil --EVL see main.lua (will be set to 20)
			--EVL WE ADD TO EXPORT DATAS THAT A FORCE-MAP-RESET HAS BEEN CALLED (before or during match ... this match should be cancelled?)
			table.insert(global.force_map_reset_export_reason, msg_gui .. " (at tick="..game.tick..")")
			--EVL Clear/Destroy all inventories (on_pre_player_left & on force-map-reset & on starting sequence // but not needed on reroll)
			Functions.remove_all_pause_and_game_type_buttons()
			show_inventory.close_all_screens("all")
        end
    end
end
local function starting_sequence()
    local player = game.player
	--EVL we want to confirm action
	if not global.confirm_starting_sequence then global.confirm_starting_sequence=false end
	
    if player and player ~= nil then
        if not player.admin then
			player.print(">>>>> [ERROR] /starting-sequence is admin-only. Please ask a referee.",{r = 175, g = 100, b = 100})
			return
        else
			if not global.confirm_starting_sequence then
				player.print(">>>>> Please repeat command to confirm [color=#FFAAAA]starting sequence[/color] map reset.", {r = 100, g = 175, b = 175})
				global.confirm_starting_sequence=true
				return
			end
			--EVL game has not ended, we can even so ask for reset (but what for ?)
			game.print("To be fair with everyone, there will be a map reset to be sure that the server is seeded with a genuinely random seed.", {r = 175, g = 255, b = 175})
			msg =">>>>> Admin/Referee " .. player.name .. " initiated [color=#FFAAAA]starting sequence[/color] map reset."
			msg_gui= player.name .. " initiated starting sequence map reset" --EVL remember (manual validation on website ?)
			game.print(msg, {r = 175, g = 100, b = 100})
			for _, player in pairs(game.players) do
				Functions.show_rules(player)
			end
			
			Server.to_discord_embed(msg)
			global.force_map_reset_exceptional=true
			global.confirm_starting_sequence=false
			global.server_restart_timer=nil --EVL see main.lua (will be set to 20)
			--EVL WE ADD TO EXPORT DATAS THAT A FORCE-MAP-RESET HAS BEEN CALLED (before or during match ... this match should be cancelled?)
			table.insert(global.force_map_reset_export_reason, msg_gui .. " (at tick="..game.tick..").")
			--EVL Clear/Destroy all inventories (on_pre_player_left & on force-map-reset & on starting sequence // but not needed on reroll)
			Functions.remove_all_pause_and_game_type_buttons()
			show_inventory.close_all_screens("all")
        end
    end
end
commands.add_command('force-map-reset','/force-map-reset <<reason>> (should never be used)',function(cmd) force_map_reset(cmd.parameter) end)--; end)--DEBUG--
commands.add_command('starting-sequence','/starting-sequence (initiate official match)',function(cmd) starting_sequence(); end)