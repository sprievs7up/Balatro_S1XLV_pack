return function(context)
    local settings = context.settings
    local hooks = context.hooks
    local blank = settings.blank
    local is_blank_run = context.is_blank_run

    local function remaining_starting_packs()
        local remaining = G
            and G.GAME
            and tonumber(G.GAME.blank_starting_packs_remaining)
            or 0
        return math.max(0, math.floor(remaining))
    end

    local function blank_starting_pack_is_active()
        return G
            and G.GAME
            and is_blank_run()
            and remaining_starting_packs() > 0
            and G.GAME.blank_starting_pack_active == true
            or false
    end
    hooks.blank_starting_pack_is_active = blank_starting_pack_is_active

    -- Hook the final Steamodded Standard Pack entry point rather than the
    -- vanilla source text that Steamodded replaces during preflight. Give each
    -- starting-draft card an independent 2% Seal roll, then ask the upstream
    -- function only to choose the Seal type when that roll succeeds.
    if SMODS and SMODS.poll_seal
        and not hooks.originals.blank_poll_seal then
        hooks.originals.blank_poll_seal = SMODS.poll_seal
        function SMODS.poll_seal(args)
            local standard_args = args or {}
            local is_standard_pack_roll = standard_args.mod == 10
                and standard_args.guaranteed ~= true
                and (standard_args.key == nil
                    or standard_args.key == 'stdseal')
            if is_standard_pack_roll
                and hooks.blank_starting_pack_is_active() then
                local ante = G.GAME.round_resets
                    and G.GAME.round_resets.ante
                    or 0
                local has_seal = pseudorandom(pseudoseed(
                    'blank_starting_seal' .. ante
                )) < blank.starting_seal_chance
                if not has_seal then return nil end

                local limited_args = {}
                for key, value in pairs(standard_args) do
                    limited_args[key] = value
                end
                limited_args.mod = 1
                limited_args.guaranteed = true
                return hooks.originals.blank_poll_seal(limited_args)
            end
            return hooks.originals.blank_poll_seal(args)
        end
    end

    -- Steamodded's owned Standard boosters pass Base/Enhanced, Edition, and
    -- Seal results through SMODS.create_card. Reroll Base/Enhanced at 10% and
    -- Edition occurrence at 5% for only the 100 starting-draft offers. The
    -- upstream guaranteed Edition roll retains the normal Foil/Holographic/
    -- Polychrome mix; Negative remains excluded as in Standard Packs.
    if SMODS and SMODS.create_card and SMODS.poll_edition
        and not hooks.originals.blank_smods_create_card then
        hooks.originals.blank_smods_create_card = SMODS.create_card
        function SMODS.create_card(args)
            local is_starting_standard_card =
                hooks.blank_starting_pack_is_active()
                and type(args) == 'table'
                and args.area == G.pack_cards
                and args.key_append == 'sta'
                and (args.set == 'Base' or args.set == 'Enhanced')
            if is_starting_standard_card then
                local limited_args = {}
                for key, value in pairs(args) do
                    limited_args[key] = value
                end
                local ante = G.GAME.round_resets
                    and G.GAME.round_resets.ante
                    or 0
                limited_args.set = pseudorandom(pseudoseed(
                    'blank_starting_enhanced' .. ante
                )) < blank.starting_enhanced_chance
                    and 'Enhanced'
                    or 'Base'

                local has_edition = pseudorandom(pseudoseed(
                    'blank_starting_edition' .. ante
                )) < blank.starting_edition_chance
                limited_args.edition = nil
                limited_args.no_edition = true
                if has_edition then
                    limited_args.edition = SMODS.poll_edition {
                        key = 'blank_starting_edition_type' .. ante,
                        no_negative = true,
                        guaranteed = true,
                    }
                    limited_args.no_edition = nil
                end
                return hooks.originals.blank_smods_create_card(limited_args)
            end
            return hooks.originals.blank_smods_create_card(args)
        end
    end

    local function finish_blank_starting_packs()
        G.GAME.blank_starting_packs_remaining = 0
        G.GAME.blank_starting_pack_active = false
        G.GAME.blank_starting_packs_complete = true
        G.GAME.blank_starting_blind_pending = true

        -- These drafted cards are the Blank Deck's real starting deck. Set the
        -- baseline only after the final pack so effects such as Erosion count
        -- cards destroyed later in the run rather than treating every draft as
        -- an ordinary mid-run addition.
        G.GAME.starting_deck_size = #(G.playing_cards or {})
    end

    local function blank_starting_pack_key()
        assert(blank.pack_keys and #blank.pack_keys > 0,
            '[S1XLV Deck Pack] Blank Deck starting pack list is empty')

        local pack_number = blank.starting_packs - remaining_starting_packs() + 1
        local roll = pseudorandom(pseudoseed(
            'blank_starting_pack_' .. tostring(pack_number)
        ))
        local index = math.min(
            #blank.pack_keys,
            math.floor(roll * #blank.pack_keys) + 1
        )
        return blank.pack_keys[index]
    end
    hooks.blank_starting_pack_key = blank_starting_pack_key

    local function open_blank_starting_pack()
        local pack_key = hooks.blank_starting_pack_key()
        local center = G.P_CENTERS[pack_key]
        assert(center,
            ('[S1XLV Deck Pack] Missing Blank Deck starting pack %s')
                :format(tostring(pack_key)))

        local card = Card(
            G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
            G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2,
            G.CARD_W * 1.27,
            G.CARD_H * 1.27,
            G.P_CARDS.empty,
            center,
            {
                bypass_discovery_center = true,
                bypass_discovery_ui = true,
            }
        )
        card.cost = 0
        card.from_tag = true
        card.sixlv_blank_starting_pack = true
        G.GAME.blank_starting_pack_active = true

        -- This is the same free-pack path used by the vanilla Standard Tag.
        -- nosave avoids creating a shop-action save for a generated card;
        -- end_consumeable still writes the normal between-pack run save.
        G.FUNCS.use_card({ config = { ref_table = card } }, nil, true)
        card:start_materialize()
    end

    local function blank_pack_can_open()
        return is_blank_run()
            and remaining_starting_packs() > 0
            and not G.GAME.blank_starting_pack_active
            and G.STATE == G.STATES.BLIND_SELECT
            and G.play
            and G.hand
            and G.P_CARDS
            and G.P_CENTERS
            and G.FUNCS
            and G.FUNCS.use_card
    end

    local function try_open_blank_starting_pack()
        if not (G and G.GAME) or not blank_pack_can_open() then return false end
        open_blank_starting_pack()
        return true
    end
    hooks.try_open_blank_starting_pack = try_open_blank_starting_pack

    local function prepare_blank_starting_packs()
        if not is_blank_run() or remaining_starting_packs() <= 0 then return end

        -- Game:start_run has finished constructing every card area at this
        -- point. Open the first pack immediately, before Blind Select creates
        -- its UI. A between-pack save also resumes from this same state.
        if G.STATE == G.STATES.BLIND_SELECT then
            G.GAME.blank_starting_pack_active = false
        end
        try_open_blank_starting_pack()
    end
    hooks.prepare_blank_starting_packs = prepare_blank_starting_packs

    local function block_blind_progress_until_draft_finishes()
        if not is_blank_run() or remaining_starting_packs() <= 0 then
            return false
        end
        try_open_blank_starting_pack()
        return true
    end
    hooks.block_blank_blind_progress = block_blind_progress_until_draft_finishes

    local function restore_blank_blind_select_after_draft()
        if not (G and G.GAME)
            or not is_blank_run()
            or not G.GAME.blank_starting_packs_complete
            or not G.GAME.blank_starting_blind_pending
            or G.STATE ~= G.STATES.BLIND_SELECT then
            return false
        end

        -- Opening the first pack before Blind Select is drawn means the pack
        -- state leaves STATE_COMPLETE set. Clear it once after the final pack
        -- so vanilla creates the Blind Select UI on the next update.
        if not G.blind_select or G.blind_select.REMOVED then
            G.STATE_COMPLETE = false
        end
        G.GAME.blank_starting_blind_pending = false
        return true
    end
    hooks.restore_blank_blind_select_after_draft =
        restore_blank_blind_select_after_draft

    local function blank_starting_pack_is_unskippable()
        return hooks.blank_starting_pack_is_active()
    end
    hooks.blank_starting_pack_is_unskippable =
        blank_starting_pack_is_unskippable

    local function remove_skip_booster_nodes(node)
        if type(node) ~= 'table' or type(node.nodes) ~= 'table' then
            return false
        end

        local removed = false
        for index = #node.nodes, 1, -1 do
            local child = node.nodes[index]
            local config = type(child) == 'table' and child.config or nil
            if config
                and (config.button == 'skip_booster'
                    or config.func == 'can_skip_booster') then
                table.remove(node.nodes, index)
                removed = true
            elseif remove_skip_booster_nodes(child) then
                removed = true
            end
        end
        return removed
    end
    hooks.remove_blank_starting_pack_skip_nodes =
        remove_skip_booster_nodes

    -- Hook: create_UIBox_standard_pack
    -- Only the 20 generated starting packs omit their Skip button. Later
    -- Standard Packs in the same Blank Deck run retain the vanilla UI.
    if create_UIBox_standard_pack
        and not hooks.originals.blank_create_UIBox_standard_pack then
        hooks.originals.blank_create_UIBox_standard_pack =
            create_UIBox_standard_pack
        function create_UIBox_standard_pack(...)
            local definition =
                hooks.originals.blank_create_UIBox_standard_pack(...)
            if hooks.blank_starting_pack_is_unskippable() then
                hooks.remove_blank_starting_pack_skip_nodes(definition)
            end
            return definition
        end
    end

    -- Hook: G.FUNCS.skip_booster
    -- The missing button is the player-facing rule. This callback guard also
    -- blocks controller shortcuts or another mod from bypassing it.
    if G and G.FUNCS and G.FUNCS.skip_booster
        and not hooks.originals.blank_skip_booster then
        hooks.originals.blank_skip_booster = G.FUNCS.skip_booster
        G.FUNCS.skip_booster = function(...)
            if hooks.blank_starting_pack_is_unskippable() then return end
            return hooks.originals.blank_skip_booster(...)
        end
    end

    -- Hook: G.FUNCS.end_consumeable
    -- Each completed starting pack consumes exactly one of the 20
    -- grants. The update watchdog opens the next one after the UI has safely
    -- returned to Blind Select.
    if G and G.FUNCS and G.FUNCS.end_consumeable
        and not hooks.originals.blank_end_consumeable then
        hooks.originals.blank_end_consumeable = G.FUNCS.end_consumeable
        G.FUNCS.end_consumeable = function(e, delay_factor)
            local was_blank_starting_pack = is_blank_run()
                and G.GAME.blank_starting_pack_active == true
                and remaining_starting_packs() > 0
            local result = hooks.originals.blank_end_consumeable(e, delay_factor)

            if was_blank_starting_pack then
                G.GAME.blank_starting_packs_remaining =
                    remaining_starting_packs() - 1
                G.GAME.blank_starting_pack_active = false

                if remaining_starting_packs() <= 0 then
                    finish_blank_starting_packs()
                end
            end
            return result
        end
    end

    -- Keep the zero-card start safe if another mod exposes the Blind controls
    -- before the draft begins or a saved run resumes between packs.
    if G and G.FUNCS and G.FUNCS.select_blind
        and not hooks.originals.blank_select_blind then
        hooks.originals.blank_select_blind = G.FUNCS.select_blind
        G.FUNCS.select_blind = function(...)
            if hooks.block_blank_blind_progress() then return end
            return hooks.originals.blank_select_blind(...)
        end
    end

    if G and G.FUNCS and G.FUNCS.skip_blind
        and not hooks.originals.blank_skip_blind then
        hooks.originals.blank_skip_blind = G.FUNCS.skip_blind
        G.FUNCS.skip_blind = function(...)
            if hooks.block_blank_blind_progress() then return end
            return hooks.originals.blank_skip_blind(...)
        end
    end

    -- Hook: Game:update
    -- Game:start_run opens the first pack before the Blind UI exists. After
    -- each pack, retry when vanilla restores BLIND_SELECT; after the twentieth,
    -- release vanilla to create the Blind Select UI normally.
    if Game and Game.update and not hooks.originals.blank_game_update then
        hooks.originals.blank_game_update = Game.update
        function Game:update(dt)
            local result = hooks.originals.blank_game_update(self, dt)
            if hooks.try_open_blank_starting_pack then
                hooks.try_open_blank_starting_pack()
            end
            if hooks.restore_blank_blind_select_after_draft then
                hooks.restore_blank_blind_select_after_draft()
            end
            return result
        end
    end
end
