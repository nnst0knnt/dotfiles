function killer_help
    echo "
🔪 killer - ポートを使用中のプロセスを強制終了するツール

[使用方法]
killer [ポート番号]

[オプション]
-h, --help     このヘルプを表示します

[例]
killer 3000         # ポート3000を使用しているプロセスを強制終了
killer --help       # ヘルプを表示"
end

function killer -d "指定したポートを使用中のプロセスを強制終了します"
    argparse 'h/help' -- $argv
    or return

    if set -q _flag_help
        killer_help
        return 0
    end

    if test (count $argv) -ne 1
        set_color red
        echo "⚠️  エラー：ポート番号を1つ指定してください"
        set_color normal
        return 1
    end

    set -l port $argv[1]

    if not string match -qr '^[0-9]+$' -- $port
        set_color red
        echo "⚠️  エラー：無効なポート番号です（$port）"
        set_color normal
        return 1
    end

    set -l match_line (ss -tulnp | command grep ":$port" | head -n1)

    if test -z "$match_line"
        set_color yellow
        echo "🔍 ポート $port を使用しているプロセスは見つかりませんでした"
        set_color normal
        return 1
    end

    # プロセスIDと名前の抽出
	set -l pid (echo $match_line | sed -n 's/.*pid=\([0-9]*\).*/\1/p')
	set -l pname (ps -p $pid -o comm=)

    if test -z "$pid"
        set_color red
        echo "⚠️  プロセスIDの抽出に失敗しました"
        set_color normal
        return 1
    end

    echo "
┌─ 🔍 使用中のプロセスを検出しました ──────────────────────────
│  ポート番号：$port
│  プロセスID：$pid
│  プロセス名：$pname
└──────────────────────────────────────────────────────────────"

    set_color normal
    read -l -P "⚠️  このプロセスを強制終了しますか？ (y/N) > " confirm

    if not string match -qr '^[Yy]' -- $confirm
        echo "ℹ️  操作をキャンセルしました"
        return 0
    end

    kill -9 $pid

    if test $status -eq 0
        echo "
✅ プロセス $pid（$pname）を正常に終了しました"
    else
        set_color red
        echo "❌ プロセスの終了に失敗しました"
        set_color normal
        return 1
    end
end
