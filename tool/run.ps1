param(
  [ValidateSet('run', 'web', 'apk')][string]$Action = 'run',
  [string]$Device = 'chrome',
  [string]$Config = 'config.json'
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectDirectory
$arguments = @()
$mapsKey = ''
if (Test-Path -LiteralPath $Config) {
  $settings = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
  $mapsKey = $settings.GOOGLE_MAPS_API_KEY
  $arguments += "--dart-define-from-file=$Config"
}
@{ GOOGLE_MAPS_API_KEY = $mapsKey } | ConvertTo-Json | Set-Content -Encoding utf8 web/maps-config.json
switch ($Action) {
  'run' { & flutter run -d $Device @arguments }
  'web' { & flutter build web --pwa-strategy=none @arguments }
  'apk' { & flutter build apk @arguments }
}
exit $LASTEXITCODE
