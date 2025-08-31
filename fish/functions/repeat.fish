function repeat_help
	echo "
🕒 repeat - コマンド繰り返しツール

[使用方法]
repeat <回数> <コマンド> [引数...]

[説明]
指定されたコマンドを指定回数実行します。

[オプション]
-h, --help     このヘルプを表示

[例]
repeat 3 echo 'Hello'  # 'Hello'を3回表示
repeat 5 ls -l         # lsコマンドを5回実行"
end

function repeat -d "指定されたコマンドを指定回数実行"
    # ヘルプオプションのチェック
    if contains -- "-h" $argv; or contains -- "--help" $argv
        repeat_help
        return 0
    end

    # 引数の数をチェック
    if test (count $argv) -lt 2
        set_color red
        echo "⚠️  エラー：引数が不足しています"
        set_color normal
        echo
        repeat_help
        return 1
    end

    set -l repeat_count $argv[1]

    # 数値チェック
    if not string match -qr '^[0-9]+$' -- $repeat_count
        set_color red
        echo "⚠️  エラー：繰り返し回数は正の整数で指定してください"
        set_color normal
        return 1
    end

    set -l command $argv[2..-1]

    # コマンドの実行
    set_color yellow
    echo "🔄 コマンドを $repeat_count 回実行します：$command"
    set_color normal
    echo

    for i in (seq $repeat_count)
        set_color blue
        echo "実行 $i/$repeat_count"
        set_color normal
        $command
        echo
    end

    set_color green
    echo "✅ $repeat_count 回コマンドが正常に実行されました"
    set_color normal
end
