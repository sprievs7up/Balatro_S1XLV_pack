# Runtime Hook Reference

This file documents every function wrapper and Lovely patch installed by
SIXLV BALATRO PACK. It is intended for maintainers and compatibility reviews;
player-facing rules remain in README.md.

## Hook rules

- main.lua loads Balance Patch, Bulky Stakes, then the Deck Pack.
- A wrapper always keeps the function that existed immediately before it was
  installed and delegates to that function outside its own condition.
- Deck Pack wrappers share the historical
  __cartomancer_deck_hook_state table. Keeping this key prevents duplicate
  wrappers during Steamodded hot reloads.
- Temporary changes to pool weights or bans are restored after the delegated
  call, including its error path.
- Steamodded take_ownership calls are listed separately. They replace center
  callbacks rather than global functions.

## Balatro Balance Patch

These hooks extend Matador so Boss Blind effects that occur outside the normal
scoring contexts can still trigger it.

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Blind:set_blind | Clears per-Blind Matador state and records the Water/Needle entry penalty. | Returns the original set_blind result. |
| G.FUNCS.draw_from_deck_to_hand | Records whether a real draw is about to occur, including Serpent's three-card rule. | Calls the original draw function first. |
| Blind:stay_flipped | Detects when Wheel, House, Mark, or Fish actually turns a drawn card face down. | Returns the original face-down decision. |
| Blind:drawn_to_hand | After the original Blind callback, emits the matching Matador context for entry, draw, face-down, Crimson Heart, or Cerulean Bell effects. | Does nothing unless an active Boss effect was observed. |
| G.FUNCS.discard_cards_from_highlighted | Detects cards discarded by The Hook and emits one Matador context. | Preserves the original discard return value. |
| Blind:press_play | Counts cards affected by The Tooth before its individual dollar deductions begin. | Returns the original press_play result. |
| ease_dollars | Emits The Tooth's Matador context after the final non-instant $1 deduction. | Returns the original money result for every call. |

Balance Patch also takes ownership of selected vanilla Jokers, Vouchers, and
Stakes to change their documented values. Those definitions are direct
Steamodded center callbacks, not global wrappers.

## Bulky Stakes

All hooks in this section are installed once through BSK.hooks_installed.

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Card:calculate_joker | Tracks Invisible Joker's copy source and converts a Bulky XMult retrigger to a linear X2 pass. | Non-Bulky results and the upstream triggered flag are returned unchanged. |
| Card:set_cost | Doubles the purchase price of a Bulky Joker after vanilla/modded cost calculation. | Non-Bulky cards retain the upstream cost. |
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
| copy_card | Selects a legal copy target and squeezes incompatible Jokers for Invisible Joker or Ankh. | Calls the original copier with the resolved source. |
| get_blind_amount | Supplies the Joker Stake Ante table and its endless continuation. | Delegates unless Joker Stake scaling is active. |

The Bulky Sticker and the Australium/Joker Stakes are registered through
Steamodded objects; those registrations are not global hooks.

## S1XLV Deck Pack

The Deck Pack is split into four files:

- modules/deck_pack/back_hooks.lua
- modules/deck_pack/decks.lua
- modules/deck_pack/small_recycling.lua
- modules/deck_pack/cartomancer_rules.lua

### Back and Inferno hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| Back:init | Copies the Small Deck low/high-contrast atlas fields to its runtime Back instance. | Calls the original initializer and returns its result. |
| Back:change_to | Updates or clears those atlas fields while browsing between deck backs. | Calls the original change function first. |
| Back:load | Restores the contrast-specific atlas fields after a saved run is loaded. | Calls the original load function first. |
| create_card | Gives Inferno shop Jokers, Buffoon Pack choices, and Judgement a 60/25/15 Common/Uncommon/Rare split. | Explicit cards or rarities, Legendary rolls, other generation sources, and other decks delegate unchanged. |
| Game:start_run | Installs the Inferno score wrapper against the final get_blind_amount chain for the new run. | Delegates the run startup unchanged. |
| Dynamic get_blind_amount wrapper | Applies Inferno's fixed Ante 10 base score for the active Stake scaling tier. | Delegates every other Ante and every non-Inferno run. |

### Small Deck hooks

| Hook | Purpose | Normal fallback |
| --- | --- | --- |
| G.FUNCS.draw_from_play_to_discard | After all scoring/destruction callbacks, shuffles surviving played cards and inserts them at the bottom of the Small Deck. | Delegates for every other deck or when recycling is disabled. |
| G.FUNCS.discard_cards_from_highlighted | Records the exact discarded card IDs for the optional discard-recycling path. This path is currently disabled by the deck modifier. | With the modifier disabled, it only delegates. |
| G.FUNCS.draw_from_deck_to_hand | If optional discard recycling is enabled later, moves the recorded survivors before replacement-card draw size is calculated. | Current gameplay delegates to the original draw. |

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

### Deck Pack ownership proxies

| Ownership | Purpose | Non-Cartomancer behaviour |
| --- | --- | --- |
| j_certificate | Reproduces Certificate with an equal Red/Gold/Purple seal pool. | Delegates to the captured original calculation. |
| Selected Tarot centers | Supplies Cartomancer display values and the High Priestess/Judgement behaviours. | Delegates to an earlier explicit override when present, otherwise follows the included vanilla branch. |

## Lovely patches

lovely.toml contains seven source patches:

1. Define configurable interest basis, scale, and effective payout.
2. Use those values in the interest cash-out row.
3. Use them in the maximum-interest comparison.
4. Use them in the round-dollar total.
5. Show the same values in the cash-out UI.
6. Make Magic Trick shop cards use the enhanced-card pool.
7. Give Illusion an equal Edition-only, Seal-only, or both finish roll.

Every interest expression defaults to vanilla $5 basis and x1 scale when the
Balance Patch stake modifiers are absent.
