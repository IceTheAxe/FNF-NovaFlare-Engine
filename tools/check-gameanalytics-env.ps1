param([switch]$Required)

$ErrorActionPreference = 'Stop'
$names = @('NOVA_GA_GAME_KEY', 'NOVA_GA_SECRET_KEY')
$missing = @($names | Where-Object {
    [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))
})

if ($missing.Count -eq 0) {
    Write-Output 'GameAnalytics build credentials are configured.'
} elseif ($Required) {
    # 只有显式 -Required 才把缺失当错误。默认放行，让没有 key 的构建正常出包
    # （此时 GAMEANALYTICS_ENABLED 未定义，GABridge 编译为空实现）。
    throw ('Missing GameAnalytics build environment variables: ' + ($missing -join ', '))
} else {
    Write-Output 'GameAnalytics is disabled for this build; no credentials were supplied.'
}
