param(
  [Parameter(Mandatory = $true)]
  [string]$VmHost,

  [Parameter(Mandatory = $true)]
  [string]$Domain,

  [string]$DomainAlias = "",
  [int]$UpstreamPort = 8090,
  [string]$ComposeFile = "docker-compose.yml",
  [string]$SshKeyPath = $env:EYEDIATECH_SSH_KEY_PATH,
  [string]$VmUser = "root",
  [string]$RepoUrl = "https://github.com/eyedia/EyediaTech.git",
  [string]$Branch = "main",
  [string]$BaseDir = "/opt/eyedeea",
  [switch]$WithSsl,
  [string]$CertbotEmail
)

$ErrorActionPreference = "Stop"

function Assert-PathExists([string]$pathToCheck, [string]$name) {
  if (-not (Test-Path -LiteralPath $pathToCheck)) {
    throw ('{0} not found - {1}' -f $name, $pathToCheck)
  }
}

function Assert-LastExitCode([string]$stepName) {
  if ($LASTEXITCODE -ne 0) {
    throw ('{0} failed with exit code {1}' -f $stepName, $LASTEXITCODE)
  }
}

function Get-Ipv4Records([string]$hostName) {
  try {
    $records = Resolve-DnsName -Name $hostName -Type A -ErrorAction Stop |
      Where-Object { $_.Type -eq 'A' } |
      Select-Object -ExpandProperty IPAddress -Unique
    return @($records)
  }
  catch {
    return @()
  }
}

function Get-Ipv6Records([string]$hostName) {
  try {
    $records = Resolve-DnsName -Name $hostName -Type AAAA -ErrorAction Stop |
      Where-Object { $_.Type -eq 'AAAA' } |
      Select-Object -ExpandProperty IPAddress -Unique
    return @($records)
  }
  catch {
    return @()
  }
}

function Assert-DnsTargetsVm([string]$hostName, [string[]]$expectedIpv4) {
  $aRecords = Get-Ipv4Records $hostName
  if ($aRecords.Count -eq 0) {
    throw ('DNS A record not found for {0}. Configure it to point to your VM before requesting SSL.' -f $hostName)
  }

  $matchingA = @($aRecords | Where-Object { $expectedIpv4 -contains $_ })
  if ($matchingA.Count -eq 0) {
    throw ('DNS mismatch for {0}. A records are [{1}], expected one of [{2}]. Update DNS, then retry.' -f $hostName, ($aRecords -join ', '), ($expectedIpv4 -join ', '))
  }

  $aaaaRecords = Get-Ipv6Records $hostName
  if ($aaaaRecords.Count -gt 0) {
    Write-Warning ('{0} has AAAA record(s): [{1}]. Ensure IPv6 also routes to this VM, or HTTP-01 validation can fail.' -f $hostName, ($aaaaRecords -join ', '))
  }
}

if ([string]::IsNullOrWhiteSpace($SshKeyPath)) {
  throw "SshKeyPath is required. Pass -SshKeyPath or set EYEDIATECH_SSH_KEY_PATH."
}

Assert-PathExists $SshKeyPath "SSH key"

if ($WithSsl -and [string]::IsNullOrWhiteSpace($CertbotEmail)) {
  throw "CertbotEmail is required when -WithSsl is used"
}

if ($WithSsl) {
  $vmIp = $null
  $vmARecords = @()
  if ([System.Net.IPAddress]::TryParse($VmHost, [ref]$vmIp)) {
    if ($vmIp.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
      throw ('VmHost must resolve to an IPv4 address for this SSL precheck. Current value: {0}' -f $VmHost)
    }
    $vmARecords = @($VmHost)
  }
  else {
    $vmARecords = Get-Ipv4Records $VmHost
  }

  if ($vmARecords.Count -eq 0) {
    throw ('Could not resolve IPv4 for VmHost: {0}' -f $VmHost)
  }

  Write-Host ('[deploy-root-web] Verifying DNS for SSL domains against VM IPv4: {0}' -f ($vmARecords -join ', '))
  Assert-DnsTargetsVm $Domain $vmARecords
}

$effectiveDomainAlias = $DomainAlias
if ($WithSsl -and -not [string]::IsNullOrWhiteSpace($effectiveDomainAlias)) {
  try {
    Assert-DnsTargetsVm $effectiveDomainAlias $vmARecords
  }
  catch {
    Write-Warning ('DomainAlias "{0}" does not currently target this VM. Continuing SSL request with primary domain only.' -f $effectiveDomainAlias)
    $effectiveDomainAlias = ""
  }
}

$localDeployScript = Join-Path $PSScriptRoot "vm-deploy-hetzner.sh"
Assert-PathExists $localDeployScript "Remote root-web deploy helper script"

$resolvedKey = (Resolve-Path -LiteralPath $SshKeyPath).Path
$target = ('{0}@{1}' -f $VmUser, $VmHost)
$remoteScriptPath = $target + ':/tmp/vm-deploy-hetzner.sh'

Write-Host ('[deploy-root-web] Uploading deploy script to {0}' -f $target)
scp -i $resolvedKey $localDeployScript $remoteScriptPath
Assert-LastExitCode "SCP remote root-web deploy script"

$sslArgs = ""
if ($WithSsl) {
  $sslArgs = " --with-ssl --certbot-email '$CertbotEmail'"
}

$domainAliasArg = ""
if (-not [string]::IsNullOrWhiteSpace($effectiveDomainAlias)) {
  $domainAliasArg = " --domain-alias '$effectiveDomainAlias'"
}

Write-Host '[deploy-root-web] Running remote deployment'
$remoteCmd = @"
bash /tmp/vm-deploy-hetzner.sh --repo-url '$RepoUrl' --branch '$Branch' --base-dir '$BaseDir' --compose-file '$ComposeFile' --upstream-port '$UpstreamPort' --domain '$Domain'$domainAliasArg$sslArgs
"@

ssh -i $resolvedKey $target $remoteCmd
Assert-LastExitCode "Remote root-web deployment command"

Write-Host '[deploy-root-web] Completed.'
