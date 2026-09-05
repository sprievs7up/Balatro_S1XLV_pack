return function(context)
    local hooks = context.hooks
    local cartomancer = context.settings.cartomancer
    local tarot = context.settings.tarot
    local is_cartomancer_run = context.is_cartomancer_run

    -- Hook: Card:set_ability
    -- Tarot config tables are shared by default. Copy the instance config before
    -- applying Cartomancer values so collection cards and other decks retain
    -- their original numbers.
    if not hooks.originals.card_set_ability then
        hooks.originals.card_set_ability = Card.set_ability
        function Card:set_ability(center, initial, delay_sprites)
            local result = hooks.originals.card_set_ability(
                self,
                center,
                initial,
                delay_sprites
            )
            local applied_center = (self.config and self.config.center) or center
            local key = hooks.current_center_key(self, applied_center)

            if hooks.is_cartomancer_run()
                and applied_center
                and applied_center.set == 'Tarot'
                and self.ability
                and self.ability.consumeable then
                self.ability.consumeable = copy_table(self.ability.consumeable)

                local max_highlighted = hooks.enhanced_max_highlighted[key]
                if max_highlighted then
                    self.ability.consumeable.max_highlighted = max_highlighted
                    self.ability.consumeable.mod_num = max_highlighted
                end

                local extra = hooks.enhanced_extra[key]
                if extra then
                    self.ability.extra = extra
                    self.ability.consumeable.extra = extra
                end

                if key == 'c_judgement' then
                    self.base_cost = hooks.judgement_base_cost
                end
            end

            return result
        end
    end

    -- Hook: SMODS.add_to_pool
    -- Remove Planet cards, Celestial packs, Black Hole, Trance, Meteor Tags, and
    -- Planet-focused vouchers only while the Cartomancer Deck is active.
    if not hooks.originals.add_to_pool then
        hooks.originals.add_to_pool = SMODS.add_to_pool
        function SMODS.add_to_pool(prototype, args)
            if hooks.is_cartomancer_run()
                and hooks.is_blocked_planet_source(prototype) then
                return false
            end
            return hooks.originals.add_to_pool(prototype, args)
        end
    end

    local function multiplied_weight_getter(original_get_weight, multiplier)
        return function(self, ...)
            return (original_get_weight(self, ...) or 0) * multiplier
        end
    end

    -- Hook: get_pack
    -- Standard and Spectral packs use prototype weights rather than shop card
    -- rates. Temporarily multiply those weights for one Cartomancer pack roll,
    -- then restore every prototype even when the upstream function errors.
    if not hooks.originals.get_pack then
        hooks.originals.get_pack = get_pack
        function get_pack(_key, _type)
            local booster_pool = G
                and G.P_CENTER_POOLS
                and G.P_CENTER_POOLS.Booster

            if not hooks.is_cartomancer_run() or not booster_pool then
                return hooks.originals.get_pack(_key, _type)
            end

            local changed_weights = {}
            for _, booster in ipairs(booster_pool) do
                local multiplier = hooks.booster_weight_multipliers[booster.kind]
                if multiplier then
                    changed_weights[#changed_weights + 1] = {
                        booster = booster,
                        weight = booster.weight,
                        get_weight = booster.get_weight,
                    }
                    if booster.get_weight then
                        booster.get_weight = multiplied_weight_getter(
                            booster.get_weight,
                            multiplier
                        )
                    else
                        booster.weight = (booster.weight or 1) * multiplier
                    end
                end
            end

            local ok, pack_or_error = pcall(hooks.originals.get_pack, _key, _type)

            for _, changed in ipairs(changed_weights) do
                changed.booster.weight = changed.weight
                changed.booster.get_weight = changed.get_weight
            end

            if not ok then error(pack_or_error, 0) end
            return pack_or_error
        end
    end

    -- Hook: Card:apply_to_run
    -- Planet Merchant and Planet Tycoon normally raise the shop Planet rate.
    -- Ignore that effect in a Cartomancer run, including forced voucher grants,
    -- while preserving the original voucher path for every other card and deck.
    if not hooks.originals.card_apply_to_run then
        hooks.originals.card_apply_to_run = Card.apply_to_run
        function Card:apply_to_run(center)
            local key = hooks.current_center_key(self, center)
            if hooks.is_cartomancer_run() and hooks.planet_vouchers[key] then
                G.GAME.planet_rate = 0
                return
            end

            local result = hooks.originals.card_apply_to_run(self, center)
            if hooks.is_cartomancer_run() then G.GAME.planet_rate = 0 end
            return result
        end
    end

    -- Hook: SMODS.poll_seal
    -- Natural seal rolls cannot select Blue in a Cartomancer run. Card:set_seal
    -- remains untouched, so an explicitly created Blue Seal still functions.
    if not hooks.originals.poll_seal then
        hooks.originals.poll_seal = SMODS.poll_seal
        function SMODS.poll_seal(args)
            if not hooks.is_cartomancer_run() then
                return hooks.originals.poll_seal(args)
            end

            local blue_seal = G and G.P_SEALS and G.P_SEALS.Blue
            if not blue_seal then return hooks.originals.poll_seal(args) end

            local original_weight = blue_seal.weight
            local original_get_weight = blue_seal.get_weight
            blue_seal.weight = 0
            blue_seal.get_weight = function() return 0 end

            local ok, seal_or_error = pcall(hooks.originals.poll_seal, args or {})

            blue_seal.weight = original_weight
            blue_seal.get_weight = original_get_weight

            if not ok then error(seal_or_error, 0) end
            return seal_or_error
        end
    end

    -- Hook: create_card_for_shop
    -- Illusion applies a seal directly after normal generation and therefore
    -- bypasses SMODS.poll_seal. Replace only a naturally rolled Blue Seal on a
    -- shop playing card, choosing Red, Gold, or Purple with equal weight.
    if not hooks.originals.create_card_for_shop then
        hooks.originals.create_card_for_shop = create_card_for_shop
        function create_card_for_shop(area)
            local card = hooks.originals.create_card_for_shop(area)
            local ability_set = card and card.ability and card.ability.set
            local is_shop_playing_card =
                ability_set == 'Default' or ability_set == 'Enhanced'
            local illusion_active = G
                and G.GAME
                and G.GAME.used_vouchers
                and G.GAME.used_vouchers.v_illusion

            if hooks.is_cartomancer_run()
                and illusion_active
                and is_shop_playing_card
                and card.seal == 'Blue' then
                local ante = G.GAME.round_resets
                    and G.GAME.round_resets.ante
                    or 0
                local replacement = pseudorandom_element(
                    cartomancer.certificate_seals,
                    pseudoseed('cartomancer_illusion_seal' .. ante)
                )
                card:set_seal(replacement, true, true)
            end

            return card
        end
    end

    -- Hook: create_card
    -- Vanilla may choose Black Hole internally after the normal pool filter.
    -- Apply a temporary ban only to unforced, soulable Planet/Spectral rolls.
    -- A forced key remains an explicit request and is intentionally respected.
    if not hooks.originals.create_card then
        hooks.originals.create_card = create_card
        function create_card(
            _type,
            area,
            legendary,
            _rarity,
            skip_materialize,
            soulable,
            forced_key,
            key_append
        )
            local should_filter_black_hole = hooks.is_cartomancer_run()
                and soulable
                and not forced_key
                and (_type == 'Planet' or _type == 'Spectral')

            if not should_filter_black_hole then
                return hooks.originals.create_card(
                    _type,
                    area,
                    legendary,
                    _rarity,
                    skip_materialize,
                    soulable,
                    forced_key,
                    key_append
                )
            end

            G.GAME.banned_keys = G.GAME.banned_keys or {}
            local previous_ban = G.GAME.banned_keys[hooks.black_hole_key]
            G.GAME.banned_keys[hooks.black_hole_key] = true

            local ok, card_or_error = pcall(
                hooks.originals.create_card,
                _type,
                area,
                legendary,
                _rarity,
                skip_materialize,
                soulable,
                forced_key,
                key_append
            )

            G.GAME.banned_keys[hooks.black_hole_key] = previous_ban

            if not ok then error(card_or_error, 0) end
            return card_or_error
        end
    end

    -- Ownership proxy: Certificate
    -- Certificate performs its own four-seal roll instead of using poll_seal.
    -- In Cartomancer runs, reproduce the vanilla event with a three-seal pool;
    -- elsewhere delegate to the implementation captured before ownership.
    if not hooks.certificate_original_captured then
        hooks.certificate_original_calculate =
            G.P_CENTERS.j_certificate.calculate
        hooks.certificate_original_captured = true
    end

    local certificate = SMODS.Joker:take_ownership('certificate', {
        calculate = function(self, card, context)
            if not is_cartomancer_run() then
                local original = hooks.certificate_original_calculate
                if original then return original(self, card, context) end
                return
            end
            if not context.first_hand_drawn then return end

            G.E_MANAGER:add_event(Event {
                func = function()
                    local generated_card = create_playing_card({
                        front = pseudorandom_element(
                            G.P_CARDS,
                            pseudoseed('cert_fr')
                        ),
                        center = G.P_CENTERS.c_base,
                    }, G.hand, nil, nil, { G.C.SECONDARY_SET.Enhanced })

                    local seal = pseudorandom_element(
                        cartomancer.certificate_seals,
                        pseudoseed('certsl')
                    )
                    generated_card:set_seal(seal, nil, true)
                    G.GAME.blind:debuff_card(generated_card)
                    G.hand:sort()

                    if context.blueprint_card then
                        context.blueprint_card:juice_up()
                    else
                        card:juice_up()
                    end
                    playing_card_joker_effects({ generated_card })
                    save_run()
                    return true
                end,
            })

            return nil, true
        end,
    }, true)
    assert(certificate,
        '[S1XLV Deck Pack] Could not take ownership of j_certificate')

    -- Ownership proxy: Tarot cards
    -- Each method checks the active deck before using the Cartomancer branch.
    -- Earlier explicit overrides are preserved with rawget; when no override
    -- exists, the supplied method also contains the vanilla fallback.
    local function take_tarot(key, definition)
        local center_key = 'c_' .. key
        local originals = hooks.tarot_originals[center_key]
        if not originals then
            originals = {}
            local current = G.P_CENTERS[center_key]
            for field, value in pairs(definition) do
                if type(value) == 'function' then
                    originals[field] = current and rawget(current, field)
                end
            end
            hooks.tarot_originals[center_key] = originals
        end

        local scoped_definition = {}
        for field, value in pairs(definition) do
            if type(value) == 'function' then
                local cartomancer_function = value
                local original_function = originals[field]
                scoped_definition[field] = function(self, ...)
                    if hooks.is_cartomancer_run() then
                        return cartomancer_function(self, ...)
                    end
                    if original_function then
                        return original_function(self, ...)
                    end
                    return cartomancer_function(self, ...)
                end
            else
                scoped_definition[field] = value
            end
        end

        local owned = SMODS.Consumable:take_ownership(
            key,
            scoped_definition,
            true
        )
        assert(owned,
            ('[S1XLV Deck Pack] Could not take ownership of c_%s'):format(key))
        return owned
    end

    local function displayed_max(self, card)
        local key = self.key
        if is_cartomancer_run() and tarot.enhanced_max_highlighted[key] then
            return tarot.enhanced_max_highlighted[key]
        end

        local ability = card and card.ability
        if ability and ability.max_highlighted ~= nil then
            return ability.max_highlighted
        end
        if ability and ability.consumeable
            and ability.consumeable.max_highlighted ~= nil then
            return ability.consumeable.max_highlighted
        end

        local registered_center = G and G.P_CENTERS and G.P_CENTERS[key]
        if registered_center and registered_center.config
            and registered_center.config.max_highlighted ~= nil then
            return registered_center.config.max_highlighted
        end
        if self.config and self.config.max_highlighted ~= nil then
            return self.config.max_highlighted
        end
        return tarot.vanilla_max_highlighted[key]
    end

    local function displayed_extra(self)
        if is_cartomancer_run() and tarot.enhanced_extra[self.key] then
            return tarot.enhanced_extra[self.key]
        end
        return self.config.extra
    end

    local function enhancement_loc_vars(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[self.config.mod_conv]
        return {
            vars = {
                displayed_max(self, card),
                localize {
                    type = 'name_text',
                    set = 'Enhanced',
                    key = self.config.mod_conv,
                },
            },
        }
    end

    for _, key in ipairs {
        'magician',
        'empress',
        'heirophant',
        'lovers',
        'chariot',
        'justice',
        'devil',
        'tower',
    } do
        take_tarot(key, { loc_vars = enhancement_loc_vars })
    end

    local function highlighted_count_loc_vars(self, info_queue, card)
        return { vars = { displayed_max(self, card) } }
    end

    take_tarot('strength', { loc_vars = highlighted_count_loc_vars })
    take_tarot('hanged_man', { loc_vars = highlighted_count_loc_vars })
    take_tarot('hermit', {
        loc_vars = function(self, info_queue, card)
            return { vars = { displayed_extra(self, card) } }
        end,
    })

    take_tarot('wheel_of_fortune', {
        loc_vars = function(self, info_queue, card)
            info_queue[#info_queue + 1] = G.P_CENTERS.e_foil
            info_queue[#info_queue + 1] = G.P_CENTERS.e_holo
            info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
            return {
                vars = {
                    G.GAME.probabilities.normal,
                    displayed_extra(self, card),
                },
            }
        end,
    })

    take_tarot('temperance', {
        loc_vars = function(self, info_queue, card)
            local cap = displayed_extra(self, card)
            local payout = 0
            if G.jokers and G.jokers.cards then
                for _, joker in ipairs(G.jokers.cards) do
                    if joker.ability.set == 'Joker' then
                        payout = payout + joker.sell_cost
                    end
                end
            end
            return { vars = { cap, math.min(cap, payout) } }
        end,
    })

    local function suit_loc_vars(self, info_queue, card)
        return {
            vars = {
                displayed_max(self, card),
                localize(self.config.suit_conv, 'suits_plural'),
                colours = { G.C.SUITS[self.config.suit_conv] },
            },
        }
    end

    for _, key in ipairs { 'star', 'moon', 'sun', 'world' } do
        take_tarot(key, { loc_vars = suit_loc_vars })
    end

    local function can_level_last_hand()
        local hand = G and G.GAME and G.GAME.last_hand_played
        return hand ~= nil and G.GAME.hands and G.GAME.hands[hand] ~= nil
    end

    take_tarot('high_priestess', {
        loc_vars = function(self)
            if is_cartomancer_run() then
                return {
                    key = 'c_cartomancer_high_priestess',
                    vars = { 2 },
                }
            end
            return { vars = { self.config.planets } }
        end,
        can_use = function(self, card)
            if is_cartomancer_run() then return can_level_last_hand() end
            return G.consumeables
                and (
                    #G.consumeables.cards < G.consumeables.config.card_limit
                    or card.area == G.consumeables
                )
        end,
        use = function(self, card)
            if is_cartomancer_run() then
                local hand = G.GAME.last_hand_played
                if not can_level_last_hand() then return end
                SMODS.smart_level_up_hand(card, hand, nil, 2)
                return
            end

            local planet_count =
                card.ability.consumeable.planets or self.config.planets
            local count = math.min(
                planet_count,
                G.consumeables.config.card_limit - #G.consumeables.cards
            )
            for _ = 1, count do
                G.E_MANAGER:add_event(Event {
                    trigger = 'after',
                    delay = 0.4,
                    func = function()
                        if G.consumeables.config.card_limit
                            > #G.consumeables.cards then
                            play_sound('timpani')
                            local planet = create_card(
                                'Planet',
                                G.consumeables,
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                'pri'
                            )
                            planet:add_to_deck()
                            G.consumeables:emplace(planet)
                            card:juice_up(0.3, 0.5)
                        end
                        return true
                    end,
                })
            end
            delay(0.6)
        end,
    })

    local function available_joker_slots()
        if not (
            G
            and G.GAME
            and G.jokers
            and G.jokers.cards
            and G.jokers.config
        ) then
            return 0
        end
        local occupied = #G.jokers.cards + (G.GAME.joker_buffer or 0)
        return math.max(0, G.jokers.config.card_limit - occupied)
    end

    take_tarot('judgement', {
        loc_vars = function()
            if is_cartomancer_run() then
                return {
                    key = 'c_cartomancer_judgement',
                    vars = { 2 },
                }
            end
            return { vars = {} }
        end,
        can_use = function(self, card)
            if is_cartomancer_run() then return available_joker_slots() > 0 end
            return G.jokers
                and (
                    #G.jokers.cards < G.jokers.config.card_limit
                    or card.area == G.jokers
                )
        end,
        use = function(self, card)
            if not is_cartomancer_run() then
                G.E_MANAGER:add_event(Event {
                    trigger = 'after',
                    delay = 0.4,
                    func = function()
                        play_sound('timpani')
                        local joker = create_card(
                            'Joker',
                            G.jokers,
                            nil,
                            nil,
                            nil,
                            nil,
                            nil,
                            'jud'
                        )
                        joker:add_to_deck()
                        G.jokers:emplace(joker)
                        card:juice_up(0.3, 0.5)
                        return true
                    end,
                })
                delay(0.6)
                return
            end

            local count = math.min(2, available_joker_slots())
            if count <= 0 then return end

            -- Reserve the delayed creations now so simultaneous effects cannot
            -- overfill the Joker area in the one-slot or two-slot cases.
            G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + count
            G.E_MANAGER:add_event(Event {
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('timpani')
                    for _ = 1, count do
                        if #G.jokers.cards < G.jokers.config.card_limit then
                            local joker = create_card(
                                'Joker',
                                G.jokers,
                                nil,
                                nil,
                                nil,
                                nil,
                                nil,
                                'jud'
                            )
                            joker:add_to_deck()
                            G.jokers:emplace(joker)
                            joker:start_materialize()
                        end
                    end
                    G.GAME.joker_buffer = math.max(
                        0,
                        (G.GAME.joker_buffer or count) - count
                    )
                    card:juice_up(0.3, 0.5)
                    return true
                end,
            })
            delay(0.6)
        end,
    })
end
