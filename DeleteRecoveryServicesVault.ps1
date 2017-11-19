param
(
    [Parameter(Mandatory=$true,Position=1)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=2)]
    [String]$VaultName,

    [Parameter(Mandatory=$false,Position=3)]
    [String]$EnvironmentName
)

if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) 
{
    if ([string]::IsNullOrEmpty($EnvironmentName))
    {
        Login-AzureRmAccount
    } else {
        Login-AzureRmAccount -Environment $EnvironmentName        
    }
}

$rv = Get-AzureRmRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName

if ($rv -eq $null) {
    Write-Host "Recovery Service Vault Not Found"
    exit 1
}

Set-AzureRmRecoveryServicesVaultContext -Vault $rv
$rcs = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM

foreach ($c in $rcs) 
{
    $bi = Get-AzureRmRecoveryServicesBackupItem -Container $c -WorkloadType AzureVM
    Disable-AzureRmRecoveryServicesBackupProtection -Item $bi -RemoveRecoveryPoints -Force
}

Remove-AzureRmRecoveryServicesVault -Vault $rv