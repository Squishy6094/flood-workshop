serverMoveset = false

for mod in pairs(gActiveMods) do
    if gActiveMods[mod].name:find("Object Spawner") or gActiveMods[mod].name:find("Noclip") then
        cheats = true
    end
end

for i in pairs(gActiveMods) do
    if (gActiveMods[i].incompatible ~= nil and gActiveMods[i].incompatible:find("moveset")) then
        serverMoveset = true
    end
end

-- localize functions to improve performance
local math_floor,is_player_active,table_insert,is_game_paused,djui_hud_set_color = math.floor,is_player_active,table.insert,is_game_paused,djui_hud_set_color

rom_hack_cam_set_collisions(false)

-- Rounds up or down depending on the decimal position of `x`.
--- @param x number
--- @return integer
function math_round(x)
    return if_then_else(x - math.floor(x) >= 0.5, math.ceil(x), math.floor(x))
end

-- Recieves a value of any type and converts it into a boolean.
function tobool(v)
    local type = type(v)
    if type == "boolean" then
        return v
    elseif type == "number" then
        return v == 1
    elseif type == "string" then
        return v == "true"
    elseif type == "table" or type == "function" or type == "thread" or type == "userdata" then
        return true
    end
    return false
end

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

--- @param m MarioState
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return 1
    end
    if not np.connected then
        return 0
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return 0
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return 0
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return 0
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return 0
    end
    return is_player_active(m)
end

function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

function string_without_hex(name)
    local s = ''
    local inSlash = false
    for i = 1, #name do
        local c = name:sub(i,i)
        if c == '\\' then
            inSlash = not inSlash
        elseif not inSlash then
            s = s .. c
        end
    end
    return s
end

function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end

function split(s)
    local result = {}
    for match in (s):gmatch(string.format("[^%s]+", " ")) do
        table.insert(result, match)
    end
    return result
end

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

--- @param m MarioState
function mario_set_full_health(m)
    m.health = 0x880
    m.healCounter = 0
    m.hurtCounter = 0
end

local levelToCourse = {
    [LEVEL_NONE] = COURSE_NONE,
    [LEVEL_BOB] = COURSE_BOB,
    [LEVEL_WF] = COURSE_WF,
    [LEVEL_JRB] = COURSE_JRB,
    [LEVEL_CCM] = COURSE_CCM,
    [LEVEL_BBH] = COURSE_BBH,
    [LEVEL_HMC] = COURSE_HMC,
    [LEVEL_LLL] = COURSE_LLL,
    [LEVEL_SSL] = COURSE_SSL,
    [LEVEL_DDD] = COURSE_DDD,
    [LEVEL_SL] = COURSE_SL,
    [LEVEL_WDW] = COURSE_WDW,
    [LEVEL_TTM] = COURSE_TTM,
    [LEVEL_THI] = COURSE_THI,
    [LEVEL_TTC] = COURSE_TTC,
    [LEVEL_RR] = COURSE_RR,
    [LEVEL_BITDW] = COURSE_BITDW,
    [LEVEL_BITFS] = COURSE_BITFS,
    [LEVEL_BITS] = COURSE_BITS,
    [LEVEL_PSS] = COURSE_PSS,
    [LEVEL_COTMC] = COURSE_COTMC,
    [LEVEL_TOTWC] = COURSE_TOTWC,
    [LEVEL_VCUTM] = COURSE_VCUTM,
    [LEVEL_WMOTR] = COURSE_WMOTR,
    [LEVEL_SA] = COURSE_SA,
    [LEVEL_ENDING] = COURSE_CAKE_END,
}

function level_to_course(level)
    return levelToCourse[level] or COURSE_NONE
end

function timestamp(seconds)
    seconds = seconds / 30
    local minutes = math.floor(seconds / 60)
    local milliseconds = math.floor((seconds - math.floor(seconds)) * 1000)
    seconds = math.floor(seconds) % 60
    return minutes > 0 and string.format("%d:%02d.%03d", minutes, seconds, milliseconds) or string.format("%01d.%03d", seconds, milliseconds)
end

function set_world_color(r, g, b, a)
    -- a: 0 = white, 255 = full color intensity
    local intensity = (a or 255) / 255
    local cr = math.floor((r - 255) * intensity + 255)
    local cg = math.floor((g - 255) * intensity + 255)
    local cb = math.floor((b - 255) * intensity + 255)
    set_lighting_color(0, cr)
    set_lighting_color(1, cg)
    set_lighting_color(2, cb)
    set_skybox_color(0, cr)
    set_skybox_color(1, cg)
    set_skybox_color(2, cb)
    set_fog_color(0, cr)
    set_fog_color(1, cg)
    set_fog_color(2, cb)
    --set_fog_intensity(a)
    set_vertex_color(0, cr)
    set_vertex_color(1, cg)
    set_vertex_color(2, cb)
end

function table_shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function vec3f_dist_2d(v1, v2)
    return math.sqrt(math.abs(v1.x - v2.x)*2 + math.abs(v1.z - v2.z)*2)
end

-- More Flexable Jumbo Star Cutsceans

--[[
ACT_JUMBO_STAR_CUTSCENE = allocate_mario_action(ACT_FLAG_AIR | ACT_FLAG_INTANGIBLE)
log_to_console("init")
local sJumboStarKeyframes = {
    { x = 20, y = 0, z = 678, w = -2916 },      { x = 30, y = 0, z = 680, w = -3500 },      { x = 40, y = 1000, z = 700, w = -4000 },
    { x = 50, y = 2500, z = 750, w = -3500 },   { x = 50, y = 3500, z = 800, w = -2000 },   { x = 50, y = 4000, z = 850, w = 0 },
    { x = 50, y = 3500, z = 900, w = 2000 },    { x = 50, y = 2000, z = 950, w = 3500 },    { x = 50, y = 0, z = 1000, w = 4000 },
    { x = 50, y = -2000, z = 1050, w = 3500 },  { x = 50, y = -3500, z = 1100, w = 2000 },  { x = 50, y = -4000, z = 1150, w = 0 },
    { x = 50, y = -3500, z = 1200, w = -2000 }, { x = 50, y = -2000, z = 1250, w = -3500 }, { x = 50, y = 0, z = 1300, w = -4000 },
    { x = 50, y = 2000, z = 1350, w = -3500 },  { x = 50, y = 3500, z = 1400, w = -2000 },  { x = 50, y = 4000, z = 1450, w = 0 },
    { x = 50, y = 3500, z = 1500, w = 2000 },   { x = 50, y = 2000, z = 1600, w = 3500 },   { x = 50, y = 0, z = 1700, w = 4000 },
    { x = 50, y = -2000, z = 1800, w = 3500 },  { x = 50, y = -3500, z = 1900, w = 2000 },  { x = 30, y = -4000, z = 2000, w = 0 },
    { x = 0, y = -3500, z = 2100, w = -2000 },  { x = 0, y = -2000, z = 2200, w = -3500 },  { x = 0, y = 0, z = 2300, w = -4000 },
}

local JUMBO_STAR_CUTSCENE_FALLING = 0
local JUMBO_STAR_CUTSCENE_TAKING_OFF = 1
local JUMBO_STAR_CUTSCENE_FLYING = 2

local function advance_cutscene_step(m)
    if not m then return end
    m.actionState = 0;
    m.actionTimer = 0;
    m.actionArg = m.actionArg + 1;
end

function jumbo_star_cutscene_falling(m)
    if not m then return end

    if m.actionState == 0 then
        m.input = m.input | INPUT_A_DOWN
        m.flags = m.flags | (MARIO_WING_CAP | MARIO_CAP_ON_HEAD)

        m.faceAngle.y = -0x8000 -- Yaw
        --m.pos.x = m.pos.x + 100.0 * m.playerIndex
        --m.pos.z = 0.0

        mario_set_forward_vel(m, 0.0)
        set_character_animation(m, CHAR_ANIM_GENERAL_FALL)

        if perform_air_step(m, 1) == AIR_STEP_LANDED then
            play_cutscene_music(SEQUENCE_ARGS(15, SEQ_EVENT_CUTSCENE_VICTORY))
            play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
            m.actionState = m.actionState + 1
        end
    else
        set_character_animation(m, CHAR_ANIM_GENERAL_LAND)
        if is_anim_at_end(m) then
            m.statusForCamera.cameraEvent = CAM_EVENT_START_GRAND_STAR
            advance_cutscene_step(m)
        end
    end
end

function jumbo_star_cutscene_taking_off(m)
    if not m then return 0 end
    local marioObj = m.marioObj

    if m.actionState == 0 then
        set_character_animation(m, CHAR_ANIM_FINAL_BOWSER_RAISE_HAND_SPIN)
        marioObj.oMarioJumboStarCutscenePosZ = m.pos.z

        if is_anim_past_end(m) then
            play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING)
            m.actionState = m.actionState + 1
        end
    else
        local animFrame = set_character_animation(m, CHAR_ANIM_FINAL_BOWSER_WING_CAP_TAKE_OFF)
        if animFrame == 3 or animFrame == 28 or animFrame == 60 then
            play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_JUMP, 1)
        end
        if animFrame >= 3 then
            marioObj.oMarioJumboStarCutscenePosZ = marioObj.oMarioJumboStarCutscenePosZ - 32.0
        end

        if animFrame == 3 then
            play_character_sound_offset(m, CHAR_SOUND_YAH_WAH_HOO, math.random(0,2)<<16)
        elseif animFrame == 28 then
            play_character_sound(m, CHAR_SOUND_HOOHOO)
        elseif animFrame == 60 then
            play_character_sound(m, CHAR_SOUND_YAHOO)
        end

        set_mario_particle_flags(m, PARTICLE_SPARKLES, 0)

        if is_anim_past_end(m) then
            advance_cutscene_step(m)
        end
    end

    --vec3f_set(m.pos, 0.0, 307.0, marioObj.oMarioJumboStarCutscenePosZ)
    m.pos.y = m.pos.y + 100.0 * m.playerIndex

    update_mario_pos_for_anim(m)
    vec3f_copy(marioObj.header.gfx.pos, m.pos)
    vec3s_set(marioObj.header.gfx.angle, 0, m.faceAngle.y, 0)

    return false
end

function jumbo_star_cutscene_flying(m)
    if not m then return 0 end
    local targetPos = { x = 0.0, y = 0.0, z = 0.0 }

    if m.actionState == 0 then
        set_character_animation(m, CHAR_ANIM_WING_CAP_FLY)
        anim_spline_init(m, sJumboStarKeyframes)
        m.actionState = 1
    end

    if m.actionState == 1 then
        if anim_spline_poll(m, targetPos) then
            set_mario_action(m, ACT_FREEFALL, 0)
            m.actionState = 2
        else
            targetPos.y = targetPos.y + 100.0 * m.playerIndex
            local heightScalar = math.min(m.actionTimer / 30.0, 1.0)
            targetPos.z = targetPos.z - 100.0 * m.playerIndex * heightScalar

            local dx = targetPos.x - m.pos.x
            local dy = targetPos.y - m.pos.y
            local dz = targetPos.z - m.pos.z
            local hyp = math.sqrt(dx * dx + dz * dz)
            local angle = atan2s(dz, dx)

            vec3f_copy(m.pos, targetPos)
            m.marioObj.header.gfx.angle.y = angle
            m.marioObj.header.gfx.angle.x = -atan2s(hyp, dy)
            m.marioObj.header.gfx.angle.z = ((m.faceAngle.z - angle) << 16 >> 16) * 20
            m.faceAngle.z = angle
        end
    elseif m.actionState == 2 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    m.marioBodyState.handState = MARIO_HAND_RIGHT_OPEN
    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    set_mario_particle_flags(m, PARTICLE_SPARKLES, 0)

    m.actionTimer = m.actionTimer + 1
    if m.actionTimer == 500 and m.playerIndex == 0 then
        -- Set Mario to Spectator rather than warping
        set_mario_spectator(m)
    end

    return false
end


local function act_jumbo_star_cutscene(m)
    if (not m)then return false end
    if m.actionArg == JUMBO_STAR_CUTSCENE_FALLING then
        jumbo_star_cutscene_falling(m)
    elseif m.actionArg == JUMBO_STAR_CUTSCENE_TAKING_OFF then
        jumbo_star_cutscene_taking_off(m)
    elseif m.actionArg == JUMBO_STAR_CUTSCENE_FLYING then
        jumbo_star_cutscene_flying(m)
    end
    return false;
end

hook_mario_action(ACT_JUMBO_STAR_CUTSCENE, act_jumbo_star_cutscene)
]]