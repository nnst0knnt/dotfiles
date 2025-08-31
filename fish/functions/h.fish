function h_help
	echo "
📚 h - コマンドヘルプ表示ツール

[使用方法]
h [オプション] [コマンド名]

[説明]
自作コマンドのヘルプを表示します。
関数名_helpとしてヘルプ関数を作成することで、ヘルプを表示できます。
コマンドを追加した場合は、`known_commands`に関数名を追加してください。

[オプション]
-h, --help     このヘルプを表示
-a, --all      すべてのコードを表示

[例]
h             # インタラクティブモードで起動
h counter     # counterコマンドのヘルプを表示"
end

function h --description "自作コマンドのヘルプを表示"
    # オプションの解析
    argparse 'h/help' 'a/all' -- $argv
    or return

    if set -q _flag_help
        h_help
        return 0
    end

    # 自作コマンドとして認識するリスト
    set -l known_commands clip counter killer open reauthor rebase repeat revert ccc h

    # コマンド一覧を取得して自作コマンドのみをフィルタリング
    set -l custom_commands
    for cmd in $known_commands
        if functions -q $cmd
            set -l description (functions -Dv $cmd)
            if test -n "$description"
                set -a custom_commands $cmd
            end
        end
    end

    # コマンド名の取得
    set -l target_command
    if test (count $argv) -eq 1
        set target_command $argv[1]
    else if test (count $argv) -eq 0
		# インタラクティブモード表示
		echo "
┌──────────────────────────────────┐
│         🛠️  コマンド一覧         │
└──────────────────────────────────┘"
		echo
		for cmd in $custom_commands
			echo "  $cmd"
		end

		echo
        read -l -P "ヘルプを表示するコマンドを入力 > " cmd_input
		
        if test -n "$cmd_input"
            set target_command $cmd_input
        else
            echo "ℹ️  操作をキャンセルしました"
            return 0
        end
    else
        set_color red
        echo "⚠️  エラー：コマンド名を1つ指定してください"
        set_color normal
        return 1
    end

    # コマンドの存在確認
    if not contains $target_command $custom_commands
        set_color red
        echo "⚠️  エラー：コマンド '$target_command' が見つかりません"
        set_color normal
        return 1
    end

    # ヘルプ表示の処理
	set -l help_command "$target_command"_help
    set -l has_help (functions -v $help_command)
    set -l description (functions -Dv $target_command)

    if set -q _flag_all
        # すべての内容を表示
        functions $target_command
    else
        if test -n "$has_help"
			# ヘルプが定義されている場合はヘルプコマンドを実行
			$help_command
			echo ""
        else
            # ヘルプが定義されていない場合
            printf "\n┌─ ℹ️  %s ───────────────────────────────────────────\n" $target_command
            printf "│\n"
            printf "│ %s\n" $description
            printf "│\n"
            printf "│ 詳細なヘルプは定義されていません。\n"
            printf "│ ソースコードを確認するには：functions %s\n" $target_command
            printf "│\n"
            printf "└────────────────────────────────────────────────────────────\n"
        end
    end
end
