return function(context)
    local hooks = context.hooks
    local blank = context.settings.blank
    local is_blank_run = context.is_blank_run

    -- Give Blank Deck the same playing-card shop rate as Magic Trick without
    -- marking either voucher as redeemed. Steamodded consequently creates Base
    -- cards until Magic Trick or Illusion is actually owned; Illusion retains
    -- its normal enhancement, edition, and seal behaviour afterwards.
    local function apply_blank_run_rules()
        if not is_blank_run() or not G or not G.GAME then return end

        G.GAME.playing_card_rate = math.max(
            tonumber(G.GAME.playing_card_rate) or 0,
            blank.playing_card_rate
        )

        -- Blank Deck uses its explicit pack-kind distribution from the first
        -- shop, so bypass the vanilla guaranteed first Buffoon Pack.
        G.GAME.first_shop_buffoon = true
    end
    hooks.apply_blank_run_rules = apply_blank_run_rules

    -- Steamodded only provides destroying_card for cards in scoring_hand and
    -- sets cardarea to G.play. Debuffed cards do not score, so they survive.
    local function blank_should_destroy_scoring_card(context_args)
        local card = context_args and context_args.destroying_card
        return card ~= nil
            and not card.debuff
            and G ~= nil
            and G.play ~= nil
            and context_args.cardarea == G.play
    end
    hooks.blank_should_destroy_scoring_card = blank_should_destroy_scoring_card

    local function is_blank_standard_pack(card)
        local center = card and card.config and card.config.center
        return hooks.is_blank_run()
            and center ~= nil
            and center.set == 'Booster'
            and center.kind == 'Standard'
    end
    hooks.is_blank_standard_pack = is_blank_standard_pack

    local function blank_standard_pack_discount(original_discount)
        local discount = tonumber(original_discount) or 0
        if discount < blank.standard_pack_discount_cap then
            discount = math.min(
                blank.standard_pack_discount_cap,
                discount + blank.standard_pack_discount_step
            )
        end
        return discount
    end
    hooks.blank_standard_pack_discount = blank_standard_pack_discount

    -- Hook: Card:set_cost
    -- Standard Packs in Blank Deck shops are always priced one vanilla discount
    -- tier ahead, capped at Liquidation's 50%. Temporarily changing the shared
    -- value lets the full upstream price calculation retain inflation, tutorial,
    -- coupon, and compatibility behaviour, then restores it immediately.
    if Card and Card.set_cost and not hooks.originals.blank_card_set_cost then
        hooks.originals.blank_card_set_cost = Card.set_cost
        function Card:set_cost(...)
            if not hooks.is_blank_standard_pack(self)
                or not G
                or not G.GAME then
                return hooks.originals.blank_card_set_cost(self, ...)
            end

            local original_discount = G.GAME.discount_percent
            G.GAME.discount_percent =
                hooks.blank_standard_pack_discount(original_discount)
            local result = {
                pcall(hooks.originals.blank_card_set_cost, self, ...)
            }
            G.GAME.discount_percent = original_discount

            if not result[1] then error(result[2], 0) end
            return unpack(result, 2)
        end
    end

    local function blank_shop_pack_kind(seed_key)
        local ante = G
            and G.GAME
            and G.GAME.round_resets
            and G.GAME.round_resets.ante
            or 0
        local roll = pseudorandom(pseudoseed(
            ('blank_pack_kind_%s_%s'):format(
                tostring(seed_key or 'pack_generic'),
                tostring(ante)
            )
        ))
        local cumulative = 0

        for _, entry in ipairs(blank.shop_pack_kinds) do
            cumulative = cumulative + entry.weight
            if roll < cumulative then return entry.kind end
        end

        return blank.shop_pack_kinds[#blank.shop_pack_kinds].kind
    end
    hooks.blank_shop_pack_kind = blank_shop_pack_kind

    -- Hook: get_pack
    -- Only generic shop rolls receive Blank Deck's kind distribution. Calls
    -- that explicitly request a pack kind (for example a Standard Tag) keep
    -- that requested kind and every non-Blank run delegates unchanged.
    if not hooks.originals.blank_get_pack then
        hooks.originals.blank_get_pack = get_pack
        function get_pack(_key, _type)
            if not hooks.is_blank_run() then
                return hooks.originals.blank_get_pack(_key, _type)
            end

            hooks.apply_blank_run_rules()
            local requested_type = _type or hooks.blank_shop_pack_kind(_key)
            return hooks.originals.blank_get_pack(_key, requested_type)
        end
    end
end
