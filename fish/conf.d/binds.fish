# 関数定義を読み込む
source ~/.config/fish/functions/github.fish

# github.com 用のキーバインド (Ctrl+g)
bind \cg '__ghq_repository_search github'
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cg '__ghq_repository_search github'
end

# archive.github.com 用のキーバインド (Ctrl+a)
bind \ca '__ghq_repository_search archive.github'
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \ca '__ghq_repository_search archive.github'
end
