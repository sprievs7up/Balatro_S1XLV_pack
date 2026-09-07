return function(context)
    local hooks = context.hooks
    local is_grandmaster_run = context.is_grandmaster_run
    hooks.grandmaster_showdown_interval =
        context.settings.grandmaster.showdown_interval

    -- Vanilla selects Showdown Bosses at multiples of G.GAME.win_ante. Grand
    -- Master still wins at Ante 12, but uses a separate four-Ante Showdown
    -- cadence. Expose that cadence only while the original selector runs so
    -- victory checks and every other consumer continue to see the true value.
    if type(get_new_boss) == 'function'
        and not hooks.originals.master_get_new_boss then
        hooks.originals.master_get_new_boss = get_new_boss
        function get_new_boss(...)
            if not (is_grandmaster_run() and G and G.GAME) then
                return hooks.originals.master_get_new_boss(...)
            end

            local true_win_ante = G.GAME.win_ante
            G.GAME.win_ante = hooks.grandmaster_showdown_interval
            local results = {
                pcall(hooks.originals.master_get_new_boss, ...)
            }
            G.GAME.win_ante = true_win_ante

            if not results[1] then error(results[2], 0) end
            return unpack(results, 2)
        end
    end

    local function center_key(card)
        return card
            and card.config
            and (card.config.center_key
                or (card.config.center and card.config.center.key))
    end

    local function is_joker(card)
        return card
            and card.ability
            and card.ability.set == 'Joker'
    end

    local function standard_joker_area()
        return hooks.master_real_joker_area or (G and G.jokers)
    end

    local function consumable_area()
        return G and G.consumeables
    end

    local function slot_usage(card)
        return 1 + ((card and card.ability
            and card.ability.extra_slots_used) or 0)
    end

    local function slot_gain(card)
        return (card and card.ability and card.ability.card_limit) or 0
    end

    local function area_slot_state(area, ignored_card)
        if not (area and area.cards and area.config) then return 0, 0 end

        local used = 0
        local card_gains = 0
        for _, card in ipairs(area.cards) do
            if card ~= ignored_card then
                used = used + slot_usage(card)
                card_gains = card_gains + slot_gain(card)
            end
        end

        local limits = area.config.card_limits
        if limits then
            local total = (limits.base or 0) + (limits.mod or 0) + card_gains
            return used, total
        end

        -- Fallback for an older CardArea implementation without Steamodded's
        -- card_limits table. Such builds do not support extra slot bodies, but
        -- the simple count remains safe for ordinary and Negative cards.
        local total = area.config.card_limit or 0
        if ignored_card then total = total - slot_gain(ignored_card) end
        return used, total
    end

    local function area_can_accept(area, card, ignored_card)
        local used, total = area_slot_state(area, ignored_card)
        return used + slot_usage(card) <= total + slot_gain(card)
    end

    local function normal_slots_available(area, ignored_card)
        local used, total = area_slot_state(area, ignored_card)
        return math.max(0, total - used)
    end

    local function joker_destination(card, ignored_consumable)
        local jokers = standard_joker_area()
        if area_can_accept(jokers, card) then return jokers end

        local consumeables = consumable_area()
        if area_can_accept(consumeables, card, ignored_consumable) then
            return consumeables
        end
    end

    local function combined_jokers()
        local cards = {}
        local seen = {}
        local areas = { standard_joker_area(), consumable_area() }
        for _, area in ipairs(areas) do
            for _, card in ipairs((area and area.cards) or {}) do
                if is_joker(card) and not seen[card] then
                    seen[card] = true
                    cards[#cards + 1] = card
                end
            end
        end
        return cards
    end

    local function stored_consumables()
        local cards = {}
        for _, card in ipairs((consumable_area()
            and consumable_area().cards) or {}) do
            if card.ability and card.ability.consumeable then
                cards[#cards + 1] = card
            end
        end
        return cards
    end

    local function area_proxy(area, cards, card_limit)
        local config = area and area.config or {}
        if card_limit ~= nil then
            config = setmetatable({ card_limit = card_limit }, { __index = config })
        end
        return setmetatable({
            cards = cards or (area and area.cards) or {},
            config = config,
        }, { __index = area })
    end

    local function with_joker_area(area, callback)
        if not (G and area) then return callback() end

        local previous_area = G.jokers
        local previous_real_area = hooks.master_real_joker_area
        hooks.master_real_joker_area = previous_real_area or previous_area
        G.jokers = area

        local ok, first, second, third, fourth = pcall(callback)
        G.jokers = previous_area
        hooks.master_real_joker_area = previous_real_area

        if not ok then error(first, 0) end
        return first, second, third, fourth
    end

    local function joker_only_area_proxy(area)
        if not area then return end

        local cards = {}
        for _, card in ipairs(area.cards or {}) do
            if is_joker(card) then cards[#cards + 1] = card end
        end
        return area_proxy(area, cards)
    end

    local function combined_joker_proxy()
        local area = standard_joker_area()
        return area and area_proxy(area, combined_jokers())
    end

    local function riff_raff_proxy()
        local jokers = standard_joker_area()
        local consumeables = consumable_area()
        if not (jokers and consumeables) then return end

        local extra_slots = normal_slots_available(consumeables)
        if extra_slots <= 0 then return end
        return area_proxy(
            jokers,
            jokers.cards,
            (jokers.config.card_limit or #jokers.cards) + extra_slots
        )
    end

    local function spawned_joker_placeholder()
        return {
            ability = {
                card_limit = 0,
                extra_slots_used = 0,
                set = 'Joker',
            },
        }
    end

    local function invisible_copy(self, context_args)
        local candidates = {}
        for _, card in ipairs(combined_jokers()) do
            if card ~= self then candidates[#candidates + 1] = card end
        end

        if #candidates == 0 then
            card_eval_status_text(
                context_args.blueprint_card or self,
                'extra', nil, nil, nil,
                { message = localize('k_no_other_jokers') }
            )
            return
        end

        local destination = self.area
        if destination ~= standard_joker_area()
            and destination ~= consumable_area() then
            destination = standard_joker_area()
        end

        card_eval_status_text(
            context_args.blueprint_card or self,
            'extra', nil, nil, nil,
            { message = localize('k_duplicated_ex') }
        )

        local chosen_joker = pseudorandom_element(
            candidates,
            pseudoseed('invisible')
        )
        local bulky_state = rawget(_G, 'BSK_BULKY_STAKES')
        if bulky_state then
            bulky_state.invisible_copy_source = self
            bulky_state.invisible_copy_area = destination
        end

        local ok, card_or_error = pcall(
            copy_card,
            chosen_joker,
            nil,
            nil,
            nil,
            chosen_joker.edition and chosen_joker.edition.negative
        )

        if bulky_state then
            bulky_state.invisible_copy_source = nil
            bulky_state.invisible_copy_area = nil
        end
        if not ok then error(card_or_error, 0) end

        local card = card_or_error
        if card.ability.invis_rounds then card.ability.invis_rounds = 0 end
        card:add_to_deck()

        -- Bypass the ordinary overflow router: Invisible Joker copies remain
        -- in the area occupied by the sold Invisible Joker. Bulky Stakes has
        -- already planned any required squeeze in that same area.
        hooks.originals.master_cardarea_emplace(destination, card)
    end

    local function perkeo_copy(self, context_args)
        local candidates = stored_consumables()
        if #candidates == 0 then return end

        G.E_MANAGER:add_event(Event({
            func = function()
                local card = copy_card(
                    pseudorandom_element(candidates, pseudoseed('perkeo')),
                    nil
                )
                card:set_edition({ negative = true }, true)
                card:add_to_deck()
                consumable_area():emplace(card)
                return true
            end,
        }))
        card_eval_status_text(
            context_args.blueprint_card or self,
            'extra', nil, nil, nil,
            { message = localize('k_duplicated_ex') }
        )
        return nil, true
    end

    hooks.master_area_can_accept = area_can_accept
    hooks.master_combined_jokers = combined_jokers

    local function install_combined_joker_history_hook(
        function_name,
        original_key
    )
        local current = rawget(_G, function_name)
        if type(current) ~= 'function' or hooks.originals[original_key] then
            return
        end

        hooks.originals[original_key] = current
        rawset(_G, function_name, function(...)
            local args = { ... }
            if is_grandmaster_run() then
                local proxy = combined_joker_proxy()
                if proxy then
                    return with_joker_area(proxy, function()
                        return hooks.originals[original_key](unpack(args))
                    end)
                end
            end
            return hooks.originals[original_key](unpack(args))
        end)
    end

    install_combined_joker_history_hook(
        'set_joker_usage',
        'master_set_joker_usage'
    )
    install_combined_joker_history_hook(
        'set_joker_win',
        'master_set_joker_win'
    )
    install_combined_joker_history_hook(
        'set_joker_loss',
        'master_set_joker_loss'
    )

    if G and G.FUNCS and G.FUNCS.check_for_buy_space
        and not hooks.originals.master_check_for_buy_space then
        hooks.originals.master_check_for_buy_space = G.FUNCS.check_for_buy_space
        G.FUNCS.check_for_buy_space = function(card)
            if is_grandmaster_run() and is_joker(card)
                and joker_destination(card) then
                return true
            end
            return hooks.originals.master_check_for_buy_space(card)
        end
    end

    if CardArea and CardArea.emplace
        and not hooks.originals.master_cardarea_emplace then
        hooks.originals.master_cardarea_emplace = CardArea.emplace
        function CardArea:emplace(card, location, stay_flipped)
            local jokers = standard_joker_area()
            local consumeables = consumable_area()
            if is_grandmaster_run()
                and self == jokers
                and is_joker(card)
                and not area_can_accept(jokers, card)
                and area_can_accept(consumeables, card) then
                return hooks.originals.master_cardarea_emplace(
                    consumeables,
                    card,
                    location,
                    stay_flipped
                )
            end
            return hooks.originals.master_cardarea_emplace(
                self,
                card,
                location,
                stay_flipped
            )
        end
    end

    if G and G.FUNCS and G.FUNCS.can_select_card
        and not hooks.originals.master_can_select_card then
        hooks.originals.master_can_select_card = G.FUNCS.can_select_card
        G.FUNCS.can_select_card = function(e)
            hooks.originals.master_can_select_card(e)
            local card = e and e.config and e.config.ref_table
            if is_grandmaster_run() and is_joker(card)
                and area_can_accept(consumable_area(), card) then
                e.config.colour = G.C.GREEN
                e.config.button = 'use_card'
            end
        end
    end

    if G and G.FUNCS and G.FUNCS.can_select_from_booster
        and not hooks.originals.master_can_select_from_booster then
        hooks.originals.master_can_select_from_booster =
            G.FUNCS.can_select_from_booster
        G.FUNCS.can_select_from_booster = function(e)
            hooks.originals.master_can_select_from_booster(e)
            local card = e and e.config and e.config.ref_table
            local select_area = booster_obj
                and card
                and card.selectable_from_pack
                and card:selectable_from_pack(booster_obj)
            if is_grandmaster_run()
                and is_joker(card)
                and select_area
                and area_can_accept(consumable_area(), card) then
                e.config.colour = G.C.GREEN
                e.config.button = 'use_card'
            end
        end
    end

    if Card and Card.can_use_consumeable
        and not hooks.originals.master_can_use_consumeable then
        hooks.originals.master_can_use_consumeable = Card.can_use_consumeable
        function Card:can_use_consumeable(any_state, skip_check)
            local spawn_keys = {
                c_judgement = true,
                c_soul = true,
                c_wraith = true,
            }
            local key = center_key(self)
            local placeholder = spawned_joker_placeholder()
            local ignored = self.area == consumable_area() and self or nil
            if is_grandmaster_run()
                and spawn_keys[key]
                and not area_can_accept(standard_joker_area(), placeholder)
                and area_can_accept(consumable_area(), placeholder, ignored) then
                local jokers = standard_joker_area()
                local proxy = area_proxy(
                    jokers,
                    jokers.cards,
                    (jokers.config.card_limit or #jokers.cards) + 1
                )
                return with_joker_area(proxy, function()
                    return hooks.originals.master_can_use_consumeable(
                        self,
                        any_state,
                        skip_check
                    )
                end)
            end
            return hooks.originals.master_can_use_consumeable(
                self,
                any_state,
                skip_check
            )
        end
    end

    if Card and Card.stop_drag
        and not hooks.originals.master_card_stop_drag then
        hooks.originals.master_card_stop_drag = Card.stop_drag
        function Card:stop_drag()
            local source = self.area
            local point = G
                and G.CONTROLLER
                and G.CONTROLLER.cursor_up
                and G.CONTROLLER.cursor_up.T
            local point_x = point and point.x
                or (self.T.x + self.T.w / 2)
            local point_y = point and point.y
                or (self.T.y + self.T.h / 2)

            local result = hooks.originals.master_card_stop_drag(self)
            if not (is_grandmaster_run() and is_joker(self)) then return result end

            local jokers = standard_joker_area()
            local consumeables = consumable_area()
            if source ~= jokers and source ~= consumeables then return result end

            local destination = source == jokers and consumeables or jokers
            local inside = destination
                and point_x >= destination.T.x
                and point_x <= destination.T.x + destination.T.w
                and point_y >= destination.T.y
                and point_y <= destination.T.y + destination.T.h
            if inside and area_can_accept(destination, self) then
                source:remove_card(self)
                destination:emplace(self)
                play_sound('cardSlide1')
            end
            return result
        end
    end

    if Card and Card.generate_UIBox_ability_table
        and not hooks.originals.master_generate_ability_ui then
        hooks.originals.master_generate_ability_ui =
            Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table()
            if not is_grandmaster_run() then
                return hooks.originals.master_generate_ability_ui(self)
            end

            local key = center_key(self)
            if key == 'j_abstract' then
                return with_joker_area(combined_joker_proxy(), function()
                    return hooks.originals.master_generate_ability_ui(self)
                end)
            end
            if self.area == consumable_area()
                and (key == 'j_blueprint' or key == 'j_brainstorm') then
                return with_joker_area(consumable_area(), function()
                    return hooks.originals.master_generate_ability_ui(self)
                end)
            end
            return hooks.originals.master_generate_ability_ui(self)
        end
    end

    if Card and Card.update and not hooks.originals.master_card_update then
        hooks.originals.master_card_update = Card.update
        function Card:update(dt)
            if not is_grandmaster_run() then
                return hooks.originals.master_card_update(self, dt)
            end

            local key = center_key(self)
            local result
            if self.area == consumable_area()
                and (key == 'j_blueprint'
                    or key == 'j_brainstorm'
                    or key == 'j_stencil') then
                result = with_joker_area(consumable_area(), function()
                    return hooks.originals.master_card_update(self, dt)
                end)
            else
                result = hooks.originals.master_card_update(self, dt)
            end

            if key == 'j_swashbuckler' and self.ability then
                local sell_cost = 0
                for _, joker in ipairs(combined_jokers()) do
                    if joker ~= self then
                        sell_cost = sell_cost + (joker.sell_cost or 0)
                    end
                end
                self.ability.mult = sell_cost
            end
            return result
        end
    end

    if Card and Card.calculate_joker
        and not hooks.originals.master_card_calculate_joker then
        hooks.originals.master_card_calculate_joker = Card.calculate_joker
        function Card:calculate_joker(context_args, ...)
            if not is_grandmaster_run() then
                return hooks.originals.master_card_calculate_joker(
                    self,
                    context_args,
                    ...
                )
            end

            context_args = context_args or {}
            local key = center_key(self)
            local extra_args = { ... }

            if key == 'j_invisible'
                and context_args.selling_self
                and not context_args.blueprint
                and self.ability.invis_rounds >= self.ability.extra then
                local original_name = self.ability.name
                self.ability.name = 'SIXLV Grand Master Invisible'
                local ok, first, second = pcall(
                    hooks.originals.master_card_calculate_joker,
                    self,
                    context_args,
                    unpack(extra_args)
                )
                self.ability.name = original_name
                if not ok then error(first, 0) end
                invisible_copy(self, context_args)
                return first, second
            end

            if key == 'j_perkeo' and context_args.ending_shop then
                return perkeo_copy(self, context_args)
            end

            if key == 'j_abstract' then
                return with_joker_area(combined_joker_proxy(), function()
                    return hooks.originals.master_card_calculate_joker(
                        self,
                        context_args,
                        unpack(extra_args)
                    )
                end)
            end

            if key == 'j_riff_raff' then
                local proxy = riff_raff_proxy()
                if proxy then
                    return with_joker_area(proxy, function()
                        return hooks.originals.master_card_calculate_joker(
                            self,
                            context_args,
                            unpack(extra_args)
                        )
                    end)
                end
            end

            if self.area == consumable_area() and key == 'j_madness' then
                -- Vanilla assumes every card in G.jokers is a Joker. The
                -- shared consumable area breaks that assumption, so expose
                -- only same-area Jokers while Madness selects its victim.
                return with_joker_area(
                    joker_only_area_proxy(consumable_area()),
                    function()
                        return hooks.originals.master_card_calculate_joker(
                            self,
                            context_args,
                            unpack(extra_args)
                        )
                    end
                )
            end

            local same_area_keys = {
                j_blueprint = true,
                j_brainstorm = true,
                j_ceremonial = true,
                j_stencil = true,
            }
            if self.area == consumable_area() and same_area_keys[key] then
                return with_joker_area(consumable_area(), function()
                    return hooks.originals.master_card_calculate_joker(
                        self,
                        context_args,
                        unpack(extra_args)
                    )
                end)
            end

            return hooks.originals.master_card_calculate_joker(
                self,
                context_args,
                unpack(extra_args)
            )
        end
    end
end
