function fish_prompt
    if not set -q VIRTUAL_ENV_DISABLE_PROMPT
        set -g VIRTUAL_ENV_DISABLE_PROMPT true
    end

    set_color 13a10e
    printf '@WSL(%s) ' (command grep PRETTY_NAME /etc/os-release | sed -E "s/.*\"([^\"]+)\".*/\1/")

    set fish_prompt_pwd_dir_length 3
    set_color normal
    printf '%s ' (prompt_pwd)

    set last_status $status
    set_color 13a10e -o -u
    printf '%s'(fish_git_prompt | string replace -r '[(]' '' | string replace -r '[)]' '' | string replace -r ' ' '')

    echo
    if test -n "$VIRTUAL_ENV"
        printf "(%s) " (set_color blue)(basename $VIRTUAL_ENV)(set_color normal)
    end

    set_color normal
    printf '$ ' (string trim $USER)
end
