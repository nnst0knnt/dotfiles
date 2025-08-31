function open_help
    echo "
🔗 open - ファイル・ディレクトリ・URL オープンツール

[使用方法]
open [オプション] [ファイル/ディレクトリ/URL...]

[説明]
指定されたファイル、ディレクトリ、またはURLをWindows側のデフォルトアプリケーションで開きます。
複数の項目を同時に開くことも可能です。

[オプション]
-h, --help        このヘルプを表示
-v, --verbose     詳細な実行情報を表示
-d, --directory   ディレクトリとして強制的に開く
-f, --fast        高速モード（ディレクトリはexplorer.exe優先）
-s, --slow        互換モード（常にwslview使用）
--debug           デバッグ情報を詳細に表示

[例]
open file.txt                   # テキストファイルをデフォルトエディタで開く
open image.jpg document.pdf     # 複数ファイルを同時に開く
open .                          # 現在のディレクトリをエクスプローラーで開く（高速）
open -f ~/Documents             # 高速モードでディレクトリを開く
open -s file.html               # 互換モードでファイルを開く
open https://github.com         # URLをデフォルトブラウザで開く
open -d file.txt                # ファイルの親ディレクトリを開く
open --debug file.html          # デバッグモードで実行"
end

function open -d "ファイル・ディレクトリ・URLをWindows側で開く"
    # argparseを使用してオプションを解析
    argparse 'h/help' 'v/verbose' 'd/directory' 'f/fast' 's/slow' 'debug' -- $argv
    or return

    # ヘルプオプションのチェック
    if set -q _flag_help
        open_help
        return 0
    end

    # 引数が指定されていない場合はカレントディレクトリを開く
    if test (count $argv) -eq 0
        set argv "."
    end

    # 詳細出力の設定
    set -l verbose false
    if set -q _flag_verbose
        set verbose true
    end

    # デバッグモードの設定
    set -l debug false
    if set -q _flag_debug
        set debug true
        set verbose true  # デバッグモード時は詳細出力も有効
    end

    # ディレクトリ強制フラグ
    set -l force_directory false
    if set -q _flag_directory
        set force_directory true
    end

    # パフォーマンスモードの設定
    set -l fast_mode false
    set -l slow_mode false
    if set -q _flag_fast
        set fast_mode true
    end
    if set -q _flag_slow
        set slow_mode true
    end

    # デフォルトは高速モード（ディレクトリ系操作を高速化）
    if test "$fast_mode" = "false" -a "$slow_mode" = "false"
        set fast_mode true
    end

    # コマンド選択のロジック（パフォーマンス最適化）
    set -l use_wslview false
    set -l use_explorer false
    set -l use_cmd false
    set -l selection_reason ""

    if test "$slow_mode" = "true"
        # 互換モード：常にwslviewを優先
        if command -v wslview >/dev/null
            set use_wslview true
            set selection_reason "互換モード（wslview優先）"
        else if command -v explorer.exe >/dev/null
            set use_explorer true
            set selection_reason "互換モード（wslview未検出、explorer.exe使用）"
        else
            set use_cmd true
            set selection_reason "互換モード（フォールバック、cmd.exe使用）"
        end
    else
        # 高速モード：用途に応じて最適化
        if command -v explorer.exe >/dev/null -a command -v wslview >/dev/null
            # 両方利用可能な場合は用途で判断
            set use_explorer true
            set use_wslview true  # ファイル用に後で判定
            set selection_reason "高速モード（用途別最適化）"
        else if command -v wslview >/dev/null
            set use_wslview true
            set selection_reason "高速モード（wslviewのみ利用可能）"
        else if command -v explorer.exe >/dev/null
            set use_explorer true
            set selection_reason "高速モード（explorer.exeのみ利用可能）"
        else
            set use_cmd true
            set selection_reason "高速モード（フォールバック、cmd.exe使用）"
        end
    end

    if test "$verbose" = "true"
        set_color green
        echo "✅ $selection_reason"
        set_color normal
    end

    # 各引数を処理
    set -l success_count 0
    set -l error_count 0

    for target in $argv
        # URLかどうかを判定
        set -l is_url false
        if string match -qr '^https?://' -- $target
            set is_url true
        end

        # ディレクトリ強制フラグの処理
        if test "$force_directory" = "true" -a "$is_url" = "false"
            if test -f $target
                set target (dirname $target)
            end
        end

        # ファイル/ディレクトリの存在確認（URLでない場合）
        if test "$is_url" = "false"
            if not test -e $target
                set_color red
                echo "⚠️  エラー：'$target' が見つかりません"
                set_color normal
                set error_count (math $error_count + 1)
                continue
            end
        end

        # 詳細出力
        if test "$verbose" = "true"
            if test "$is_url" = "true"
                set_color cyan
                echo "🌐 URL を開いています：$target"
                set_color normal
            else if test -d $target
                set_color blue
                echo "📁 ディレクトリを開いています：$target"
                set_color normal
            else
                set_color green
                echo "📄 ファイルを開いています：$target"
                set_color normal
            end
        end

        # 実際の実行（パフォーマンス最適化）
        set -l command_success false
        set -l exit_code 0
        set -l used_command ""

        # 高速モードでの最適化判定
        if test "$fast_mode" = "true" -a "$use_explorer" = "true" -a "$use_wslview" = "true"
            if test "$is_url" = "false" -a -d "$target"
                # ディレクトリの場合は高速なexplorer.exeを優先
                set use_wslview false
                set used_command "explorer.exe (ディレクトリ最適化)"
            else if test "$is_url" = "true"
                # URLの場合はwslviewを優先（関連付け確実性）
                set use_explorer false
                set used_command "wslview (URL最適化)"
            else
                # ファイルの場合はwslviewを優先（関連付け確実性）
                set use_explorer false
                set used_command "wslview (ファイル最適化)"
            end
        end

        if test "$use_wslview" = "true"
            # wslviewを使用
            set used_command (test -n "$used_command" && echo "$used_command" || echo "wslview")
            if test "$verbose" = "true"
                wslview "$target"
                set exit_code $status
            else
                wslview "$target" >/dev/null 2>&1
                set exit_code $status
            end
            
            # wslviewは通常、成功時でも0以外を返すことがあるため、
            # プロセス起動に関する終了コードは寛容に判定
            if test $exit_code -le 2
                set command_success true
            end
        else if test "$use_explorer" = "true"
            # explorer.exeを使用（ディレクトリとファイル用）
            if test "$is_url" = "true"
                # URLの場合はcmd.exeを使用
                set used_command "cmd.exe (URL対応)"
                if test "$verbose" = "true"
                    cmd.exe /c start "$target"
                    set exit_code $status
                else
                    cmd.exe /c start "$target" >/dev/null 2>&1
                    set exit_code $status
                end
                # cmd.exe start は非同期実行のため、終了コード0-2を成功とみなす
                if test $exit_code -le 2
                    set command_success true
                end
            else
                # ファイル/ディレクトリの場合
                set used_command (test -n "$used_command" && echo "$used_command" || echo "explorer.exe")
                set -l windows_path (wslpath -w "$target" 2>/dev/null)
                if test $status -eq 0
                    if test "$verbose" = "true"
                        explorer.exe "$windows_path"
                        set exit_code $status
                    else
                        explorer.exe "$windows_path" >/dev/null 2>&1
                        set exit_code $status
                    end
                    # explorer.exe は非同期実行のため、終了コード0または1を成功とみなす
                    if test $exit_code -le 1
                        set command_success true
                    end
                end
            end
        else if test "$use_cmd" = "true"
            # cmd.exe start を使用
            set used_command "cmd.exe"
            if test "$is_url" = "false"
                set -l windows_path (wslpath -w "$target" 2>/dev/null)
                if test $status -eq 0
                    set target "$windows_path"
                end
            end
            
            if test "$verbose" = "true"
                cmd.exe /c start "$target"
                set exit_code $status
            else
                cmd.exe /c start "$target" >/dev/null 2>&1
                set exit_code $status
            end
            
            # cmd.exe start は非同期実行のため、終了コード0-2を成功とみなす
            if test $exit_code -le 2
                set command_success true
            end
        end
        
        # デバッグ情報（詳細モード時のみ）
        if test "$debug" = "true"
            set_color yellow
            echo "🔧 デバッグ情報："
            echo "   - 使用コマンド: $used_command"
            echo "   - 終了コード: $exit_code"
            echo "   - 判定結果: "(test "$command_success" = "true" && echo "成功" || echo "失敗")
            set_color normal
        else if test "$verbose" = "true"
            set_color blue
            echo "🔧 実行: $used_command (終了コード: $exit_code)"
            set_color normal
        end

        # 結果の処理
        if test "$command_success" = "true"
            set success_count (math $success_count + 1)
            if test "$verbose" = "true"
                set_color green
                echo "✅ 正常に開きました"
                set_color normal
            end
        else
            set_color red
            echo "⚠️  エラー：'$target' を開けませんでした"
            set_color normal
            set error_count (math $error_count + 1)
        end

        # 項目間の区切り（複数項目処理時）
        if test (count $argv) -gt 1 -a "$verbose" = "true"
            echo
        end
    end

    # 実行結果のサマリー
    if test (count $argv) -gt 1
        echo
        set_color cyan
        echo "📊 実行結果："
        set_color green
        echo "  ✅ 成功：$success_count 件"
        if test $error_count -gt 0
            set_color red
            echo "  ❌ 失敗：$error_count 件"
        end
        set_color normal
    end

    # 終了ステータス
    if test $error_count -gt 0
        return 1
    else
        return 0
    end
end
