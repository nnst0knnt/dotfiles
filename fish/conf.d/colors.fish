# 基本色：ほぼ全て白で統一
set -g fish_color_command white                       # コマンド：白
set -g fish_color_param white                         # 引数：白
set -g fish_color_option white                        # オプション：白
set -g fish_color_quote white                         # 文字列：白
set -g fish_color_operator white                      # 演算子：白
set -g fish_color_redirection white                   # リダイレクト：白
set -g fish_color_end white                           # セミコロン等：白
set -g fish_color_valid_path white '--underline'      # 有効なパス：白に下線
set -g fish_color_cwd white                           # カレントディレクトリ：白
set -g fish_color_user white                          # ユーザー名：白
set -g fish_color_host white                          # ホスト名：白
set -g fish_color_host_remote white                   # リモートホスト：白
set -g fish_color_normal white                        # 通常テキスト：白
set -g fish_color_escape white                        # エスケープ文字：白

# エラー・警告のみ赤
set -g fish_color_error brred                         # エラー：明るい赤
set -g fish_color_cwd_root brred                      # rootディレクトリ：明るい赤
set -g fish_color_status brred                        # ステータス：明るい赤
set -g fish_color_cancel brred '--reverse'            # キャンセル：反転赤

# 控えめ要素のみグレー
set -g fish_color_comment 666666                      # コメント：グレー
set -g fish_color_autosuggestion 666666               # 自動補完：グレー

# 履歴・検索
set -g fish_color_history_current white '--bold'      # 履歴現在行：太字白
set -g fish_color_search_match white '--background=444444'      # 検索マッチ：白
set -g fish_color_selection white '--background=444444'        # 選択範囲：白
