return {
    descriptions = {
        Joker = {
            j_mystic_summit = {
                text = {
                    "剩餘{C:attention}#2#{}次棄牌時",
                    "{C:chips}+#1#{}籌碼",
                },
            },
            j_8_ball = {
                text = {
                    "每張打出的{C:attention}8{}計分時",
                    "有{C:green}#1#/#2#{}機率產生",
                    "{C:attention}#3#{}張{C:tarot}愚者{}",
                    "{C:inactive}(必須有空位)",
                },
            },
            j_seance = {
                text = {
                    "如果{C:attention}手牌{}為{C:attention}#1#{}，",
                    "即產生一張隨機的",
                    "{C:dark_edition}負片{}{C:spectral}幻靈牌{}",
                },
            },
            j_hiker = {
                text = {
                    "每張打出的{C:attention}牌{}",
                    "在計分時永久獲得",
                    "{C:mult}+#1#{}倍數",
                },
            },
            j_matador = {
                text = {
                    "{C:attention}Boss盲注{}的能力每次觸發時",
                    "獲得{C:money}$#1#{}",
                },
            },
            j_superposition = {
                text = {
                    "若牌型包含{C:attention}A{}及{C:attention}順子{}，",
                    "產生上一張使用的{C:tarot}塔羅牌{}或",
                    "{C:planet}行星牌{}的{C:dark_edition}負片{}版本",
                },
            },
            j_flower_pot = {
                text = {
                    "計分牌有{C:attention}2{}種花色時，倍數{X:mult,C:white}X#1#{}",
                    "計分牌有{C:attention}3{}種花色時，倍數{X:mult,C:white}X#2#{}",
                    "計分牌有{C:attention}4{}種花色時，倍數{X:mult,C:white}X#3#{}",
                },
            },
            j_to_the_moon = {
                text = {
                    "每回合結束時，每擁有{C:money}$#2#{}",
                    "即可額外獲得{C:money}$#1#{}{C:attention}利息{}",
                },
            },
        },
        Voucher = {
            v_magic_trick = {
                text = {
                    "商店中有{C:enhanced}加強版遊戲牌{}",
                    "可供選購",
                },
            },
            v_illusion = {
                text = {
                    "商店中的{C:enhanced}加強版遊戲牌{}",
                    "必定擁有{C:dark_edition}不同版本{}",
                    "和/或{C:attention}封蠟章{}",
                },
            },
            v_seed_money = {
                text = {
                    "將每回合可獲得的",
                    "利息上限提高至{C:money}$#1#{}",
                },
            },
            v_money_tree = {
                text = {
                    "將每回合可獲得的",
                    "利息上限提高至{C:money}$#1#{}",
                },
            },
        },
        Stake = {
            stake_blue = {
                text = {
                    "商店可能出現{C:attention}非保久{}小丑",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_orange = {
                text = {
                    "商店可能出現{C:attention}租賃{}小丑",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
            stake_gold = {
                text = {
                    "每擁有{C:money}$10{}可獲得{C:money}$2{}利息",
                    "基本利息每回合上限為{C:money}$4{}",
                    "{s:0.8}適用於所有先前的賭注",
                },
            },
        },
    },
    misc = {
        dictionary = {
            k_bbp_one_fool = "+1張愚者！",
            k_bbp_negative_only = "產生負片！",
        },
    },
}
