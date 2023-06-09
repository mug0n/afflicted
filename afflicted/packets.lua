-- taken from the windower shim library
local packets = {}

packets.parse_action = function(packet)
    local res = {}
    if string.byte(packet) ~= 0x28 then return res end

    res["size"]         = ashita.bits.unpack_be(packet:totable(),  32,  8)
    res["actor_id"]     = ashita.bits.unpack_be(packet:totable(),  40, 32)
    res["target_count"] = ashita.bits.unpack_be(packet:totable(),  72, 10)
    res["type"]         = ashita.bits.unpack_be(packet:totable(),  82,  4)
    res["param"]        = ashita.bits.unpack_be(packet:totable(),  86, 16)
    res["unknown"]      = ashita.bits.unpack_be(packet:totable(), 102, 16)
    res["recast"]       = ashita.bits.unpack_be(packet:totable(), 118, 32)
    res["targets"]      = {}

    local offset = 150
    for i = 1, res.target_count do
        local target = {}
        target["offset_start"]                   = offset
        target["id"]                             = ashita.bits.unpack_be(packet:totable(), offset,       32)
        target["action_count"]                   = ashita.bits.unpack_be(packet:totable(), offset + 32,   4)
        target["actions"]                        = {}
        offset = offset + 36

        for n = 1, target.action_count do
            local action = {}
            action["offset_start"]               = offset
            action["reaction"]                   = ashita.bits.unpack_be(packet:totable(), offset,       5)
            action["animation"]                  = ashita.bits.unpack_be(packet:totable(), offset + 5,  11)
            action["effect"]                     = ashita.bits.unpack_be(packet:totable(), offset + 16,  5)
            action["stagger"]                    = ashita.bits.unpack_be(packet:totable(), offset + 21,  6)
            action["param"]                      = ashita.bits.unpack_be(packet:totable(), offset + 27, 17)
            action["message"]                    = ashita.bits.unpack_be(packet:totable(), offset + 44, 10)
            action["unknown"]                    = ashita.bits.unpack_be(packet:totable(), offset + 54, 31)
            action["has_add_effect"]             = ashita.bits.unpack_be(packet:totable(), offset + 85,  1)
            action["has_add_effect"]             = action.has_add_effect == 1
            offset = offset + 86

            if action.has_add_effect then
                action["add_effect_animation"]   = ashita.bits.unpack_be(packet:totable(), offset,       6)
                action["add_effect_effect"]      = ashita.bits.unpack_be(packet:totable(), offset + 6,   4)
                action["add_effect_param"]       = ashita.bits.unpack_be(packet:totable(), offset + 10, 17)
                action["add_effect_message"]     = ashita.bits.unpack_be(packet:totable(), offset + 27, 10)
                offset = offset + 37
            end

            action["has_spike_effect"]           = ashita.bits.unpack_be(packet:totable(), offset,       1)
            action["has_spike_effect"]           = action.has_spike_effect == 1
            offset = offset + 1

            if action.has_spike_effect then
                action["spike_effect_animation"] = ashita.bits.unpack_be(packet:totable(), offset,       6)
                action["spike_effect_effect"]    = ashita.bits.unpack_be(packet:totable(), offset + 6,   4)
                action["spike_effect_param"]     = ashita.bits.unpack_be(packet:totable(), offset + 10, 14)
                action["spike_effect_message"]   = ashita.bits.unpack_be(packet:totable(), offset + 24, 10)
                offset = offset + 34
            end

            action["offset_end"]                 = offset
            table.insert(target["actions"], action)
        end

        target["offset_end"] = offset
        table.insert(res["targets"], target)
    end

    return res
end

return packets