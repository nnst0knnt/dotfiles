# 🚀 WSL2 + Fish + Neovim 開発環境構築ガイド

開発環境を一から構築するための完全ガイドです。

## 📋 前提条件

この環境構築には以下が必要です。

- **Windows 11** with WSL2
- **Fish shell**　モダンで使いやすいシェル
- **Fisher**　Fish package manager
- **Homebrew**　パッケージ管理ツール
- **JetBrains Mono Nerd Font**　美しいアイコン表示用フォント

## 🎯 完成後の環境

この手順を完了すると、以下のような環境が手に入ります。

✨ **美しいターミナル**　JetBrains Mono Nerd Fontによる美しいアイコン表示  
⚡ **高速なファイル検索**　fzf + ripgrepによる爆速検索  
🎨 **モダンなNeovim**　プラグイン満載の美しいエディタ  
🐚 **Fish shell**　自動補完とシンタックスハイライト  
🔧 **カスタム関数**　生産性を向上させる便利コマンド  

## 🛠️ セットアップ手順

### 1️⃣ WSL2とLinuxディストリビューションのインストール

まずはWSL2の基盤を整えます。

```powershell
# PowerShellで実行
wsl --install
```

インストール完了後、Ubuntuを起動してユーザー設定を完了してください。

### 2️⃣ 基本ツールのインストール

開発に必要な基本ツールをインストールします。

```bash
# システムアップデート
sudo apt update && sudo apt upgrade -y

# ベース開発ツール
sudo apt install build-essential git curl unzip tree
sudo add-apt-repository ppa:wslutilities/wslu
sudo apt install wslu

# Homebrew のインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Fish shell のインストール
sudo apt install fish

# Fish をデフォルトシェルに設定
chsh -s $(which fish)

# Fisher のインストール（Fish起動後に実行）
fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher decors/fish-ghq
exit
```

### 3️⃣ Neovim関連ツールのインストール

⚠️ **重要** この手順はNeovimの検索機能に必須です

```bash
# Neovimのインストール（AppImage版）
cd /opt
sudo curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
sudo chmod u+x nvim.appimage
sudo mv nvim.appimage nvim
```

### 4️⃣ JetBrains Mono Nerd Font設定

美しいアイコン表示のために、**両方の環境**でフォントをインストールします。

#### 📱 WSL2側（Linux）でのフォントインストール

```bash
# JetBrains Mono Nerd Fontをダウンロード・インストール
cd ~
mkdir -p ~/.local/share/fonts
curl -fLo "JetBrainsMono.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip -d JetBrainsMono
cp JetBrainsMono/*.ttf ~/.local/share/fonts/
fc-cache -fv
rm -rf JetBrainsMono JetBrainsMono.zip

# フォントインストール確認
fc-list | grep -i jetbrains
```

#### 🪟 Windows側でのフォントインストール

1. [JetBrains Mono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip)をダウンロード
2. zipファイルを解凍
3. `.ttf`ファイルを選択 → 右クリック → **すべてのユーザーに対してインストール**

#### ⚙️ Windows Terminalのフォント設定

1. Windows Terminalを開く
2. `Ctrl + ,`で設定を開く
3. プロファイル → Ubuntu → 外観
4. フォントフェイスを**JetBrains Mono**または**JetBrainsMono Nerd Font**に変更
5. 保存して**Windows Terminalを完全に再起動**

### 5️⃣ ghqのセットアップ

dotfilesをghq経由で管理するための準備をします。

```bash
# Homebrewの環境変数設定
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ghqのインストール
brew install ghq

# ghq rootディレクトリの設定
git config --global ghq.root "~/workspaces"

# ワークスペースディレクトリの作成
mkdir -p ~/workspaces
```

### 6️⃣ SSH鍵の設定

GitHub接続用のSSH鍵を設定します。

```bash
# SSH鍵を適切な場所に配置
# 権限設定
chmod 600 ~/.ssh/*/{private_key}
chmod 644 ~/.ssh/config ~/.ssh/*/config

# SSH接続テスト
ssh -T git@github.com
```

### 7️⃣ dotfilesのクローン

ghqを使ってSSH経由でdotfilesをクローンします。

```bash
# ghq経由でSSH接続でクローン
ghq get git@github.com:nnst0knnt/dotfiles.git

# クローンされた場所を確認
ghq list | grep dotfiles
# ~/workspaces/github.com/nnst0knnt/dotfiles

# dotfilesディレクトリに移動
cd $(ghq root)/github.com/nnst0knnt/dotfiles
```

### 8️⃣ 設定ファイルの配置

クローンしたdotfilesから設定ファイルをコピーします。

```bash
# dotfilesディレクトリから実行
cd $(ghq root)/github.com/nnst0knnt/dotfiles

# Fish設定
mkdir -p ~/.config/fish/{conf.d,functions}
cp fish/config.fish ~/.config/fish/
cp fish/conf.d/* ~/.config/fish/conf.d/
cp fish/functions/* ~/.config/fish/functions/

# Git設定
cp git/.gitconfig ~/.gitconfig
cp git/gitmojis.json ~/.gitmojis.json

# Neovim設定
mkdir -p ~/.config/nvim/lua
cp nvim/init.lua ~/.config/nvim/
cp nvim/lua/plugins.lua ~/.config/nvim/lua/

# SSH設定
mkdir -p ~/.ssh/{github,remousa}
cp ssh/config ~/.ssh/
cp ssh/github/config ~/.ssh/github/
cp ssh/remousa/config ~/.ssh/remousa/

# PowerShell設定
clip power-shell/Microsoft.PowerShell_profile.ps1
# PowerShellを開く
notepad $PROFILE
# ペーストして上書き
# PowerShellの起動コマンドを C:\Program Files\PowerShell\7\pwsh.exe -NoLogo に上書き
```

### 9️⃣ Fish設定とNeovimの統合

エディタとシェルの連携を設定します。

#### 🐚 Fish config.fishの設定確認

リポジトリのfish/config.fishに以下が含まれていることを確認します。

```fish
# エディタ設定
set -gx EDITOR nvim
set -gx VISUAL nvim

# エイリアス
alias vim='nvim'
alias vi='nvim'
```

#### 📝 Git設定

```bash
# デフォルトエディタをNeovimに設定
git config --global core.editor "nvim"
```

### 🔟 追加のパッケージインストール

生産性向上のための追加ツールをインストールします。

```bash
# 必要なツール
brew install gh fzf gitmoji xh bat eza fd ripgrep delta

# Fisher プラグイン（必要に応じて）
fisher install jorgebucaran/nvm.fish
# デフォルトのバージョンを設定する場合
nvm list
set --universal nvm_default_version {version}
# Homebrew経由でインストールしたgitmojiで使用されるNode.jsとのバッティング回避
brew uninstall node --ignore-dependencies
# 先頭行を #!/usr/bin/env node に変更
which gitmoji | xargs code
# バージョンが一致しているか確認
node -v
nvm current
```

### 1️⃣1️⃣ 動作確認

#### 🎨 フォント確認テスト

```bash
# Nerd Fontアイコンのテスト
printf "\ue5fe \uf07b \uf1c0 \uf0c7 \uf013\n"
```

#### 🔧 Neovim確認

```bash
# Neovimを起動してプラグインインストール
nvim
```

Neovim内で以下を実行して動作確認します。

```vim
:checkhealth
:Lazy
:NvimTreeToggle
```

#### 📄 各種ファイルタイプの確認

```bash
# 各種ファイルを作成してアイコン確認
touch README.md test.js test.py package.json
nvim README.md
```

### 1️⃣2️⃣ 環境固有の設定を調整

以下のファイルで、環境に応じてパスやユーザー名を変更してください。

#### 🐚 fish/config.fish
- 29行目 VS Code のパス（Windowsユーザー名を変更）
- 40行目 Homebrew のパス（必要に応じて調整）

```fish
# 例 ユーザー名部分を変更
set -x PATH $PATH:'/mnt/c/Users/YOUR_USERNAME/AppData/Local/Programs/Microsoft VS Code/bin'
```

#### 📂 fish/functions/github.fish
- 30行目 ワークスペースのパス（/home/[ユーザー名]/workspaces）

#### 📝 Git設定（個別に設定）

```bash
# ユーザー情報を設定
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_EMAIL@example.com"
```

#### 🔐 SSH設定
- ssh/github/config 秘密鍵のパス（~/.ssh/github/[キー名]）
- ssh/remousa/config 秘密鍵のパス（~/.ssh/remousa/[キー名]）

### 1️⃣3️⃣ 設定の確認

すべての設定が正しく動作することを確認します。

```bash
# Fish設定の確認
fish
echo $PATH

# Git設定の確認
git config --list

# SSH設定の確認
ssh -T git@github.com

# ghqの動作確認
ghq list
```

## 🚨 トラブルシューティング

### 🎨 アイコンが表示されない場合

1. **Windows Terminalのフォント設定を確認**
   ```bash
   # Windows TerminalでJetBrains Monoが選択されているか確認
   ```

2. **WSL2でのフォント確認**
   ```bash
   fc-list | grep -i jetbrains
   ```

3. **Neovim内でアイコンテスト**
   ```vim
   :lua print(require("nvim-web-devicons").get_icon("README.md"))
   ```

### 🔍 Telescopeの検索が動作しない場合

```bash
# ripgrepとfd-findの確認
which rg
which fd

# 不足している場合は再インストール
sudo apt install ripgrep fd-find
sudo ln -s $(which fdfind) /usr/local/bin/fd
```

### 🔌 プラグインエラーの場合

```vim
:checkhealth
:Lazy clean
:Lazy sync
```

### 📂 ghqが動作しない場合

```bash
# ghqの設定確認
git config --get ghq.root

# パスの確認
which ghq

# 再インストール
brew reinstall ghq
```

## ⚠️ 注意事項

- **WSL2環境での使用を想定**しています
- **Windows側とWSL2側の両方**でJetBrains Mono Nerd Fontのインストールが必要
- **SSH鍵は別途生成・配置**する必要があります
- **環境に応じてパスの調整**が必要です
- **初回Neovim起動時**にプラグインインストールで数分かかる場合があります
- **ghq経由でのクローン**を前提としているため、ghqの設定が重要です
