BBP_TO_THE_MOON = BBP_TO_THE_MOON or {}
local M = BBP_TO_THE_MOON

M.INTEREST_BASIS = 5

local function center_key(card)
    return card
        and card.config
        and (card.config.center_key or (card.config.center and card.config.center.key))
end

local function is_to_the_moon(card)
    return center_key(card) == 'j_to_the_moon'
        or (card and card.ability and card.ability.name == 'To the Moon')
end

local function card_rate(card)
    local extra = card and card.ability and card.ability.extra
    return math.max(0, tonumber(extra) or 1)
end

local function neutralize_vanilla_interest_delta(card, direction)
    if not (G and G.GAME) or not is_to_the_moon(card) then return end

    -- Vanilla folds To the Moon into interest_amount. Undo that delta so the
    -- ordinary capped interest calculation remains completely independent.
    G.GAME.interest_amount = (G.GAME.interest_amount or 0)
        - (tonumber(direction) or 0) * card_rate(card)
end

local function active_to_the_moon_cards()
    if not G then return {}, 0 end

    local cards = {}
    local rate = 0
    local seen = {}
    local areas = {}
    if G.jokers then areas[#areas + 1] = G.jokers end
    if G.consumeables then areas[#areas + 1] = G.consumeables end

    for _, area in ipairs(areas) do
        for _, card in ipairs((area and area.cards) or {}) do
            if not seen[card]
                and is_to_the_moon(card)
                and card.added_to_deck == true
                and not card.debuff then
                cards[#cards + 1] = card
                local bulky_repetitions = card.ability
                    and card.ability.bsk_bulky and 2 or 1
                rate = rate + card_rate(card) * bulky_repetitions
            end
            seen[card] = true
        end
    end
    return cards, rate
end

function M.round_bonus(dollars)
    if not (G and G.GAME) then return 0 end

    local cards, rate = active_to_the_moon_cards()
    local held_dollars = math.max(0, tonumber(dollars) or 0)
    local payout = rate * math.floor(held_dollars / M.INTEREST_BASIS)
    if payout <= 0 then return 0 end
    return payout, cards[1]
end

local function install_hooks()
    if M.hooks_installed then return end
    M.hooks_installed = true

    M.card_add_to_deck = Card.add_to_deck
    function Card:add_to_deck(from_debuff)
        local was_added = self.added_to_deck
        local result = M.card_add_to_deck(self, from_debuff)
        if not was_added and self.added_to_deck then
            neutralize_vanilla_interest_delta(self, 1)
        end
        return result
    end

    M.card_remove_from_deck = Card.remove_from_deck
    function Card:remove_from_deck(from_debuff)
        local was_added = self.added_to_deck
        local result = M.card_remove_from_deck(self, from_debuff)
        if was_added and not self.added_to_deck then
            neutralize_vanilla_interest_delta(self, -1)
        end
        return result
    end
end

function M.register(take_joker)
    install_hooks()
    take_joker('to_the_moon', {
        config = { extra = 1 },
        cost = 8,
        loc_vars = function(self, info_queue, card)
            local extra = card and card.ability and card.ability.extra
                or self.config.extra
            return { vars = { extra, M.INTEREST_BASIS } }
        end,
    })
end

return M
