$ErrorActionPreference = 'Stop'

$backendPath = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $backendPath '.env'
function Test-ExistingAtlasConnection {
    Push-Location $backendPath
    try {
        $checkExitCode = 1
        try {
            & npm.cmd run db:check
            $checkExitCode = $LASTEXITCODE
        }
        catch {
            $checkExitCode = 1
        }
        return $checkExitCode -eq 0
    }
    finally {
        Pop-Location
    }
}

function Set-EnvironmentValue {
    param(
        [string[]]$Lines,
        [string]$Name,
        [string]$Value
    )

    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*='
    $replacement = "$Name=$Value"
    $found = $false

    for ($index = 0; $index -lt $Lines.Length; $index++) {
        if ($Lines[$index] -match $pattern) {
            if (-not $found) {
                $Lines[$index] = $replacement
                $found = $true
            }
            else {
                $Lines[$index] = $null
            }
        }
    }

    $Lines = @($Lines | Where-Object { $null -ne $_ })
    if (-not $found) {
        $Lines += $replacement
    }

    return ,$Lines
}

function Test-BackendHealthEndpoints {
    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        0
    )
    $listener.Start()
    $testPort = $listener.LocalEndpoint.Port
    $listener.Stop()

    $previousHost = [Environment]::GetEnvironmentVariable('HOST', 'Process')
    $previousPort = [Environment]::GetEnvironmentVariable('PORT', 'Process')
    $previousUri = [Environment]::GetEnvironmentVariable('MONGODB_URI', 'Process')
    $stdoutPath = Join-Path ([IO.Path]::GetTempPath()) "dailyduel-backend-$([Guid]::NewGuid()).out"
    $stderrPath = Join-Path ([IO.Path]::GetTempPath()) "dailyduel-backend-$([Guid]::NewGuid()).err"
    $serverProcess = $null

    try {
        [Environment]::SetEnvironmentVariable('HOST', '127.0.0.1', 'Process')
        [Environment]::SetEnvironmentVariable('PORT', "$testPort", 'Process')
        [Environment]::SetEnvironmentVariable('MONGODB_URI', $null, 'Process')

        $nodePath = (Get-Command node.exe -ErrorAction Stop).Source
        $serverProcess = Start-Process `
            -FilePath $nodePath `
            -ArgumentList 'src/server.js' `
            -WorkingDirectory $backendPath `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath `
            -PassThru
    }
    finally {
        [Environment]::SetEnvironmentVariable('HOST', $previousHost, 'Process')
        [Environment]::SetEnvironmentVariable('PORT', $previousPort, 'Process')
        [Environment]::SetEnvironmentVariable('MONGODB_URI', $previousUri, 'Process')
    }

    $baseUrl = "http://127.0.0.1:$testPort"
    $livenessVerified = $false
    $databaseVerified = $false

    try {
        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            if ($serverProcess.HasExited) {
                break
            }

            try {
                $health = Invoke-RestMethod "$baseUrl/health" -TimeoutSec 2
                $livenessVerified = $health.status -eq 'ok'
                if ($livenessVerified) {
                    $databaseHealth = Invoke-RestMethod "$baseUrl/health/database" -TimeoutSec 2
                    $databaseVerified =
                        $databaseHealth.status -eq 'ok' -and
                        $databaseHealth.database -eq 'connected'
                    if ($databaseVerified) {
                        break
                    }
                }
            }
            catch [System.Net.Http.HttpRequestException] {
                Start-Sleep -Milliseconds 500
            }
            catch [System.Net.WebException] {
                Start-Sleep -Milliseconds 500
            }
        }
    }
    finally {
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Stop-Process -Id $serverProcess.Id -Force
            $serverProcess.WaitForExit()
        }

        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }

    if (-not $livenessVerified -or -not $databaseVerified) {
        throw 'Backend health endpoint verification failed. Connection details were not displayed.'
    }

    Write-Host 'GET /health: ok'
    Write-Host 'GET /health/database: connected'
}

$originalContent = ''
$existingUriConfigured = $false
if (Test-Path -LiteralPath $envPath) {
    $originalContent = [System.IO.File]::ReadAllText($envPath)
    $existingUriConfigured = $originalContent -match '(?m)^\s*MONGODB_URI\s*=\s*\S+'

    if ($existingUriConfigured) {
        Write-Host 'Checking the existing MongoDB configuration without displaying its URI...'
        if (Test-ExistingAtlasConnection) {
            Write-Host 'The existing Atlas connection is verified; .env was left unchanged.'
            $replaceExisting = Read-Host 'Replace it anyway? Type REPLACE to continue'
            if ($replaceExisting -cne 'REPLACE') {
                Write-Host 'No changes made.'
                exit 0
            }
        }
        else {
            Write-Warning 'The existing MongoDB URI did not connect. Its value will remain private.'
            $replaceExisting = Read-Host 'Replace only MONGODB_URI after configuring a new one? Type REPLACE to continue'
            if ($replaceExisting -cne 'REPLACE') {
                Write-Host 'No changes made.'
                exit 1
            }
        }
    }
}

$databaseUsername = (Read-Host 'Atlas database username (confirm it in Atlas)')
if ([string]::IsNullOrWhiteSpace($databaseUsername)) {
    throw 'Database username is required.'
}
$databaseUsername = $databaseUsername.Trim()

$clusterHost = (Read-Host 'Atlas cluster hostname (enter exactly as shown in Atlas)')
if ([string]::IsNullOrWhiteSpace($clusterHost)) {
    throw 'Atlas cluster hostname is required.'
}
$clusterHost = $clusterHost.Trim().TrimEnd('.').ToLowerInvariant()
if ($clusterHost -notmatch '^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$') {
    throw 'Enter only a valid cluster hostname, without a URI scheme, port, or path.'
}

$databaseName = Read-Host 'Database name [dailyduel]'
if ([string]::IsNullOrWhiteSpace($databaseName)) {
    $databaseName = 'dailyduel'
}
$databaseName = $databaseName.Trim()
if ($databaseName -notmatch '^[A-Za-z0-9_-]+$') {
    throw 'Database name may contain only letters, numbers, underscores, and hyphens.'
}

$srvRecords = @(Resolve-DnsName -Name "_mongodb._tcp.$clusterHost" -Type SRV -ErrorAction Stop)
if (-not ($srvRecords | Where-Object { $_.Type -eq 'SRV' -and $_.NameTarget })) {
    throw 'The cluster hostname has no MongoDB SRV records. Confirm it in Atlas.'
}

$securePassword = Read-Host 'Atlas database password (input is hidden)' -AsSecureString
if ($securePassword.Length -eq 0) {
    throw 'Database password is required.'
}

$passwordPointer = [IntPtr]::Zero
try {
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $databasePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $encodedUsername = [Uri]::EscapeDataString($databaseUsername)
    $encodedPassword = [Uri]::EscapeDataString($databasePassword)
    $encodedDatabase = [Uri]::EscapeDataString($databaseName)
    $connectionUri = "mongodb+srv://${encodedUsername}:${encodedPassword}@${clusterHost}/${encodedDatabase}?retryWrites=true&w=majority&appName=DailyDuel"
}
finally {
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
    $databasePassword = $null
    $encodedPassword = $null
    $securePassword.Dispose()
}

$lines = @()
if ($originalContent.Length -gt 0) {
    $lines = @($originalContent -split '\r?\n')
    if ($lines.Count -gt 0 -and $lines[-1] -eq '') {
        if ($lines.Count -gt 1) {
            $lines = $lines[0..($lines.Count - 2)]
        }
        else {
            $lines = @()
        }
    }
}

$lines = Set-EnvironmentValue -Lines $lines -Name 'HOST' -Value '127.0.0.1'
$lines = Set-EnvironmentValue -Lines $lines -Name 'PORT' -Value '3000'
$lines = Set-EnvironmentValue -Lines $lines -Name 'MONGODB_URI' -Value $connectionUri
$connectionUri = $null

$newContent = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
$temporaryPath = "$envPath.tmp"
[System.IO.File]::WriteAllText(
    $temporaryPath,
    $newContent,
    [System.Text.UTF8Encoding]::new($false)
)
Move-Item -LiteralPath $temporaryPath -Destination $envPath -Force

Write-Host 'Local backend/.env configured. No credentials were displayed.'
Write-Host 'Testing MongoDB Atlas connectivity...'
Push-Location $backendPath
try {
    & npm.cmd run db:check
    if ($LASTEXITCODE -ne 0) {
        throw 'Atlas connection verification failed. Use the sanitized diagnostic above; do not share .env.'
    }
}
finally {
    Pop-Location
}

Test-BackendHealthEndpoints
