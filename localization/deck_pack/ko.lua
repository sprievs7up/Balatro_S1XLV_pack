return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "점술가 덱",
                text = {
                    "강화된 {C:tarot}타로{} 카드로 런을 시작하지만",
                    "{C:planet}행성{} 카드와 {C:blue,T:blue_seal}블루 봉인{}은",
                    "획득할 수 없습니다",
                },
            },
            b_cartomancer_icebound = {
                name = "빙해 덱",
                text = {
                    "라운드마다 {C:blue}+#1#{} 핸드",
                    "초기 버리기 횟수는 {C:red}#2#{}회",
                    "남은 핸드 {C:attention}#3#{}회당 {C:money}$#4#{} 획득",
                },
            },
            b_cartomancer_inferno = {
                name = "인페르노 덱",
                text = {
                    "{s:0.8}{C:attention}+#1#{} 핸드 크기",
                    "{s:0.8}{C:attention}#3#{}, {C:attention}#4#{},",
                    "{s:0.8}{C:attention}#5#{}, {C:attention}#6#{}로 시작",
                    "{s:0.8}시작 앤티 {C:red}+#2#{}",
                    "{s:0.8}처음 플레이한 {C:attention}포커 핸드{}의",
                    "{s:0.8}레벨을 {C:attention}#7#{} 올립니다",
                },
            },
            b_cartomancer_small = {
                name = "소형 덱",
                text = {
                    "덱에 {C:clubs}#1#장의 클럽{}과",
                    "{C:diamonds}#1#장의 다이아몬드{}로 시작합니다",
                    "플레이한 카드는 덱으로 돌아갑니다",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "고위 여사제",
                text = {
                    "이전 핸드에서 플레이한 포커 핸드의",
                    "레벨을 {C:attention}#1#{} 올립니다",
                },
            },
            c_cartomancer_judgement = {
                name = "심판",
                text = {
                    "무작위 {C:attention}조커{} 카드를",
                    "최대 {C:attention}#1#{}장 생성합니다",
                    "{C:inactive}(공간이 있어야 합니다)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "남은 핸드",
        },
    },
}
