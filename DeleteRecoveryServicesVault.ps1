param
(
    [Parameter(Mandatory=$true,Position=1)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=2)]
    [String]$VaultName
)

$rv = Get-AzureRmRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName
Set-AzureRmRecoveryServicesVaultContext -Vault $rv
$rcs = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM

foreach ($c in $rcs) {
    $bi = Get-AzureRmRecoveryServicesBackupItem -Container $c -WorkloadType AzureVM
    Disable-AzureRmRecoveryServicesBackupProtection -Item $bi -RemoveRecoveryPoints -Force
}

Remove-AzureRmRecoveryServicesVault -Vault $rv