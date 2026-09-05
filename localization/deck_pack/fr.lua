return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Jeu du cartomancien",
                text = {
                    "Commencez la partie avec des cartes",
                    "de {C:tarot}Tarot{} améliorées, mais les cartes",
                    "{C:planet}Planète{} et les {C:blue,T:blue_seal}Sceaux bleus{}",
                    "ne peuvent pas être obtenus",
                },
            },
            b_cartomancer_icebound = {
                name = "Jeu de la mer gelée",
                text = {
                    "{C:blue}+#1#{} mains à chaque manche",
                    "Commencez avec {C:red}#2#{} défausses",
                    "Gagnez {C:money}$#4#{} par groupe de",
                    "{C:attention}#3#{} mains restantes",
                },
            },
            b_cartomancer_inferno = {
                name = "Jeu infernal",
                text = {
                    "{s:0.8}{C:attention}+#1#{} à la taille de la main",
                    "{s:0.8}Commencez avec :",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{} et {C:attention}#6#{}",
                    "{s:0.8}Mise initiale {C:red}+#2#{}",
                    "{s:0.8}La première {C:attention}main de poker{} jouée",
                    "{s:0.8}gagne {C:attention}+#7#{} niveaux",
                },
            },
            b_cartomancer_small = {
                name = "Petit jeu",
                text = {
                    "Commencez avec {C:clubs}#1# Trèfles{} et",
                    "{C:diamonds}#1# Carreaux{} dans votre jeu",
                    "Les cartes jouées reviennent dans le jeu",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "La Papesse",
                text = {
                    "Améliore de {C:attention}#1#{} niveaux la main de poker",
                    "jouée lors de la main précédente",
                },
            },
            c_cartomancer_judgement = {
                name = "Le Jugement",
                text = {
                    "Crée jusqu'à {C:attention}#1#{} cartes",
                    "{C:attention}Joker{} aléatoires",
                    "{C:inactive}(Selon la place disponible)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Mains restantes",
        },
    },
}
