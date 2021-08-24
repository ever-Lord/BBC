local Server = require 'utils.server'
local Color = require 'utils.color_presets'

--EVL some changes for BBC, only used for exceptionnal reasons
local function force_map_reset(reason)
    local player = game.player
	--EVL we want to confirm action
	if not global.confirm_map_reset_exceptional then global.confirm_map_reset_exceptional=false end
	
    if player and player ~= nil then
        if not player.admin then
			player.print("[ERROR] Command is admin-only. Please ask an admin.",Color.warning)
			return
        elseif not reason or string.len(reason) <= 5 then
           player.print("[ERROR] Please enter reason, min length of 5")
			return
        else
			if not global.confirm_map_reset_exceptional then
				player.print(">>>>> Please repeat command to confirm exceptional map reset. Reason: "..reason, Color.warning)
				global.confirm_map_reset_exceptional=true
				return
			end
			if not global.rocket_silo["north"].valid or not global.rocket_silo["south"].valid then
				--game.print("[ERROR] Map is during reset already") --EVL changed to below
				
				--EVL game has ended, we can even so ask for reset (but what for : rematch ? training ?)
				msg =">>>>> Admin/Referee " .. player.name .. " initiated exceptional map reset (after end). Reason: " .. reason --EVL shouldnt be used in BBC
				msg_gui="Admin/Referee " .. player.name .. " initiated exceptional map reset (after end).\nReason: " .. reason --EVL remember (manual validation on website ?)
				game.print(msg, Color.fail)
				Server.to_discord_embed(msg)
				global.force_map_reset_exceptional=true
				global.confirm_map_reset_exceptional=false
				global.server_restart_timer=nil --EVL see main.lua (will be set to 20)
				--EVL WE ADD TO EXPORT DATAS THAT A FORCE-MAP-RESET HAS BEEN CALLED (after match ends so its fine, we just write it down)
				global.force_map_reset_export_reason[#global.force_map_reset_export_reason + 1] = msg_gui .. " (at tick="..game.tick..")"
				return
			end
			--EVL game has not ended, we can even so ask for reset (but what for ?)
			msg =">>>>> Admin/Referee " .. player.name .. " initiated exceptional map reset (before end). Reason: " .. reason --EVL shouldnt be used in BBC
			msg_gui="Admin/Referee " .. player.name .. " initiated exceptional map reset (before end).\nReason: " .. reason --EVL remember (manual validation on website ?)
			game.print(msg, Color.fail)
			Server.to_discord_embed(msg)
			--local p = global.rocket_silo["north"].position
			--global.rocket_silo["north"].die("south_biters")
			global.force_map_reset_exceptional=true
			global.confirm_map_reset_exceptional=false
			global.server_restart_timer=nil --EVL see main.lua (will be set to 20)
			--EVL WE ADD TO EXPORT DATAS THAT A FORCE-MAP-RESET HAS BEEN CALLED (before or during match ... this match should be cancelled?)
			global.force_map_reset_export_reason[#global.force_map_reset_export_reason + 1] = msg_gui .. " (at tick="..game.tick..")"
        end
    end
end

commands.add_command('force-map-reset',
                     '/force-map-reset <reason> (should never be used)',
                     function(cmd) force_map_reset(cmd.parameter); end)
