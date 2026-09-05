return function(context)
    local settings = context.settings
    local hooks = context.hooks
    local small_back_key = settings.keys.small
    local inferno_win_ante = settings.inferno.win_ante

    local function sync_back_contrast_atlases(back)
        local center = back
            and back.effect
            and back.effect.center

        if center and center.key == small_back_key then
            back.atlas = center.atlas
            back.lc_atlas = center.lc_atlas
            back.hc_atlas = center.hc_atlas
            back.__cartomancer_small_contrast_atlases = true
        elseif back and back.__cartomancer_small_contrast_atlases then
            back.lc_atlas = center and center.lc_atlas or nil
            back.hc_atlas = center and center.hc_atlas or nil
            back.__cartomancer_small_contrast_atlases = nil
        end
    end
    hooks.sync_back_contrast_atlases = sync_back_contrast_atlases

    -- Hook: Back:init
    -- Steamodded copies only the normal atlas into a runtime Back object.
    -- Mirror the Small Deck's low/high-contrast atlases after initialization.
    if Back and not hooks.originals.back_init then
        hooks.originals.back_init = Back.init
        function Back:init(selected_back)
            local result = hooks.originals.back_init(self, selected_back)
            hooks.sync_back_contrast_atlases(self)
            return result
        end
    end

    -- Hook: Back:change_to
    -- Keep both contrast variants correct while browsing between deck backs.
    if Back and not hooks.originals.back_change_to then
        hooks.originals.back_change_to = Back.change_to
        function Back:change_to(new_back)
            local result = hooks.originals.back_change_to(self, new_back)
            hooks.sync_back_contrast_atlases(self)
            return result
        end
    end

    -- Hook: Back:load
    -- Restore the contrast-specific atlas fields after loading a saved run.
    if Back and not hooks.originals.back_load then
        hooks.originals.back_load = Back.load
        function Back:load(back_table)
            local result = hooks.originals.back_load(self, back_table)
            hooks.sync_back_contrast_atlases(self)
            return result
        end
    end

    -- Hook: get_blind_amount (installed when a run starts)
    -- get_blind_amount may already be wrapped by another component. Install
    -- this wrapper when a run starts so it delegates to the final upstream
    -- implementation, then special-cases only Inferno Ante 10.
    local function install_inferno_blind_amount_hook()
        if get_blind_amount == hooks.inferno_blind_amount_wrapper then return end

        local base_get_blind_amount = get_blind_amount
        local wrapper = function(ante)
            if hooks.is_inferno_run() and ante == inferno_win_ante then
                return base_get_blind_amount(ante - 1)
                    * hooks.inferno_ante_ten_multiplier
            end
            return base_get_blind_amount(ante)
        end

        hooks.inferno_blind_amount_wrapper = wrapper
        get_blind_amount = wrapper
    end
    hooks.install_inferno_blind_amount_hook = install_inferno_blind_amount_hook

    -- Hook: Game:start_run
    -- Rebuild the Inferno score wrapper against the current hook chain at the
    -- start of each run; all non-Inferno calls continue to delegate unchanged.
    if not hooks.originals.game_start_run then
        hooks.originals.game_start_run = Game.start_run
        function Game:start_run(args)
            hooks.install_inferno_blind_amount_hook()
            return hooks.originals.game_start_run(self, args)
        end
    end
end
