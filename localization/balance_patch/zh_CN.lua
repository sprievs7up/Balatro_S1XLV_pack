return {
    descriptions = {
        Joker = {
            j_mystic_summit = {
                text = {
                    "当剩余{C:attention}#2#{}次弃牌时",
                    "{C:chips}+#1#{}筹码",
                },
            },
            j_8_ball = {
                text = {
                    "打出的每一张{C:attention}8{}",
                    "有{C:green}#1#/#2#{}几率在计分时",
                    "生成{C:attention}#3#{}张{C:tarot}愚者{}",
                    "{C:inactive}（必须有空位）",
                },
            },
            j_seance = {
                text = {
                    "如果{C:attention}牌型{}为{C:attention}#1#{}，",
                    "随机生成一张{C:dark_edition}负片{}",
                    "{C:spectral}幻灵牌{}",
                },
            },
            j_hiker = {
                text = {
                    "打出的每一张牌",
                    "在{C:attention}计分{}时",
                    "会永久获得{C:mult}+#1#{}倍率",
                },
            },
            j_matador = {
                text = {
                    "{C:attention}Boss盲注{}的能力每次触发时",
                    "获得{C:money}$#1#{}",
                },
            },
            j_superposition = {
                text = {
                    "如果打出的牌中包含",
                    "一张{C:attention}A{}和一个{C:attention}顺子{}",
                    "生成上一次使用的{C:tarot}塔罗牌{}/",
                    "{C:planet}星球牌{}的{C:dark_edition}负片{}版本",
                },
            },
            j_flower_pot = {
                text = {
                    "得分牌有{C:attention}2{}种花色时{X:mult,C:white}X#1#{}倍率",
                    "得分牌有{C:attention}3{}种花色时{X:mult,C:white}X#2#{}倍率",
                    "得分牌有{C:attention}4{}种花色时{X:mult,C:white}X#3#{}倍率",
                },
            },
            j_to_the_moon = {
                text = {
                    "回合结束时，每持有{C:money}$#2#{}",
                    "额外获得{C:money}$#1#{}{C:attention}利息{}",
                },
            },
        },
        Voucher = {
            v_magic_trick = {
                text = {
                    "商店中有{C:enhanced}加强版游戏牌{}",
                    "可供选购",
                },
            },
            v_illusion = {
                text = {
                    "商店中的{C:enhanced}加强版游戏牌{}",
                    "必定拥有{C:dark_edition}不同版本{}",
                    "和/或{C:attention}蜡封{}",
                },
            },
            v_seed_money = {
                text = {
                    "将每回合可获得的",
                    "{C:attention}利息{}上限提高至{C:money}$#1#{}",
                },
            },
            v_money_tree = {
                text = {
                    "将每回合可获得的",
                    "{C:attention}利息{}上限提高至{C:money}$#1#{}",
                },
            },
        },
        Stake = {
            stake_blue = {
                text = {
                    "商店可能出现{C:attention}易腐{}小丑牌",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_orange = {
                text = {
                    "商店可能出现{C:attention}租赁{}小丑牌",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
            stake_gold = {
                text = {
                    "每持有{C:money}$10{}获得{C:money}$2{}利息",
                    "基础利息每回合上限为{C:money}$4{}",
                    "{s:0.8}之前所有赌注也都起效",
                },
            },
        },
    },
    misc = {
        dictionary = {
            k_bbp_one_fool = "+1张愚者！",
            k_bbp_negative_only = "生成负片！",
        },
    },
}
