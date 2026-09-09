return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "Колода картоманта",
                text = {
                    "Начинаете партию с усиленными",
                    "картами {C:tarot}Таро{}, но карты {C:planet}планет{}",
                    "и {C:blue,T:blue_seal}Синие печати{}",
                    "нельзя получить",
                },
            },
            b_cartomancer_icebound = {
                name = "Колода ледяного моря",
                text = {
                    "{C:blue}+#1#{} руки в каждом раунде",
                    "Начальное число сбросов: {C:red}#2#{}",
                    "Получайте {C:money}$#4#{} за каждые",
                    "{C:attention}#3#{} оставшиеся руки",
                },
            },
            b_cartomancer_inferno = {
                name = "Адская колода",
                text = {
                    "{s:0.8}{C:attention}+#1#{} размер руки",
                    "{s:0.8}Стартовые джокеры:",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{} и {C:attention}#6#{}",
                    "{s:0.8}Начальное анте {C:red}+#2#{}",
                    "{s:0.8}Уровень первой сыгранной {C:attention}покерной руки{}",
                    "{s:0.8}повышается на {C:attention}#7#{} уровня",
                    "{s:0.8}Дополнительно {C:money}$#8#{} на старте",
                },
            },
            b_cartomancer_small = {
                name = "Малая колода",
                text = {
                    "Начинаете с {C:clubs}#1# трефами{} и",
                    "{C:diamonds}#1# бубнами{} в колоде",
                    "Сыгранные карты возвращаются в колоду",
                    "Начинаете каждый раунд с",
                    "{C:red}#2#{} сбросами",
                },
            },
            b_cartomancer_grandmaster = {
                name = "Колода гроссмейстера",
                text = {
                    "Ячейки {C:attention}расходников{} можно",
                    "занимать {C:attention}джокерами{}",
                    "Каждые {C:red}#2#{} анте —",
                    "{C:attention}особый босс-блайнд{}",
                    "Анте для победы {C:red}+#1#{}",
                },
            },
            b_cartomancer_blank = {
                name = "    колода",
                text = {
                    "{C:inactive}Ничего не делает?",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "Верховная Жрица",
                text = {
                    "Повышает уровень покерной руки из",
                    "предыдущей руки на {C:attention}#1#{} уровня",
                },
            },
            c_cartomancer_judgement = {
                name = "Суд",
                text = {
                    "Создает до {C:attention}#1#{} случайных",
                    "карт {C:attention}джокера{}",
                    "{C:inactive}(должно быть место)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "Осталось рук",
        },
    },
}
