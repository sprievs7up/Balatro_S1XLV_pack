return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "占卜師牌組",
                text = {
                    "在強化版的{C:tarot}塔羅牌{}中開始遊戲",
                    "但不再獲得{C:planet}行星牌{}",
                    "以及{C:blue,T:blue_seal}藍色封蠟章{}",
                },
            },
            b_cartomancer_icebound = {
                name = "冰洋牌組",
                text = {
                    "每一回合{C:blue}+#1#{}次出牌",
                    "初始棄牌次數為{C:red}#2#{}",
                    "每剩餘{C:attention}#3#{}次出牌獲得{C:money}$#4#{}",
                },
            },
            b_cartomancer_inferno = {
                name = "煉獄牌組",
                text = {
                    "{s:0.8}手牌上限{C:attention}+#1#{}",
                    "{s:0.8}初始獲得{C:attention}#3#{}、{C:attention}#4#{}、",
                    "{s:0.8}{C:attention}#5#{}、{C:attention}#6#{}",
                    "{s:0.8}遊戲底注{C:red}+#2#{}",
                    "{s:0.8}第一手出牌的牌型",
                    "{s:0.8}等級{C:attention}+#7#{}",
                },
            },
            b_cartomancer_small = {
                name = "小牌組",
                text = {
                    "開局時，牌組有{C:clubs}#1#張梅花{}",
                    "和{C:diamonds}#1#張方塊{}",
                    "打出的牌會返回牌組",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "女祭司",
                text = {
                    "將上一手出牌的",
                    "牌型等級提升{C:attention}#1#級{}",
                },
            },
            c_cartomancer_judgement = {
                name = "審判",
                text = {
                    "產生最多{C:attention}#1#張",
                    "隨機{C:attention}小丑牌{}",
                    "{C:inactive}(必須有空位)",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "剩餘出牌次數",
        },
    },
}
