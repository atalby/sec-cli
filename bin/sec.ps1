# bin/sec.ps1: Native Windows PowerShell zero-plaintext secret manager wrapper
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Command,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$Key,

    [Parameter(Position=2, Mandatory=$false)]
    [string]$Value
)

$CacheDir = "$HOME\.cache\bitwarden"
$SessionFile = "$CacheDir\session"

if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

function Ensure-BwSession {
    if (-not $env:BW_SESSION -and (Test-Path $SessionFile)) {
        $env:BW_SESSION = Get-Content $SessionFile -Raw
    }
}

switch ($Command) {
    "get" {
        if (-not $Key) { Write-Error "Usage: sec.ps1 get <key> or sec.ps1 get <item>/<field>"; exit 1 }
        Ensure-BwSession

        $itemName = $Key
        $fieldName = $null

        if ($Key -like "*/*") {
            $parts = $Key.Split('/')
            $itemName = $parts[0]
            $fieldName = $parts[1]
        }

        if (Get-Command bws -ErrorAction SilentlyContinue) {
            $val = bws secret get $Key --value-only 2>$null
            if ($val) { $val; exit 0 }
        }
        
        if (Get-Command bw -ErrorAction SilentlyContinue) {
            $items = bw list items --search $itemName 2>$null | ConvertFrom-Json
            if ($items.Count -gt 1 -and -not $fieldName) {
                Write-Host "[sec] Notice: Multiple items match '$itemName'. Use 'sec get \"$itemName/field\"' for exact targeting." -ForegroundColor Yellow
            }
            if ($items.Count -ge 1) {
                $item = $items[0]
                if ($fieldName) {
                    if ($fieldName -eq "password") { $item.login.password }
                    elseif ($fieldName -eq "username") { $item.login.username }
                    elseif ($fieldName -eq "notes") { $item.notes }
                    else { ($item.fields | Where-Object { $_.name -eq $fieldName }).value }
                } else {
                    if ($item.notes) { $item.notes } else { $item.login.password }
                }
                exit 0
            }
        }

        if (Get-Command op -ErrorAction SilentlyContinue) {
            if ($fieldName) {
                op read "op://private/$itemName/$fieldName" 2>$null
            } else {
                op read "op://private/$Key/password" 2>$null
            }
            exit 0
        }

        Write-Error "[sec] Error: Secret '$Key' not found."
        exit 1
    }
    "set" {
        if (-not $Key) { Write-Error "Usage: sec.ps1 set <key> [<val>]"; exit 1 }
        Ensure-BwSession
        if (-not $Value) {
            $Value = Read-Host -Prompt "Enter secret value for '$Key'" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
            $Value = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }

        if (Get-Command bws -ErrorAction SilentlyContinue) {
            $projId = (bws project list 2>$null | ConvertFrom-Json)[0].id
            if ($projId) {
                bws secret create $Key $Value $projId | Out-Null
                Write-Host "[sec] Secret '$Key' saved to Bitwarden Secrets Manager."
                exit 0
            }
        }
        if (Get-Command bw -ErrorAction SilentlyContinue) {
            $tmpl = bw get template item | ConvertFrom-Json
            $tmpl.name = $Key
            $tmpl.type = 1
            $tmpl.login.password = $Value
            $encoded = $tmpl | ConvertTo-Json -Depth 5 | bw encode
            bw create item $encoded | Out-Null
            Write-Host "[sec] Secret '$Key' saved to Bitwarden Vault."
            exit 0
        }
    }
    "housekeep" {
        Ensure-BwSession
        $scriptPath = "$PSScriptRoot\sec-organizer"
        if (Test-Path $scriptPath) {
            bash $scriptPath $Key
        } else {
            Write-Error "[sec] Error: sec-organizer script not found."
        }
    }
    "migrate" {
        Ensure-BwSession
        $scriptPath = "$PSScriptRoot\sec-migrator"
        if (Test-Path $scriptPath) {
            bash $scriptPath $args
        } else {
            Write-Error "[sec] Error: sec-migrator script not found."
        }
    }
    "run" {
        Ensure-BwSession
        if (Get-Command bws -ErrorAction SilentlyContinue) {
            bws run -- $args
        } elseif (Get-Command op -ErrorAction SilentlyContinue) {
            op run -- $args
        } else {
            Invoke-Expression ($args -join " ")
        }
    }
    default {
        Write-Host "Fleet Zero-Plaintext Secret Manager (sec.ps1)"
        Write-Host "Usage: sec.ps1 {get|set|run|housekeep|migrate} <args>"
    }
}
