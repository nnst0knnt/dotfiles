function revert_help
	echo "
🐞 revert - マージ済みPRのリバートツール

[使用方法]
revert [オプション] [PR番号]

[説明]
マージ済みPRをリバートするブランチとコミットを作成します。

[オプション]
-h, --help     このヘルプを表示
-l, --list     最近マージされたPRの一覧を表示

[例]
revert 123     # PR #123 をリバート
revert -l      # 最近のPR一覧を表示"
end

function revert -d "マージ済みPRをリバートするコミットを作成"
   # gh CLIの確認
   if not command -v gh >/dev/null
       set_color red
       echo "⚠️  エラー：GitHub CLI (gh) がインストールされていません"
       echo "インストール方法：https://cli.github.com"
       set_color normal
       return 1
   end

   # ヘルプ表示
   if contains -- "-h" $argv; or contains -- "--help" $argv
       revert_help
       return 0
   end

   function __format_date
       set -l iso_date $argv[1]
       string replace -r 'T' ' ' $iso_date | string replace -r 'Z$' ''
   end

   function __format_branch
       set -l branch $argv[1]
       set -l max_length 30
       if test (string length $branch) -gt $max_length
           string sub -l $max_length $branch"..."
       else
           echo $branch
       end
   end

   function __print_pr_list
       set -l prs $argv[1]
       echo "
┌─ 📋 マージ済みPR一覧 ───────────────────────────────────────────────────"
       
       echo $prs | jq -r '.[] | select(.mergedAt != null) | [
           (.number | tostring),
           .author.login,
           .headRefName,
           .mergedAt,
           .title
       ] | @tsv' | while read -l number author branch merged_at title
           set -l formatted_date (__format_date $merged_at)
           set -l formatted_branch (__format_branch $branch)
           
           echo "│"
           set_color green
           echo -n "│ #$number "
           set_color normal
           echo "$title"
           echo -n "│ └─ "
           echo -n "@$author / $formatted_branch / $formatted_date"
           echo
       end
       echo "│"
       echo "└────────────────────────────────────────────────────────────────────"
   end

   # PR一覧表示
   if contains -- "-l" $argv; or contains -- "--list" $argv
       set_color yellow
       echo "🔍 PRを取得中..."
       set_color normal
       
       set -l pr_list (gh pr list \
           --limit 20 \
           --state merged \
           --json number,title,headRefName,mergedAt,author)
       
       __print_pr_list $pr_list
       return 0
   end

   # PR番号の取得とバリデーション
   set -l pr_number

   if test (count $argv) = 1
       if not string match -qr '^[0-9]+$' -- $argv[1]
           set_color red
           echo "⚠️  エラー：無効なPR番号です（$argv[1]）"
           set_color normal
           return 1
       end
       set pr_number $argv[1]
   else
       set_color yellow
       echo "🔍 PRを取得中..."
       set_color normal
       
       set -l pr_list (gh pr list \
           --limit 10 \
           --state merged \
           --json number,title,headRefName,mergedAt,author)
       
       __print_pr_list $pr_list

       echo
       set_color normal
       read -l -P "リバートするPR番号を入力 > #" pr_input

       if test -z "$pr_input"
           echo "ℹ️  操作をキャンセルしました"
           return 0
       end

       if not string match -qr '^[0-9]+$' -- $pr_input
           set_color red
           echo "⚠️  エラー：無効なPR番号です（$pr_input）"
           set_color normal
           return 1
       end
       set pr_number $pr_input
   end

   # PRの詳細を取得
   set_color yellow
   echo ""
   echo "🔍 PR #$pr_number の詳細を取得中..."
   set_color normal

   set -l pr_details (gh pr view $pr_number \
       --json number,title,state,mergedAt,mergeCommit,author,headRefName,url)
   if test $status -ne 0
       set_color red
       echo "⚠️  エラー：PR #$pr_number の取得に失敗しました"
       set_color normal
       return 1
   end

   # マージ済み確認
   set -l merged_at (echo $pr_details | jq -r .mergedAt)
   if test "$merged_at" = "null"
       set_color red
       echo "⚠️  エラー：PR #$pr_number はマージされていません"
       set_color normal
       return 1
   end

   # 情報取得
   set -l merge_commit (echo $pr_details | jq -r .mergeCommit.oid)
   set -l pr_title (echo $pr_details | jq -r .title)
   set -l pr_author (echo $pr_details | jq -r .author.login)
   set -l pr_branch (echo $pr_details | jq -r .headRefName)
   set -l pr_url (echo $pr_details | jq -r .url)
   set -l formatted_date (__format_date $merged_at)

   # 確認表示
   echo "
┌─ 🔄 リバート対象 ────────────────────────────────────────────────────"
   set_color green
   echo -n "│ #$pr_number "
   set_color normal
   echo "$pr_title"
   echo "│"
   echo "│ 作成者：@$pr_author"
   echo "│ ブランチ：$pr_branch"
   echo "│ マージ日時：$formatted_date"
   echo "│ URL：$pr_url"
   echo "└────────────────────────────────────────────────────────────────────"
   echo

   read -l -P "このPRをリバートしますか？ (y/N) > " confirm
   if not string match -qr '^[Yy]' -- $confirm
       echo "ℹ️  操作をキャンセルしました"
       return 0
   end

   # リバートブランチの作成
   set -l revert_branch "revert/pr-$pr_number"
   echo "🔄 ブランチ '$revert_branch' を作成中..."

   git checkout -b $revert_branch
   if test $status -ne 0
       set_color red
       echo "⚠️  エラー：ブランチの作成に失敗しました"
       set_color normal
       return 1
   end

   # リバートの実行
   echo "🔄 リバートコミットを作成中..."

   git revert -m 1 $merge_commit
   if test $status -ne 0
       set_color red
       echo "⚠️  エラー：リバートに失敗しました"
       echo "コンフリクトが発生している可能性があります"
       set_color normal
       return 1
   end

   # 成功表示
   echo "
┌─ ✅ リバート完了 ─────────────────────────────────────────────────────
│
│ リバート対象：#$pr_number
│ タイトル：$pr_title
│ 作成ブランチ：$revert_branch
│
│ 次のステップ：
│ 1. 変更内容を確認：    git diff HEAD^
│ 2. 必要に応じて修正
│ 3. プッシュ：          git push origin $revert_branch
│ 4. PRを作成：         gh pr create
│
└────────────────────────────────────────────────────────────────────"

   functions -e revert_help
   functions -e __format_date
   functions -e __format_branch
   functions -e __print_pr_list
end
