local M = {}

local STATE_KEY = 'bbp_satellite_progress'
local STATE_VERSION = 2

local BASE_HANDS = {
    'High Card',
    'Pair',
    'Two Pair',
    'Three of a Kind',
    'Straight',
    'Flush',
    'Full House',
    'Four of a Kind',
    'Straight Flush',
}

local SECRET_HANDS = {
    ['Five of a Kind'] = true,
    ['Flush Five'] = true,
    ['Flush House'] = true,
}

local PLANET_KEYS = {
    ['High Card'] = 'c_pluto',
    ['Pair'] = 'c_mercury',
    ['Two Pair'] = 'c_uranus',
    ['Three of a Kind'] = 'c_venus',
    ['Straight'] = 'c_saturn',
    ['Flush'] = 'c_jupiter',
    ['Full House'] = 'c_earth',
    ['Four of a Kind'] = 'c_mars',
    ['Straight Flush'] = 'c_neptune',
    ['Five of a Kind'] = 'c_planet_x',
    ['Flush House'] = 'c_ceres',
    ['Flush Five'] = 'c_eris',
}

local function raw_planet_uses(hand)
    local usage = G
        and G.GAME
        and G.GAME.consumeable_usage
        and G.GAME.consumeable_usage[PLANET_KEYS[hand]]
    return math.max(0, math.floor(tonumber(usage and usage.count) or 0))
end

local function hand_was_played(hand)
    local hand_state = G and G.GAME and G.GAME.hands and G.GAME.hands[hand]
    return hand_state and (tonumber(hand_state.played) or 0) > 0
end

local function rebuild_from_vanilla_history()
    local state = {
        version = STATE_VERSION,
        uses = {},
        credits = {},
        active_secrets = {},
        completed_layer = 0,
    }

    -- Planet usage counts preserve upgrades made before this implementation or
    -- before Satellite was purchased. Ordinary hands establish the historical
    -- shared layer; newly active secret hands then catch up without reducing
    -- income that was already earned.
    local base_floor
    for _, hand in ipairs(BASE_HANDS) do
        local uses = raw_planet_uses(hand)
        state.uses[hand] = uses
        base_floor = base_floor and math.min(base_floor, uses) or uses
    end
    base_floor = base_floor or 0
    state.completed_layer = base_floor

    for _, hand in ipairs(BASE_HANDS) do
        state.credits[hand] = math.min(state.uses[hand], base_floor + 1)
    end

    for hand in pairs(SECRET_HANDS) do
        if hand_was_played(hand) then
            state.active_secrets[hand] = true
            state.uses[hand] = raw_planet_uses(hand)
            state.credits[hand] = math.min(state.uses[hand], base_floor + 1)
            if state.uses[hand] < base_floor then
                state.catchup_layer = base_floor
            end
        end
    end

    return state
end

local function ensure_state()
    if not G or not G.GAME then return nil end

    local state = G.GAME[STATE_KEY]
    if type(state) ~= 'table' or state.version ~= STATE_VERSION then
        state = rebuild_from_vanilla_history()
        G.GAME[STATE_KEY] = state
    end

    state.uses = state.uses or {}
    state.credits = state.credits or {}
    state.active_secrets = state.active_secrets or {}
    state.completed_layer = math.max(
        0,
        math.floor(tonumber(state.completed_layer) or 0)
    )
    for _, hand in ipairs(BASE_HANDS) do
        state.uses[hand] = math.max(
            0,
            math.floor(tonumber(state.uses[hand]) or 0)
        )
        state.credits[hand] = math.max(
            0,
            math.floor(tonumber(state.credits[hand]) or 0)
        )
    end

    -- This also migrates a save in which a secret hand was played before the
    -- new Satellite hooks first ran. Activation never removes earned income.
    for hand in pairs(SECRET_HANDS) do
        if hand_was_played(hand) and not state.active_secrets[hand] then
            state.active_secrets[hand] = true
            state.uses[hand] = raw_planet_uses(hand)
            state.credits[hand] = math.min(
                state.uses[hand],
                state.completed_layer + 1
            )
            if state.uses[hand] < state.completed_layer then
                state.catchup_layer = math.max(
                    tonumber(state.catchup_layer) or 0,
                    state.completed_layer
                )
            end
        end
        if state.active_secrets[hand] then
            state.uses[hand] = math.max(
                0,
                math.floor(tonumber(state.uses[hand]) or 0)
            )
            state.credits[hand] = math.max(
                0,
                math.floor(tonumber(state.credits[hand]) or 0)
            )
        end
    end

    return state
end

local function each_active_hand(state, callback)
    for _, hand in ipairs(BASE_HANDS) do callback(hand) end
    for hand in pairs(SECRET_HANDS) do
        if state.active_secrets[hand] then callback(hand) end
    end
end

local function all_active_at_least(state, amount)
    local complete = true
    each_active_hand(state, function(hand)
        if (state.uses[hand] or 0) < amount then complete = false end
    end)
    return complete
end

local function sync_credits(state, cap)
    each_active_hand(state, function(hand)
        state.credits[hand] = math.max(
            state.credits[hand] or 0,
            math.min(state.uses[hand] or 0, cap)
        )
    end)
end

local function refresh_progress(state)
    local catchup_layer = tonumber(state.catchup_layer)
    if catchup_layer and catchup_layer > 0 then
        -- Keep existing partial-layer income, count every missing historical
        -- layer for lagging hands, and bank all progress beyond that boundary.
        sync_credits(state, catchup_layer)
        if not all_active_at_least(state, catchup_layer) then return end
        state.catchup_layer = nil
    end

    sync_credits(state, state.completed_layer + 1)
    while all_active_at_least(state, state.completed_layer + 1) do
        state.completed_layer = state.completed_layer + 1
        sync_credits(state, state.completed_layer + 1)
    end
end

function M.activate_secret_hand(hand)
    if not SECRET_HANDS[hand] then return false end
    local state = ensure_state()
    if not state or state.active_secrets[hand] then return false end

    state.active_secrets[hand] = true
    state.uses[hand] = state.uses[hand] or 0
    state.credits[hand] = state.credits[hand] or 0
    if state.uses[hand] < state.completed_layer then
        state.catchup_layer = math.max(
            tonumber(state.catchup_layer) or 0,
            state.completed_layer
        )
    end
    refresh_progress(state)
    return true
end

function M.record_planet_upgrade(hand)
    if not PLANET_KEYS[hand] then return false end
    local state = ensure_state()
    if not state then return false end
    if SECRET_HANDS[hand] and not state.active_secrets[hand] then return false end

    state.uses[hand] = (state.uses[hand] or 0) + 1
    refresh_progress(state)
    return true
end

function M.current_payout()
    local state = ensure_state()
    if not state then return 0 end

    local payout = 0
    each_active_hand(state, function(hand)
        payout = payout + (state.credits[hand] or 0)
    end)
    return payout
end

local function planet_hand_type(card)
    if not card or not card.ability or card.ability.set ~= 'Planet' then return nil end
    local consumeable = card.ability.consumeable
    if consumeable and consumeable.hand_type then return consumeable.hand_type end
    local center = card.config and card.config.center
    return center and center.config and center.config.hand_type
end

local function install_hooks()
    BBP_SATELLITE = BBP_SATELLITE or {}
    local hooks = BBP_SATELLITE
    if hooks.installed then return end
    hooks.installed = true

    hooks.set_consumeable_usage = set_consumeable_usage
    function set_consumeable_usage(card)
        local hand = planet_hand_type(card)
        if hand then ensure_state() end
        local result = hooks.set_consumeable_usage(card)
        if hand then M.record_planet_upgrade(hand) end
        return result
    end

    hooks.set_hand_usage = set_hand_usage
    function set_hand_usage(hand)
        local result = hooks.set_hand_usage(hand)
        if SECRET_HANDS[hand] then M.activate_secret_hand(hand) end
        return result
    end
end

function M.register(take_joker)
    install_hooks()
    take_joker('satellite', {
        config = { extra = 1 },
        loc_vars = function()
            return { vars = { M.current_payout() } }
        end,
        calc_dollar_bonus = function()
            local payout = M.current_payout()
            if payout > 0 then return payout end
        end,
    })
end

return M
