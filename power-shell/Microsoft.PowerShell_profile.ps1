# Commands
Clear-Host

# PSReadLine
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{
    Command = 'White'                    # コマンド：白
    Parameter = 'White'                  # パラメータ：白
    Operator = 'White'                   # 演算子：白
    Variable = 'White'                   # 変数：白
    String = 'White'                     # 文字列：白
    Number = 'White'                     # 数値：白
    Comment = 'DarkGray'                 # コメント：グレー
    Error = 'Red'                        # エラー：赤
    InlinePrediction = 'DarkGray'        # インライン予測：グレー
    ListPrediction = 'DarkGray'          # リスト予測：グレー
}

# Functions
function prompt {
    $Esc = [char]27
    $Reset = "${Esc}[0m"

    $Green = "${Esc}[32m"
    $White = "${Esc}[37m"
    $Blue  = "${Esc}[36m"

    $user = $env:USERNAME
    $currentPath = (Get-Location).Path
    $psVersion = $PSVersionTable.PSVersion.ToString()
    
    # ホームディレクトリを ~ に置換
    $homePath = $env:USERPROFILE
    if ($currentPath.StartsWith($homePath)) {
        $currentPath = $currentPath.Replace($homePath, "~")
    }
    
    # パスを分割して省略形に変換
    $pathParts = $currentPath -split '[/\\]'
    
    if ($pathParts.Length -gt 1) {
        # 最初の部分（~やドライブ文字）と最後の部分以外を省略
        $abbreviatedParts = @()
        
        # 最初の部分をそのまま追加
        $abbreviatedParts += $pathParts[0]
        
        # 中間の部分を省略（最初の文字のみ）
        for ($i = 1; $i -lt $pathParts.Length - 1; $i++) {
            if ($pathParts[$i] -ne "") {
                $abbreviatedParts += $pathParts[$i].Substring(0, 1)
            }
        }
        
        # 最後の部分（カレントディレクトリ）をフルネームで追加
        if ($pathParts[-1] -ne "") {
            $abbreviatedParts += $pathParts[-1]
        }
        
        $location = $abbreviatedParts -join "/"
    } else {
        $location = $currentPath
    }

    # プロンプト文字列を返す（重要：戻り値として返す）
    return "$Green@Windows(PowerShell $psVersion) $White$location`n$ $Reset"
}

function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

# Bindings
Set-PSReadlineKeyHandler -Key "Ctrl+;" -Function BeginningOfLine
Set-PSReadlineKeyHandler -Key "Ctrl+'" -Function EndOfLine
