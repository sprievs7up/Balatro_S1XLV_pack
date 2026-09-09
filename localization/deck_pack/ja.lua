return {
    descriptions = {
        Back = {
            b_cartomancer_deck = {
                name = "占い師デッキ",
                text = {
                    "強化された{C:tarot}タロット{}カードで",
                    "ランをスタートするが、{C:planet}惑星{}カードと",
                    "{C:blue,T:blue_seal}ブルーシール{}は入手できない",
                },
            },
            b_cartomancer_icebound = {
                name = "氷海デッキ",
                text = {
                    "すべてのラウンドでハンド {C:blue}+#1#{}",
                    "初期ディスカード回数は{C:red}#2#{}",
                    "残りハンド{C:attention}#3#{}回ごとに{C:money}$#4#{}",
                },
            },
            b_cartomancer_inferno = {
                name = "インフェルノデッキ",
                text = {
                    "{s:0.8}ハンドサイズ {C:attention}+#1#{}",
                    "{s:0.8}{C:attention}#3#{}、{C:attention}#4#{}、",
                    "{s:0.8}{C:attention}#5#{}、{C:attention}#6#{}で開始",
                    "{s:0.8}開始アンティ {C:red}+#2#{}",
                    "{s:0.8}最初にプレイした{C:attention}ポーカーハンド{}の",
                    "{s:0.8}レベルを {C:attention}#7#{} 上げる",
                    "{s:0.8}所持金 {C:money}$#8#{} を追加で所持して開始",
                },
            },
            b_cartomancer_small = {
                name = "スモールデッキ",
                text = {
                    "デッキに {C:clubs}#1# 枚のクラブ{} と",
                    "{C:diamonds}#1# 枚のダイヤ{} がある状態で開始",
                    "プレイしたカードはデッキに戻る",
                    "各ラウンドの開始時に",
                    "{C:red}#2#{}回ディスカード可能",
                },
            },
            b_cartomancer_grandmaster = {
                name = "グランドマスターデッキ",
                text = {
                    "{C:attention}消耗品{}スロットに",
                    "{C:attention}ジョーカー{}を置ける",
                    "{C:red}#2#{}アンティごとに",
                    "{C:attention}特別なボスブラインド{}が出現",
                    "勝利アンティ {C:red}+#1#{}",
                },
            },
            b_cartomancer_blank = {
                name = "    デッキ",
                text = {
                    "{C:inactive}何もしない？",
                },
            },
        },
        Tarot = {
            c_cartomancer_high_priestess = {
                name = "女教皇",
                text = {
                    "直前のハンドでプレイしたポーカーハンドの",
                    "レベルを {C:attention}#1#{} 上げる",
                },
            },
            c_cartomancer_judgement = {
                name = "審判",
                text = {
                    "ランダムな {C:attention}ジョーカー{} カードを",
                    "最大 {C:attention}#1#{} 枚まで作る",
                    "{C:inactive}（空きが必要）",
                },
            },
        },
    },
    misc = {
        dictionary = {
            s1xlv_icebound_remaining_hands = "残りのハンド",
        },
    },
}
