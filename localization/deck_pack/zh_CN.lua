return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "占卜师牌组",
                text = {
                    "在增强版的{C:tarot}塔罗牌{}中开始游戏",
                    "但不再获取{C:planet}星球牌{}",
                    "以及{C:blue,T:blue_seal}蓝色蜡封{}",
                },
            },
            b_cartomancer_icebound = {
                name = "冻洋牌组",
                text = {
                    "每回合{C:blue}+#1#{}次出牌",
                    "初始弃牌次数为{C:red}#2#{}",
                    "每剩余{C:attention}#3#{}次出牌获得{C:money}$#4#{}",
                },
            },
            b_cartomancer_inferno = {
                name = "炼狱牌组",
                text = {
                    "{s:0.8}手牌上限{C:attention}+#1#{}",
                    "{s:0.8}初始获得{C:attention}#3#{}、{C:attention}#4#{}、",
                    "{s:0.8}{C:attention}#5#{}、{C:attention}#6#{}",
                    "{s:0.8}游戏底注{C:red}+#2#{}",
                    "{s:0.8}第一手出牌的牌型",
                    "{s:0.8}等级{C:attention}+#7#{}",
                },
            },
            b_cartomancer_small = {
                name = "小牌组",
                text = {
                    "开局时，牌组有{C:clubs}#1#张梅花{}",
                    "和{C:diamonds}#1#张方块{}",
                    "出牌手牌会返回牌堆",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "女祭司",
                text = {
                    "将上一手出牌的",
                    "牌型等级提升{C:attention}#1#级{}",
                },
            },
            c_cartomancer_judgement = {
                name = "审判",
                text = {
                    "生成最多{C:attention}#1#张",
                    "随机{C:attention}小丑牌{}",
                    "{C:inactive}（必须有空位）",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "剩余出牌次数",
        },
    },
}
