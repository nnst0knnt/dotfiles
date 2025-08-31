function counter_help
    echo "
📊 counter - ファイル行数・サイズカウントツール

[使用方法]
counter [オプション] [ファイル/ディレクトリ...] [除外パターン...]

[説明]
指定されたファイルまたはディレクトリ内のファイルの行数とサイズをカウントします。

[オプション]
-h, --help        このヘルプを表示
-d, --dir DIR     スキャンするディレクトリ（デフォルト：カレント）
-e, --exclude PAT 除外するパターン（複数指定可能）
-f, --format FMT  出力フォーマット
	- simple：合計のみ表示
	- detail：全ファイルの詳細を表示（デフォルト）
	- tree：ツリー構造で表示
-n, --number NUM  表示するファイル数を制限（デフォルト：制限なし）
-s, --sort TYPE   ソート方式を指定
	- size：ファイルサイズ順（降順）
	- lines：行数順（降順）
	- name：ファイル名順（昇順、デフォルト）

[例]
counter some_dir
counter file1.ts file2.ts
counter -d ./src -e node_modules
counter src -f tree
counter -n 10 -s size"
end

function counter -d ファイル行数とサイズをカウントする
    argparse h/help 'd/dir=' 'e/exclude=+' 'f/format=' 'n/number=' 's/sort=' -- $argv
    or return

    if set -q _flag_help
        counter_help
        return 0
    end

    function __format_size
        set -l size $argv[1]

        if test $size -lt 1024
            echo "$size B"
        else if test $size -lt 1048576
            set -l kb_size (math "round($size / 1024 * 10) / 10")
            echo "$kb_size KB"
        else if test $size -lt 1073741824
            set -l mb_size (math "round($size / 1048576 * 10) / 10")
            echo "$mb_size MB"
        else
            set -l gb_size (math "round($size / 1073741824 * 100) / 100")
            echo "$gb_size GB"
        end
    end

    set -l target_paths
    set -l exclude_patterns
    set -l format detail
    set -l max_files 0
    set -l sort_type name

    if set -q _flag_dir
        set -a target_paths $_flag_dir
    end

    if set -q _flag_exclude
        set exclude_patterns $_flag_exclude
    end

    if set -q _flag_format
        switch $_flag_format
            case simple detail tree
                set format $_flag_format
            case '*'
                set_color red
                echo "⚠️ エラー：不正なフォーマット指定です（simple | detail | tree）"
                set_color normal
                return 1
        end
    end

    if set -q _flag_number
        if not string match -qr '^[0-9]+$' -- $_flag_number
            set_color red
            echo "⚠️ エラー：ファイル数は正の整数で指定してください"
            set_color normal
            return 1
        end
        set max_files $_flag_number
    end

    if set -q _flag_sort
        switch $_flag_sort
            case size lines name
                set sort_type $_flag_sort
            case '*'
                set_color red
                echo "⚠️ エラー：不正なソート指定です（size | lines | name）"
                set_color normal
                return 1
        end
    end

    for arg in $argv
        switch $arg
            case '-*'
                continue
            case '*'
                set -a target_paths $arg
        end
    end

    if test (count $target_paths) -eq 0
        set target_paths "."
    end

    set -l find_exclude_args
    for pattern in $exclude_patterns
        set -a find_exclude_args -not -path "*/$pattern/*" -not -path "*/$pattern"
    end

    echo
    set_color yellow
    echo "🔍 ファイルを検索中..."
    set_color normal

    set -l files
    for target in $target_paths
        if test -f $target
            set -a files $target
        else if test -d $target
            set -a files (find $target -type f $find_exclude_args)
        else
            set_color red
            echo "⚠️ 警告：'$target' は存在しないため無視されます"
            set_color normal
        end
    end
    set files (string join \n $files | sort -u)

    if test (count $files) -eq 0
        set_color red
        echo "⚠️ エラー：カウント対象のファイルが見つかりませんでした"
        set_color normal
        return 1
    end

    set -l total_file_count (count $files)
    set_color green
    echo "✅ $total_file_count 個のファイルが見つかりました"
    set_color normal

    set_color yellow
    echo "📊 ファイル情報を解析中..."
    set_color normal

    set -l file_info_list
    set -l processed_count 0
    set -l progress_interval 100

    if test $total_file_count -gt 1000
        set progress_interval 500
    else if test $total_file_count -gt 100
        set progress_interval 50
    else
        set progress_interval 25
    end

    for file in $files
        set -l lines (wc -l < $file 2>/dev/null; or echo 0)
        set -l size (stat -c%s $file 2>/dev/null; or echo 0)
        set -a file_info_list "$file:$lines:$size"

        set processed_count (math $processed_count + 1)

        if test (math $processed_count % $progress_interval) -eq 0
            set -l percentage (math "round($processed_count * 100 / $total_file_count)")
            printf "\r⏳ 進捗：%d/%d (%d%%) " $processed_count $total_file_count $percentage
        end
    end

    if test $total_file_count -gt $progress_interval
        printf "\r%50s\r" " "
    end

    set_color green
    echo "✅ ファイル解析が完了しました"
    set_color normal

    if test $total_file_count -gt 100
        set_color yellow
        echo "🔄 ソート中..."
        set_color normal
    end

    switch $sort_type
        case size
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k3 -nr)
        case lines
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k2 -nr)
        case name
            set file_info_list (printf "%s\n" $file_info_list | sort -t: -k1)
    end

    if test $max_files -gt 0
        set file_info_list (printf "%s\n" $file_info_list | head -n $max_files)
        if test $max_files -lt $total_file_count
            set_color cyan
            echo "📋 上位 $max_files ファイルを表示します"
            set_color normal
        end
    end

    echo

    set_color cyan
    echo "📊 ファイル解析結果"
    set_color normal
    echo "────────────────────────────────────────────────────────────"

    switch $format
        case simple
            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0
            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l lines $parts[2]
                set -l size $parts[3]
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)
            end

            set -l formatted_total_size (__format_size $total_size)

            set_color green
            echo " 📁 合計ファイル数：$file_count"
            echo " 📝 合計行数：$total_lines 行"
            echo " 💾 合計サイズ：$formatted_total_size"
            set_color normal

        case detail
            set -l max_length 0
            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0

            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                set -l length (string length -- $file)
                set max_length (math "max($max_length, $length)")
            end
            set max_length (math $max_length + 3)

            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                set -l lines $parts[2]
                set -l size $parts[3]
                set -l formatted_size (__format_size $size)
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)

                set_color blue
                printf " %s" $file
                set_color normal

                set -l padding (math $max_length - (string length -- $file))
                printf "%"$padding"s" " "

                set_color yellow
                printf "│ "
                set_color green
                printf "%d 行" $lines
                set_color normal
                printf " "
                set_color cyan
                printf "(%s)\n" $formatted_size
                set_color normal
            end

            set -l formatted_total_size (__format_size $total_size)

            echo "────────────────────────────────────────────────────────────"
            set_color green
            echo " 📁 合計ファイル数：$file_count"
            echo " 📝 合計行数：$total_lines 行"
            echo " 💾 合計サイズ：$formatted_total_size"
            set_color normal

        case tree
            function __print_tree
                set -l path $argv[1]
                set -l prefix $argv[2]
                set -l is_last $argv[3]
                set -l lines $argv[4]
                set -l formatted_size $argv[5]

                set -l basename (basename $path)
                if test $is_last = true
                    set_color blue
                    printf "%s└── " $prefix
                else
                    set_color blue
                    printf "%s├── " $prefix
                end

                set_color normal
                printf "%s " $basename

                set_color green
                printf "(%d 行" $lines
                set_color normal
                printf ", "
                set_color cyan
                printf "%s)\n" $formatted_size
                set_color normal
            end

            set -l total_lines 0
            set -l total_size 0
            set -l file_count 0
            set -l prev_dir ""

            for info in $file_info_list
                set -l parts (string split ":" $info)
                set -l file $parts[1]
                set -l lines $parts[2]
                set -l size $parts[3]
                set -l formatted_size (__format_size $size)
                set total_lines (math $total_lines + $lines)
                set total_size (math $total_size + $size)
                set file_count (math $file_count + 1)

                set -l dir (dirname $file)
                set -l depth (string replace -r '^\./' '' $dir | string split '/' | count)
                set -l prefix " "
                if test $depth -gt 1
                    set prefix (string repeat --count (math $depth - 1) " ")
                end

                if test $dir != $prev_dir
                    if test $prev_dir != ""
                        echo
                    end
                    set_color yellow
                    echo " 📁 $dir"
                    set_color normal
                end

                if test $depth -eq 1
                    set prefix ""
                end

                set -l is_last true
                set -l current_index 0
                for info_check in $file_info_list
                    set current_index (math $current_index + 1)
                    if test "$info_check" = "$info"
                        break
                    end
                end

                if test $current_index -lt (count $file_info_list)
                    set -l next_info $file_info_list[(math $current_index + 1)]
                    set -l next_parts (string split ":" $next_info)
                    set -l next_file $next_parts[1]
                    if test (dirname $next_file) = $dir
                        set is_last false
                    end
                end

                __print_tree $file $prefix $is_last $lines $formatted_size
                set prev_dir $dir
            end

            set -l formatted_total_size (__format_size $total_size)

            echo
            echo "────────────────────────────────────────────────────────────"
            set_color green
            echo " 📁 合計ファイル数：$file_count"
            echo " 📝 合計行数：$total_lines 行"
            echo " 💾 合計サイズ：$formatted_total_size"
            set_color normal
    end

    echo

    functions -e __print_tree
    functions -e __format_size
end
