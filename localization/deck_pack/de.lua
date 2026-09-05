return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Kartomanten-Deck",
                text = {
                    "Beginne den Durchlauf mit verstärkten",
                    "{C:tarot}Tarot{}-Karten, aber {C:planet}Planeten{}-Karten",
                    "und {C:blue,T:blue_seal}Blaue Siegel{} sind nicht erhältlich",
                },
            },
            b_cartomancer_icebound = {
                name = "Eismeer-Deck",
                text = {
                    "Jede Runde {C:blue}+#1#{} Hände",
                    "Beginne mit {C:red}#2#{} Abwürfen",
                    "{C:money}$#4#{} pro {C:attention}#3#{} verbleibende Hände",
                },
            },
            b_cartomancer_inferno = {
                name = "Inferno-Deck",
                text = {
                    "{s:0.8}{C:attention}+#1#{} Handgröße",
                    "{s:0.8}Beginne mit:",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{} und {C:attention}#6#{}",
                    "{s:0.8}Start-Ante {C:red}+#2#{}",
                    "{s:0.8}Die erste gespielte {C:attention}Pokerhand{}",
                    "{s:0.8}erhält {C:attention}+#7#{} Stufen",
                },
            },
            b_cartomancer_small = {
                name = "Kleines Deck",
                text = {
                    "Beginne mit {C:clubs}#1# Kreuz-Karten{} und",
                    "{C:diamonds}#1# Karo-Karten{} im Deck",
                    "Gespielte Karten kehren ins Deck zurück",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "Die Hohepriesterin",
                text = {
                    "Wertet die Pokerhand aus der vorherigen",
                    "Hand um {C:attention}#1#{} Stufen auf",
                },
            },
            c_cartomancer_judgement = {
                name = "Gericht",
                text = {
                    "Lässt bis zu {C:attention}#1#{} zufällige",
                    "{C:attention}Joker{}-Karten erscheinen",
                    "{C:inactive}(Muss Platz haben)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Verbleibende Hände",
        },
    },
}
