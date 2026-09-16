-- Main-menu palette: coral-red centre and light-blue outer swirl.
-- Keep the vanilla splash shader itself intact so its white highlights,
-- transition flash, motion, and reduced-motion behaviour are preserved.

local hook_state = rawget(_G, '__sixlv_menu_theme_hook_state')
if not hook_state then
    hook_state = {}
    rawset(_G, '__sixlv_menu_theme_hook_state', hook_state)
end

hook_state.colour_1 = HEX('E56B6F')
hook_state.colour_2 = HEX('60C2FF')

local function apply_menu_theme()
    local splash_back = G and G.SPLASH_BACK
    if not (splash_back and splash_back.draw_steps) then return end

    for _, draw_step in ipairs(splash_back.draw_steps) do
        if draw_step.shader == 'splash' and draw_step.send then
            for _, shader_arg in ipairs(draw_step.send) do
                if shader_arg.name == 'colour_1' then
                    shader_arg.val = hook_state.colour_1
                    shader_arg.ref_table = nil
                    shader_arg.ref_value = nil
                elseif shader_arg.name == 'colour_2' then
                    shader_arg.val = hook_state.colour_2
                    shader_arg.ref_table = nil
                    shader_arg.ref_value = nil
                end
            end
        end
    end
end

if not hook_state.installed then
    assert(Game and Game.main_menu, '[SIXLV BALATRO PACK] Game:main_menu is unavailable')
    hook_state.original_main_menu = Game.main_menu

    function Game:main_menu(...)
        local result = hook_state.original_main_menu(self, ...)
        apply_menu_theme()
        return result
    end

    hook_state.installed = true
end

-- Refresh an already-open menu during a Steamodded hot reload.
apply_menu_theme()

return {
    apply = apply_menu_theme,
    colour_1 = hook_state.colour_1,
    colour_2 = hook_state.colour_2,
}
