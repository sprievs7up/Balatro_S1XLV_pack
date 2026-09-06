-- Shared configuration and loader for the S1XLV deck collection.
--
-- The individual files under modules/deck_pack are arranged by responsibility:
-- runtime compatibility, deck registration, Small Deck recycling, and the
-- Cartomancer-only rule set. They all receive this module's context table so
-- that run detection and reload-safe hook state have a single owner.

local settings = {
    keys = {
        cartomancer = 'b_cartomancer_deck',
        inferno = 'b_cartomancer_inferno',
        small = 'b_cartomancer_small',
    },
    cartomancer = {
        shop_rates = {
            joker = 20,
            tarot = 4,
            planet = 0,
        },
        booster_weight_multipliers = {
            Standard = 1.5,
            Spectral = 2,
        },
        certificate_seals = {
            'Red',
            'Gold',
            'Purple',
        },
        judgement_base_cost = 5,
        black_hole_key = 'c_black_hole',
        planet_vouchers = {
            v_planet_merchant = true,
            v_planet_tycoon = true,
            v_telescope = true,
            v_observatory = true,
        },
        blocked_planet_source_keys = {
            c_black_hole = true,
            c_trance = true,
            tag_meteor = true,
        },
    },
    icebound = {
        hands_per_dollar = 2,
        dollars_per_group = 1,
    },
    inferno = {
        hand_size_bonus = 4,
        ante_offset = 2,
        first_hand_levels = 2,
        joker_rarity_weights = {
            common = 0.60,
            uncommon = 0.25,
            rare = 0.15,
        },
        ante_ten_base_amounts = {
            [1] = 240000,
            [2] = 500000,
            [3] = 1000000,
            joker = 2000000,
        },
        win_ante = 10,
        starting_jokers = {
            'j_greedy_joker',
            'j_lusty_joker',
            'j_wrathful_joker',
            'j_gluttenous_joker',
        },
    },
    small = {
        recycle_played_cards = true,
        recycle_discarded_cards = false,
        ranks = {
            'Ace',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            'Jack',
            'Queen',
            'King',
        },
        starting_suits = {
            'Clubs',
            'Diamonds',
        },
    },
    tarot = {
        enhanced_max_highlighted = {
            c_magician = 3,
            c_empress = 3,
            c_heirophant = 3,
            c_lovers = 2,
            c_chariot = 2,
            c_justice = 2,
            c_strength = 4,
            c_hanged_man = 3,
            c_devil = 2,
            c_tower = 2,
            c_star = 4,
            c_moon = 4,
            c_sun = 4,
            c_world = 4,
        },
        -- These are UI fallbacks only. Strength is owned internally by
        -- Steamodded and may not expose its vanilla config through self.config.
        vanilla_max_highlighted = {
            c_magician = 2,
            c_empress = 2,
            c_heirophant = 2,
            c_lovers = 1,
            c_chariot = 1,
            c_justice = 1,
            c_strength = 2,
            c_hanged_man = 2,
            c_devil = 1,
            c_tower = 1,
            c_star = 3,
            c_moon = 3,
            c_sun = 3,
            c_world = 3,
        },
        enhanced_extra = {
            c_hermit = 30,
            c_wheel_of_fortune = 3,
            c_temperance = 80,
        },
    },
}

local function selected_back_is(back_key)
    local selected_back = G
        and G.GAME
        and G.GAME.selected_back
    local center = selected_back
        and selected_back.effect
        and selected_back.effect.center
    return center and center.key == back_key or false
end

local function run_uses(modifier_key, back_key)
    if not (G and G.GAME) then return false end
    if G.GAME.modifiers and G.GAME.modifiers[modifier_key] then return true end
    return selected_back_is(back_key)
end

local function is_cartomancer_run()
    return run_uses('cartomancer_tarots', settings.keys.cartomancer)
end

local function is_inferno_run()
    return run_uses('inferno_deck', settings.keys.inferno)
end

local function is_small_run()
    return run_uses('small_deck', settings.keys.small)
end

local function small_recycle_enabled(modifier_key, default_value)
    if not is_small_run() then return false end

    local modifiers = G.GAME.modifiers or {}
    if modifiers[modifier_key] == nil then return default_value end
    return modifiers[modifier_key] == true
end

local function small_recycle_seed(kind)
    local game = G and G.GAME or {}
    local round = game.current_round or {}
    local round_resets = game.round_resets or {}
    return ('small_%s_a%s_h%s_d%s'):format(
        kind,
        tostring(round_resets.ante or 0),
        tostring(round.hands_played or 0),
        tostring(round.discards_used or 0)
    )
end

local function shuffle_card_batch(cards, seed_key)
    if #cards > 1 then
        pseudoshuffle(cards, pseudoseed(seed_key))
    end
end

local function current_center_key(card, fallback)
    local center = fallback or (card and card.config and card.config.center)
    return center and center.key
end

local function is_blocked_planet_source(prototype)
    if not prototype then return false end
    if prototype.set == 'Planet' then return true end
    if prototype.set == 'Booster' and prototype.kind == 'Celestial' then return true end

    local key = prototype.key
    if not key then return false end
    return settings.cartomancer.blocked_planet_source_keys[key]
        or settings.cartomancer.planet_vouchers[key]
        or key:match('^p_celestial_') ~= nil
end

-- Keep the historical state key so a Steamodded hot reload can reuse wrappers
-- installed by an earlier build instead of nesting a second copy around them.
local HOOK_STATE_KEY = '__cartomancer_deck_hook_state'
local hook_state = rawget(_G, HOOK_STATE_KEY)
if type(hook_state) ~= 'table' then
    hook_state = {}
    rawset(_G, HOOK_STATE_KEY, hook_state)
end
hook_state.originals = hook_state.originals or {}
hook_state.tarot_originals = hook_state.tarot_originals or {}

-- Wrappers read changing callbacks and values through hook_state. Reassigning
-- them here keeps hot reloads idempotent while allowing the current source to
-- replace helpers without changing the public center keys or saved-run flags.
hook_state.is_cartomancer_run = is_cartomancer_run
hook_state.is_inferno_run = is_inferno_run
hook_state.is_small_run = is_small_run
hook_state.small_recycle_enabled = small_recycle_enabled
hook_state.small_recycle_seed = small_recycle_seed
hook_state.shuffle_card_batch = shuffle_card_batch
hook_state.current_center_key = current_center_key
hook_state.is_blocked_planet_source = is_blocked_planet_source
hook_state.enhanced_max_highlighted = settings.tarot.enhanced_max_highlighted
hook_state.enhanced_extra = settings.tarot.enhanced_extra
hook_state.booster_weight_multipliers = settings.cartomancer.booster_weight_multipliers
hook_state.planet_vouchers = settings.cartomancer.planet_vouchers
hook_state.judgement_base_cost = settings.cartomancer.judgement_base_cost
hook_state.black_hole_key = settings.cartomancer.black_hole_key
hook_state.inferno_joker_rarity_weights = settings.inferno.joker_rarity_weights
hook_state.inferno_ante_ten_base_amounts = settings.inferno.ante_ten_base_amounts

local context = {
    settings = settings,
    hooks = hook_state,
    is_cartomancer_run = is_cartomancer_run,
    is_inferno_run = is_inferno_run,
    is_small_run = is_small_run,
}

local sections = {
    'modules/deck_pack/back_hooks.lua',
    'modules/deck_pack/decks.lua',
    'modules/deck_pack/small_recycling.lua',
    'modules/deck_pack/cartomancer_rules.lua',
}

local function load_section(path)
    local chunk, load_error = SMODS.load_file(path)
    assert(chunk, ('[S1XLV Deck Pack] Could not load %s: %s')
        :format(path, tostring(load_error)))

    local install = chunk()
    assert(type(install) == 'function',
        ('[S1XLV Deck Pack] %s must return an installer function'):format(path))
    install(context)
end

for _, path in ipairs(sections) do
    load_section(path)
end
