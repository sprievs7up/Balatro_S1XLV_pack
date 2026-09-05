-- Shared helpers

local function take_joker(key, definition)
    local owned = SMODS.Joker:take_ownership(key, definition, true)
    assert(owned, ('[Balatro Balance Patch] Could not take ownership of j_%s'):format(key))
    return owned
end

local function take_voucher(key, definition)
    local owned = SMODS.Voucher:take_ownership(key, definition, true)
    assert(owned, ('[Balatro Balance Patch] Could not take ownership of v_%s'):format(key))
    return owned
end

-- Matador's vanilla calculation only observes Boss effects that reach the
-- scoring contexts. The hooks below translate the remaining Boss events into
-- one Steamodded context per activation. This keeps Blueprint, Brainstorm, and
-- Joker retriggers on Steamodded's normal calculation path.
BBP_MATADOR = BBP_MATADOR or {}
local MATADOR = BBP_MATADOR

local function blind_key(blind)
    return blind
        and blind.config
        and blind.config.blind
        and blind.config.blind.key
end

local function blind_matches(blind, key, name)
    return blind_key(blind) == key or (blind and blind.name == name)
end

local function is_active_boss(blind)
    return G
        and G.GAME
        and G.GAME.facing_blind
        and G.GAME.blind == blind
        and blind
        and not blind.disabled
        and blind.config
        and blind.config.blind
        and blind.config.blind.boss
end

function MATADOR.trigger(reason, repetitions)
    local blind = G and G.GAME and G.GAME.blind
    if not is_active_boss(blind) then return false end

    local count = math.max(0, math.floor(repetitions or 1))
    for _ = 1, count do
        SMODS.calculate_context({
            bbp_matador_boss_event = true,
            bbp_matador_reason = reason,
        })
    end
    return count > 0
end

local function hand_has_forced_selection()
    if not G or not G.hand then return false end
    for _, playing_card in ipairs(G.hand.cards or {}) do
        if playing_card.ability and playing_card.ability.forced_selection then
            return true
        end
    end
    return false
end

local function any_joker_is_debuffed()
    if not G or not G.jokers then return false end
    for _, joker in ipairs(G.jokers.cards or {}) do
        if joker.debuff then return true end
    end
    return false
end

local function pending_draw_size(argument)
    if not G or not G.GAME or not G.deck or not G.hand then return 0 end
    if (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK)
        or (G.hand.config.card_limit <= 0 and #G.hand.cards == 0) then
        return 0
    end

    local amount = argument
        or math.min(#G.deck.cards, G.hand.config.card_limit - #G.hand.cards)
    local blind = G.GAME.blind
    if blind_matches(blind, 'bl_serpent', 'The Serpent')
        and not blind.disabled
        and (G.GAME.current_round.hands_played > 0
            or G.GAME.current_round.discards_used > 0) then
        amount = math.min(#G.deck.cards, 3)
    end
    return math.max(0, tonumber(amount) or 0)
end

local function install_matador_hooks()
    if MATADOR.hooks_installed then return end
    MATADOR.hooks_installed = true

    MATADOR.blind_set_blind = Blind.set_blind
    function Blind:set_blind(blind, reset, silent)
        local result = MATADOR.blind_set_blind(self, blind, reset, silent)

        if not reset then
            self.bbp_matador_entry_event = nil
            self.bbp_matador_draw_pending = nil
            self.bbp_matador_face_down_pending = nil
            self.bbp_matador_house_paid = nil
            self.bbp_matador_tooth_remaining = nil

            if blind_matches(self, 'bl_water', 'The Water') then
                self.bbp_matador_entry_event = {
                    reason = 'water',
                    repetitions = math.max(0, self.discards_sub or 0),
                }
            elseif blind_matches(self, 'bl_needle', 'The Needle') then
                self.bbp_matador_entry_event = {
                    reason = 'needle',
                    repetitions = math.max(0, self.hands_sub or 0),
                }
            end
        end

        return result
    end

    MATADOR.draw_from_deck_to_hand = G.FUNCS.draw_from_deck_to_hand
    G.FUNCS.draw_from_deck_to_hand = function(argument)
        local draw_size = pending_draw_size(argument)
        local result = MATADOR.draw_from_deck_to_hand(argument)
        local blind = G and G.GAME and G.GAME.blind
        if draw_size > 0 and is_active_boss(blind) then
            blind.bbp_matador_draw_pending = true
        end
        return result
    end

    MATADOR.blind_stay_flipped = Blind.stay_flipped
    function Blind:stay_flipped(area, card)
        local flipped = MATADOR.blind_stay_flipped(self, area, card)
        if flipped
            and area == G.hand
            and self.bbp_matador_draw_pending
            and (blind_matches(self, 'bl_wheel', 'The Wheel')
                or blind_matches(self, 'bl_house', 'The House')
                or blind_matches(self, 'bl_mark', 'The Mark')
                or blind_matches(self, 'bl_fish', 'The Fish')) then
            self.bbp_matador_face_down_pending = true
        end
        return flipped
    end

    MATADOR.blind_drawn_to_hand = Blind.drawn_to_hand
    function Blind:drawn_to_hand()
        local had_forced_selection = hand_has_forced_selection()
        local was_prepped = self.prepped
        local drew_cards = self.bbp_matador_draw_pending == true
        local drew_face_down = self.bbp_matador_face_down_pending == true
        local entry_event = self.bbp_matador_entry_event

        local result = MATADOR.blind_drawn_to_hand(self)

        self.bbp_matador_draw_pending = nil
        self.bbp_matador_face_down_pending = nil
        self.bbp_matador_entry_event = nil

        if not is_active_boss(self) then return result end

        if entry_event then
            MATADOR.trigger(entry_event.reason, entry_event.repetitions)
        end

        if blind_matches(self, 'bl_serpent', 'The Serpent') and drew_cards then
            MATADOR.trigger('serpent')
        elseif blind_matches(self, 'bl_fish', 'The Fish')
            and drew_cards and drew_face_down and was_prepped then
            MATADOR.trigger('fish')
        elseif blind_matches(self, 'bl_wheel', 'The Wheel')
            and drew_cards and drew_face_down then
            MATADOR.trigger('wheel')
        elseif blind_matches(self, 'bl_mark', 'The Mark')
            and drew_cards and drew_face_down then
            MATADOR.trigger('mark')
        elseif blind_matches(self, 'bl_house', 'The House')
            and drew_cards and drew_face_down and not self.bbp_matador_house_paid then
            self.bbp_matador_house_paid = true
            MATADOR.trigger('house')
        end

        if blind_matches(self, 'bl_final_heart', 'Crimson Heart')
            and was_prepped and any_joker_is_debuffed() then
            MATADOR.trigger('crimson_heart')
        elseif blind_matches(self, 'bl_final_bell', 'Cerulean Bell')
            and not had_forced_selection and hand_has_forced_selection() then
            MATADOR.trigger('cerulean_bell')
        end

        return result
    end

    MATADOR.discard_cards_from_highlighted = G.FUNCS.discard_cards_from_highlighted
    G.FUNCS.discard_cards_from_highlighted = function(event, hook)
        local blind = G and G.GAME and G.GAME.blind
        local discarded = G and G.hand and G.discard and G.play
            and math.min(#G.hand.highlighted, G.discard.config.card_limit - #G.play.cards)
            or 0
        local hook_triggered = hook
            and discarded > 0
            and is_active_boss(blind)
            and blind_matches(blind, 'bl_hook', 'The Hook')

        local result = MATADOR.discard_cards_from_highlighted(event, hook)
        if hook_triggered then MATADOR.trigger('hook') end
        return result
    end

    MATADOR.blind_press_play = Blind.press_play
    function Blind:press_play()
        local tooth_triggered = is_active_boss(self)
            and blind_matches(self, 'bl_tooth', 'The Tooth')
            and G.play
            and #G.play.cards > 0
        local played_cards = tooth_triggered and #G.play.cards or 0
        local result = MATADOR.blind_press_play(self)
        self.bbp_matador_tooth_remaining = tooth_triggered and played_cards or nil
        return result
    end

    MATADOR.ease_dollars = ease_dollars
    function ease_dollars(amount, instant)
        local result = MATADOR.ease_dollars(amount, instant)
        local blind = G and G.GAME and G.GAME.blind
        if amount == -1
            and not instant
            and is_active_boss(blind)
            and blind_matches(blind, 'bl_tooth', 'The Tooth')
            and blind.bbp_matador_tooth_remaining then
            blind.bbp_matador_tooth_remaining = blind.bbp_matador_tooth_remaining - 1
            if blind.bbp_matador_tooth_remaining <= 0 then
                blind.bbp_matador_tooth_remaining = nil
                MATADOR.trigger('tooth')
            end
        end
        return result
    end
end

install_matador_hooks()

SMODS.Atlas {
    key = 'magic_trick',
    path = 'magic_trick.png',
    px = 71,
    py = 95,
}

local function gold_interest_is_active()
    return G
        and G.GAME
        and G.GAME.modifiers
        and G.GAME.modifiers.bbp_gold_interest == true
end

-- Mirrors vanilla Flower Pot suit assignment. Natural cards are counted first;
-- Wild Cards then fill one still-missing suit apiece.
local function count_flower_pot_suits(scoring_hand)
    local suits = {
        Hearts = 0,
        Diamonds = 0,
        Spades = 0,
        Clubs = 0,
    }

    for _, playing_card in ipairs(scoring_hand or {}) do
        if not SMODS.has_any_suit(playing_card) then
            if playing_card:is_suit('Hearts', true) and suits.Hearts == 0 then
                suits.Hearts = 1
            elseif playing_card:is_suit('Diamonds', true) and suits.Diamonds == 0 then
                suits.Diamonds = 1
            elseif playing_card:is_suit('Spades', true) and suits.Spades == 0 then
                suits.Spades = 1
            elseif playing_card:is_suit('Clubs', true) and suits.Clubs == 0 then
                suits.Clubs = 1
            end
        end
    end

    for _, playing_card in ipairs(scoring_hand or {}) do
        if SMODS.has_any_suit(playing_card) then
            if playing_card:is_suit('Hearts') and suits.Hearts == 0 then
                suits.Hearts = 1
            elseif playing_card:is_suit('Diamonds') and suits.Diamonds == 0 then
                suits.Diamonds = 1
            elseif playing_card:is_suit('Spades') and suits.Spades == 0 then
                suits.Spades = 1
            elseif playing_card:is_suit('Clubs') and suits.Clubs == 0 then
                suits.Clubs = 1
            end
        end
    end

    return suits.Hearts + suits.Diamonds + suits.Spades + suits.Clubs
end

local function reserve_consumable_slots(amount)
    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + amount
end

local function release_consumable_slots(amount)
    G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 0) - amount)
end

local function available_consumable_slots()
    return G.consumeables.config.card_limit
        - (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0))
end

local function last_tarot_or_planet_key()
    local key = G.GAME.last_tarot_planet
    local center = key and G.P_CENTERS[key]
    if center and (center.set == 'Tarot' or center.set == 'Planet') then
        return key
    end
    return 'c_fool'
end

-- Joker balance overrides

-- Greedy, Lusty, Wrathful, and Gluttonous Joker
for _, data in ipairs({
    { key = 'greedy_joker', suit = 'Diamonds' },
    { key = 'lusty_joker', suit = 'Hearts' },
    { key = 'wrathful_joker', suit = 'Spades' },
    -- The vanilla internal key intentionally contains this spelling.
    { key = 'gluttenous_joker', suit = 'Clubs' },
}) do
    take_joker(data.key, {
        config = { extra = { s_mult = 4, suit = data.suit } },
    })
end

-- Banner
take_joker('banner', {
    config = { extra = 40 },
})

-- Mystic Summit
take_joker('mystic_summit', {
    config = { extra = { chips = 150, d_remaining = 0 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.d_remaining } }
    end,
    calculate = function(self, card, context)
        if context.joker_main
            and G.GAME.current_round.discards_left == card.ability.extra.d_remaining then
            return { chips = card.ability.extra.chips }
        end
    end,
})

-- 8 Ball
take_joker('8_ball', {
    config = { extra = { odds = 4, copies = 1 } },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card,
            1,
            card.ability.extra.odds,
            'bbp_8_ball'
        )
        return { vars = { numerator, denominator, card.ability.extra.copies } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == 8
                and available_consumable_slots() >= card.ability.extra.copies
                and SMODS.pseudorandom_probability(
                    card,
                    'bbp_8_ball',
                    1,
                    card.ability.extra.odds,
                    'bbp_8_ball'
                ) then
                local copies = card.ability.extra.copies
                reserve_consumable_slots(copies)
                return {
                    extra = {
                        focus = card,
                        message = localize('k_bbp_one_fool'),
                        func = function()
                            G.E_MANAGER:add_event(Event({
                                trigger = 'before',
                                delay = 0,
                                func = function()
                                    for index = 1, copies do
                                        SMODS.add_card({
                                            key = 'c_fool',
                                            area = G.consumeables,
                                            no_edition = true,
                                            key_append = 'bbp_8_ball_' .. index,
                                        })
                                    end
                                    release_consumable_slots(copies)
                                    return true
                                end,
                            }))
                        end,
                    },
                    colour = G.C.SECONDARY_SET.Tarot,
                }
            end

            -- Returning a truthy second value prevents Card:calculate_joker from
            -- falling through to vanilla 8 Ball, whose numeric extra is replaced
            -- by this mod's { odds, copies } table.
            return nil, true
        end
    end,
})

-- Scary Face
take_joker('scary_face', {
    config = { extra = 40 },
})

-- Scholar
take_joker('scholar', {
    rarity = 1,
    config = { extra = { mult = 5, chips = 20 } },
})

-- Hologram
take_joker('hologram', {
    config = { extra = 0.2, Xmult = 1 },
})

-- Arrowhead
take_joker('arrowhead', {
    config = { extra = 40 },
})

-- Green Joker
take_joker('green_joker', {
    config = { extra = { hand_add = 1, discard_sub = 2 }, mult = 0 },
})

-- Mail-In Rebate
take_joker('mail', {
    config = { extra = 4 },
})

-- Faceless Joker
take_joker('faceless', {
    config = { extra = { dollars = 8, faces = 3 } },
})

-- Hanging Chad
take_joker('hanging_chad', {
    rarity = 2,
})

-- Vampire
take_joker('vampire', {
    config = { extra = 0.15, Xmult = 1 },
})

-- Gros Michel
take_joker('gros_michel', {
    config = { extra = { odds = 10, mult = 15 } },
})

-- Seance
take_joker('seance', {
    config = { extra = { poker_hand = 'Straight Flush' } },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        local poker_hand = card
            and card.ability
            and card.ability.extra
            and card.ability.extra.poker_hand
            or self.config.extra.poker_hand
        return {
            vars = {
                localize(poker_hand, 'poker_hands'),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main
            and next(context.poker_hands[card.ability.extra.poker_hand]) then
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0,
                func = function()
                    SMODS.add_card({
                        set = 'Spectral',
                        area = G.consumeables,
                        edition = 'e_negative',
                        key_append = 'bbp_seance',
                    })
                    return true
                end,
            }))
            return {
                message = localize('k_plus_spectral'),
                colour = G.C.SECONDARY_SET.Spectral,
            }
        end
    end,
})

-- Erosion
take_joker('erosion', {
    config = { extra = 5 },
})

-- Hiker
take_joker('hiker', {
    cost = 7,
    config = { extra = 1 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            context.other_card.ability.perma_mult = context.other_card.ability.perma_mult or 0
            context.other_card.ability.perma_mult = context.other_card.ability.perma_mult
                + card.ability.extra
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MULT,
            }
        end
    end,
})

-- Loyalty Card
take_joker('loyalty_card', {
    rarity = 1,
})

-- Matador
take_joker('matador', {
    rarity = 3,
    cost = 10,
    config = { extra = 8 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.bbp_matador_boss_event then
            return { dollars = card.ability.extra }
        end
    end,
})

-- Superposition
take_joker('superposition', {
    config = {},
    rarity = 3,
    cost = 10,
    calculate = function(self, card, context)
        if context.joker_main then
            local has_ace = false
            for _, playing_card in ipairs(context.scoring_hand or {}) do
                if playing_card:get_id() == 14 then
                    has_ace = true
                    break
                end
            end

            if has_ace and next(context.poker_hands['Straight']) then
                local consumable_key = last_tarot_or_planet_key()
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0,
                    func = function()
                        SMODS.add_card({
                            key = consumable_key,
                            area = G.consumeables,
                            edition = 'e_negative',
                            key_append = 'bbp_superposition_negative',
                        })
                        return true
                    end,
                }))
                return {
                    message = localize('k_bbp_negative_only'),
                    colour = G.C.SECONDARY_SET.Tarot,
                }
            end
        end
    end,
})

-- Red Card
take_joker('red_card', {
    config = { extra = 4, mult = 0 },
})

-- Square Joker
take_joker('square', {
    config = { extra = { chips = 16, chip_mod = 4 } },
})

-- Stone Joker
take_joker('stone', {
    config = { extra = 50 },
})

-- Throwback
take_joker('throwback', {
    config = { extra = 0.5 },
})

-- Flower Pot
take_joker('flower_pot', {
    rarity = 3,
    cost = 8,
    config = { extra = { two = 1.25, three = 2.5, four = 4 } },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.two, extra.three, extra.four } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local suit_count = count_flower_pot_suits(context.scoring_hand)
            local extra = card.ability.extra
            local x_mult = suit_count == 4 and extra.four
                or suit_count == 3 and extra.three
                or suit_count == 2 and extra.two

            if x_mult then
                return { x_mult = x_mult }
            end
        end
    end,
})

-- Hit the Road
take_joker('hit_the_road', {
    config = { extra = 0.75 },
})

-- The Family
take_joker('family', {
    config = { Xmult = 5, type = 'Four of a Kind' },
})

-- The Tribe
take_joker('tribe', {
    config = { Xmult = 2.5, type = 'Flush' },
})

-- Satellite
take_joker('satellite', {
    config = { extra = 2 },
})

-- Bootstraps
take_joker('bootstraps', {
    config = { extra = { mult = 3, dollars = 5 } },
})

-- Golden Ticket
take_joker('ticket', {
    config = { extra = 5 },
})

-- Magic Trick artwork
take_voucher('magic_trick', {
    atlas = 'magic_trick',
    pos = { x = 0, y = 0 },
})

-- Stake and interest overrides

-- To the Moon uses the Gold Stake interest basis when it is active.
take_joker('to_the_moon', {
    config = { extra = 1 },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local interest_scale = gold_interest_is_active() and 2 or 1
        local interest_basis = gold_interest_is_active() and 10 or 5
        return { vars = { extra * interest_scale, interest_basis } }
    end,
})

-- Gold Stake uses a lower interest balance cap, so its interest vouchers use
-- Gold-specific caps. On all lower Stakes these remain at their vanilla values.
take_voucher('seed_money', {
    config = { extra = 50 },
    loc_vars = function()
        return { vars = { gold_interest_is_active() and 8 or 10 } }
    end,
    redeem = function()
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.interest_cap = gold_interest_is_active() and 40 or 50
                return true
            end,
        }))
    end,
})

take_voucher('money_tree', {
    config = { extra = 100 },
    loc_vars = function()
        return { vars = { gold_interest_is_active() and 16 or 20 } }
    end,
    redeem = function()
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.interest_cap = gold_interest_is_active() and 80 or 100
                return true
            end,
        }))
    end,
})

-- Blue Stake enables Perishable Jokers without the vanilla discard penalty.
local blue_stake = SMODS.Stake:take_ownership('blue', {
    modifiers = function()
        G.GAME.modifiers.enable_perishables_in_shop = true
    end,
}, true)
assert(blue_stake, '[Balatro Balance Patch] Could not take ownership of stake_blue')

-- Orange Stake enables Rental Jokers; Perishable is inherited from Blue.
local orange_stake = SMODS.Stake:take_ownership('orange', {
    modifiers = function()
        G.GAME.modifiers.enable_rentals_in_shop = true
    end,
}, true)
assert(orange_stake, '[Balatro Balance Patch] Could not take ownership of stake_orange')

-- Gold Stake uses $2 interest per $10, capped at $4 before vouchers.
local gold_stake = SMODS.Stake:take_ownership('gold', {
    modifiers = function()
        G.GAME.modifiers.bbp_gold_interest = true
        G.GAME.modifiers.bbp_interest_basis = 10
        G.GAME.modifiers.bbp_interest_scale = 2
        G.GAME.interest_cap = 20
    end,
}, true)
assert(gold_stake, '[Balatro Balance Patch] Could not take ownership of stake_gold')
