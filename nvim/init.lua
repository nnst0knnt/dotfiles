-- ~/.config/nvim/init.lua
-- JetBrains Mono Nerd Font用のクリーンなNeovim設定

-- 基本設定
vim.opt.number = true                -- 行番号表示
vim.opt.relativenumber = false       -- 相対行番号
vim.opt.mouse = 'a'                 -- マウス有効
vim.opt.ignorecase = true           -- 検索時大文字小文字を無視
vim.opt.smartcase = true            -- 大文字が含まれる場合は区別
vim.opt.hlsearch = true             -- 検索結果ハイライト
vim.opt.wrap = false                -- 行の折り返しなし
vim.opt.breakindent = true          -- 折り返し時のインデント保持
vim.opt.tabstop = 2                 -- タブの幅
vim.opt.shiftwidth = 2              -- インデントの幅
vim.opt.expandtab = true            -- タブをスペースに変換
vim.opt.autoindent = true           -- 自動インデント
vim.opt.smartindent = true          -- スマートインデント
vim.opt.clipboard = 'unnamedplus'   -- システムクリップボード連携
vim.opt.splitbelow = true           -- 水平分割を下に
vim.opt.splitright = true           -- 垂直分割を右に
vim.opt.termguicolors = true        -- 24bit色有効
vim.opt.updatetime = 250            -- スワップファイル書き込み間隔
vim.opt.timeoutlen = 300            -- キーシーケンスタイムアウト
vim.opt.completeopt = 'menuone,noselect'  -- 補完メニュー設定
vim.opt.undofile = true             -- アンドゥファイル永続化
vim.opt.signcolumn = 'yes'          -- サインカラムを常に表示
vim.opt.cursorline = true           -- カーソル行ハイライト
vim.opt.scrolloff = 8               -- スクロール時の余白
vim.opt.sidescrolloff = 8           -- 横スクロール時の余白

-- リーダーキー設定
vim.g.mapleader = ' '               -- スペースをリーダーキーに
vim.g.maplocalleader = ' '

-- 基本キーマップ
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 基本操作
keymap('n', '<C-s>', ':w<CR>', opts)           -- Ctrl+S: 保存
keymap('i', '<C-s>', '<Esc>:w<CR>a', opts)     -- Insert モードでも保存
keymap('n', '<C-a>', 'ggVG', opts)             -- Ctrl+A: 全選択
keymap('i', '<C-a>', '<Esc>ggVG', opts)        -- Insert モードでも全選択

-- コピー・ペースト・カット
keymap('v', '<C-c>', '"+y', opts)              -- Ctrl+C: コピー（ビジュアルモード）
keymap('n', '<C-c>', '"+yy', opts)             -- Ctrl+C: 行コピー（ノーマルモード）
keymap('i', '<C-v>', '<C-r>+', opts)           -- Ctrl+V: ペースト（インサートモード）
keymap('n', '<C-v>', '"+p', opts)              -- Ctrl+V: ペースト（ノーマルモード）
keymap('v', '<C-v>', '"+p', opts)              -- Ctrl+V: ペースト（ビジュアルモード）
keymap('v', '<C-x>', '"+d', opts)              -- Ctrl+X: カット（ビジュアルモード）
keymap('n', '<C-x>', '"+dd', opts)             -- Ctrl+X: 行カット（ノーマルモード）

-- アンドゥ・リドゥ
keymap('n', '<C-z>', 'u', opts)                -- Ctrl+Z: アンドゥ
keymap('i', '<C-z>', '<Esc>ua', opts)          -- Insert モードでもアンドゥ
keymap('n', '<C-y>', '<C-r>', opts)            -- Ctrl+Y: リドゥ
keymap('i', '<C-y>', '<Esc><C-r>a', opts)      -- Insert モードでもリドゥ

-- 検索・置換
keymap('n', '<C-f>', '/', opts)                -- Ctrl+F: 検索
keymap('i', '<C-f>', '<Esc>/', opts)           -- Insert モードでも検索
keymap('n', '<C-h>', ':%s/', opts)             -- Ctrl+H: 置換

-- 行操作
keymap('i', '<C-d>', '<Esc>dda', opts)         -- Ctrl+D: 行削除（Insert モード）
keymap('n', '<C-d>', 'dd', opts)               -- Ctrl+D: 行削除（ノーマルモード）

-- Shift+矢印キーでの選択（標準エディタライク）
keymap('n', '<S-Right>', 'v<Right>', opts)     -- Shift+→: 右に文字選択
keymap('n', '<S-Left>', 'v<Left>', opts)       -- Shift+←: 左に文字選択
keymap('n', '<S-Up>', 'v<Up>', opts)           -- Shift+↑: 上に行選択
keymap('n', '<S-Down>', 'v<Down>', opts)       -- Shift+↓: 下に行選択

keymap('v', '<S-Right>', '<Right>', opts)      -- 選択中の右拡張
keymap('v', '<S-Left>', '<Left>', opts)        -- 選択中の左拡張
keymap('v', '<S-Up>', '<Up>', opts)            -- 選択中の上拡張
keymap('v', '<S-Down>', '<Down>', opts)        -- 選択中の下拡張

-- 単語単位の選択
keymap('n', '<C-S-Right>', 'vw', opts)         -- Ctrl+Shift+→: 単語選択
keymap('n', '<C-S-Left>', 'vb', opts)          -- Ctrl+Shift+←: 逆方向単語選択
keymap('v', '<C-S-Right>', 'w', opts)          -- 選択中の単語拡張
keymap('v', '<C-S-Left>', 'b', opts)           -- 選択中の逆方向拡張

-- 行選択
keymap('n', '<C-l>', 'V', opts)                -- Ctrl+L: 行選択

-- プラグイン読み込み
require('plugins')
