<#
    .SYNOPSIS
    Windows RSAT installer

    .DESCRIPTION
    Install:   %WINDIR%\SysNative\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "install-rsat.ps1" -install
    Uninstall: %WINDIR%\SysNative\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "install-rsat.ps1" -uninstall

    .RUNSAS
    SYSTEM

    .ENVIRONMENT
    PowerShell 5.0

    .AUTHOR
    Niklas Rast
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, ParameterSetName = 'install')]
    [switch]$install,
    [Parameter(Mandatory = $True, ParameterSetName = 'uninstall')]
    [switch]$uninstall
)

try {

    $logFile = ('{0}\{1}.log' -f "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs", [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))

    $featureList = Get-WindowsCapability -Online -Name RSAT* -Source $PSScriptRoot -ErrorAction Stop

    if ($install) {
        $featureList |
        Add-WindowsCapability -Online -LogPath $logFile -LogLevel 1 -Source $PSScriptRoot -ErrorAction Stop |
        Out-Null

        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remote Server Administration Tools" -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remote Server Administration Tools" -Name "Developer" -Value "Microsoft" -Force
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remote Server Administration Tools" -Name "CurrentVersion" -Value "2.1" -Force
    }

    if ($uninstall) {
        $featureList | Where-Object {
            ( $_.Name -notlike "Rsat.ServerManager*" ) -and
            ( $_.Name -notlike "Rsat.GroupPolicy*" ) -and
            ( $_.Name -notlike "Rsat.ActiveDirectory*" )
        } |
        Remove-WindowsCapability -Online -LogPath $logFile -LogLevel 1 -ErrorAction Stop |
        Out-Null

        $featureList | Where-Object {
            ( $_.Name -notlike "Rsat.ServerManager*" )
        } |
        Remove-WindowsCapability -Online -LogPath $logFile -LogLevel 1 -ErrorAction Stop |
        Out-Null

        $featureList |
        Remove-WindowsCapability -Online -LogPath $logFile -LogLevel 1 -ErrorAction Stop |
        Out-Null

        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remote Server Administration Tools" -Force

    }
}
catch {
    Write-Information -MessageData ('{0} ERROR: "{1}" in "{2}:{3} char:{4}"' -f (Get-Date -Format G -ErrorAction Stop), $_.Exception.Message, $_.InvocationInfo.PSCommandPath, $_.InvocationInfo.ScriptLineNumber, $_.InvocationInfo.OffsetInLine) -ErrorAction Stop 6>> $logFile
    Exit 1
}