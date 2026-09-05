-- SIXLV BALATRO PACK
--
-- The three components keep their historical Steamodded prefixes so existing
-- center keys, stake progress, and localization keys remain
-- compatible after migration from the standalone mods.

local pack = assert(SMODS.current_mod, '[SIXLV BALATRO PACK] Missing current mod context')
local pack_prefix = pack.prefix

-- Replace the vanilla title-screen atlas while retaining its exact logical
-- dimensions. The unprefixed key is required because the base game looks up
-- G.ASSET_ATLAS["balatro"] directly.
SMODS.Atlas {
    key = 'balatro',
    path = 'balatrolv.png',
    px = 333,
    py = 216,
    prefix_config = { key = false },
}

local components = {
    { name = 'Balatro Balance Patch', prefix = 'bbp', path = 'modules/balance_patch.lua' },
    { name = 'Bulky Stakes', prefix = 'bsk', path = 'modules/bulky_stakes.lua' },
    { name = 'S1XLV Deck Pack', prefix = 'cartomancer', path = 'modules/deck_pack.lua' },
}

local function load_component(component)
    pack.prefix = component.prefix

    local chunk, load_error = SMODS.load_file(component.path)
    if not chunk then
        pack.prefix = pack_prefix
        error(('[SIXLV BALATRO PACK] Could not load %s: %s')
            :format(component.name, tostring(load_error)))
    end

    local ok, run_error = pcall(chunk)
    pack.prefix = pack_prefix
    if not ok then
        error(('[SIXLV BALATRO PACK] Could not initialize %s: %s')
            :format(component.name, tostring(run_error)))
    end
end

for _, component in ipairs(components) do
    load_component(component)
end

pack.prefix = pack_prefix
