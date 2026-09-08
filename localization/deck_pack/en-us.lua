return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Cartomancer Deck",
                text = {
                    "Start a run with enhanced {C:tarot}Tarot cards{}",
                    "but {C:planet}Planet cards{} and",
                    "{C:blue,T:blue_seal}Blue Seals{} cannot be obtained",
                },
            },
            b_cartomancer_icebound = {
                name = "Icebound Deck",
                text = {
                    "{C:blue}+#1#{} hands every round",
                    "Start with {C:red}#2#{} discards",
                    "Earn {C:money}$#4#{} per {C:attention}#3#{} remaining hands",
                },
            },
            b_cartomancer_inferno = {
                name = "Inferno Deck",
                text = {
                    "{s:0.8}{C:attention}+#1#{} hand size",
                    "{s:0.8}Start with {C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{}, and {C:attention}#6#{}",
                    "{s:0.8}Starting Ante {C:red}+#2#{}",
                    "{s:0.8}The first played {C:attention}poker hand{}",
                    "{s:0.8}gains {C:attention}+#7#{} levels",
                    "{s:0.8}Start with an extra {C:money}$#8#{}",
                },
            },
            b_cartomancer_small = {
                name = "Small Deck",
                text = {
                    "Start with {C:clubs}#1# Clubs{} and",
                    "{C:diamonds}#1# Diamonds{}",
                    "Played cards return to the deck",
                    "Start each round with",
                    "{C:red}#2#{} discards",
                },
            },
            b_cartomancer_grandmaster = {
                name = "Grand Master Deck",
                text = {
                    "{C:attention}Consumable{} slots can be used as",
                    "{C:attention}Joker{} slots",
                    "Face a {C:attention}special Boss Blind{}",
                    "every {C:red}#2#{} Antes",
                    "Win Ante {C:red}+#1#{}",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "The High Priestess",
                text = {
                    "Upgrade the poker hand played",
                    "in the previous hand by {C:attention}#1#{} levels",
                },
            },
            c_cartomancer_judgement = {
                name = "Judgement",
                text = {
                    "Creates up to {C:attention}#1#{} random",
                    "{C:attention}Joker{} cards",
                    "{C:inactive}(Must have room)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Remaining Hands",
        },
    },
}
