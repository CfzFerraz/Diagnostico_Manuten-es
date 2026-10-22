#requires -Version 5.1
< #
    KIT PROFISSIONAL DE DIAGNOSTICO WINDOWS V2.0
    Compatibilidade: Windows 10 / Windows 11 - Windows PowerShell 5.1

    Principios:
      - Somente leitura por padrao.
      - Toda operacao potencialmente modificadora exige confirmacao.
      - Cada teste gera seu proprio TXT.
      - Erros de um modulo nao interrompem o diagnostico inteiro.
      - Hipoteses sao apresentadas como indicios, nunca como certezas.

    Ponto de entrada: Diagnostico_V2.bat
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'SilentlyContinue'
$Script:BaseDesktop = [Environment]::GetFolderPath('Desktop')
$Script:ReportRoot = Join-Path $Script:BaseDesktop 'Diagnosticos_PC'
$Script:HistoryFile = Join-Path $Script:ReportRoot 'Historico_Diagnosticos.txt'
$Script:CurrentFindings = New-Object System.Collections.ArrayList
$Script:LastReport = $null
$Script:SessionReports = New-Object System.Collections.ArrayList
$Script:SessionStart = Get-Date
$Script:FullDiagnosticMode = $false

function Initialize-Environment {
    try {
        if (-not (Test-Path -LiteralPath $Script:ReportRoot)) {
            New-Item -ItemType Directory -Path $Script:ReportRoot -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $Script:HistoryFile)) {
            @(
                '============================================================'
                'HISTORICO DE DIAGNOSTICOS'
                '============================================================'
            ) | Set-Content -LiteralPath $Script:HistoryFile -Encoding UTF8
        }
    } catch {
        Write-Host "[ERRO] Nao foi possivel preparar a pasta de diagnosticos: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Get-AdminText {
    if (Test-IsAdmin) { return 'SIM' }
    return 'NAO'
}

function Get-CimSafe {
    param(
        [Parameter(Mandatory=$true)][string]$ClassName,
        [string]$Namespace = 'root/cimv2',
        [string]$Filter
    )
    try {
        if ($Filter) {
            return @(Get-CimInstance -Namespace $Namespace -ClassName $ClassName -Filter $Filter -ErrorAction Stop)
        }
        return @(Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ErrorAction Stop)
    } catch {
        return @()
    }
}

function Normalize-NativeText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $t = $Text -replace "`0", ''
    $t = $t -replace "\uFEFF", ''
    return $t.Trim()
}

function Invoke-NativeSafe {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    try {
        $output = & $FilePath @ArgumentList 2>&1
        return (Normalize-NativeText (($output | Out-String)))
    } catch {
        return "[ERRO AO EXECUTAR $FilePath] $($_.Exception.Message)"
    }
}

function Invoke-NativeCapture {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [int]$TimeoutSeconds = 900
    )
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = (($ArgumentList | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"','\\"') + '"' } else { $_ } }) -join ' ')
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEndAsync()
        $stderr = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
            try { $p.Kill() } catch {}
            return [pscustomobject]@{ ExitCode = -1; Output = '[TIMEOUT] Processo excedeu o limite.' }
        }
        $text = ($stdout.Result + "`r`n" + $stderr.Result).Trim()
        return [pscustomobject]@{ ExitCode = $p.ExitCode; Output = $text }
    } catch {
        return [pscustomobject]@{ ExitCode = -1; Output = "[ERRO] $($_.Exception.Message)" }
    }
}

function Get-ToolPath {
    param([string]$Name)
    $candidates = @(
        (Join-Path $PSScriptRoot (Join-Path 'tools' $Name)),
        (Join-Path $env:ProgramFiles (Join-Path 'smartmontools\bin' $Name)),
        (Join-Path ${env:ProgramFiles(x86)} (Join-Path 'smartmontools\bin' $Name)),
        (Join-Path $env:LOCALAPPDATA (Join-Path 'Programs\smartmontools\bin' $Name))
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path -LiteralPath $c)) { return $c } }
    try {
        $cmd = Get-Command $Name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    } catch {}
    if ($Name -eq 'LibreHardwareMonitor.exe') {
        try {
            $wg = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
            $hit = Get-ChildItem -LiteralPath $wg -Filter $Name -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        } catch {}
    }
    return $null
}

function Convert-ToolTextToLines {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @('[SEM SAIDA]') }
    return @($Text -split "`r?`n")
}

function Get-SfcResultClass {
    param([string]$Text)
    if ($Text -match 'did not find any integrity violations|não encontrou violações de integridade|nenhuma violação de integridade') { return 'OK' }
    if ($Text -match 'found corrupt|encontrou violações de integridade|encontrou arquivos corrompidos|could not repair|não pôde corrigir|cannot repair') { return 'PROBLEMA' }
    return 'INDETERMINADO'
}

function Get-DismResultClass {
    param([string]$Text)
    if ($Text -match 'No component store corruption detected|nenhuma corrupção foi detectada|repositório de componentes não apresenta corrupção') { return 'OK' }
    if ($Text -match 'repairable|reparável|component store corruption|corrupção.*component') { return 'PROBLEMA' }
    return 'INDETERMINADO'
}

