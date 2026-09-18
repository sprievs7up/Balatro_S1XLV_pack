# Runtime Hook Reference

This file documents every function wrapper and Lovely patch installed by
SIXLV BALATRO PACK. It is intended for maintainers and compatibility reviews;
player-facing rules remain in README.md.

## Hook rules

- main.lua loads the Main Menu Theme, Balance Patch, Bulky Stakes, then the Deck Pack.
- A wrapper always keeps the function that existed immediately before it was
  installed and delegates to that function outside its own condition.
- Deck Pack wrappers share the historical
  __cartomancer_deck_hook_state table. Keeping this key prevents duplicate
  wrappers during Steamodded hot reloads.
- Temporary changes to pool weights or bans are restored after the delegated
  call, including its error path.
- Steamodded take_ownership calls are listed separately. They replace center
  callbacks rather than global functions.

## Main Menu Theme

The theme stores its wrapper state in `__sixlv_menu_theme_hook_state` so a
Steamodded hot reload cannot wrap the menu twice.

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Game:main_menu | After the menu is created, replaces only the vanilla splash shader's `colour_1` and `colour_2` inputs with `#E56B6F` and `#60C2FF`. The shader, white highlights, transition flash, timing, and reduced-motion behaviour remain vanilla. | Calls the original menu function first and returns its result. |

## Balatro Balance Patch

These hooks extend Matador so Boss Blind effects that occur outside the normal
scoring contexts can still trigger it. They also maintain Satellite's
run-persistent Planet-upgrade layers.

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Blind:set_blind | Clears per-Blind Matador state and records the Water, Needle, Manacle, or Amber Acorn entry event. | Returns the original set_blind result. |
| G.FUNCS.draw_from_deck_to_hand | Records whether a real draw is about to occur, including Serpent's three-card rule. | Calls the original draw function first. |
| Blind:stay_flipped | Detects when Wheel, House, Mark, or Fish actually turns a drawn card face down. | Returns the original face-down decision. |
| Blind:drawn_to_hand | After the original Blind callback, emits the matching Matador context for entry, draw, face-down, Crimson Heart, or Cerulean Bell effects. | Does nothing unless an active Boss effect was observed. |
| G.FUNCS.discard_cards_from_highlighted | Detects cards discarded by The Hook and emits one Matador context. | Preserves the original discard return value. |
| Blind:press_play | Counts the highlighted cards selected for The Tooth before their queued move into the play area. | Returns the original press_play result. |
| ease_dollars | Emits The Tooth's Matador context after the final non-instant $1 deduction. | Returns the original money result for every call. |
| set_consumeable_usage | Records every Planet upgrade for Satellite, pays the currently unlocked layer, and releases banked higher-layer upgrades as soon as every required poker hand catches up. | Records every consumable through the original function; non-Planet cards do not affect Satellite. |
| set_hand_usage | Adds Five of a Kind, Flush Five, or Flush House to Satellite's required poker-hand set after that hidden hand is first played. | Preserves vanilla hand-usage bookkeeping for every hand. |

Balance Patch also takes ownership of selected vanilla Jokers, Vouchers, and
Stakes to change their documented values. Satellite uses a Steamodded
`calc_dollar_bonus` callback to cash out its saved layered total. Red Card is
no longer owned and therefore uses its full vanilla definition. These
definitions are direct Steamodded center callbacks, not global wrappers.

## Bulky Stakes

All hooks in this section are installed once through BSK.hooks_installed.

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Card:calculate_joker | Tracks Invisible Joker's copy source and converts a Bulky XMult retrigger to a linear X2 pass. | Non-Bulky results and the upstream triggered flag are returned unchanged. |
| Card:set_cost | Doubles both the purchase price and the already-calculated sell value of a Bulky Joker, then refreshes its sell-price label. | Non-Bulky cards retain the upstream prices. |
| Card:add_to_deck | Applies the second copy of supported passive effects when a Bulky Joker first enters the deck. | Delegates before testing the final added state. |
| Card:remove_from_deck | Removes that extra passive contribution when a Bulky Joker leaves. | Delegates before testing the final removed state. |
| Card:calculate_dollar_bonus | Doubles end-of-round cash Joker payouts that do not pass through normal retrigger scoring. | Returns the original payout for non-Bulky cards. |
| Card:calculate_rental | Applies Rental's end-of-round charge twice for a Bulky Joker. | Calls the original calculation once for all other cards. |
| Card:calculate_perishable | Advances Perishable twice for a Bulky Joker. | Calls the original calculation once for all other cards. |
| SMODS.Stickers.rental.calculate | Suppresses Rental during the added Bulky retrigger so the explicit double charge does not become four charges. | Delegates in every other context. |
| SMODS.Stickers.perishable.calculate | Suppresses Perishable during the added Bulky retrigger for the same reason. | Delegates in every other context. |
| Card:set_edition | Removes Bulky before applying Negative because the two slot modifiers are incompatible. | Delegates after the compatibility check. |
| Card:update | Removes newly blacklisted Bulky stickers, excludes Bulky targets from Ectoplasm, and includes Bulky's occupied body in Joker Stencil. | Runs the original update first. |
| Card:check_use | Prevents Ankh when no legal copy arrangement fits, while retaining normal booster selection behaviour. | Delegates for non-Ankh cards and valid uses. |
| create_card | Removes stickers from Jokers created through the explicitly stickerless source keys. Editions remain intact. | Returns the original created card. |
| Card:use_consumeable | Marks an Ankh use until its delayed copy is constructed. | Delegates the actual consumable use. |
| copy_card | Selects a legal copy target and squeezes incompatible cards for Invisible Joker or Ankh. In Grand Master runs, Invisible Joker resolves capacity in its own area and may squeeze cards from that area. | Calls the original copier with the resolved source. |
| get_blind_amount | Supplies the Joker Stake Ante table and its endless continuation. | Delegates unless Joker Stake scaling is active. |

The Bulky Sticker and the Australium/Joker Stakes are registered through
Steamodded objects; those registrations are not global hooks.

## S1XLV Deck Pack

The Deck Pack is split into seven files:

- modules/deck_pack/back_hooks.lua
- modules/deck_pack/decks.lua
- modules/deck_pack/blank_start.lua
- modules/deck_pack/small_recycling.lua
- modules/deck_pack/cartomancer_rules.lua
- modules/deck_pack/blank_rules.lua
- modules/deck_pack/grandmaster.lua

### Back and Inferno hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Back:init | Copies the Small Deck low/high-contrast atlas fields to its runtime Back instance. | Calls the original initializer and returns its result. |
| Back:change_to | Updates or clears those atlas fields while browsing between deck backs. | Calls the original change function first. |
| Back:load | Restores the contrast-specific atlas fields after a saved run is loaded. | Calls the original load function first. |
| create_card | Gives Inferno shop Jokers, Buffoon Pack choices, and Judgement a 60/25/15 Common/Uncommon/Rare split. | Explicit cards or rarities, Legendary rolls, other generation sources, and other decks delegate unchanged. |
| Game:start_run | Installs the Inferno score wrapper against the final get_blind_amount chain, reapplies Blank Deck shop rules to loaded runs, then immediately opens the first Blank Deck pack after all run card areas exist and before Blind Select is drawn. | Delegates the run startup unchanged. |
| Dynamic get_blind_amount wrapper | Applies Inferno's fixed Ante 10 base score for the active Stake scaling tier. | Delegates every other Ante and every non-Inferno run. |

### Small Deck hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| G.FUNCS.draw_from_play_to_discard | After all scoring/destruction callbacks, shuffles surviving played cards and inserts them at the bottom of the Small Deck. | Delegates for every other deck or when recycling is disabled. |
| G.FUNCS.discard_cards_from_highlighted | Records the exact discarded card IDs for the optional discard-recycling path. This path is currently disabled by the deck modifier. | With the modifier disabled, it only delegates. |
| G.FUNCS.draw_from_deck_to_hand | If optional discard recycling is enabled later, moves the recorded survivors before replacement-card draw size is calculated. | Current gameplay delegates to the original draw. |

### Blank Deck hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Game:update | Opens the next randomly selected Mega Standard Pack variant whenever pack cleanup returns to `BLIND_SELECT`, then releases vanilla to create the Blind Select UI after pack `20`. | Calls the original update first and does nothing outside a Blank Deck starting draft. |
| create_UIBox_standard_pack | Removes the **Skip** button from only the `20` generated Blank Deck starting packs. | Later packs in the same run and every other deck keep the original Standard Pack UI. |
| G.FUNCS.skip_booster | Blocks controller shortcuts or another mod from bypassing the mandatory starting-pack choices. | Delegates after the starting draft and for every other pack. |
| G.FUNCS.end_consumeable | Counts one completed starting Mega Standard Pack and records the final drafted deck size after all `20` are resolved. | Delegates every non-starting pack unchanged. |
| G.FUNCS.select_blind / skip_blind | Prevents a zero-card Blank Deck from advancing a Blind before its starting draft is complete. | Delegates after the draft and for every other deck. |
| SMODS.poll_seal | Gives only the `100` cards offered by the `20` starting Mega Standard Packs an independent `2%` Seal roll; also removes Blue from natural Cartomancer rolls. | Only the exact starting-draft Standard Pack call is intercepted; later Standard Packs retain their original `{mod = 10}` roll. |
| SMODS.create_card | Rerolls only those `100` starting-pack cards at independent `10%` Enhanced and `5%` Edition rates, explicitly clearing the upstream Edition on a miss. | Later Standard Packs and all non-Standard creation delegate unchanged. |
| get_pack | Chooses generic shop Booster Pack kinds at `70%` Standard, `10%` Buffoon, `10%` Celestial, `8%` Arcana, and `2%` Spectral, including the first shop. | Explicitly requested pack kinds and every non-Blank run delegate unchanged. |
| Card:set_cost | Prices Blank Deck Standard Packs one discount tier ahead: `25%` before Clearance Sale, `50%` after it, and still `50%` after Liquidation. | Other packs, shop items, and non-Blank runs use the upstream price calculation unchanged. |
| Blank Back calculate | Returns Steamodded's `remove` flag for non-debuffed scoring cards in `G.play`; Steamodded then shatters Glass Cards and dissolves all other scored cards. | Unscored played cards, held cards, debuffed cards, and every other deck are unaffected. |

### Cartomancer hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Card:set_ability | Copies a Tarot instance's config and applies enhanced counts, caps, or Judgement's $5 base cost without mutating the shared center. | Non-Cartomancer cards keep the original ability data. |
| SMODS.add_to_pool | Filters Planet cards, Celestial packs, Black Hole, Trance, Meteor Tags, and Planet vouchers from natural Cartomancer pools. | Delegates every other prototype and every other deck. |
| get_pack | Temporarily multiplies Standard pack weight by 1.5 and Spectral pack weight by 2. | Restores all weights immediately after the roll. |
| Card:apply_to_run | Prevents a forced Planet Merchant/Tycoon from restoring Planet shop weight. | Delegates other vouchers and all non-Cartomancer runs. |
| SMODS.poll_seal | Gives Blue Seal zero weight during natural Cartomancer seal rolls. | Restores Blue Seal's original weight and getter after the roll. |
| create_card_for_shop | Replaces a Blue Seal added directly by Illusion with an equal Red/Gold/Purple roll. | Returns all other generated shop cards unchanged. |
| create_card | Temporarily bans Black Hole during unforced soulable Planet/Spectral generation. | Explicit forced keys and direct card creation remain allowed. |

### Grand Master hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| get_new_boss | Uses a four-Ante Showdown cadence while preserving Ante 12 as Grand Master's true win condition. | Delegates unchanged outside Grand Master runs and restores `G.GAME.win_ante` immediately after every selection. |
| G.FUNCS.check_for_buy_space | Lets a Joker use a free consumable slot after the standard Joker area is full. | Delegates for other decks and non-Joker cards. |
| CardArea:emplace | Routes an overflowing Joker into the consumable area, preferring the standard Joker area whenever it has room. | Preserves the requested destination outside Grand Master runs. |
| G.FUNCS.can_select_card / can_select_from_booster | Enables selecting a Joker from a pack when only a consumable slot is available. | Preserves the original selection result otherwise. |
| Card:can_use_consumeable | Lets Judgement, The Soul, and Wraith use a free consumable slot for the Joker they create. | Delegates all other use checks. |
| Card:stop_drag | Moves Jokers between the standard and consumable areas when dropped over the other area. Consumables are never moved into the Joker area. | Preserves ordinary same-area dragging and every non-Grand-Master run. |
| Card:generate_UIBox_ability_table | Displays Abstract Joker's combined count and the local Blueprint/Brainstorm compatibility state. | Delegates other tooltip generation. |
| Card:update | Makes Blueprint, Brainstorm, and Joker Stencil read their own area; Swashbuckler totals Joker sell values from both areas. | Delegates other card updates. |
| Card:calculate_joker | Applies same-area Blueprint, Brainstorm, Ceremonial Dagger, and Joker Stencil rules; limits Madness victims to same-area Jokers; handles combined Abstract Joker counting, cross-area Invisible Joker targets, consumable-slot Riff-raff room, and a true-consumable-only Perkeo target pool. | Delegates all other calculations. |
| set_joker_usage / set_joker_win / set_joker_loss | Includes Joker cards from both playable areas in usage, win-sticker, and loss bookkeeping while excluding ordinary consumables. | Delegates unchanged outside Grand Master runs. |

Amber Acorn and Crimson Heart retain their vanilla `G.jokers` targeting. They
do not shuffle, flip, or debuff Jokers in the consumable area.

### Deck Pack ownership proxies

| Ownership | Purpose | Non-Cartomancer behaviour |
| --- | --- | --- |
| j_certificate | Reproduces Certificate with an equal Red/Gold/Purple seal pool. | Delegates to the captured original calculation. |
| Selected Tarot centers | Supplies Cartomancer display values and the High Priestess/Judgement behaviours. | Delegates to an earlier explicit override when present, otherwise follows the included vanilla branch. |

## Lovely patches

lovely.toml contains nine source patches:

1. Extend the Game Speed option cycle with `8x`, `16x`, and `256x`.
2. Add To the Moon's separate uncapped interest row to round cash-out.
3. Define configurable base-interest basis, scale, and effective payout.
4. Use those values in the base-interest cash-out row.
5. Use them in the maximum-interest comparison.
6. Use them in the round-dollar total.
7. Show the same values in the base-interest cash-out UI.
8. Make Magic Trick shop cards use the enhanced-card pool.
9. Give Illusion an equal Edition-only, Seal-only, or both finish roll.

Base-interest expressions default to the vanilla $5 basis and x1 scale when
the Balance Patch stake modifiers are absent. In every mode, To the Moon adds
its own uncapped $1 per $5 without changing the base interest amount or cap.
