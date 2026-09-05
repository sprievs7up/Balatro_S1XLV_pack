return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Mazzo del cartomante",
                text = {
                    "Inizia la sessione con carte",
                    "{C:tarot}Tarocco{} potenziate, ma non puoi",
                    "ottenere carte {C:planet}Pianeta{} né",
                    "{C:blue,T:blue_seal}Sigilli blu{}",
                },
            },
            b_cartomancer_icebound = {
                name = "Mazzo del mare ghiacciato",
                text = {
                    "{C:blue}+#1#{} mani in ogni round",
                    "Inizia con {C:red}#2#{} scarti",
                    "Ottieni {C:money}$#4#{} ogni {C:attention}#3#{} mani rimaste",
                },
            },
            b_cartomancer_inferno = {
                name = "Mazzo infernale",
                text = {
                    "{s:0.8}{C:attention}+#1#{} carte della mano",
                    "{s:0.8}Inizia con:",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{} e {C:attention}#6#{}",
                    "{s:0.8}Ante iniziale {C:red}+#2#{}",
                    "{s:0.8}La prima {C:attention}mano di poker{} giocata",
                    "{s:0.8}ottiene {C:attention}+#7#{} livelli",
                },
            },
            b_cartomancer_small = {
                name = "Mazzo piccolo",
                text = {
                    "Inizia con {C:clubs}#1# Fiori{} e",
                    "{C:diamonds}#1# Quadri{} nel mazzo",
                    "Le carte giocate ritornano nel mazzo",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "La papessa",
                text = {
                    "Aumenta di {C:attention}#1#{} livelli la mano di poker",
                    "giocata nella mano precedente",
                },
            },
            c_cartomancer_judgement = {
                name = "Il giudizio",
                text = {
                    "Crea fino a {C:attention}#1#{}",
                    "{C:attention}Jolly{} casuali",
                    "{C:inactive}(Serve spazio)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Mani rimaste",
        },
    },
}
