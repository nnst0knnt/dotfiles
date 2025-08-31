function rebase_help
	echo "
🌴 rebase - リベース自動修正ツール

[使用方法]
rebase [オプション] [コミットハッシュ]

[説明]
指定した範囲のコミットのリベースを行います。
引数を指定しない場合は、派生元のコミットハッシュを自動検出します。
デフォルトでは指定したコミットの次から HEAD まで処理されます。

[オプション]
-h, --help            このヘルプを表示
-b, --base REF        比較元のブランチを指定（デフォルト：main/master）
-d, --date STR        設定する日時を指定（例：'Sat Mar 22 00:00:00 2025 +0900'）
-a, --author-date     コミット日時を Author の日時に合わせるか（デフォルト：true）
-r, --root            指定したコミット自体も処理対象に含める

[例]
rebase                                                # ブランチの派生元を自動検出してリベース
rebase abc123                                         # 指定したコミットの次から順にリベース
rebase -r abc123                                      # 指定したコミット自体も含めてリベース
rebase -d 'Sat Mar 22 00:00:00 2025 +0900'            # 日時を指定して更新
rebase -b develop -d 'Sun Mar 23 20:50:46 2025 +0900' # developブランチからの派生元から順にリベースし指定した日時に更新"
end

function rebase -d "Gitコミットの日時を変更してリベースを実行"
    # argparseを使用してオプションを解析
    argparse 'h/help' 'b/base=' 'd/date=' 'a/author-date' 'r/root' -- $argv
    or return

    # ヘルプオプションのチェック
    if set -q _flag_help
        rebase_help
        return 0
    end

    # Gitリポジトリであることを確認
    if not git rev-parse --git-dir >/dev/null 2>&1
        set_color red
        echo "⚠️  エラー：カレントディレクトリはGitリポジトリではありません"
        set_color normal
        return 1
    end

    # dateオプションとauthor-dateオプションの両方を指定している場合はエラー
    if set -q _flag_date && set -q _flag_author_date
        set_color red
        echo "⚠️  エラー：date オプションと author-date オプションは同時に指定できません"
        set_color normal
        return 1
    end

    # 日時の設定
    set -l date_str
    set -l date_mode "author"  # どの日時に合わせるかのモード
    if set -q _flag_date
        set date_str $_flag_date
        set date_mode "fixed"
    else if set -q _flag_author_date
        set date_mode "author"
    else
        # フォールバック
        # 現在の日時をGitが認識できる英語フォーマットで設定
        # LC_TIMEを一時的に英語に変更して日付を取得
        set date_str (env LC_TIME=C date "+%a %b %d %H:%M:%S %Y %z")
        set date_mode "fixed"
    end

    # コミットハッシュの取得
    set -l commit_hash

    # コマンドライン引数からコミットハッシュを取得
    if test (count $argv) -eq 1
        set commit_hash $argv[1]
    else
        # 比較元のブランチを決定
        set -l base_branch
        if set -q _flag_base
            set base_branch $_flag_base
        else
            # デフォルトのブランチを探索（main か master）
            if git show-ref --verify --quiet refs/heads/main
                set base_branch "main"
            else if git show-ref --verify --quiet refs/heads/master
                set base_branch "master"
            else
                set_color red
                echo "⚠️  エラー：デフォルトブランチ（main/master）が見つかりません"
                echo "比較元ブランチを -b/--base オプションで指定してください"
                set_color normal
                return 1
            end
        end

        # 派生元コミットの自動検出
        set commit_hash (git show-branch --sha1-name | command grep '*' | command grep -v "$(git rev-parse --abbrev-ref HEAD)" | command grep '+' | head -1 | awk -F'[]~^[]' '{print $2}' 2>/dev/null)

        # 自動検出に失敗した場合はmerge-baseを使用
        if test -z "$commit_hash"
            set commit_hash (git merge-base $base_branch (git rev-parse --abbrev-ref HEAD))
            
            # 同一ブランチでmerge-baseを実行すると最新コミットが返されるため、
            # merge-baseがHEADと同じ場合は最初のコミットを使用
            if test "$commit_hash" = (git rev-parse HEAD)
                # 最初のコミットを取得
                set commit_hash (git rev-list --max-parents=0 HEAD)
            end
        end
    end

    # 範囲の決定
    set -l commit_range
    set -l include_start_commit false
    set -l temp_file
    
    if set -q _flag_root
        set include_start_commit true
        # 指定したコミット自体も含める
        # 最初のコミット（root commit）かどうかを確認
        set -l root_commit (git rev-list --max-parents=0 HEAD)
        
        if test "$commit_hash" = "$root_commit"
            # root commitの場合は、現在のブランチの全てのコミットを対象にして
            # 一時ファイルで対象コミットを管理
            set commit_range "HEAD"
            set temp_file "/tmp/rebase_target_commits_"(random)
            # 指定したコミットからHEADまでのコミットハッシュリストを一時ファイルに保存
            git rev-list "$commit_hash..HEAD" > $temp_file
            echo $commit_hash >> $temp_file
        else
            # 通常のコミットの場合は、その1つ前からHEADまで
            set commit_range "$commit_hash^..HEAD"
        end
    else
        # デフォルト：従来の挙動（指定したコミットの次からHEADまで）
        set commit_range "$commit_hash..HEAD"
    end

    # コミット情報を表示
    set -l commit_short (git rev-parse --short $commit_hash)
    set -l commit_subject (git show -s --format='%s' $commit_hash)
    
    # コミットが含まれるブランチを検索
    set -l branch_names (git branch --contains $commit_hash | string replace -r '^\*?\s+' '' | string join ', ')
    
    echo "
┌─ 🔄 リベース対象 ────────────────────────────────────────────────────
│
│ 開始コミット：$commit_short
│ メッセージ：$commit_subject
│ ブランチ：$branch_names"

    # 範囲の詳細表示
    if test "$include_start_commit" = "true"
        echo "│ 処理範囲：指定コミットから HEAD まで（コミット自体も含む）"
    else
        echo "│ 処理範囲：指定コミットの次から HEAD まで（従来の挙動）"
    end

    # 日時モードに応じた表示
    if test "$date_mode" = "fixed"
        echo "│ 設定する日時：$date_str"
    else
        echo "│ 設定する日時：各コミットのAuthorDateに合わせる"
    end
    
    echo "│
└────────────────────────────────────────────────────────────────────"

    # 確認を求める
    read -l -P "この設定でコミット日時を変更しますか？ (y/N) > " confirm
    if not string match -qr '^[Yy]' -- $confirm
        echo "ℹ️  操作をキャンセルしました"
        return 0
    end

    # 現在のブランチを保存
    set -l current_branch (git rev-parse --abbrev-ref HEAD)
    
    # 環境変数を設定して警告を抑制
    set -x FILTER_BRANCH_SQUELCH_WARNING 1
    
    set_color yellow
    echo "🔄 コミット日時を変更しています..."
    set_color normal
    
    # filter-branchを使って日時を変更
    set -l env_filter
    
    if test -n "$temp_file"
        # root commitの場合：一時ファイルで対象コミットを管理
        if test "$date_mode" = "fixed"
            set env_filter "
                if grep -q \$GIT_COMMIT $temp_file; then
                    export GIT_AUTHOR_DATE=\"$date_str\"
                    export GIT_COMMITTER_DATE=\"$date_str\"
                fi
            "
        else
            set env_filter "
                if grep -q \$GIT_COMMIT $temp_file; then
                    export GIT_COMMITTER_DATE=\"\$GIT_AUTHOR_DATE\"
                fi
            "
        end
    else
        # 通常の範囲指定の場合
        if test "$date_mode" = "fixed"
            # 固定日時に設定
            set env_filter "export GIT_AUTHOR_DATE=\"$date_str\"; export GIT_COMMITTER_DATE=\"$date_str\";"
        else
            # AuthorDateに合わせてCommitterDateを設定
            set env_filter 'export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE";'
        end
    end

    # git filter-branchコマンドを実行
    if git filter-branch --force --env-filter "$env_filter" -- $commit_range
        set_color green
        echo "✅ コミット日時の変更が完了しました"
        set_color normal
    else
        set_color red
        echo "⚠️  エラー：コミット日時の変更に失敗しました"
        set_color normal
        # 一時ファイルのクリーンアップ
        if test -n "$temp_file" -a -f "$temp_file"
            rm "$temp_file"
        end
        return 1
    end
    
    # 一時ファイルのクリーンアップ
    if test -n "$temp_file" -a -f "$temp_file"
        rm "$temp_file"
    end
    
    # 環境変数を解除
    set -e FILTER_BRANCH_SQUELCH_WARNING
    
    return 0
end
