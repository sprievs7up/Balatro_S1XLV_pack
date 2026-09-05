return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Baraja de cartomante",
                text = {
                    "Comienza la partida con cartas",
                    "de {C:tarot}Tarot{} mejoradas, pero no puedes",
                    "obtener cartas de {C:planet}planeta{} ni",
                    "{C:blue,T:blue_seal}sellos azules{}",
                },
            },
            b_cartomancer_icebound = {
                name = "Baraja del mar helado",
                text = {
                    "{C:blue}+#1#{} manos en cada ronda",
                    "Empiezas con {C:red}#2#{} descartes",
                    "Gana {C:money}$#4#{} por cada {C:attention}#3#{} manos restantes",
                },
            },
            b_cartomancer_inferno = {
                name = "Baraja infernal",
                text = {
                    "{s:0.8}{C:attention}+#1#{} tamaño de mano",
                    "{s:0.8}Empiezas con:",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{} y {C:attention}#6#{}",
                    "{s:0.8}Apuesta inicial {C:red}+#2#{}",
                    "{s:0.8}La primera {C:attention}mano de póker{} jugada",
                    "{s:0.8}gana {C:attention}+#7#{} niveles",
                },
            },
            b_cartomancer_small = {
                name = "Baraja pequeña",
                text = {
                    "Comienza con {C:clubs}#1# tréboles{} y",
                    "{C:diamonds}#1# diamantes{} en la baraja",
                    "Las cartas jugadas vuelven a la baraja",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "La sacerdotisa",
                text = {
                    "Sube {C:attention}#1#{} niveles la mano de póker",
                    "jugada en la mano anterior",
                },
            },
            c_cartomancer_judgement = {
                name = "El juicio",
                text = {
                    "Genera hasta {C:attention}#1#{} cartas",
                    "de {C:attention}comodín{} al azar",
                    "{C:inactive}(Debe haber espacio)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Manos restantes",
        },
    },
}
