function _gish_error
    set_color red
    echo "⚠️  エラー：$argv"
    set_color normal
end

function _gish_info
    set_color blue
    echo "ℹ️  $argv"
    set_color normal
end

function _gish_success
    set_color green
    echo "✅ $argv"
    set_color normal
end

function _gish_progress
    set_color yellow
    echo "🔄 $argv"
    set_color normal
end

# 日時処理関数
function _gish_normalize_date
    set -l input_date $argv[1]
    
    # 空の場合は現在時刻
    if test -z "$input_date"
        env LC_TIME=C date "+%a %b %d %H:%M:%S %Y %z"
        return 0
    end
    
    # 既にGit形式かチェック
    if string match -qr '^[A-Z][a-z][a-z] [A-Z][a-z][a-z] [0-9]' $input_date
        echo $input_date
        return 0
    end
    
    # ISO形式のパターンマッチング
    if string match -qr '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}' $input_date
        # 時刻が含まれていない場合は 00:00:00 を追加
        if not string match -qr '[0-9]{2}:[0-9]{2}' $input_date
            set input_date "$input_date 00:00:00"
        end
        
        # タイムゾーンが含まれていない場合は現在のタイムゾーンを追加
        if not string match -qr '[+-][0-9]{4}' $input_date
            set -l tz (date "+%z")
            set input_date "$input_date $tz"
        end
        
        # dateコマンドを使ってGit形式に変換
        if set -l git_date (env LC_TIME=C date -d "$input_date" "+%a %b %d %H:%M:%S %Y %z" 2>/dev/null)
            echo $git_date
            return 0
        end
    end
    
    # 直接dateコマンドで解析を試みる
    if set -l git_date (env LC_TIME=C date -d "$input_date" "+%a %b %d %H:%M:%S %Y %z" 2>/dev/null)
        echo $git_date
        return 0
    end
    
    _gish_error "無効な日時形式: $input_date"
    _gish_info "使用可能な形式例："
    _gish_info "  2025-09-01"
    _gish_info "  2025-09-01 12:00:00"
    _gish_info "  'Mon Sep 01 12:00:00 2025 +0900'"
    return 1
end

# Git関連検証関数
function _gish_validate_git_repo
    if not git rev-parse --git-dir >/dev/null 2>&1
        _gish_error "カレントディレクトリはGitリポジトリではありません"
        return 1
    end
    return 0
end

function _gish_validate_commit
    set -l commit $argv[1]
    if not git rev-parse --verify $commit >/dev/null 2>&1
        _gish_error "指定されたコミット '$commit' が見つかりません"
        return 1
    end
    return 0
end

function _gish_find_default_branch
    if git show-ref --verify --quiet refs/heads/main
        echo "main"
    else if git show-ref --verify --quiet refs/heads/master
        echo "master"
    else
        return 1
    end
    return 0
end

function _gish_detect_base_commit
    set -l base_branch $argv[1]
    
    # 派生元コミットの自動検出
    set -l commit_hash (git show-branch --sha1-name 2>/dev/null | command grep '*' | command grep -v (git rev-parse --abbrev-ref HEAD) | command grep '+' | head -1 | awk -F'[]~^[]' '{print $2}' 2>/dev/null)

    # 自動検出に失敗した場合はmerge-baseを使用
    if test -z "$commit_hash"
        set commit_hash (git merge-base $base_branch (git rev-parse --abbrev-ref HEAD) 2>/dev/null)
        
        # 同一ブランチの場合は最初のコミットを使用
        if test "$commit_hash" = (git rev-parse HEAD 2>/dev/null)
            set commit_hash (git rev-list --max-parents=0 HEAD 2>/dev/null)
        end
    end
    
    if test -n "$commit_hash"
        echo $commit_hash
        return 0
    end
    
    return 1
end

function _gish_parse_options
    set -l fix_date false
    set -l date_str ""
    set -l fix_user false
    set -l base_branch ""
    set -l include_root false
    set -l skip_confirm false
    set -l show_help false
    set -l remaining_args
    
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        
        switch $arg
            case -h --help
                set show_help true
            case -d --date
                set fix_date true
                # 次の引数が日時かどうかチェック
                if test (math $i + 1) -le (count $argv)
                    set -l next_arg $argv[(math $i + 1)]
                    # 次の引数がオプションでなく、日時らしい形式であれば日時として扱う
                    if not string match -q -- '-*' $next_arg
                        # 日時らしい形式かチェック
                        if string match -qr '[0-9]' $next_arg
                            set date_str $next_arg
                            set i (math $i + 1)  # 日時引数をスキップ
                        end
                    end
                end
            case -u --user
                set fix_user true
            case -b --base
                if test (math $i + 1) -le (count $argv)
                    set i (math $i + 1)
                    set base_branch $argv[$i]
                else
                    _gish_error "-b/--base オプションには引数が必要です"
                    return 1
                end
            case -r --root
                set include_root true
            case -y --yes
                set skip_confirm true
            case -du -ud
                set fix_date true
                set fix_user true
            case -dr -rd
                set fix_date true  
                set include_root true
            case -dy -yd
                set fix_date true
                set skip_confirm true
            case -ur -ru
                set fix_user true
                set include_root true
            case -uy -yu
                set fix_user true
                set skip_confirm true
            case -ry -yr
                set include_root true
                set skip_confirm true
            case -dur -dru -udr -urd -rdu -rud
                set fix_date true
                set fix_user true
                set include_root true
            case -duy -dyu -udy -uyd -ydu -yud
                set fix_date true
                set fix_user true
                set skip_confirm true
            case -dry -dyr -rdy -ryd -ydr -yrd
                set fix_date true
                set include_root true
                set skip_confirm true
            case -ury -uyr -ruy -ryu -yur -yru
                set fix_user true
                set include_root true
                set skip_confirm true
            case '-*'
                _gish_error "不明なオプション: $arg"
                return 1
            case '*'
                set remaining_args $remaining_args $arg
        end
        set i (math $i + 1)
    end
    
    # 結果を出力（呼び出し元で使用）
    echo "fix_date:$fix_date"
    echo "date_str:$date_str"
    echo "fix_user:$fix_user"
    echo "base_branch:$base_branch"
    echo "include_root:$include_root"
    echo "skip_confirm:$skip_confirm"
    echo "show_help:$show_help"
    for arg in $remaining_args
        echo "arg:$arg"
    end
    
    return 0
end

# メイン処理関数
function _gish_fix_command
    # オプション解析
    set -l parse_result (_gish_parse_options $argv)
    if test $status -ne 0
        return 1
    end
    
    # 結果を変数に設定
    set -l fix_date false
    set -l date_str ""
    set -l fix_user false
    set -l base_branch ""
    set -l include_root false
    set -l skip_confirm false
    set -l show_help false
    set -l remaining_args
    
    for line in $parse_result
        set -l key (string split ':' $line)[1]
        set -l value (string split ':' $line)[2]
        
        switch $key
            case fix_date
                set fix_date $value
            case date_str
                set date_str $value
            case fix_user
                set fix_user $value
            case base_branch
                set base_branch $value
            case include_root
                set include_root $value
            case skip_confirm
                set skip_confirm $value
            case show_help
                set show_help $value
            case arg
                set remaining_args $remaining_args $value
        end
    end
    
    # ヘルプ表示
    if test $show_help = true
        _gish_detailed_help
        return 0
    end
    
    # Git検証
    _gish_validate_git_repo
    or return 1
    
    # 最低一つのオプションが必要
    if test $fix_date != true && test $fix_user != true
        _gish_error "少なくとも -d（日時修正）または -u（作成者統一）オプションを指定してください"
        return 1
    end
    
    # 日時の正規化
    set -l normalized_date ""
    if test $fix_date = true && test -n "$date_str"
        set normalized_date (_gish_normalize_date "$date_str")
        if test $status -ne 0
            return 1
        end
    end
    
    # ベースブランチの決定
    if test -z "$base_branch"
        set base_branch (_gish_find_default_branch)
        if test $status -ne 0
            _gish_error "デフォルトブランチ（main/master）が見つかりません。-b/--base オプションで指定してください"
            return 1
        end
    end
    
    # 対象コミットの決定
    set -l target_commit
    if test (count $remaining_args) -ge 1
        set target_commit $remaining_args[1]
        _gish_validate_commit $target_commit
        or return 1
    else
        set target_commit (_gish_detect_base_commit $base_branch)
        if test $status -ne 0 || test -z "$target_commit"
            _gish_error "派生元コミットの自動検出に失敗しました。コミットハッシュを明示的に指定してください"
            return 1
        end
    end
    
    # 実際の修正処理
    _gish_execute_fix "$target_commit" $fix_date "$normalized_date" $fix_user $include_root $skip_confirm
    return $status
end

function _gish_collect_user_info
    set -l commit_range $argv[1]
    
    set -l authors (git log --format="%an|%ae" $commit_range 2>/dev/null | sort | uniq -c | sort -nr)
    set -l committers (git log --format="%cn|%ce" $commit_range 2>/dev/null | sort | uniq -c | sort -nr)
    
    set -l all_users
    for line in $authors
        set -l count (echo $line | awk '{print $1}')
        set -l user (echo $line | awk '{$1=""; print $0}' | string trim)
        set all_users $all_users "author:$count:$user"
    end
    
    for line in $committers
        set -l count (echo $line | awk '{print $1}')
        set -l user (echo $line | awk '{$1=""; print $0}' | string trim)
        if not contains "author:$count:$user" $all_users
            set all_users $all_users "committer:$count:$user"
        end
    end
    
    for user in $all_users
        echo $user
    end
end

function _gish_interactive_user_selection
    set -l commit_range $argv[1]
    
    _gish_info "ユーザー情報の処理を選択してください:" >&2
    echo "1) CommitterをAuthorに同期（従来機能）" >&2
    echo "2) 既存のユーザー情報から選択" >&2
    echo "3) 新しいユーザー情報を入力" >&2
    
    read -l -P "選択 (1-3) > " selection
    
    switch $selection
        case 1
            echo "mode:sync"
            return 0
        case 2
            set -l user_info (_gish_collect_user_info $commit_range)
            if test (count $user_info) -eq 0
                _gish_error "対象範囲内にユーザー情報が見つかりません"
                return 1
            end
            
            echo >&2
            _gish_info "対象範囲内のユーザー情報:" >&2
            set -l i 1
            for info in $user_info
                set -l count (echo $info | cut -d: -f2)
                set -l user (echo $info | cut -d: -f3)
                echo "$i) $user ($count commits)" >&2
                set i (math $i + 1)
            end
            
            set -l git_name (git config user.name 2>/dev/null)
            set -l git_email (git config user.email 2>/dev/null)
            set -l git_config_index -1
            if test -n "$git_name" && test -n "$git_email"
                set git_config_index $i
                echo "$i) [git config] $git_name <$git_email>" >&2
                set i (math $i + 1)
            end
            
            read -l -P "選択 (1-$(math $i - 1)) > " user_selection
            
            if test $user_selection -le (count $user_info)
                set -l selected_info $user_info[$user_selection]
                set -l user (echo $selected_info | cut -d: -f3)
                set -l name (echo $user | cut -d'|' -f1)
                set -l email (echo $user | cut -d'|' -f2)
                echo "mode:existing"
                echo "name:$name"
                echo "email:$email"
            else if test $git_config_index -ne -1 && test $user_selection -eq $git_config_index
                echo "mode:existing"
                echo "name:$git_name"
                echo "email:$git_email"
            else
                _gish_error "無効な選択です"
                return 1
            end
            return 0
        case 3
            echo >&2
            _gish_info "新しいユーザー情報を入力してください:" >&2
            read -l -P "名前 > " new_name
            read -l -P "メール > " new_email
            
            if test -z "$new_name" || test -z "$new_email"
                _gish_error "名前とメールアドレスは必須です"
                return 1
            end
            
            echo "mode:new"
            echo "name:$new_name"
            echo "email:$new_email"
            return 0
        case '*'
            _gish_error "無効な選択です"
            return 1
    end
end

function _gish_select_target_user
    _gish_info "適用対象を選択してください:" >&2
    echo "1) Author のみ" >&2
    echo "2) Committer のみ" >&2
    echo "3) Author と Committer 両方" >&2
    
    read -l -P "選択 (1-3) > " target_selection
    
    switch $target_selection
        case 1
            echo "target:author"
        case 2
            echo "target:committer"
        case 3
            echo "target:both"
        case '*'
            _gish_error "無効な選択です"
            return 1
    end
    return 0
end

# コミット修正実行関数
function _gish_execute_fix
    set -l target_commit $argv[1]
    set -l fix_date $argv[2]
    set -l date_str $argv[3]
    set -l fix_user $argv[4]
    set -l include_root $argv[5]
    set -l skip_confirm $argv[6]
    
    # 範囲決定
    set -l commit_range
    if test $include_root = true
        # rootコミットかチェック
        set -l root_commit (git rev-list --max-parents=0 HEAD 2>/dev/null)
        if test "$target_commit" = "$root_commit"
            set commit_range "HEAD"
        else
            set commit_range "$target_commit^..HEAD"
        end
    else
        set commit_range "$target_commit..HEAD"
    end
    
    # ユーザー情報の処理（表示前に全て完了）
    set -l user_mode ""
    set -l user_name ""
    set -l user_email ""
    set -l user_target ""
    
    if test $fix_user = true
        set -l user_selection_result (_gish_interactive_user_selection $commit_range)
        if test $status -ne 0
            return 1
        end
        
        for line in $user_selection_result
            set -l key (echo $line | cut -d: -f1)
            set -l value (echo $line | cut -d: -f2-)
            
            switch $key
                case mode
                    set user_mode $value
                case name
                    set user_name $value
                case email
                    set user_email $value
            end
        end
        
        if test "$user_mode" != "sync"
            set -l target_result (_gish_select_target_user)
            if test $status -ne 0
                return 1
            end
            set user_target (echo $target_result | cut -d: -f2)
        end
    end
    
    # 情報表示（インタラクティブ処理完了後）
    set -l commit_short (git rev-parse --short $target_commit)
    set -l commit_subject (git show -s --format='%s' $target_commit)
    
    echo "
┌─ 🔄 修正対象 ─────────────────────────────────────────────────────────
│
│ 開始コミット：$commit_short
│ メッセージ：$commit_subject"

    if test $include_root = true
        echo "│ 処理範囲：指定コミットから HEAD まで（コミット自体も含む）"
    else
        echo "│ 処理範囲：指定コミットの次から HEAD まで"
    end

    if test $fix_date = true
        if test -n "$date_str"
            echo "│ 日時修正：固定日時 ($date_str) に設定"
        else
            echo "│ 日時修正：CommitterDateをAuthorDateに同期"
        end
    end
    
    if test $fix_user = true
        echo "│"
        switch $user_mode
            case sync
                echo "│ 作成者修正：CommitterをAuthorに統一"
            case existing new
                echo "│ 作成者修正：$user_name <$user_email>"
                switch $user_target
                    case author
                        echo "│ 適用対象：Author のみ"
                    case committer
                        echo "│ 適用対象：Committer のみ"
                    case both
                        echo "│ 適用対象：Author と Committer 両方"
                end
        end
    end
    
    echo "│
└──────────────────────────────────────────────────────────────────────"
    
    # 確認
    if test $skip_confirm != true
        read -l -P "この設定でコミット情報を修正しますか？ (y/N) > " confirm
        if not string match -qr '^[Yy]' -- $confirm
            _gish_info "操作をキャンセルしました"
            return 0
        end
    end
    
    # filter-branchスクリプト生成
    set -l env_filter ""
    
    set -l date_part ""
    set -l user_part ""
    
    if test $fix_date = true
        if test -n "$date_str"
            set date_part "export GIT_AUTHOR_DATE=\"$date_str\"; export GIT_COMMITTER_DATE=\"$date_str\";"
        else
            set date_part "export GIT_COMMITTER_DATE=\"\$GIT_AUTHOR_DATE\";"
        end
    end
    
    if test $fix_user = true
        switch $user_mode
            case sync
                set user_part "export GIT_COMMITTER_NAME=\"\$GIT_AUTHOR_NAME\"; export GIT_COMMITTER_EMAIL=\"\$GIT_AUTHOR_EMAIL\";"
            case existing new
                switch $user_target
                    case author
                        set user_part "export GIT_AUTHOR_NAME=\"$user_name\"; export GIT_AUTHOR_EMAIL=\"$user_email\";"
                    case committer
                        set user_part "export GIT_COMMITTER_NAME=\"$user_name\"; export GIT_COMMITTER_EMAIL=\"$user_email\";"
                    case both
                        set user_part "export GIT_AUTHOR_NAME=\"$user_name\"; export GIT_AUTHOR_EMAIL=\"$user_email\"; export GIT_COMMITTER_NAME=\"$user_name\"; export GIT_COMMITTER_EMAIL=\"$user_email\";"
                end
        end
    end
    
    set env_filter "$date_part $user_part"
    
    # 実行
    set -x FILTER_BRANCH_SQUELCH_WARNING 1
    _gish_progress "コミット情報を修正しています..."
    
    if git filter-branch --force --env-filter "$env_filter" -- $commit_range
        _gish_success "コミット情報の修正が完了しました"
        set -e FILTER_BRANCH_SQUELCH_WARNING
        return 0
    else
        _gish_error "コミット情報の修正に失敗しました"
        set -e FILTER_BRANCH_SQUELCH_WARNING
        return 1
    end
end

# ヘルプ関数
function gish_help
    echo "
🐟 gish - Git修正ツール

[使用方法]
gish fix [オプション] [コミット]

[説明]
Gitコミットの日時や作成者情報を修正します。

[オプション]
-d, --date [<datetime>]   日時修正（引数なし=同期、引数あり=固定日時）
-u, --user               CommitterをAuthorに統一
-b, --base <ref>         比較元のブランチを指定（デフォルト：main/master）
-r, --root               指定したコミット自体も処理対象に含める
-y, --yes                確認プロンプトをスキップ
-h, --help               このヘルプを表示

[例]
gish fix -d                    # CommitterDateをAuthorDateに同期
gish fix -d '2025-09-01'       # 固定日時に設定
gish fix -u                    # CommitterをAuthorに統一
gish fix -du abc123            # 日時同期 + 作成者統一
gish fix -r abc123             # 指定コミット自体も含めて修正"
end

# 詳細ヘルプ関数（内部使用）
function _gish_detailed_help
    echo "
🔧 gish fix - コミット情報修正（詳細）

[オプション詳細]
-d, --date [<datetime>]
    引数なし：CommitterDateをAuthorDateに同期
    引数あり：指定した固定日時に設定
    対応形式：
      - 2025-09-01
      - 2025-09-01 12:00:00
      - 'Mon Sep 01 12:00:00 2025 +0900'

-u, --user
    Committerの名前とメールをAuthorと同じに統一

-b, --base <ref>
    比較元のブランチを指定（デフォルト：main/master）

-r, --root
    指定したコミット自体も処理対象に含める

-y, --yes
    確認プロンプトをスキップして自動実行"
end

# メイン関数
function gish -d "Git修正ツール"
    if test (count $argv) -eq 0
        gish_help
        return 0
    end

    set -l subcommand $argv[1]
    
    switch $subcommand
        case fix
            set -l fix_args $argv[2..-1]
            _gish_fix_command $fix_args
            return $status
        case help
            if test (count $argv) -eq 2 && test "$argv[2]" = "fix"
                _gish_detailed_help
            else
                gish_help
            end
            return 0
        case -h --help
            gish_help
            return 0
        case '*'
            _gish_error "不明なサブコマンド '$subcommand'"
            echo
            gish_help
            return 1
    end
end