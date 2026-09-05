return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Deck Cartomancer",
                text = {
                    "Mulai giliran dengan kartu",
                    "{C:tarot}Tarot{} yang ditingkatkan, tetapi",
                    "kartu {C:planet}Planet{} dan {C:blue,T:blue_seal}Blue Seal{}",
                    "tidak dapat diperoleh",
                },
            },
            b_cartomancer_icebound = {
                name = "Icebound Deck",
                text = {
                    "{C:blue}+#1#{} hand setiap babak",
                    "Mulai dengan {C:red}#2#{} discard",
                    "Dapatkan {C:money}$#4#{} untuk setiap",
                    "{C:attention}#3#{} hand tersisa",
                },
            },
            b_cartomancer_inferno = {
                name = "Inferno Deck",
                text = {
                    "{s:0.8}{C:attention}+#1#{} ukuran hand",
                    "{s:0.8}Mulai dengan:",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{}, dan {C:attention}#6#{}",
                    "{s:0.8}Ante awal {C:red}+#2#{}",
                    "{s:0.8}{C:attention}Poker hand{} pertama yang dimainkan",
                    "{s:0.8}mendapat {C:attention}+#7#{} level",
                },
            },
            b_cartomancer_small = {
                name = "Small Deck",
                text = {
                    "Mulai dengan {C:clubs}#1# Keriting{} dan",
                    "{C:diamonds}#1# Wajik{} di deck",
                    "Kartu yang dimainkan kembali ke deck",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "The High Priestess",
                text = {
                    "Tingkatkan poker hand dari hand",
                    "sebelumnya sebanyak {C:attention}#1#{} level",
                },
            },
            c_cartomancer_judgement = {
                name = "Judgement",
                text = {
                    "Memunculkan hingga {C:attention}#1#{} kartu",
                    "{C:attention}Joker{} secara acak",
                    "{C:inactive}(Harus memiliki tempat)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Sisa Hands",
        },
    },
}
