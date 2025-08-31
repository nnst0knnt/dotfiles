function ccc_help
    echo "
🧹 ccc - Cyclic Cleanup Commands

[使用方法]
ccc [オプション]

[説明]
定期的に実行すべきシステムメンテナンスコマンドを選択して実行します。
矢印キー(↑↓)で選択し、Enterで実行できます。
※ fzfが必要です (https://github.com/junegunn/fzf)

[オプション]
-h, --help     このヘルプを表示
-q, --quiet    出力を最小限にする
-y, --yes      確認をスキップして実行（全コマンド実行）

[例]
ccc           # インタラクティブモードで起動
ccc -y        # 全コマンドを確認なしで実行"
end

function clear_memory_cache -d "システムのメモリキャッシュをクリア"
    set -l verbose $argv[1]

    if test "$verbose" = "true"
        set_color yellow
        echo "🗣️ メモリキャッシュをクリアしています..."
        set_color normal
		echo
    end

    if sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
		set_color green
		echo "✅ メモリキャッシュのクリアが完了しました"
		set_color normal
		echo
    else
        set_color red
        echo "⚠️  エラー：メモリキャッシュのクリアに失敗しました"
        set_color normal
		echo
    end
end

function update_packages -d "システムパッケージを更新"
    set -l verbose $argv[1]

    if test "$verbose" = "true"
        set_color yellow
        echo "🗣️ システムパッケージを更新しています..."
        set_color normal
		echo
    end

    if sudo apt update && sudo apt upgrade -y
		echo
		set_color green
		echo "✅ システムパッケージの更新が完了しました"
		set_color normal
		echo
    else
		echo
        set_color red
        echo "⚠️  エラー：システムパッケージの更新に失敗しました"
        set_color normal
		echo
    end
end

function run_all_commands -d "すべてのメンテナンスコマンドを実行"
    set -l verbose $argv[1]
    set -l commands $argv[2..-1]

    # 各コマンドを順番に実行
    for command in $commands
		$command $verbose
    end

    if test $status -eq 0
        set_color green
        echo "✅ すべてのメンテナンスコマンドが正常に完了しました"
        set_color normal
		echo
    else
        set_color yellow
		echo "⚠️ 一部のコマンドが正常に完了しませんでした"
        set_color normal
		echo
    end
end

function create_preview
    set -l index $argv[1]
    set -l title $argv[2]
    set -l description $argv[3]
    
    # 指定されたインデックスでプレビューファイルを作成
    echo "$title

$description" > "/tmp/ccc_preview_$index.txt"
end

function ccc -d "Cyclic Cleanup Commands - 定期的なシステムメンテナンス"
    # ヘルプオプションのチェック
    if contains -- "-h" $argv; or contains -- "--help" $argv
        ccc_help
        return 0
    end

    # 出力の詳細さの設定
    set -l verbose "true"
    if contains -- "-q" $argv; or contains -- "--quiet" $argv
        set verbose "false"
    end

    # -yフラグのチェック
    set -l yes_flag false
    if contains -- "-y" $argv; or contains -- "--yes" $argv
        set yes_flag true
    end

    # fzfの存在確認
    if not command -v fzf >/dev/null
		echo
        set_color red
        echo "⚠️  エラー：fzf がインストールされていません"
        echo "インストール方法：'sudo apt install fzf' または https://github.com/junegunn/fzf"
        set_color normal
		echo
        return 1
    end

    # コマンド定義
	# [関数名]:[タイトル]:[説明]
    set -l commands "clear_memory_cache:メモリキャッシュのクリア:システムのメモリキャッシュをクリアします" \
                     "update_packages:システムパッケージの更新:apt updateとapt upgradeを実行します" \
                     "run_all_commands:すべてのコマンドを実行:すべてのコマンドを順番に実行します"
	set -l command_names
	for command in $commands
		set -l command_name (string split -m 1 ":" $command)[1]

		if test "$command_name" != "run_all_commands"
			set -a command_names $command_name
		end
	end

    # -yフラグが指定されている場合は全コマンドを実行
    if test "$yes_flag" = "true"
		run_all_commands $verbose $command_names
        return 0
    end

	# 既存のプレビューファイルをクリーンアップ
	set file_list /tmp/ccc_preview_*.txt
	if count $file_list >/dev/null
		rm $file_list
	end

    # コマンド選択リストと説明を準備
    set -l task_options
    for i in (seq (count $commands))
        set -l parts (string split ":" $commands[$i])
        set -l function $parts[1]
        set -l title $parts[2]
        set -l description $parts[3]

        # コマンド選択リストに名前を追加
        set -a task_options $function

        # プレビューファイルを作成
        create_preview (expr $i - 1) $title $description
    end

    # 選択肢からコマンドを選択
    set -l selected_function (
        printf "%s\n" $task_options | \
        fzf --layout=reverse \
            --prompt="🧹 " \
            --no-info \
            --height=~70% \
            --preview="cat /tmp/ccc_preview_{n}.txt" \
            --preview-window=right:60%:wrap
    )

    # プレビューファイルを削除
    rm -f /tmp/ccc_preview_*.txt

    # 選択がキャンセルされた場合
    if test -z "$selected_function"
		echo
        echo "ℹ️  操作をキャンセルしました"
		echo
        return 0
    end

    # 選択されたコマンドを探して実行
    for i in (seq (count $commands))
        set -l parts (string split ":" $commands[$i])
        set -l function $parts[1]
        set -l title $parts[2]

        if test "$function" = "$selected_function"
            echo
            set_color yellow
            echo "🧹 $title"
            set_color normal
            echo

            $function $verbose $command_names

            return 0
        end
    end

    return 1
end
