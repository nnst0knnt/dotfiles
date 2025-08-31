function reauthor_help
	echo "
✒️ reauthor - Git Committer変更ツール

[使用方法]
reauthor <開始コミット>

[説明]
指定したコミットから現在までの範囲で、CommitterをAuthorと同じ値に設定し直します。

[オプション]
-h, --help     このヘルプを表示

[例]
reauthor HEAD~3  # 3つ前のコミットから変更
reauthor abc123  # 特定のコミットハッシュから変更"
end

function reauthor -d "指定コミット以降のCommitterをAuthorに変更" 
    # ヘルプオプションのチェック
    if contains -- "-h" $argv; or contains -- "--help" $argv
        reauthor_help
        return 0
    end

    # 引数チェック
    if test (count $argv) -ne 1
        set_color red
        echo "⚠️  エラー：開始コミットを1つ指定してください"
        set_color normal
        echo
        reauthor_help
        return 1
    end

    set -l start_commit $argv[1]

    # Gitリポジトリチェック
    if not git rev-parse --git-dir >/dev/null 2>&1
        set_color red
        echo "⚠️  エラー：カレントディレクトリはGitリポジトリではありません"
        set_color normal
        return 1
    end

    # コミットの存在確認
    if not git rev-parse --verify $start_commit >/dev/null 2>&1
        set_color red
        echo "⚠️  エラー：指定されたコミット '$start_commit' が見つかりません"
        set_color normal
        return 1
    end

    # Gitリポジトリのルートディレクトリに移動
    set -l git_root (git rev-parse --show-toplevel)
    if test $status -ne 0
        set_color red
        echo "⚠️  エラー：Gitリポジトリのルートディレクトリを特定できません"
        set_color normal
        return 1
    end

    # 現在のディレクトリを保存
    set -l current_dir (pwd)

    # リポジトリのルートに移動
    cd $git_root

    set_color yellow
    echo "🔄 Committerの情報を更新しています..."
    set_color normal

    # 環境変数を設定
    set -x FILTER_BRANCH_SQUELCH_WARNING 1

    # git filter-branchを実行
    if git filter-branch --force --env-filter '
        if [ "$GIT_COMMITTER_EMAIL" != "$GIT_AUTHOR_EMAIL" ]; then
            export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
            export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
        fi
    ' -- "$start_commit"..HEAD

        set_color green
        echo "✅ Committer情報の更新が完了しました"
    else
        set_color red
        echo "⚠️  エラー：Committer情報の更新に失敗しました"
        set_color normal
        cd $current_dir
        return 1
    end

    # 環境変数を解除
    set -e FILTER_BRANCH_SQUELCH_WARNING

    # 元のディレクトリに戻る
    cd $current_dir
end
