################
# Scripts name : check-process.ps1
# Usage        : ./check-process.ps1
#                同一ディレクトリにcheck-process.confを配置し、タスクスケジューラーで定期実行する。
#                事前にAdmin権限で以下コマンドをを実行すること。
#                New-EventLog -LogName Application -Source "Process Check Script"
# Description  : Windowsプロセスチェックスクリプト
# Create       : 2017/12/16 Tetsu Okamoto (https://tech-mmmm.blogspot.jp/)
# Modify       : 
################

$currentdir = Split-Path -Parent $MyInvocation.MyCommand.Path
$conffile = $currentdir + "\check-process.conf"    # 設定ファイル
$tmpfile = $currentdir + "\check-process.tmp"      # プロセス情報保存用一時ファイル
$event_source = "Process Check Script"

# すでにDownしているプロセス情報を取得
$down_process = Get-Content $tmpfile
echo $null | Out-File $tmpfile

# 設定ファイル読み込み
foreach ($line in (Get-Content $conffile)) {
    # 空白区切りで分割 (p[0] : プロセス名, p[1] : プロセス数)
    $p = $line.split(" ",[StringSplitOptions]::RemoveEmptyEntries)
    
    # コメント行と空行を処理しない
    if ( $p[0] -notmatch "^ *#|^$" ){
        # 現在のプロセス数を取得
        $count = (Get-Process | Where-Object {$_.name -like $p[0] + "*"}).count
        
        # プロセス数チェック
        if ( $count -lt $p[1] ){
            # Down時の処理
            # Downしているプロセスか確認
            if ( $down_process -eq $p[0] ){
                # すでにDown
                $message = "Process """ + $p[0] + """ still down"
                $event_type = "Information"
            }else{
                # 初回Down
                $message = "Process """ + $p[0] + """ down"
                $event_type = "Error"
            }
            
            # イベントログに出力
            Write-EventLog -LogName Application -EntryType $event_type -Source "Process Check Script" -EventId 100 -Message $message
            echo $p[0] | Out-File -Append $tmpfile
        }else{
            # Up時の処理
            # Downしていたプロセスか確認
            if ( $down_process -eq $p[0] ){
                # Downだった
                $message = "Process """ + $p[0] + """ up"
                $event_type = "Information"
                
                # イベントログに出力
                Write-EventLog -LogName Application -EntryType $event_type -Source "Process Check Script" -EventId 100 -Message $message
            }
        }
    }
}




