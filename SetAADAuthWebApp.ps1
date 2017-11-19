param(

    # Parameter help description
    [Parameter(Mandatory=$true,Position=1)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$WebAppName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$ClientId,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$IssuerUrl,
    
    [Parameter(Mandatory=$false,Position=5)]
    [ValidateSet("AzureCloud","AzureUsGovernment","AzureGermanCloud","AzureChinaCloud")]
    [String]$Environment = "AzureCloud"
)

$azcontext = Get-AzureRmContext
if ([string]::IsNullOrEmpty($azcontext.Account) -or
    !($azcontext.Environment.Name -eq $Environment)) 
{
    Login-AzureRmAccount -Environment $Environment        
}
$azcontext = Get-AzureRmContext

$authResourceName = $WebAppName + "/authsettings"
$auth = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $authResourceName -Action list -ApiVersion 2016-08-01 -Force

$auth.properties.enabled = "True"
$auth.properties.unauthenticatedClientAction = "RedirectToLoginPage"
$auth.properties.tokenStoreEnabled = "True"
$auth.properties.defaultProvider = "AzureActiveDirectory"
$auth.properties.isAadAutoProvisioned = "False"
$auth.properties.clientId = $ClientId
$auth.properties.clientSecret = $ClientSecret
$auth.properties.issuer = $IssuerUrl

New-AzureRmResource -PropertyObject $auth.properties -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName $authResourceName -ApiVersion 2016-08-01 -Force