-- name: Flood Workshop
-- category: gamemode
-- incompatible: gamemode flood
-- description: Flood Workshop v1\nBy \\#008800\\Squishy6094\\#dcdcdc\\\n\nThis mod adds a flood escape gamemode\nto sm64coopdx, you must escape the flood and reach the top of the level before everything is flooded.\n\nFlood Workshop aims to update the original Flood with a fresh coat of paint, while keeping the expirience as close to the original as possible!\n\nOriginal By \\#ec7731\\Agent X\n\\#898989\\Forked from Flood v2.4.8

if unsupported then return end

local ROUND_STATE_INACTIVE = 0
ROUND_STATE_ACTIVE         = 1
local ROUND_COOLDOWN       = 600

local SPEEDRUN_MODE_OFF = 0
local SPEEDRUN_MODE_PROGRESS = 1
local SPEEDRUN_MODE_RESTART = 2

local TEX_FLOOD_FLAG = get_texture_info("flood_flag")

gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
gGlobalSyncTable.timer = ROUND_COOLDOWN
gGlobalSyncTable.level = LEVEL_BOB
gGlobalSyncTable.waterLevel = -20000
gGlobalSyncTable.speedMultiplier = 1
gGlobalSyncTable.materialPhys = mod_storage_load_bool("materialPhys") and mod_storage_load_bool("materialPhys") or true

local sFlagIconPrevPos = { x = 0, y = 0 }

local globalTimer = 0
local listedSurvivors = false
local speedrunner = 0

gFloodPlayers = {}
for i = 0, MAX_PLAYERS - 1 do
    gFloodPlayers[i] = {
        index = network_global_index_from_local(i),
        finished = false,
        modifiers = "",
        forceSpec = false,
        time = 0,
        timeFull = 0,
        points = 0,
    }
end

local function get_modifiers_string()
    local moveset = false
    if _G.OmmEnabled and _G.OmmApi.omm_get_setting(m, _G.OmmApi["OMM_SETTING_MOVESET"]) == _G.OmmApi["OMM_SETTING_MOVESET_ODYSSEY"] then
        moveset = true
    end
    if _G.charSelectExists then
        local charMoveset = #_G.charSelect.character_get_moveset(_G.charSelect.character_get_current_number(0)) > 0
        local charToggle = _G.charSelect.get_options_status(_G.charSelect.optionTableRef.localMoveset) ~= 0 
        if charMoveset and charToggle then
            moveset = true
        end
    end

    local modifiers = ""
    if serverMoveset or moveset then
        modifiers = modifiers .. "Moveset"
    end
    if cheats then
        modifiers = modifiers .. ", Cheats"
    end
    if modifiers ~= "" then
        modifiers = " (" .. modifiers .. ")"
    end
    return modifiers
end

local SAVETAG_TIME = "time"
local SAVETAG_POINTS = "points"

local function get_level_save_name(saveTag)
    return game..gLevels[gGlobalSyncTable.level].name..saveTag
end

local function get_best_beaten(saveTag, value)
    local saveValue = mod_storage_load_number(get_level_save_name(saveTag))
    if value == 0 or get_modifiers_string() ~= "" then return false end
    if saveValue == 0 then return true end
    if (if_then_else(saveTag == SAVETAG_TIME, value < saveValue, value > saveValue)) then return true end
    return false
end

local function get_best_beaten_string(saveTag, value)
    local saveValue = mod_storage_load_number(get_level_save_name(saveTag))
    if saveValue == 0 then return "" end
    return " \\#ffff00\\" .. (get_best_beaten(saveTag, value) and "New Record! " or "")
end

local function network_send_time(time)
    if time == nil then time = gFloodPlayers[0].time end
    gFloodPlayers[0].time = time
    if get_best_beaten(SAVETAG_TIME, time) then
        mod_storage_save_number(get_level_save_name(SAVETAG_TIME), time)
    end
    gLevels[gGlobalSyncTable.level].time = time

    local total = 0
    for i = 1, #gMapRotation do
        local level = gMapRotation[i]
        total = total + gLevels[level].time
    end
    gFloodPlayers[0].timeFull = total
    network_send(true, gFloodPlayers[0])
end

local function network_send_points(points)
    if points == nil then points = gFloodPlayers[0].points end
    gFloodPlayers[0].points = points
    if get_best_beaten(SAVETAG_POINTS, points) then
        mod_storage_save_number(get_level_save_name(SAVETAG_POINTS), points)
    end
    network_send(true, gFloodPlayers[0])
end

local function network_send_finished(finished)
    gFloodPlayers[0].finished = finished
    network_send(true, gFloodPlayers[0])
end

local function on_packet_recieve(data)
    local index = network_local_index_from_global(data.index)
    gFloodPlayers[index] = data
end

-- localize functions to improve performance
local network_player_connected_count,init_single_mario,warp_to_level,play_sound,network_is_server,network_get_player_text_color_string,djui_chat_message_create,disable_time_stop,network_player_set_description,set_mario_action,obj_get_first_with_behavior_id,obj_check_hitbox_overlap,spawn_mist_particles,vec3f_dist,play_race_fanfare,play_music,djui_hud_set_resolution,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,clampf,math_floor,djui_hud_measure_text,djui_hud_print_text,hud_render_power_meter,hud_get_value,save_file_erase_current_backup_save,save_file_set_flags,save_file_set_using_backup_slot,find_floor_height,spawn_non_sync_object,set_environment_region,vec3f_set,vec3f_copy,math_random,set_ttc_speed_setting,get_level_name,hud_hide,smlua_text_utils_secret_star_replace,smlua_audio_utils_replace_sequence = network_player_connected_count,init_single_mario,warp_to_level,play_sound,network_is_server,network_get_player_text_color_string,djui_chat_message_create,disable_time_stop,network_player_set_description,set_mario_action,obj_get_first_with_behavior_id,obj_check_hitbox_overlap,spawn_mist_particles,vec3f_dist,play_race_fanfare,play_music,djui_hud_set_resolution,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,clampf,math.floor,djui_hud_measure_text,djui_hud_print_text,hud_render_power_meter,hud_get_value,save_file_erase_current_backup_save,save_file_set_flags,save_file_set_using_backup_slot,find_floor_height,spawn_non_sync_object,set_environment_region,vec3f_set,vec3f_copy,math.random,set_ttc_speed_setting,get_level_name,hud_hide,smlua_text_utils_secret_star_replace,smlua_audio_utils_replace_sequence

function speedrun_mode(mode)
    if mode == nil then
        return speedrunner > 0 and network_player_connected_count() == 1
    else
        return speedrunner == mode and network_player_connected_count() == 1
    end
end

local function is_final_level()
    return gNetworkPlayers[0].currLevelNum == gMapRotation[#gMapRotation]
end

-- runs serverside
local function round_start()
    gGlobalSyncTable.roundState = ROUND_STATE_ACTIVE
    gGlobalSyncTable.timer = if_then_else(is_final_level(), 730, 100)
end

-- runs serverside
local function round_end()
    gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
    gGlobalSyncTable.timer = ROUND_COOLDOWN
    gGlobalSyncTable.waterLevel = -20000
end

local function get_dest_act()
    if game ~= GAME_STAR_ROAD then
        return if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS, 99, 6)
    else
        if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
            return 99
        end
        return if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_BBH, 1, 6)
    end
end

function level_restart()
    round_start()
    init_single_mario(gMarioStates[0])
    mario_set_full_health(gMarioStates[0])
    network_send_time(0)
    network_send_points(0)
    network_send_finished(network_player_connected_count() > 1 and gFloodPlayers[0].forceSpec or false)
    warp_to_level(gGlobalSyncTable.level, gLevels[gGlobalSyncTable.level].area, get_dest_act())
end

local function on_interact(m, o, type, value)
    if m.playerIndex ~= 0 then return end
    if type == INTERACT_COIN then
        gFloodPlayers[0].points = gFloodPlayers[0].points + math.max(o.oDamageOrCoinValue, 1)
    end
    if type == INTERACT_STAR_OR_KEY then
        gFloodPlayers[0].points = gFloodPlayers[0].points + 10
    end
end

local function server_update()
    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level then
            gGlobalSyncTable.waterLevel = gGlobalSyncTable.waterLevel + gLevels[gGlobalSyncTable.level].speed * gGlobalSyncTable.speedMultiplier

            local active = 0
            for i = 0, (MAX_PLAYERS - 1) do
                local m = gMarioStates[i]
                if active_player(m) ~= 0 and m.health > 0xFF and not gFloodPlayers[i].finished then
                    active = active + 1
                end
            end

            if active == 0 then
                local dead = 0
                for i = 0, (MAX_PLAYERS) - 1 do
                    if active_player(gMarioStates[i]) ~= 0 and gMarioStates[i].health <= 0xFF then
                        dead = dead + 1
                    end
                end
                if dead == network_player_connected_count() or (speedrun_mode() and not is_final_level()) then
                    gGlobalSyncTable.timer = 0
                end

                if gGlobalSyncTable.timer > 0 then
                    gGlobalSyncTable.timer = gGlobalSyncTable.timer - 1
                else
                    round_end()

                    if not speedrun_mode() or speedrun_mode(SPEEDRUN_MODE_PROGRESS) then
                        -- move to the next level
                        local finished = 0
                        for i = 0, (MAX_PLAYERS - 1) do
                            if active_player(gMarioStates[i]) ~= 0 and gFloodPlayers[i].finished then
                                finished = finished + 1
                            end
                        end

                        if finished ~= 0 then
                            -- calculate position
                            local position = 1
                            for k, v in pairs(gMapRotation) do
                                if gGlobalSyncTable.level == v then
                                    position = k
                                end
                            end

                            position = position + 1
                            if position > #gMapRotation --[[FLOOD_LEVEL_COUNT - FLOOD_BONUS_LEVELS]] then
                                position = 1
                            end

                            gGlobalSyncTable.level = gMapRotation[position]
                        end
                    end
                end
            end
        end
    else
        if network_player_connected_count() > 1 then
            if gGlobalSyncTable.timer > 0 then
                gGlobalSyncTable.timer = gGlobalSyncTable.timer - 1

                if gGlobalSyncTable.timer == 30 or gGlobalSyncTable.timer == 60 or gGlobalSyncTable.timer == 90 then
                    play_sound(SOUND_MENU_CHANGE_SELECT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                elseif gGlobalSyncTable.timer == 11 then
                    play_sound(SOUND_GENERAL_RACE_GUN_SHOT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                end
            else
                round_start()
            end
        end
    end
end

local function update()
    if network_is_server() then server_update() end

    if gServerSettings.playerInteractions == PLAYER_INTERACTIONS_PVP then
        gServerSettings.playerInteractions = PLAYER_INTERACTIONS_SOLID
    end
    gServerSettings.playerKnockbackStrength = 20

    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_LOBBY or gNetworkPlayers[0].currActNum ~= 0 then

            warp_to_level(LEVEL_LOBBY, 1, 0)

            if network_player_connected_count() > 1 and not listedSurvivors and globalTimer > 5 then
                listedSurvivors = true
                local finished = 0
                local string = "Survivors:"
                for i = 0, (MAX_PLAYERS - 1) do
                    if gNetworkPlayers[i].connected and gFloodPlayers[i].finished and not gFloodPlayers[i].forceSpec then
                        string = string .. "\n" .. network_get_player_text_color_string(i) .. gNetworkPlayers[i].name .. " - " .. timestamp(gFloodPlayers[i].time) .. " - " .. tostring(gFloodPlayers[i].points) .. " " .. gFloodPlayers[0].modifiers
                        finished = finished + 1
                    end
                end
                if finished == 0 then
                    string = string .. "\n\\#ff0000\\None"
                end
                djui_chat_message_create(string)
            end

            if speedrun_mode() then
                level_restart()
            end
        end
    elseif gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        local act = get_dest_act()
        if gNetworkPlayers[0].currLevelNum ~= gGlobalSyncTable.level or gNetworkPlayers[0].currActNum ~= act then
            listedSurvivors = false
            mario_set_full_health(gMarioStates[0])
            network_send_time(0)
            network_send_points(0)
            network_send_finished(network_player_connected_count() > 1 and gFloodPlayers[0].forceSpec or false)
            warp_to_level(gGlobalSyncTable.level, gLevels[gGlobalSyncTable.level].area, act)
        end
    end

    -- stops the star spawn cutscenes from happening
    local m = gMarioStates[0]
    if m.area ~= nil and m.area.camera ~= nil and (m.area.camera.cutscene == CUTSCENE_STAR_SPAWN or m.area.camera.cutscene == CUTSCENE_RED_COIN_STAR_SPAWN) then
        m.area.camera.cutscene = 0
        m.freeze = 0
        disable_time_stop()
    end

    globalTimer = globalTimer + 1
end

--- @param m MarioState
local function mario_update(m)
    if not gNetworkPlayers[m.playerIndex].connected then return end

    if m.health > 0xFF then
        network_player_set_description(gNetworkPlayers[m.playerIndex], "Alive", 75, 255, 75, 255)
    else
        network_player_set_description(gNetworkPlayers[m.playerIndex], "Dead", 255, 75, 75, 255)
    end

    if m.playerIndex ~= 0 then return end

    -- action specific modifications
    if m.action == ACT_STEEP_JUMP then
        m.action = ACT_JUMP
    elseif m.action == ACT_JUMBO_STAR_CUTSCENE then
        m.flags = m.flags | MARIO_WING_CAP
    end

    -- disable instant warps
    if m.floor ~= nil and (m.floor.type == SURFACE_WARP or (m.floor.type >= SURFACE_PAINTING_WARP_D3 and m.floor.type <= SURFACE_PAINTING_WARP_FC) or (m.floor.type >= SURFACE_INSTANT_WARP_1B and m.floor.type <= SURFACE_INSTANT_WARP_1E)) then
        m.floor.type = SURFACE_DEFAULT
    end

    -- disable insta kills
    if m.floor ~= nil and (m.floor.type == SURFACE_INSTANT_QUICKSAND or m.floor.type == SURFACE_INSTANT_MOVING_QUICKSAND) then
        m.floor.type = SURFACE_BURNING
    end

    -- disable damage in lobby
    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        mario_set_full_health(m)
        m.peakHeight = m.pos.y
    end

    -- dialog boxes
    if (m.action == ACT_SPAWN_NO_SPIN_AIRBORNE or m.action == ACT_SPAWN_NO_SPIN_LANDING or m.action == ACT_SPAWN_SPIN_AIRBORNE or m.action == ACT_SPAWN_SPIN_LANDING) and m.pos.y < m.floorHeight + 10 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    -- manage CTT
    if is_final_level() then
        local star = obj_get_first_with_behavior_id(id_bhvFinalStar)
        if star ~= nil and obj_check_hitbox_overlap(m.marioObj, star) and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            spawn_mist_particles()
            set_mario_action(m, ACT_JUMBO_STAR_CUTSCENE, 0)
            m.pos.x = star.oPosX
            m.pos.y = star.oPosY
            m.pos.z = star.oPosZ
        end
    end

    -- check if the player has reached the end of the level 
    local goalPos = gLevels[gGlobalSyncTable.level].goalPos
    local atGoalPoal = (vec3f_dist_2d(m.pos, goalPos) < 10 and m.pos.y > goalPos.y and m.pos.y < goalPos.y + 650)
    if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level and not gFloodPlayers[0].finished and (((m.action & ACT_FLAG_ON_POLE) ~= 0 and atGoalPoal) or m.action == ACT_JUMBO_STAR_CUTSCENE) then
        local bestTimeString = get_best_beaten_string(SAVETAG_TIME, gFloodPlayers[0].time)
        local bestPointString = get_best_beaten_string(SAVETAG_POINTS, gFloodPlayers[0].points)
        network_send_finished(true)
        network_send_points()
        network_send_time()
        gFloodPlayers[0].modifiers = get_modifiers_string()

        local string = ""
        if not is_final_level() then
            string = string .. "\\#00ff00\\You escaped the flood!\n"
            play_race_fanfare()
        else
            string = string .. "\\#00ff00\\You escaped the \\#ffff00\\final\\#00ff00\\ flood! Congratulations!\n"
            play_music(0, SEQUENCE_ARGS(8, SEQ_EVENT_CUTSCENE_VICTORY), 0)
        end
        string = string .. "\\#dcdcdc\\Time: " .. timestamp(gFloodPlayers[0].time) .. bestTimeString .. "\n"
        string = string .. "\\#dcdcdc\\Points: " .. gFloodPlayers[0].points .. bestPointString .. "\n"
        if get_modifiers_string() ~= "" then
            string = string .. "\\#898989\\Your score did not save..."  .. "\n"
        end
        djui_chat_message_create(string)
    end

    -- update spectator if finished, manage other things if not
    if gFloodPlayers[0].finished then
        mario_set_full_health(m)
        if network_player_connected_count() > 1 and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            set_mario_spectator(m)
        end
    else
        if m.pos.y < gGlobalSyncTable.waterLevel then
            -- Different Water Types
            local water = obj_get_first_with_behavior_id(id_bhvWater)
            if water ~= nil and gFloodPlayers[0].time > 10 and m.action ~= ACT_SPECTATOR then
                switch(gGlobalSyncTable.materialPhys and water.oAnimState or 0, {
                    ['default'] = function()
                        if m.pos.y + 150 < gGlobalSyncTable.waterLevel then
                            m.health = m.health - 30
                        end
                        m.vel.y = m.vel.y + 2
                        m.peakHeight = m.pos.y
                    end,
                    [FLOOD_LAVA] = function()
                        if (not (m.flags & MARIO_METAL_CAP) ~= 0) then
                            m.hurtCounter = m.hurtCounter + (m.flags & MARIO_CAP_ON_HEAD) and 12 or 18;
                        end
                        m.pos.y = gGlobalSyncTable.waterLevel + 10
                        set_mario_action(m, ACT_LAVA_BOOST, 0)
                    end,
                    [FLOOD_SAND] = function()
                        local velCap = -10
                        if m.controller.buttonPressed & (A_BUTTON) ~= 0 then
                            set_mario_action(m, ACT_JUMP, 0)
                            m.faceAngle.y = m.intendedYaw
                            m.vel.y = m.vel.y * 0.75
                        end
                        m.health = m.health - 30
                        if m.pos.y + 200 < gGlobalSyncTable.waterLevel then
                            m.health = 0xFF
                        end
                        m.vel.y = math.max(velCap, m.vel.y)
                    end,
                    --[[
                    [FLOOD_MUD] = function()
                        djui_hud_set_color(74, 123, 0, 220)
                    end
                    ]]
                })
            end
        end

        if m.action == ACT_QUICKSAND_DEATH then
            m.health = 0xFF
        end

        if m.health <= 0xFF then
            if network_player_connected_count() > 1 then
                m.area.camera.cutscene = 0
                set_mario_spectator(m)
            end
        else
            gFloodPlayers[0].time = gFloodPlayers[0].time + 1
        end
    end
end

local function on_hud_render()
    hud_hide()
    set_world_color(255, 255, 255, 255)
    djui_hud_set_color(255, 255, 255, 0)
    local water = obj_get_first_with_behavior_id(id_bhvWater)
    if water ~= nil then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        if gLakituState.pos.y < gGlobalSyncTable.waterLevel then
            switch(water.oAnimState, {
                [FLOOD_WATER] = function()
                    set_world_color(0, 20, 200, 120)
                    djui_hud_set_color(0, 20, 200, 60)
                end,
                [FLOOD_LAVA] = function()
                    set_world_color(200, 20, 20, 220)
                    djui_hud_set_color(200, 20, 20, 110)
                end,
                [FLOOD_SAND] = function()
                    set_world_color(254, 193, 70, 220)
                    djui_hud_set_color(254, 193, 70, 110)
                end,
                [FLOOD_MUD] = function()
                    set_world_color(74, 123, 0, 220)
                    djui_hud_set_color(74, 123, 0, 110)
                end
            })
            djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
        end
    end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_TINY)

    local width = djui_hud_get_screen_width()
    local height = 240
    local level = gLevels[gNetworkPlayers[0].currLevelNum]
    if level ~= nil and level.name ~= "ctt" then
        local out = { x = 0, y = 0, z = 0 }
        djui_hud_world_pos_to_screen_pos(level.goalPos, out)
        local dX = clampf(out.x - 5, 0, djui_hud_get_screen_width() - 19.2)
        local dY = clampf(out.y - 20, 0, djui_hud_get_screen_height() - 19.2)

        djui_hud_set_color(255, 255, 255, 200)
        djui_hud_render_texture_interpolated(TEX_FLOOD_FLAG, sFlagIconPrevPos.x, sFlagIconPrevPos.y, 0.15, 0.15, dX, dY, 0.15, 0.15)

        sFlagIconPrevPos.x = dX
        sFlagIconPrevPos.y = dY
    end

    local text = if_then_else(gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE, "Type '/flood start' to start a round", "0.000 seconds" .. get_modifiers_string())
    if gNetworkPlayers[0].currAreaSyncValid then
        if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
            text = if_then_else(network_player_connected_count() > 1, "Round starts in " .. tostring(math_floor(gGlobalSyncTable.timer / 30)), "Type '/flood start' to start a round")
        elseif gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level then
            text = timestamp(gFloodPlayers[0].time) .. get_modifiers_string()
        end
    end

    local scale = 1
    local width = djui_hud_measure_text(text) * scale
    local x = (djui_hud_get_screen_width() - width) * 0.5

    djui_hud_set_color(0, 0, 0, 128)
    djui_hud_render_rect(x - 6, 0, width + 12, 16)
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(text, x, 0, scale)

    hud_render_power_meter(gMarioStates[0].health, djui_hud_get_screen_width() - 64, 0, 64, 64)

    djui_hud_set_font(FONT_HUD)

    -- Points
    djui_hud_print_text(tostring(gFloodPlayers[0].points) .. " PTS", 5, 5, 1)
    -- Coins
    djui_hud_render_texture(gTextures.coin, 5, height - 21, 1, 1)
    djui_hud_print_text("<", 21, height - 21, 1)
    djui_hud_print_text(tostring(hud_get_value(HUD_DISPLAY_COINS)), 37, height - 21, 1)

    if gGlobalSyncTable.speedMultiplier ~= 1 then
        djui_hud_print_text(string.format("%.2fx", gGlobalSyncTable.speedMultiplier), 5, 24, 1)
    end
end

local function on_level_init()
    -- reset save
    save_file_erase_current_backup_save()
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_GROUNDS then
        save_file_set_flags(SAVE_FLAG_HAVE_VANISH_CAP)
        save_file_set_flags(SAVE_FLAG_HAVE_WING_CAP)
    end
    save_file_set_using_backup_slot(true)

    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if network_is_server() then
            local start = gLevels[gGlobalSyncTable.level].customStartPos
            if start ~= nil then
                gGlobalSyncTable.waterLevel = find_floor_height(start.x, start.y, start.z) - 1200
            else
                -- only sub areas have a weird issue where this function appears to always return the floor lower limit on level init
                gGlobalSyncTable.waterLevel = if_then_else(gLevels[gGlobalSyncTable.level].area == 1, find_floor_height(gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z), gMarioStates[0].pos.y) - 1200
            end
        end

        if game == GAME_VANILLA then
            if gNetworkPlayers[0].currLevelNum == LEVEL_BITS then
                spawn_non_sync_object(
                    id_bhvCustomStaticObject,
                    E_MODEL_CTT,
                    10000, -2000, -40000,
                    function(o) obj_scale(o, 0.5) end
                )
            elseif gNetworkPlayers[0].currLevelNum == LEVEL_WDW then
                set_environment_region(1, -20000)
            end
        end

        spawn_non_sync_object(
            id_bhvWater,
            E_MODEL_FLOOD,
            0, gGlobalSyncTable.waterLevel, 0,
            nil
        )
    else
        if gNetworkPlayers[0].currLevelNum == LEVEL_LOBBY then
            if network_is_server() then
                gGlobalSyncTable.waterLevel = get_water_level(0) and get_water_level(0) or find_floor_height(gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z) - 200
            end

            water = spawn_non_sync_object(
                id_bhvWater,
                E_MODEL_FLOOD,
                0, gGlobalSyncTable.waterLevel, 0,
                nil
            )
        end
    end

    if gLevels[gNetworkPlayers[0].currLevelNum] == nil then
        warp_to_level(LEVEL_LOBBY, 1, 0)
        return
    end
    local pos = gLevels[gNetworkPlayers[0].currLevelNum].goalPos
    if pos == nil then return end
    local floorHeight = find_floor_height(pos.x, pos.y, pos.z)
    pos.y = (pos.y - 1000 < floorHeight) and floorHeight or pos.y
    if gNetworkPlayers[0].currLevelNum == gMapRotation[#gMapRotation] then
        spawn_non_sync_object(
            id_bhvFinalStar,
            E_MODEL_STAR,
            pos.x, pos.y + 400, pos.z,
            nil
        )
    else
        spawn_non_sync_object(
            id_bhvFloodFlag,
            E_MODEL_KOOPA_FLAG,
            pos.x, pos.y, pos.z,
            --- @param o Object
            function(o)
                o.oFaceAnglePitch = 0
                o.oFaceAngleYaw = pos.a
                o.oFaceAngleRoll = 0
            end
        )
    end
end

if _G.charSelectExists then
    _G.charSelect.hook_allow_menu_open(function()
        return gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE
    end)
end

-- dynos warps mario back to castle grounds facing the wrong way, likely something from the title screen
local function on_warp()
    --- @type MarioState
    local m = gMarioStates[0]
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        if game == GAME_STAR_ROAD then
            if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
                vec3f_set(m.pos, -6797, 1830, 2710)
                m.faceAngle.y = 0x6000
            else
                vec3f_set(m.pos, -1644, -614, -1524)
                m.faceAngle.y = -0x4000
            end
        end

        if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
            play_music(0, SEQUENCE_ARGS(4, SEQ_LEVEL_BOSS_KOOPA_FINAL), 0)
        end
    elseif gLevels[gGlobalSyncTable.level].customStartPos ~= nil then
        local start = gLevels[gGlobalSyncTable.level].customStartPos
        vec3f_copy(m.pos, start)
        set_mario_action(m, ACT_SPAWN_SPIN_AIRBORNE, 0)
        m.faceAngle.y = start.a
    end
end

local function on_player_connected()
    if network_is_server() and gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then gGlobalSyncTable.timer = ROUND_COOLDOWN end
end

local function on_start_command(msg)
    if not network_is_server() then return end
    if msg == "?" then
        djui_chat_message_create("/flood \\#00ffff\\start\\#ffff00\\ [random|1-" .. FLOOD_LEVEL_COUNT .. "]\\#dcdcdc\\\nSets the level to a random one or a specific one, you can also leave it empty for normal progression.")
        return true
    end

    if msg == "random" then
        gGlobalSyncTable.level = math_random(1, FLOOD_LEVEL_COUNT)
    else
        local override = tonumber(msg)
        if override ~= nil then
            override = clamp(math_floor(override), 1, FLOOD_LEVEL_COUNT)
            gGlobalSyncTable.level = gMapRotation[override]
        else
            for k, v in pairs(gLevels) do
                if msg ~= nil and msg:lower() == v.name then
                    gGlobalSyncTable.level = k
                end
            end
        end
    end
    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        network_send(true, { restart = true })
        level_restart()
    else
        round_start()
    end
    return true
end

local function on_speed_command(msg)
    if not network_is_server() then return end
    local speed = tonumber(msg)
    if speed ~= nil then
        speed = clampf(speed, 0, 10)
        djui_chat_message_create("Water speed set to " .. speed)
        gGlobalSyncTable.speedMultiplier = speed
        return true
    end

    djui_chat_message_create("/flood \\#00ffff\\speed\\#ffff00\\ [number]\\#dcdcdc\\\nSets the speed multiplier of the flood")
    gGlobalSyncTable.speedMultiplier = msg
    return true
end

local function on_ttc_speed_command(msg)
    if not network_is_server() then return end
    if gGlobalSyncTable.roundState ~= ROUND_STATE_INACTIVE then
        djui_chat_message_create("\\#ff0000\\You can only change the TTC speed before the round starts!")
        return true
    end

    msg = msg:lower()
    if msg == "fast" then
        set_ttc_speed_setting(TTC_SPEED_FAST)
        djui_chat_message_create("TTC speed set to fast")
        return true
    elseif msg == "slow" then
        set_ttc_speed_setting(TTC_SPEED_SLOW)
        djui_chat_message_create("TTC speed set to slow")
        return true
    elseif msg == "random" then
        set_ttc_speed_setting(TTC_SPEED_RANDOM)
        djui_chat_message_create("TTC speed set to random")
        return true
    elseif msg == "stopped" then
        set_ttc_speed_setting(TTC_SPEED_STOPPED)
        djui_chat_message_create("TTC speed stopped")
        return true
    end

    djui_chat_message_create("/flood \\#00ffff\\ttc-speed\\#ffff00\\ [fast|slow|random|stopped]\\#dcdcdc\\\nChanges the speed of TTC")
    return true
end

local function on_speedrun_command(msg)
    if not network_is_server() then return end
    msg = msg:lower()
    if msg == "off" then
        djui_chat_message_create("Speedrun mode status: \\#ff0000\\OFF")
        speedrunner = SPEEDRUN_MODE_OFF
        return true
    elseif msg == "progress" then
        djui_chat_message_create("Speedrun mode status: \\#00ff00\\Progress Level")
        speedrunner = SPEEDRUN_MODE_PROGRESS
        return true
    elseif msg == "restart" then
        djui_chat_message_create("Speedrun mode status: \\#00ff00\\Restart Level")
        speedrunner = SPEEDRUN_MODE_RESTART
        return true
    end

    djui_chat_message_create("/flood \\#00ffff\\speedrun\\#ffff00\\ [off|progress|restart]\\#dcdcdc\\\nTo make adjustments to singleplayer Flood helpful for speedrunners")
    return true
end

local function on_scoreboard_command()
    djui_chat_message_create("Times:")
    local modifiers = get_modifiers_string()
    local total = 0
    for i = 1, FLOOD_LEVEL_COUNT do
        local level = gMapRotation[i]
        djui_chat_message_create(get_level_name(level_to_course(level), level, 1) .. " - " .. timestamp(gLevels[level].time) .. modifiers)
        total = total + gLevels[level].time
    end

    djui_chat_message_create("Total Time: " .. timestamp(total))
    return true
end

local function on_force_spectator_command()
    gFloodPlayers[0].forceSpec = not gFloodPlayers[0].forceSpec
    djui_chat_message_create("Force Spectator: " .. (gFloodPlayers[0].forceSpec and "\\#00ff00\\ON" or "\\#ff0000\\OFF"))
    return true
end

local function on_flood_command(msg)
    local args = split(msg)
    if args[1] == "start" then
        return on_start_command(args[2] or "")
    elseif args[1] == "speed" then
        return on_speed_command(args[2] or "")
    elseif args[1] == "ttc-speed" then
        return on_ttc_speed_command(args[2] or "")
    elseif args[1] == "speedrun" then
        return on_speedrun_command(args[2] or "")
    elseif args[1] == "scoreboard" then
        return on_scoreboard_command()
    elseif args[1] == "spectator" then
        return on_force_spectator_command()
    end

    djui_chat_message_create("/flood \\#00ffff\\[start|speed|ttc-speed|speedrun|scoreboard|spectator]")
    return true
end

gServerSettings.skipIntro = 1
gServerSettings.stayInLevelAfterStar = 2

gLevelValues.entryLevel = LEVEL_LOBBY
gLevelValues.floorLowerLimit = -20000
gLevelValues.floorLowerLimitMisc = -20000 + 1000
gLevelValues.floorLowerLimitShadow = -20000 + 1000.0
gLevelValues.fixCollisionBugs = 1
gLevelValues.fixCollisionBugsRoundedCorners = 0

if game == GAME_VANILLA then
    set_ttc_speed_setting(TTC_SPEED_STOPPED)

    smlua_text_utils_secret_star_replace(COURSE_SA, "   Climb The Tower Flood")

    smlua_audio_utils_replace_sequence(SEQ_LEVEL_BOSS_KOOPA_FINAL, 37, 60, "00_pinball_custom")
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_recieve)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_USE_ACT_SELECT, function() return false end)

if network_is_server() then
    hook_chat_command("flood", "\\#00ffff\\[start|speed|ttc-speed|speedrun|scoreboard|spectator]", on_flood_command)
    hook_mod_menu_text("Host Settings")
    local loadMatPhys = mod_storage_load_bool("materialPhys")
    hook_mod_menu_checkbox("Material Physics", loadMatPhys ~= nil and loadMatPhys or true, function(index, value)
        gGlobalSyncTable.materialPhys = value
        mod_storage_save_bool("materialPhys", value)
    end)
else
    hook_chat_command("flood", "\\#00ffff\\[scoreboard|spectator]", on_flood_command)
end