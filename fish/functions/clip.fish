function clip_help
    echo "
📋 clip - ファイル内容をクリップボードにコピー

[使用方法]
clip <ファイルパス>

[説明]
指定されたファイルの内容をクリップボードにコピーします。
日本語や改行もそのまま保持されます。

[オプション]
-h, --help     このヘルプを表示

[例]
clip memo.txt"
end

function clip -d 指定されたファイルの内容をクリップボードにコピー
    if contains -- -h $argv; or contains -- --help $argv
        clip_help
        return 0
    end

    if test (count $argv) -ne 1
        set_color red
        echo "⚠️ エラー：ファイルパスを1つ指定してください"
        set_color normal
        echo
        clip_help
        return 1
    end

    set -l file_path $argv[1]

    if not test -f $file_path
        set_color red
        echo "⚠️ エラー：ファイル '$file_path' が見つかりません"
        set_color normal
        return 1
    end

    cat $file_path | fish_clipboard_copy

    if test $status -eq 0
        set_color green
        echo "✅ クリップボードにコピーしました：$file_path"
        set_color normal
    else
        set_color red
        echo "❌ コピーに失敗しました"
        set_color normal
        return 1
    end
end
