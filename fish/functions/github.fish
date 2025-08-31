function __ghq_get_findable_directory_name -a kind
    switch "$kind"
        case github
            echo "github.com"
        case "archive.github"
            echo "archive.github.com"
        case '*'
            echo ""
    end
end

function __ghq_repository_search -d 'Repository search' -a kind
    set -l selector
    [ -n "$GHQ_SELECTOR" ]; and set selector $GHQ_SELECTOR; or set selector fzf
    set -l selector_options
    [ -n "$GHQ_SELECTOR_OPTS" ]; and set selector_options $GHQ_SELECTOR_OPTS

    if not type -qf $selector
        printf "\nERROR：'$selector' not found.\n"
        return 1
    end

    set -l directory_name (__ghq_get_findable_directory_name $kind)

    if [ -z "$directory_name" ]
        printf "\nERROR：Invalid repository kind：$kind\n"
        return 1
    end

    set -l base (ghq root)
    set -l path "$base/$directory_name"
    if [ ! -d "$path" ]
        printf "\nERROR：Path not found：$path\n"
        return 1
    end

    set -l query (commandline -b)
    [ -n "$query" ]; and set flags --query="$query"; or set flags
    set -l select

    if test "$selector" = fzf
        set -a selector_options \
            "--preview=cat '$path/{}'/README.md 2>/dev/null || cat '$path/{}'/README 2>/dev/null" \
            "--height=55%" \
            "--layout=reverse" \
            "--info=inline" \
            "--border=none" \
            "--margin=0,0"
    end

    switch "$selector"
        case fzf fzf-tmux peco percol fzy sk
            ghq list --full-path | command grep "/$directory_name/" | sed "s|$path/||" | "$selector" $selector_options $flags | read select
        case \*
            printf "\nERROR：plugin-ghq is not support '$selector'.\n"
    end

    if [ -n "$select" ]
        cd "$path/$select"
    end

    commandline -f repaint
end
