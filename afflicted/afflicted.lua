addon.name      = "Afflicted"
addon.author    = "mug0n"
addon.version   = "1.0"
addon.desc      = "Keeps track of any debuff applied to mobs."
addon.link      = "https://github.com/mug0n/afflicted"

require("common")
local chat = require("chat")
local imgui = require("imgui")
local packets = require("packets")

local Afflicted = {}
Afflicted.hWnd = "Afflicted"
Afflicted.debugMode = false
Afflicted.fixedWidth = 240
Afflicted.mobs = {}

-- list of status effects we will be tracking, readability+1
Afflicted.effects = {
    SLEEP           =   2,
    POISON          =   3,
    PARALYSIS       =   4,
    BLINDNESS       =   5,
    SILENCE         =   6,
    PETRIFICATION   =   7,
    DISEASE         =   8,
    CURSE           =   9,
    STUN            =  10,
    BIND            =  11,
    WEIGHT          =  12,
    SLOW            =  13,
    SLEEP_II        =  19,
    CURSE_II        =  20,
    ADDLE           =  21,
    INTIMIDATE      =  22,
    TERROR          =  28,
    PLAGUE          =  31,
    BURN            = 128,
    FROST           = 129,
    CHOKE           = 130,
    RASP            = 131,
    SHOCK           = 132,
    DROWN           = 133,
    DIA             = 134,
    BIO             = 135,
    STR_DOWN        = 136,
    DEX_DOWN        = 137,
    VIT_DOWN        = 138,
    AGI_DOWN        = 139,
    INT_DOWN        = 140,
    MND_DOWN        = 141,
    CHR_DOWN        = 142,
    MAX_HP_DOWN     = 144,
    MAX_MP_DOWN     = 145,
    ACCURACY_DOWN   = 146,
    ATTACK_DOWN     = 147,
    EVASION_DOWN    = 148,
    DEFENSE_DOWN    = 149,
    FLASH           = 156,
    MAGIC_DEF_DOWN  = 167,
    MAGIC_ACC_DOWN  = 174,
    MAGIC_ATK_DOWN  = 175,
    REQUIEM         = 192,
    LULLABY         = 193,
    ELEGY           = 194,
    THRENODY        = 217,
    NOCTURNE        = 223,
    MAGIC_EVA_DOWN  = 404,
    INUNDATION      = 597,
}

-- list of spells that trigger the effects we want to track
Afflicted.spells = {
    [23]  = { duration =  60, effect = Afflicted.effects.DIA,            name = "Dia", },
    [24]  = { duration = 120, effect = Afflicted.effects.DIA,            name = "Dia II",               removes = T{ 23, 33, 230 } },
    [25]  = { duration = 180, effect = Afflicted.effects.DIA,            name = "Dia III",              removes = T{ 23, 24, 33, 230, 231 } },
    [33]  = { duration =  60, effect = Afflicted.effects.DIA,            name = "Diaga",                removes = T{ 23 }},
    [56]  = { duration = 180, effect = Afflicted.effects.SLOW,           name = "Slow", },
    [58]  = { duration = 120, effect = Afflicted.effects.PARALYSIS,      name = "Paralyze", },
    [59]  = { duration = 120, effect = Afflicted.effects.SILENCE,        name = "Silence", },
    [79]  = { duration = 180, effect = Afflicted.effects.SLOW,           name = "Slow II", },
    [80]  = { duration = 120, effect = Afflicted.effects.PARALYSIS,      name = "Paralyze II", },
    [98]  = { duration =  90, effect = Afflicted.effects.SLEEP_II,       name = "Repose",               removes = T{ 253, 273, 376, 463 } },
    [112] = { duration =  12, effect = Afflicted.effects.FLASH,          name = "Flash", },
    [216] = { duration = 120, effect = Afflicted.effects.WEIGHT,         name = "Gravity", },
    [217] = { duration = 120, effect = Afflicted.effects.WEIGHT,         name = "Gravity II", },
    [220] = { duration =  30, effect = Afflicted.effects.POISON,         name = "Poison", },
    [221] = { duration = 120, effect = Afflicted.effects.POISON,         name = "Poison II", },
    [225] = { duration =  60, effect = Afflicted.effects.POISON,         name = "Poisonga", },
    [226] = { duration = 120, effect = Afflicted.effects.POISON,         name = "Poisonga II", },
    [230] = { duration =  60, effect = Afflicted.effects.BIO,            name = "Bio",                  removes = T{ 23, 33 } },
    [231] = { duration = 120, effect = Afflicted.effects.BIO,            name = "Bio II",               removes = T{ 23, 24, 33, 230 } },
    [232] = { duration = 180, effect = Afflicted.effects.BIO,            name = "Bio III",              removes = T{ 23, 24, 25, 33, 230, 231 } },
    [235] = { duration =  90, effect = Afflicted.effects.BURN,           name = "Burn",                 removes = T{ 236 } },
    [236] = { duration =  90, effect = Afflicted.effects.FROST,          name = "Frost",                removes = T{ 237 } },
    [237] = { duration =  90, effect = Afflicted.effects.CHOKE,          name = "Choke",                removes = T{ 238 } },
    [238] = { duration =  90, effect = Afflicted.effects.RASP,           name = "Rasp",                 removes = T{ 239 } },
    [239] = { duration =  90, effect = Afflicted.effects.SHOCK,          name = "Shock",                removes = T{ 240 } },
    [240] = { duration =  90, effect = Afflicted.effects.DROWN,          name = "Drown",                removes = T{ 235 } },
    [252] = { duration =   5, effect = Afflicted.effects.STUN,           name = "Stun", },
    [253] = { duration =  60, effect = Afflicted.effects.SLEEP,          name = "Sleep", },
    [254] = { duration = 180, effect = Afflicted.effects.BLINDNESS,      name = "Blind", },
    [255] = { duration =  30, effect = Afflicted.effects.PETRIFICATION,  name = "Break", },
    [258] = { duration =  60, effect = Afflicted.effects.BIND,           name = "Bind", },
    [259] = { duration =  90, effect = Afflicted.effects.SLEEP_II,       name = "Sleep II",             removes = T{ 253, 273, 376, 463 } },
    [273] = { duration =  60, effect = Afflicted.effects.SLEEP,          name = "Sleepga", },
    [274] = { duration =  90, effect = Afflicted.effects.SLEEP_II,       name = "Sleepga II",           removes = T{ 253, 273, 376, 463 } },
    [276] = { duration = 180, effect = Afflicted.effects.BLINDNESS,      name = "Blind II", },
    [286] = { duration = 180, effect = Afflicted.effects.ADDLE,          name = "Addle", },
    [319] = { duration = 120, effect = Afflicted.effects.ATTACK_DOWN,    name = "Aisha: Ichi", },
    [341] = { duration = 180, effect = Afflicted.effects.PARALYSIS,      name = "Jubaku: Ichi", },
    [344] = { duration = 180, effect = Afflicted.effects.SLOW,           name = "Hojo: Ichi", },
    [345] = { duration = 300, effect = Afflicted.effects.SLOW,           name = "Hojo: Ni",             removes = T{ 344 } },
    [347] = { duration = 180, effect = Afflicted.effects.BLINDNESS,      name = "Kurayami: Ichi", },
    [348] = { duration = 300, effect = Afflicted.effects.BLINDNESS,      name = "Kurayami: Ni",         removes = T{ 347 } },
    [350] = { duration =  60, effect = Afflicted.effects.POISON,         name = "Dokumori: Ichi", },
    [365] = { duration =  30, effect = Afflicted.effects.PETRIFICATION,  name = "Breakga", },
    [368] = { duration =  64, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem", },
    [369] = { duration =  80, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem II",       removes = T{ 368 } },
    [370] = { duration =  96, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem III",      removes = T{ 368, 369 } },
    [371] = { duration = 112, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem IV",       removes = T{ 368, 369, 370 } },
    [372] = { duration = 128, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem V",        removes = T{ 368, 369, 370, 371 } },
    [373] = { duration = 144, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem VI",       removes = T{ 368, 369, 370, 371, 372 } },
    [374] = { duration = 160, effect = Afflicted.effects.REQUIEM,        name = "Foe Requiem VII",      removes = T{ 368, 369, 370, 371, 372, 373 } },
    [376] = { duration =  30, effect = Afflicted.effects.LULLABY,        name = "Foe Lullaby", },
    [421] = { duration = 120, effect = Afflicted.effects.ELEGY,          name = "Battlefield Elegy", },
    [422] = { duration = 180, effect = Afflicted.effects.ELEGY,          name = "Carnage Elegy",        removes = T{ 421 } },
    [423] = { duration = 240, effect = Afflicted.effects.ELEGY,          name = "Massacre Elegy",       removes = T{ 421, 422 } },
    [454] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Fire Threnody",        removes = T{ 455, 456, 457, 458, 459, 460, 461 } },
    [455] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Ice Threnody",         removes = T{ 454, 456, 457, 458, 459, 460, 461 } },
    [456] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Wind Threnody",        removes = T{ 454, 455, 457, 458, 459, 460, 461 } },
    [457] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Earth Threnody",       removes = T{ 454, 455, 456, 458, 459, 460, 461 } },
    [458] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Lightning Threnody",   removes = T{ 454, 455, 456, 457, 459, 460, 461 } },
    [459] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Water Threnody",       removes = T{ 454, 455, 456, 457, 458, 460, 461 } },
    [460] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Light Threnody",       removes = T{ 454, 455, 456, 457, 458, 459, 461 } },
    [461] = { duration =  60, effect = Afflicted.effects.THRENODY,       name = "Dark Threnody",        removes = T{ 454, 455, 456, 457, 458, 459, 460 } },
    [463] = { duration =  30, effect = Afflicted.effects.LULLABY,        name = "Horde Lullaby", },
    [513] = { duration = 180, effect = Afflicted.effects.POISON,         name = "Venom Shell", },
    [524] = { duration =  60, effect = Afflicted.effects.ACCURACY_DOWN,  name = "Sandspin", },
    [531] = { duration =   5, effect = Afflicted.effects.BIND,           name = "Ice Break", },
    [535] = { duration =  30, effect = Afflicted.effects.FROST,          name = "Cold Wave", },
    [536] = { duration =  30, effect = Afflicted.effects.POISON,         name = "Poison Breath", },
    [572] = { duration =  30, effect = Afflicted.effects.BURN,           name = "Sound Blast", },
    [575] = { duration =  10, effect = Afflicted.effects.TERROR,         name = "Jettatura", },
    [584] = { duration =  45, effect = Afflicted.effects.SLEEP,          name = "Sheep Song", },
    [588] = { duration = 120, effect = Afflicted.effects.PLAGUE,         name = "Lowing", },
    [598] = { duration =  90, effect = Afflicted.effects.SLEEP_II,       name = "Soporific" },
    [599] = { duration =  30, effect = Afflicted.effects.POISON,         name = "Queasyshroom", },
    [608] = { duration =  60, effect = Afflicted.effects.PARALYSIS,      name = "Frost Breath", },
    [610] = { duration =  60, effect = Afflicted.effects.EVASION_DOWN,   name = "Infrasonics", },
    [611] = { duration = 180, effect = Afflicted.effects.POISON,         name = "Disseverment", },
    [638] = { duration =  30, effect = Afflicted.effects.POISON,         name = "Feather Storm", },
    [644] = { duration =  60, effect = Afflicted.effects.PARALYSIS,      name = "Mind Blast", },
    [651] = { duration =  60, effect = { Afflicted.effects.ATTACK_DOWN, Afflicted.effects.DEFENSE_DOWN }, name = "Corrosive Ooze", },
    [654] = { duration =  60, effect = Afflicted.effects.PARALYSIS,      name = "Sub-Zero Smash", },
    [656] = { duration =  12, effect = Afflicted.effects.MAGIC_DEF_DOWN, name = "Acrid Stream", },
    [659] = { duration =  30, effect = Afflicted.effects.ATTACK_DOWN,    name = "Demoralizing Roar", },
    [678] = { duration =  60, effect = Afflicted.effects.SLEEP,          name = "Dream Flower", },
    [682] = { duration =  60, effect = Afflicted.effects.PLAGUE,         name = "Delta Thrust", },
    [699] = { duration =  60, effect = Afflicted.effects.ACCURACY_DOWN,  name = "Barbed Crescent", },
    [841] = { duration = 120, effect = Afflicted.effects.EVASION_DOWN,   name = "Distract", },
    [842] = { duration = 120, effect = Afflicted.effects.EVASION_DOWN,   name = "Distract II",          removes = T{ 841 } },
    [843] = { duration = 120, effect = Afflicted.effects.MAGIC_EVA_DOWN, name = "Frazzle", },
    [844] = { duration = 120, effect = Afflicted.effects.MAGIC_EVA_DOWN, name = "Frazzle II",           removes = T{ 843 } },
    [871] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Fire Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 872, 873, 874, 875, 876, 877, 878 } },
    [872] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Ice Threnody II",      removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 873, 874, 875, 876, 877, 878 } },
    [873] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Wind Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 874, 875, 876, 877, 878 } },
    [874] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Earth Threnody II",    removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 875, 876, 877, 878 } },
    [875] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Ltng Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 876, 877, 878 } },
    [876] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Water Threnody II",    removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 877, 878 } },
    [877] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Light Threnody II",    removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 876, 878 } },
    [878] = { duration =  90, effect = Afflicted.effects.THRENODY,       name = "Dark Threnody II",     removes = T{ 454, 455, 456, 457, 458, 459, 460, 461, 871, 872, 873, 874, 875, 876, 877 } },
    [879] = { duration = 300, effect = Afflicted.effects.INUNDATION,     name = "Inundation", },
}

Afflicted.reset = function(self)
    self.mobs = {}
end

Afflicted.applyEffect = function (self, target_id, spell_id)
    -- init target table
    if (self.mobs[target_id] == nil) then
        self.mobs[target_id] = T{}
    end

    -- get the spell
    local spell = self.spells[spell_id]
    if (spell == nil) then return end

    -- check if spell is blocked by any of the already applied ones
    -- (spell.blocked_by is generated at load time)
    for _, v in pairs(self.mobs[target_id]) do
        -- cannot overwrite itself or is blocked by another
        local blocked_by = spell.blocked_by or T{}
        if (spell_id == v.spell_id or blocked_by:contains(v.spell_id)) then return end
    end

    -- remove any other spell this one overwrites (spell.removes)
    local removes = spell.removes or T{}
    for _, remove_id in pairs(removes) do
        local remove = Afflicted.spells[remove_id]
        local current = self.mobs[target_id][remove.effect]

        if (current ~= nil and removes:contains(current.spell_id)) then
            self:removeEffect(target_id, remove.effect)
        end
    end

    -- apply effect(s) -- spell.effect may or may not be a table
    local effects = type(spell.effect) == "table" and spell.effect or { spell.effect }
    for _, effect_id in pairs(effects) do
        self.mobs[target_id][effect_id] = { spell_id = spell_id, expiration = os.time() + spell.duration }
    end
end

Afflicted.removeEffect = function(self, target_id, effect)
    -- remove effect from target table
    local target = self.mobs[target_id]
    if (target ~= nil) then
        target[effect] = nil
    end
end

Afflicted.getTarget = function(self, target_id)
    return self.mobs[target_id] or T{}
end

Afflicted.removeTarget = function(self, target_id)
    self.mobs[target_id] = nil
end


--[[
    event: load
    desc : Event called when the addon is loaded
]]--
ashita.events.register("load", "afflicted_load", function ()
    -- build a spell.removes reverse lookup cache (spell.blocked_by)
    for k, v in pairs(Afflicted.spells) do
        local removes = v.removes or {}
        for _, rv in pairs(removes) do
            if (Afflicted.spells[rv].blocked_by == nil) then
                Afflicted.spells[rv].blocked_by = T{}
            end

            if not (Afflicted.spells[rv].blocked_by:contains(k)) then
                Afflicted.spells[rv].blocked_by:append(k)
            end
        end
    end
end)


--[[
    event: command
    desc : Event called when the addon is processing a command.
--]]
ashita.events.register("command", "afflicted_command", function (e)
    -- parse the command arguments
    local args = e.command:args()
    if (#args == 0 or not args[1]:any("/afflicted")) then
        return
    end

    -- block propagation
    e.blocked = true

    -- print header
    local header = chat.header(addon.name) - 1

    -- defaulting to list
    local param = "list"
    if (#args > 1) then param = args[2] end

    if (param == "list") then
        print(header .. " Listing tracked debuffs")
        for k, v in pairs(Afflicted.mobs) do
            print(header .. string.format(" For mob %s:", k))
            for vk, vv in pairs(v) do
                local spell = Afflicted.spells[vv.spell_id]
                print(header .. string.format(" spell=%s expiration=%s", spell.name, vv.expiration))
            end
        end
    elseif (param == "debug") then
        Afflicted.debugMode = not Afflicted.debugMode
        print(header .. string.format(" Debug mode: %s.", ( Afflicted.debugMode and "ON" or "OFF" )))
    end
end)


--[[
    event: d3d_present
    desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register("d3d_present", "afflicted_present", function ()
    -- get target information
    local entity = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0))
    if entity == nil or entity.Type ~= 2 or entity.SpawnFlags ~= 16 then
        return
    end

    -- init imgui
    imgui.SetNextWindowBgAlpha(0.8)
    imgui.SetNextWindowSize({ Afflicted.fixedWidth, -1, }, ImGuiCond_Always)

    if (imgui.Begin(Afflicted.hWnd, true,
        bit.bor(
            ImGuiWindowFlags_NoDecoration,
            ImGuiWindowFlags_AlwaysAutoResize,
            ImGuiWindowFlags_NoFocusOnAppearing,
            ImGuiWindowFlags_NoNav ))
    ) then
        -- caption text
        imgui.TextColored({ 0.508, 0.712, 0.832, 1.0 }, entity.Name)
        imgui.SameLine()

        local headerID = "[" .. entity.ServerId .. "]"
        local x, _ = imgui.CalcTextSize(headerID)
        local cursorPosX = imgui.GetCursorPosX()
        imgui.SetCursorPosX(math.max(cursorPosX, cursorPosX + imgui.GetContentRegionAvail() - x))
        imgui.Text(headerID)

        local target = Afflicted:getTarget(entity.ServerId)
        if not (target:empty()) then
            -- 2 columns, debuff name and expiration progress bar
            imgui.Columns(2)
            imgui.Separator()

            for _, debuff in pairs(target) do
                -- check if debuff has expired
                local remaining = debuff.expiration - os.time()
                if (remaining >= 0) then
                    -- spell name and remaining time as progress bar 
                    local spell = Afflicted.spells[debuff.spell_id]
                    imgui.Text(spell.name)
                    imgui.NextColumn()
                    imgui.ProgressBar(remaining / spell.duration, { -1, 14 }, string.format("%ss", remaining))
                    imgui.NextColumn()
                end
            end
        else
            imgui.Separator()
            imgui.Text("No debuff data.")
        end
    end

    imgui.End()
end)


--[[
    event: packet_in
    desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register("packet_in", "afflicted_packet_in", function (e)
    if (e.blocked) then return end

    -- zone entry packet
    if (e.id == 0x0A) then
        -- cleanup upon entering new zone
        Afflicted:reset()

    -- action packet
    elseif (e.id == 0x28) then
        local packet = packets.parse_action(e.data_modified)
        if (packet.type == 4) then
            for _, target in pairs(packet.targets) do
                local action = target.actions[1]

                -- debug mode
                if (Afflicted.debugMode) then
                    local header = chat.header(addon.name) - 1
                    print(header .. string.format(" target=%s action=%s param=%s", target.id, action.message, packet.param))
                end

                -- 2 and 252 are damaging spells
                -- 236, 237, 268, 271 are non damaging spells
                -- 264 is damaging spells such as Diaga for targets caught in the aoe (2 on target and 264 on other mobs caught in aoe)
                -- 277 is non damaging spells such as Sleepga for targets caught in aoe spells (271 on target and 277 on mobs caught in aoe)
                if (action ~= nil and T{ 2, 236, 237, 252, 264, 268, 271, 277 }:contains(action.message)) then
                    -- try to apply the effect
                    Afflicted:applyEffect(target.id, packet.param)
                end
            end
        end

    -- action message packet
    elseif (e.id == 0x29) then
        local message = {}
        message.target_id = struct.unpack("I", e.data_modified, 0x09)
        message.param_1 = struct.unpack("I", e.data_modified, 0x0D)
        message.message_id = struct.unpack("H", e.data_modified, 0x19) % 32768

        if (T{ 6, 20, 113, 406, 605, 646 }:contains(message.message_id)) then
            -- target died
            Afflicted:removeTarget(message.target_id)
        elseif T{ 64, 204, 206, 350, 531 }:contains(message.message_id) then
            -- wore off
            Afflicted:removeEffect(message.target_id, message.param_1)
        end
    end
end)