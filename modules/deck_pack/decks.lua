return function(context)
    local settings = context.settings
    local hooks = context.hooks
    local cartomancer = settings.cartomancer
    local icebound = settings.icebound
    local inferno = settings.inferno
    local small = settings.small

    local function register_back_atlas(key, path)
        SMODS.Atlas {
            key = key,
            path = path,
            px = 71,
            py = 95,
        }
    end

    register_back_atlas('back', 'cartomancer_back.png')
    register_back_atlas('icebound_back', 'icebound_back.png')
    register_back_atlas('small_back_lc', 'small_back_lc.png')
    register_back_atlas('small_back_hc', 'small_back_hc.png')
    register_back_atlas('inferno_back', 'inferno_back.png')

    SMODS.Back {
        key = 'deck',
        atlas = 'back',
        pos = { x = 0, y = 0 },
        unlocked = true,
        config = {},
        loc_vars = function()
            return { vars = {} }
        end,
        apply = function()
            G.GAME.modifiers = G.GAME.modifiers or {}
            G.GAME.modifiers.cartomancer_tarots = true
            G.GAME.joker_rate = cartomancer.shop_rates.joker
            G.GAME.tarot_rate = cartomancer.shop_rates.tarot
            G.GAME.planet_rate = cartomancer.shop_rates.planet
        end,
    }

    local function icebound_cashout()
        local hands_left = G
            and G.GAME
            and G.GAME.current_round
            and G.GAME.current_round.hands_left
            or 0
        local payout = math.floor(hands_left / icebound.hands_per_dollar)
            * icebound.dollars_per_group
        return hands_left, payout
    end

    SMODS.Back {
        key = 'icebound',
        atlas = 'icebound_back',
        pos = { x = 0, y = 0 },
        unlocked = true,
        config = {
            hands = 3,
            starting_discards = 0,
        },
        loc_vars = function(self)
            return {
                vars = {
                    self.config.hands,
                    self.config.starting_discards,
                    icebound.hands_per_dollar,
                    icebound.dollars_per_group,
                },
            }
        end,
        apply = function(self)
            -- Blue Stake is applied before the selected Back. Set the starting
            -- value explicitly so this deck always begins with zero discards.
            G.GAME.starting_params.discards = self.config.starting_discards
            G.GAME.modifiers = G.GAME.modifiers or {}
            G.GAME.modifiers.no_extra_hand_money = true
        end,
        calculate = function(_, _, context_args)
            if not context_args or context_args.context ~= 'eval' then return end

            local hands_left, payout = icebound_cashout()
            if payout <= 0 then return end

            add_round_eval_row {
                dollars = payout,
                bonus = true,
                name = 'custom_icebound_hands',
                pitch = 1,
                number = hands_left,
                number_colour = G.C.BLUE,
                number_scale = 0.8,
                text = localize('s1xlv_icebound_remaining_hands'),
                text_colour = G.C.UI.TEXT_LIGHT,
                text_scale = 0.4,
            }
        end,
        calc_dollar_bonus = function()
            local _, payout = icebound_cashout()
            if payout <= 0 then return end
            return payout, { no_eval_row = true }
        end,
    }

    local function remove_starting_joker_extras(card)
        if not card then return end

        if card.edition and card.set_edition then
            card:set_edition(nil, true, true)
        end

        -- Ask every registered Sticker to remove itself so third-party
        -- stickers can reverse their own slot or passive effects correctly.
        if SMODS and SMODS.Sticker and SMODS.Sticker.obj_buffer
            and card.remove_sticker then
            for _, sticker_key in ipairs(SMODS.Sticker.obj_buffer) do
                card:remove_sticker(sticker_key)
            end
        end

        -- Vanilla sticker flags may still be stored directly on ability by an
        -- older API or another constructor.
        if card.ability then
            card.ability.eternal = nil
            card.ability.perishable = nil
            card.ability.perish_tally = nil
            card.ability.rental = nil
        end
        card.pinned = nil

        if card.set_cost then card:set_cost() end
    end

    local function add_inferno_starting_jokers()
        for index, center_key in ipairs(inferno.starting_jokers) do
            local card = add_joker(center_key, nil, index ~= 1)
            remove_starting_joker_extras(card)
        end
    end

    local inferno_back = {
        key = 'inferno',
        atlas = 'inferno_back',
        pos = { x = 0, y = 0 },
        unlocked = true,
        config = {
            hand_size = inferno.hand_size_bonus,
            ante = inferno.ante_offset,
        },
        loc_vars = function(self)
            return {
                vars = {
                    self.config.hand_size,
                    self.config.ante,
                    localize { type = 'name_text', set = 'Joker', key = inferno.starting_jokers[1] },
                    localize { type = 'name_text', set = 'Joker', key = inferno.starting_jokers[2] },
                    localize { type = 'name_text', set = 'Joker', key = inferno.starting_jokers[3] },
                    localize { type = 'name_text', set = 'Joker', key = inferno.starting_jokers[4] },
                    inferno.first_hand_levels,
                },
            }
        end,
        apply = function(self)
            G.GAME.modifiers = G.GAME.modifiers or {}
            G.GAME.modifiers.inferno_deck = true

            local starting_ante = 1 + self.config.ante
            G.GAME.round_resets.ante = starting_ante
            G.GAME.round_resets.blind_ante = starting_ante
            G.GAME.win_ante = inferno.win_ante

            -- Vanilla consumes this before reading the first played hand's
            -- base Chips and Mult, so the opening hand receives the bonus.
            G.GAME.first_used_hand_level =
                (G.GAME.first_used_hand_level or 0) + inferno.first_hand_levels

            delay(0.4)
            G.E_MANAGER:add_event(Event {
                func = function()
                    add_inferno_starting_jokers()
                    return true
                end,
            })
        end,
    }

    local function add_small_starting_cards()
        local starting_params = G.GAME.starting_params
        local extra_cards = starting_params.extra_cards or {}

        for _, suit_key in ipairs(small.starting_suits) do
            for _, rank_key in ipairs(small.ranks) do
                local suit = SMODS.Suits[suit_key]
                local rank = SMODS.Ranks[rank_key]
                assert(suit and rank,
                    ('[S1XLV Deck Pack] Missing vanilla card data for %s of %s')
                        :format(tostring(rank_key), tostring(suit_key)))
                extra_cards[#extra_cards + 1] = {
                    s = suit.card_key,
                    r = rank.card_key,
                }
            end
        end

        starting_params.extra_cards = extra_cards
    end

    SMODS.Back {
        key = 'small',
        atlas = 'small_back_lc',
        lc_atlas = 'small_back_lc',
        hc_atlas = 'small_back_hc',
        pos = { x = 0, y = 0 },
        unlocked = true,
        config = {},
        -- Removing every rank from the default whitelist suppresses the
        -- vanilla 52-card deck; apply() supplies the intended 26 cards.
        initial_deck = {
            ranks = {},
        },
        loc_vars = function()
            return {
                vars = {
                    #small.ranks,
                },
            }
        end,
        apply = function(_, back)
            hooks.sync_back_contrast_atlases(back)
            G.GAME.modifiers = G.GAME.modifiers or {}
            G.GAME.modifiers.small_deck = true
            G.GAME.modifiers.small_recycle_played_cards = small.recycle_played_cards
            G.GAME.modifiers.small_recycle_discarded_cards = small.recycle_discarded_cards
            G.GAME.small_pending_discard_ids = nil
            add_small_starting_cards()
        end,
    }

    SMODS.Back(inferno_back)
end
