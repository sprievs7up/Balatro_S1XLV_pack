-- Mod state and assets

local BULKY_KEY = 'bsk_bulky'

BSK_BULKY_STAKES = BSK_BULKY_STAKES or {}
local BSK = BSK_BULKY_STAKES

-- Enable Steamodded's Joker retrigger context for the Bulky sticker.
SMODS.current_mod.optional_features = SMODS.current_mod.optional_features or {}
SMODS.current_mod.optional_features.retrigger_joker = true

SMODS.Atlas {
    key = 'bulky_stickers',
    path = 'bulky_stickers.png',
    px = 71,
    py = 95,
}

SMODS.Atlas {
    key = 'stake_stickers',
    path = 'stake_stickers.png',
    px = 71,
    py = 95,
}

-- Compatibility rules

local bulky_blacklist = {
    j_four_fingers = true,
    j_pareidolia = true,
    j_egg = true,
    j_splash = true,
    j_shortcut = true,
    j_midas_mask = true,
    j_luchador = true,
    j_mr_bones = true,
    j_smeared = true,
    j_ring_master = true,
    j_showman = true,
    j_invisible = true,
    j_astronomer = true,

    -- Retrigger sources are excluded; per-card XMult Jokers remain compatible.
    j_mime = true,
    j_dusk = true,
    j_hack = true,
    j_selzer = true,
    j_sock_and_buskin = true,
    j_hanging_chad = true,

    -- Vanilla Legendary Jokers
    j_caino = true,
    j_triboulet = true,
    j_yorick = true,
    j_chicot = true,
    j_perkeo = true,
}

-- Shared helpers

local function has_bulky(card)
    return card
        and card.ability
        and card.ability[BULKY_KEY]
end

local function is_negative(edition)
    if type(edition) == 'string' then
        return edition == 'negative' or edition == 'e_negative'
    end
    if type(edition) ~= 'table' then return false end
    return edition.negative == true
        or edition.key == 'e_negative'
        or edition.type == 'negative'
end

local function change_hand_size(amount)
    if amount ~= 0 and G and G.hand then
        G.hand:change_size(amount)
    end
end

-- Apply static passive effects that do not use Card:calculate_joker().
local function apply_extra_passive_delta(card, direction)
    if not card or not card.ability or not G or not G.GAME then return end

    local ability = card.ability
    local center_key = card.config and card.config.center_key

    if ability.h_size and ability.h_size ~= 0 then
        change_hand_size(direction * ability.h_size)
    end

    if ability.d_size and ability.d_size > 0 then
        G.GAME.round_resets.discards = G.GAME.round_resets.discards + direction * ability.d_size
        if ease_discard then ease_discard(direction * ability.d_size) end
    end

    if center_key == 'j_credit_card' then
        G.GAME.bankrupt_at = G.GAME.bankrupt_at - direction * ability.extra
    elseif center_key == 'j_chaos' then
        SMODS.change_free_rerolls(direction)
        calculate_reroll_cost(true)
    elseif center_key == 'j_turtle_bean' then
        change_hand_size(direction * ability.extra.h_size)
    elseif center_key == 'j_oops' then
        local factor = direction > 0 and 1.5 or (2 / 3)
        for key, value in pairs(G.GAME.probabilities) do
            G.GAME.probabilities[key] = value * factor
        end
    elseif center_key == 'j_to_the_moon' then
        G.GAME.interest_amount = G.GAME.interest_amount + direction * ability.extra
    elseif center_key == 'j_troubadour' then
        change_hand_size(direction * ability.extra.h_size)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + direction * ability.extra.h_plays
    elseif center_key == 'j_stuntman' then
        change_hand_size(-direction * ability.extra.h_size)
    end
end

local function draw_bulky_sticker(sticker, card)
    local sprite = G.shared_stickers[sticker.key]
    if not sprite or not card.children or not card.children.center then return end

    local has_eternal_or_perishable = card.ability.eternal or card.ability.perishable
    local has_rental = card.ability.rental
    local variant = 0

    if has_eternal_or_perishable and has_rental then
        variant = 2 -- 44px: one original sticker interval below Rental
    elseif has_eternal_or_perishable then
        variant = 1 -- 24px: the normal Rental position
    else
        variant = 0 -- 4px: the normal Eternal/Perishable position
    end

    sprite:set_sprite_pos({ x = variant, y = 0 })
    sprite.role.draw_major = card
    sprite:draw_shader('dissolve', nil, nil, nil, card.children.center)
    sprite:draw_shader('voucher', nil, card.ARGS.send_to_shader, nil, card.children.center)
end

-- Bulky sticker

local bulky_sticker = SMODS.Sticker {
    key = 'bulky',
    atlas = 'bulky_stickers',
    pos = { x = 0, y = 0 },
    badge_colour = HEX('8A71E1'),
    rate = 0.3,
    default_compat = true,
    compat_exceptions = bulky_blacklist,
    sets = { Joker = true },
    needs_enable_flag = true,
    config = { extra_slots_used = 1 },

    should_apply = function(self, card, center, area, bypass_roll)
        if not center or center.set ~= 'Joker' then return false end
        if bulky_blacklist[center.key] or center.rarity == 4 then return false end
        if is_negative(card and card.edition) then return false end
        if not G or not G.GAME or not G.GAME.modifiers['enable_' .. self.key] then return false end

        local explicit_compat = center[self.key .. '_compat']
        if explicit_compat == false then return false end
        if explicit_compat == nil and not self.default_compat then return false end

        self.last_roll = pseudorandom(
            (area == G.pack_cards and 'packssj' or 'shopssj')
                .. self.key
                .. G.GAME.round_resets.ante
        )
        return bypass_roll ~= nil and bypass_roll or self.last_roll > (1 - self.rate)
    end,

    apply = function(self, card, value)
        if value and is_negative(card.edition) then return false end

        local had_bulky = has_bulky(card)
        if had_bulky and not value and card.added_to_deck then
            apply_extra_passive_delta(card, -1)
        end

        SMODS.Sticker.apply(self, card, value)

        if not had_bulky and value and card.added_to_deck then
            apply_extra_passive_delta(card, 1)
        end

        if card.set_cost then card:set_cost() end
        return true
    end,

    draw = function(self, card)
        draw_bulky_sticker(self, card)
    end,

    calculate = function(self, card, context)
        if context.retrigger_joker_check
            and context.other_card == card
            and not context.retrigger_joker then
            return {
                repetitions = 1,
                message = localize('k_again_ex'),
                card = card,
            }
        end
    end,
}

assert(bulky_sticker, '[Bulky Stakes] Could not register the Bulky sticker')

-- Retrigger result normalization

local xmult_keys = {
    x_mult = true,
    Xmult = true,
    xmult = true,
    x_mult_mod = true,
    Xmult_mod = true,
}

local function convert_bulky_retrigger_xmult(effect)
    if type(effect) ~= 'table' then return false end

    local changed = false
    for key, value in pairs(effect) do
        if xmult_keys[key] and type(value) == 'number' then
            effect[key] = 2
            changed = true
        end
    end

    if type(effect.extra) == 'table' then
        changed = convert_bulky_retrigger_xmult(effect.extra) or changed
    end

    if changed then
        effect.message = localize {
            type = 'variable',
            key = 'a_xmult',
            vars = { 2 },
        }
    end

    return changed
end

-- Copy and slot-management helpers

local function remove_all_stickers(card)
    if not card or not card.ability then return end

    for _, key in ipairs(SMODS.Sticker.obj_buffer) do
        if card.ability[key] or (key == 'pinned' and card.pinned) then
            card:remove_sticker(key)
        end
    end

    -- Rental affects displayed cost, so recalculate after sticker removal.
    if card.set_cost then card:set_cost() end
end

local stickerless_joker_append_keys = {
    rif = true, -- Riff-raff
    jud = true, -- Judgement
    sou = true, -- The Soul
    wra = true, -- Wraith
}

local function joker_center_key(card)
    return card
        and card.config
        and (card.config.center_key or (card.config.center and card.config.center.key))
end

local function is_eternal(card, source)
    if not card or not card.ability then return false end
    if SMODS.is_eternal then return SMODS.is_eternal(card, source) end
    return card.ability.eternal == true
end

local function joker_slot_usage(card)
    return 1 + ((card and card.ability and card.ability.extra_slots_used) or 0)
end

local function joker_slot_gain(card)
    return (card and card.ability and card.ability.card_limit) or 0
end

local function copied_slot_values(card)
    local usage = joker_slot_usage(card)
    local gain = joker_slot_gain(card)

    -- Ankh and Invisible Joker strip Negative from their copy.
    if is_negative(card and card.edition) then
        usage = usage - ((card.edition and card.edition.extra_slots_used) or 0)
        gain = gain - ((card.edition and card.edition.card_limit) or 0)
    end

    return usage, gain
end

local function current_joker_slot_state()
    local used = 0
    for _, card in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        used = used + joker_slot_usage(card)
    end

    local limits = G
        and G.jokers
        and G.jokers.config
        and G.jokers.config.card_limits
    local total = limits and limits.total_slots
        or ((G and G.jokers and G.jokers.config and G.jokers.config.card_limit) or 0)
    return used, total
end

local function invisible_copy_overflow(source, target, removed)
    local used, total = current_joker_slot_state()
    removed = removed or {}

    used = used - joker_slot_usage(source)
    total = total - joker_slot_gain(source)
    for _, card in ipairs(removed) do
        used = used - joker_slot_usage(card)
        total = total - joker_slot_gain(card)
    end

    local copy_usage, copy_gain = copied_slot_values(target)
    return used + copy_usage - (total + copy_gain)
end

local function remove_from_list(list, value)
    for index = #list, 1, -1 do
        if list[index] == value then
            table.remove(list, index)
            return
        end
    end
end

local function plan_invisible_copy(source, target)
    if not has_bulky(target) or invisible_copy_overflow(source, target) <= 0 then
        return target, {}
    end

    local squeeze_pool = {}
    for _, card in ipairs(G.jokers.cards) do
        if card ~= source
            and card ~= target
            and not card.getting_sliced
            and not is_eternal(card, source)
            and joker_slot_usage(card) - joker_slot_gain(card) > 0 then
            squeeze_pool[#squeeze_pool + 1] = card
        end
    end

    local squeezed = {}
    while #squeeze_pool > 0
        and invisible_copy_overflow(source, target, squeezed) > 0 do
        local card = pseudorandom_element(
            squeeze_pool,
            pseudoseed('bsk_invisible_squeeze')
        )
        squeezed[#squeezed + 1] = card
        remove_from_list(squeeze_pool, card)
    end

    if invisible_copy_overflow(source, target, squeezed) <= 0 then
        return target, squeezed
    end

    -- Fall back to a target that fits after Invisible Joker is sold.
    local alternatives = {}
    for _, card in ipairs(G.jokers.cards) do
        if card ~= source
            and card ~= target
            and not card.getting_sliced
            and invisible_copy_overflow(source, card) <= 0 then
            alternatives[#alternatives + 1] = card
        end
    end

    local alternative = #alternatives > 0 and pseudorandom_element(
        alternatives,
        pseudoseed('bsk_invisible_fallback')
    ) or nil
    return alternative or target, alternative and {} or squeezed
end

local function ankh_copy_overflow(target, source)
    local limits = G
        and G.jokers
        and G.jokers.config
        and G.jokers.config.card_limits
    local total = limits
        and ((limits.base or 0) + (limits.mod or 0))
        or ((G and G.jokers and G.jokers.config and G.jokers.config.card_limit) or 0)
    local used = 0

    -- Ankh keeps its target and every Eternal Joker.
    for _, card in ipairs(G.jokers.cards) do
        if card == target or is_eternal(card, source) then
            used = used + joker_slot_usage(card)
            total = total + joker_slot_gain(card)
        end
    end

    local copy_usage, copy_gain = copied_slot_values(target)
    return used + copy_usage - (total + copy_gain)
end

local function plan_ankh_copy(source, target)
    if not has_bulky(target) or ankh_copy_overflow(target, source) <= 0 then
        return target, {}
    end

    local alternatives = {}
    for _, card in ipairs(G.jokers.cards) do
        if card ~= target
            and not card.getting_sliced
            and ankh_copy_overflow(card, source) <= 0 then
            alternatives[#alternatives + 1] = card
        end
    end

    local alternative = #alternatives > 0 and pseudorandom_element(
        alternatives,
        pseudoseed('bsk_ankh_fallback')
    ) or nil
    local squeezed = {}
    if alternative and not is_eternal(target, source) then
        squeezed[1] = target
    end
    return alternative or target, squeezed
end

local function has_viable_ankh_copy(source)
    for _, card in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        if ankh_copy_overflow(card, source) <= 0 then
            return true
        end
    end
    return false
end

local function squeeze_joker(card)
    if not card or card.getting_sliced then return end

    card.getting_sliced = true
    G.E_MANAGER:add_event(Event({
        trigger = 'before',
        delay = 0.15,
        func = function()
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = localize('k_bsk_squeezed'),
                colour = G.C.RED,
            })
            card:start_dissolve({ HEX('8A71E1') }, nil, 1.2)
            return true
        end,
    }))
end

-- Runtime hooks

if not BSK.hooks_installed then
    BSK.hooks_installed = true

    BSK.card_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        local invisible_sale = context
            and context.selling_self
            and joker_center_key(self) == 'j_invisible'
        if invisible_sale then
            BSK.invisible_copy_source = self
        end

        local result, triggered = BSK.card_calculate_joker(self, context)

        if invisible_sale and BSK.invisible_copy_source == self then
            BSK.invisible_copy_source = nil
        end
        -- Steamodded's scoring loops pass retrigger_joker as true rather than
        -- the source card. Normalize every Bulky XMult retrigger to X2 so the
        -- sticker doubles XMult linearly instead of applying the original XMult
        -- a second time (for example, X3 becomes X6 rather than X9).
        if has_bulky(self)
            and context
            and context.retrigger_joker then
            convert_bulky_retrigger_xmult(result)
        end
        return result, triggered
    end

    BSK.card_set_cost = Card.set_cost
    function Card:set_cost()
        BSK.card_set_cost(self)
        if has_bulky(self) then
            self.cost = (self.cost or 0) * 2
        end
    end

    BSK.card_add_to_deck = Card.add_to_deck
    function Card:add_to_deck(from_debuff)
        local was_added = self.added_to_deck
        local result = BSK.card_add_to_deck(self, from_debuff)
        if not was_added and self.added_to_deck and has_bulky(self) then
            apply_extra_passive_delta(self, 1)
        end
        return result
    end

    BSK.card_remove_from_deck = Card.remove_from_deck
    function Card:remove_from_deck(from_debuff)
        local was_added = self.added_to_deck
        local result = BSK.card_remove_from_deck(self, from_debuff)
        if was_added and not self.added_to_deck and has_bulky(self) then
            apply_extra_passive_delta(self, -1)
        end
        return result
    end

    -- End-of-round cash Jokers are evaluated once through this separate path,
    -- so they do not receive the normal Bulky Joker retrigger.
    BSK.card_calculate_dollar_bonus = Card.calculate_dollar_bonus
    function Card:calculate_dollar_bonus()
        local dollars = BSK.card_calculate_dollar_bonus(self)
        if dollars and has_bulky(self) then
            return dollars * 2
        end
        return dollars
    end

    BSK.card_calculate_rental = Card.calculate_rental
    function Card:calculate_rental()
        BSK.card_calculate_rental(self)
        if has_bulky(self) and self.ability.rental then
            BSK.card_calculate_rental(self)
        end
    end

    BSK.card_calculate_perishable = Card.calculate_perishable
    function Card:calculate_perishable()
        BSK.card_calculate_perishable(self)
        if has_bulky(self) and self.ability.perishable then
            BSK.card_calculate_perishable(self)
        end
    end

    -- Rental and Perishable are doubled explicitly above. Steamodded evaluates
    -- every sticker again during a Joker retrigger, so letting these two base
    -- stickers run on the Bulky pass would make both penalties occur four times.
    BSK.rental_sticker_calculate = SMODS.Stickers.rental.calculate
    SMODS.Stickers.rental.calculate = function(self, card, context)
        if has_bulky(card)
            and context
            and context.end_of_round
            and context.retrigger_joker then
            return nil
        end
        return BSK.rental_sticker_calculate(self, card, context)
    end

    BSK.perishable_sticker_calculate = SMODS.Stickers.perishable.calculate
    SMODS.Stickers.perishable.calculate = function(self, card, context)
        if has_bulky(card)
            and context
            and context.end_of_round
            and context.retrigger_joker then
            return nil
        end
        return BSK.perishable_sticker_calculate(self, card, context)
    end

    BSK.card_set_edition = Card.set_edition
    function Card:set_edition(edition, immediate, silent)
        -- Negative takes priority over Bulky.
        if is_negative(edition) and has_bulky(self) then
            SMODS.Stickers[BULKY_KEY]:apply(self, false)
        end
        return BSK.card_set_edition(self, edition, immediate, silent)
    end

    BSK.card_update = Card.update
    function Card:update(dt)
        BSK.card_update(self, dt)

        -- Remove Bulky from cards that became incompatible in a later version.
        if has_bulky(self) and bulky_blacklist[joker_center_key(self)] then
            SMODS.Stickers[BULKY_KEY]:apply(self, false)
        end

        -- Ectoplasm should not select a Bulky Joker only to strip the sticker.
        if self.ability
            and self.ability.name == 'Ectoplasm'
            and self.eligible_editionless_jokers then
            for index = #self.eligible_editionless_jokers, 1, -1 do
                if has_bulky(self.eligible_editionless_jokers[index]) then
                    table.remove(self.eligible_editionless_jokers, index)
                end
            end
        end

        -- Include Joker Stencil's Bulky body in its empty-slot value.
        if G and G.jokers
            and self.area == G.jokers
            and self.config
            and self.config.center_key == 'j_stencil'
            and has_bulky(self) then
            self.ability.x_mult = (self.ability.x_mult or 0) + 1
        end
    end

    BSK.card_check_use = Card.check_use
    function Card:check_use()
        if joker_center_key(self) == 'c_ankh' and G and G.jokers then
            -- Selecting Ankh from a booster is not the same as using it.
            if self.area == G.pack_cards
                and G.pack_cards
                and booster_obj
                and self:selectable_from_pack(booster_obj) then
                return BSK.card_check_use(self)
            end

            if has_viable_ankh_copy(self) then return nil end
            alert_no_space(self, G.jokers)
            return true
        end
        return BSK.card_check_use(self)
    end

    BSK.create_card = create_card
    function create_card(_type, area, legendary, rarity, skip_materialize, soulable, forced_key, key_append)
        local card = BSK.create_card(
            _type,
            area,
            legendary,
            rarity,
            skip_materialize,
            soulable,
            forced_key,
            key_append
        )

        -- Generated Jokers from these sources are stickerless; Editions remain.
        if _type == 'Joker' and stickerless_joker_append_keys[key_append] then
            remove_all_stickers(card)
        end

        return card
    end

    BSK.card_use_consumeable = Card.use_consumeable
    function Card:use_consumeable(area, copier)
        local center_key = self.config
            and (self.config.center_key or (self.config.center and self.config.center.key))
        if center_key == 'c_ankh' and not self.debuff then
            -- Retain the Ankh marker until its queued copy is constructed.
            BSK.ankh_copy_pending = self
        end
        return BSK.card_use_consumeable(self, area, copier)
    end

    BSK.copy_card = copy_card
    function copy_card(other, new_card, card_scale, playing_card, strip_edition)
        local source = BSK.invisible_copy_source or BSK.ankh_copy_pending
        local mode = BSK.invisible_copy_source and 'invisible'
            or (BSK.ankh_copy_pending and 'ankh')
        local target = other
        local squeezed = {}

        if mode == 'invisible' and other and other.ability and other.ability.set == 'Joker' then
            target, squeezed = plan_invisible_copy(source, other)
        elseif mode == 'ankh' and other and other.ability and other.ability.set == 'Joker' then
            target, squeezed = plan_ankh_copy(source, other)
            BSK.ankh_copy_pending = nil
        end

        if target ~= other then
            strip_edition = target.edition and target.edition.negative
        end

        local card = BSK.copy_card(target, new_card, card_scale, playing_card, strip_edition)
        for _, squeezed_card in ipairs(squeezed) do
            squeeze_joker(squeezed_card)
        end
        return card
    end

    BSK.get_blind_amount = get_blind_amount
    function get_blind_amount(ante)
        if G
            and G.GAME
            and G.GAME.modifiers
            and G.GAME.modifiers.bsk_joker_stake_scaling then
            local amounts = {
                300,
                1100,
                3900,
                12000,
                37000,
                100000,
                200000,
                400000,
            }
            if ante < 1 then return 100 end
            if ante <= 8 then return amounts[ante] end

            -- Continue with the base game's endless exponential curve, using
            -- Joker Stake's Ante 8 value as the anchor.
            local k = 0.75
            local a, b, c, d = amounts[8], 1.6, ante - 8, 1 + 0.2 * (ante - 8)
            local amount = math.floor(a * (b + (k * c) ^ d) ^ c)
            amount = amount - amount % (10 ^ math.floor(math.log10(amount) - 1))
            return amount
        end
        return BSK.get_blind_amount(ante)
    end
end

-- Stake registration

-- Extend Gold's unlock chain without replacing its modifiers.
local gold_stake = SMODS.Stake:take_ownership('gold', {
    unlocked_stake = 'australium',
}, true)
assert(gold_stake, '[Bulky Stakes] Could not extend stake_gold')

local australium_stake = SMODS.Stake {
    key = 'australium',
    applied_stakes = { 'gold' },
    above_stake = 'gold',
    unlocked_stake = 'joker',
    prefix_config = {
        applied_stakes = { mod = false },
        above_stake = { mod = false },
    },
    pos = { x = 3, y = 1 },
    sticker_atlas = 'stake_stickers',
    sticker_pos = { x = 0, y = 0 },
    colour = HEX('E3B448'),
    shiny = true,
    modifiers = function()
        G.GAME.modifiers.enable_bsk_bulky = true
    end,
}
assert(australium_stake, '[Bulky Stakes] Could not register Australium Stake')

local joker_stake = SMODS.Stake {
    key = 'joker',
    applied_stakes = { 'australium' },
    above_stake = 'australium',
    pos = { x = 4, y = 1 },
    sticker_atlas = 'stake_stickers',
    sticker_pos = { x = 1, y = 0 },
    colour = G.C.WHITE,
    modifiers = function()
        G.GAME.modifiers.bsk_joker_stake_scaling = true
    end,
}
assert(joker_stake, '[Bulky Stakes] Could not register Joker Stake')
