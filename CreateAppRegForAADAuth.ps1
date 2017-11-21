param
(
    [Parameter(Mandatory=$true,Position=1)]
    [System.Uri]$SiteUri,
    
    [Parameter(Mandatory=$false,Position=2)]
    [ValidateSet("AzureCloud","AzureUsGovernment","AzureGermanCloud","AzureChinaCloud")]
    [String]$Environment = "AzureCloud",

    [Parameter(Mandatory=$false,Position=3)]
    [String]$Password
)

<#

    More details at: http://blog.octavie.nl/index.php/2017/09/19/create-azure-ad-app-registration-with-powershell-part-2

    Finding information about App Permissions and Delegated Permissions:

    1. Locate the ServicePrincipal (API) you need to access, e.g.:
        
        PS> $svcPrincipal = Get-AzureADServicePrincipal -SearchString "Windows azure active directory"
        PS> $svcPrincipal

        ObjectId                             AppId                                DisplayName
        --------                             -----                                -----------
        d80f4d2b-d115-44ad-b39e-69ebdbe6c9fe 00000002-0000-0000-c000-000000000000 Windows Azure Active Directory

    2. List App Permissions:

        PS> $svcPrincipal.AppRoles | FT Id, Value, DisplayName

        Id                                   Value                         DisplayName
        --                                   -----                         -----------
        5778995a-e1bf-45b8-affa-663a9f3f4d04 Directory.Read.All            Read directory data
        abefe9df-d5a9-41c6-a60b-27b38eac3efb Domain.ReadWrite.All          Read and write domains
        78c8a3c8-a07e-4b9e-af1b-b5ccab50a175 Directory.ReadWrite.All       Read and write directory data
        1138cb37-bd11-4084-a2b7-9f71582aeddb Device.ReadWrite.All          Read and write devices
        9728c0c4-a06b-4e0e-8d1b-3d694e8ec207 Member.Read.Hidden            Read all hidden memberships
        824c81eb-e3f8-4ee6-8f6d-de7f50d565b7 Application.ReadWrite.OwnedBy Manage apps that this app creates or owns
        1cda74f2-2616-4834-b122-5cb1b07f8a59 Application.ReadWrite.All     Read and write all applications
        aaff0dfd-0295-48b6-a5cc-9f465bc87928 Domain.ReadWrite.All          Read and write domains

    3. List Delegated Permissions:

        PS> $svcPrincipal.Oauth2Permissions | FT Id, Value, UserConsentDisplayName

        Id                                   Value                      UserConsentDisplayName
        --                                   -----                      ----------------------
        a42657d6-7f20-40e3-b6f0-cee03008a62a Directory.AccessAsUser.All Access the directory as you
        5778995a-e1bf-45b8-affa-663a9f3f4d04 Directory.Read.All         Read directory data
        78c8a3c8-a07e-4b9e-af1b-b5ccab50a175 Directory.ReadWrite.All    Read and write directory data
        970d6fa6-214a-4a9b-8513-08fad511e2fd Group.ReadWrite.All        Read and write all groups
        6234d376-f627-4f0f-90e0-dff25c5211a3 Group.Read.All             Read all groups
        c582532d-9d9e-43bd-a97c-2667a28ce295 User.Read.All              Read all user's full profiles
        cba73afc-7f69-4d86-8450-4978e04ecd1a User.ReadBasic.All         Read all user's basic profiles
        311a71cc-e848-46a1-bdf8-97ff7156d8e6 User.Read                  Sign you in and read your profile
        2d05a661-f651-4d57-a595-489c91eda336 Member.Read.Hidden         Read your hidden memberships
#>

$aadConnection = Connect-AzureAD -AzureEnvironmentName $Environment

if ([string]::IsNullOrEmpty($Password)) 
{
    $Password = [System.Convert]::ToBase64String($([guid]::NewGuid()).ToByteArray())
}

$Guid = New-Guid
$startDate = Get-Date     
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.Value = $Password

$displayName = $SiteUri.Host
[string[]]$replyUrl = $SiteUri.AbsoluteUri + ".auth/login/aad/callback"

$reqAAD = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqAAD.ResourceAppId = "00000002-0000-0000-c000-000000000000" #See above on how to find GUIDs 
$delPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope" #Sign you in and read your profile
$reqAAD.ResourceAccess = $delPermission1

$appReg = New-AzureADApplication -DisplayName $displayName -IdentifierUris $SiteUri -Homepage $SiteUri -ReplyUrls $replyUrl -PasswordCredential $PasswordCredential -RequiredResourceAccess $reqAAD

$loginBaseUrl = $(Get-AzureRmEnvironment -Name $Environment).ActiveDirectoryAuthority

#Small inconsistency for US gov in current AzureRm module
if ($loginBaseUrl -eq "https://login-us.microsoftonline.com/") {
    $loginBaseUrl = "https://login.microsoftonline.us/"
}

$issuerUrl = $loginBaseUrl +  $aadConnection.Tenant.Id.Guid + "/"

return @{ 'IssuerUrl' = $issuerUrl
          'ClientId' = $appReg.AppId 
          'ClientSecret' = $Password
        }