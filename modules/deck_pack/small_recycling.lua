return function(context)
    local hooks = context.hooks
    local small = context.settings.small

    -- Hook: G.FUNCS.draw_from_play_to_discard
    -- This callback runs after scoring, glass shattering, destruction, and
    -- Joker reactions. For the Small Deck, surviving played cards are shuffled
    -- as a batch and inserted at the bottom of G.deck instead of G.discard.
    -- Every other deck delegates directly to the original callback.
    if not hooks.originals.draw_from_play_to_discard then
        hooks.originals.draw_from_play_to_discard = G.FUNCS.draw_from_play_to_discard
        function G.FUNCS.draw_from_play_to_discard(e)
            if not hooks.small_recycle_enabled(
                'small_recycle_played_cards',
                small.recycle_played_cards
            ) then
                return hooks.originals.draw_from_play_to_discard(e)
            end

            local surviving_cards = {}
            for _, card in ipairs(G.play.cards) do
                if not card.shattered and not card.destroyed then
                    surviving_cards[#surviving_cards + 1] = card
                end
            end

            hooks.shuffle_card_batch(
                surviving_cards,
                hooks.small_recycle_seed('played')
            )
            local card_count = #surviving_cards
            for index, card in ipairs(surviving_cards) do
                draw_card(
                    G.play,
                    G.deck,
                    index * 100 / card_count,
                    'down',
                    false,
                    card
                )
            end
        end
    end

    -- Discard recycling is intentionally disabled by the Small Deck's saved
    -- modifier. The following two hooks keep the already-designed path
    -- available without changing current gameplay.

    -- Hook: G.FUNCS.discard_cards_from_highlighted
    -- When the optional modifier is enabled, remember exactly which highlighted
    -- cards entered the discard pile; otherwise this is a transparent delegate.
    if not hooks.originals.discard_cards_from_highlighted then
        hooks.originals.discard_cards_from_highlighted =
            G.FUNCS.discard_cards_from_highlighted
        function G.FUNCS.discard_cards_from_highlighted(e, hook)
            local recycle_discards = hooks.small_recycle_enabled(
                'small_recycle_discarded_cards',
                small.recycle_discarded_cards
            )
            local pending_ids = nil

            if recycle_discards and G.hand and G.hand.highlighted and G.discard then
                local highlighted_count = math.min(
                    #G.hand.highlighted,
                    G.discard.config.card_limit - #G.play.cards
                )
                if highlighted_count > 0 then
                    table.sort(G.hand.highlighted, function(a, b)
                        return a.T.x < b.T.x
                    end)
                    pending_ids = {}
                    for index = 1, highlighted_count do
                        pending_ids[#pending_ids + 1] =
                            G.hand.highlighted[index].playing_card
                    end
                end
            end

            local result = hooks.originals.discard_cards_from_highlighted(e, hook)
            if pending_ids then
                G.GAME.small_pending_discard_ids = pending_ids
            end
            return result
        end
    end

    local function recycle_pending_small_discards()
        local pending_ids = G.GAME.small_pending_discard_ids
        G.GAME.small_pending_discard_ids = nil
        if not pending_ids or not G.discard or not G.deck then return end

        local pending_lookup = {}
        for _, playing_card_id in ipairs(pending_ids) do
            pending_lookup[playing_card_id] = true
        end

        local surviving_cards = {}
        for _, card in ipairs(G.discard.cards) do
            if pending_lookup[card.playing_card]
                and not card.shattered
                and not card.destroyed then
                surviving_cards[#surviving_cards + 1] = card
            end
        end
        hooks.shuffle_card_batch(
            surviving_cards,
            hooks.small_recycle_seed('discarded')
        )

        -- Move synchronously so the following draw sees the replenished deck.
        for _, card in ipairs(surviving_cards) do
            G.discard:remove_card(card)
            if card.ability then card.ability.discarded = nil end
            G.deck:emplace(card)
        end
    end
    hooks.recycle_pending_small_discards = recycle_pending_small_discards

    -- Hook: G.FUNCS.draw_from_deck_to_hand
    -- Complete optional discard recycling before Balatro calculates how many
    -- replacement cards can be drawn. With the modifier disabled, only a stale
    -- pending marker is cleared and the original draw path is unchanged.
    if not hooks.originals.draw_from_deck_to_hand then
        hooks.originals.draw_from_deck_to_hand = G.FUNCS.draw_from_deck_to_hand
        function G.FUNCS.draw_from_deck_to_hand(e)
            if hooks.is_small_run() and G.GAME.small_pending_discard_ids then
                if hooks.small_recycle_enabled(
                    'small_recycle_discarded_cards',
                    small.recycle_discarded_cards
                ) then
                    hooks.recycle_pending_small_discards()
                else
                    G.GAME.small_pending_discard_ids = nil
                end
            end
            return hooks.originals.draw_from_deck_to_hand(e)
        end
    end
end
