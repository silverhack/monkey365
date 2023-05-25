# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function Connect-MonkeyCloud{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyCloud
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param ()
    $app_params = $null
    #Using MSAL authentication
    if($null -ne $O365Object.msalapplication -and $null -ne $O365Object.msal_application_args){
        #Set new application args
        $app_params = @{}
        foreach($elem in $O365Object.msal_application_args.GetEnumerator()){
            [void]$app_params.Add($elem.Key,$elem.Value)
        }
        if($O365Object.msalapplication.isPublicApp){
            #Set parameters
            if($app_params.ContainsKey('publicApp')){
                #Remove and add public application
                [ref]$null = $app_params.Remove('publicApp')
                [ref]$null = $app_params.Add('publicApp',$O365Object.msalapplication);
            }
            else{
                [ref]$null = $app_params.Add('publicApp',$O365Object.msalapplication);
            }
            if($O365Object.application_args.ContainsKey('Silent') -and $O365Object.application_args.Silent){
                #Add silent auth if not exists
                if(-NOT $app_params.ContainsKey('Silent')){
                    #Add silent auth
                    [ref]$null = $app_params.Add('Silent',$true)
                }
            }
        }
        else{
            #Confidential App
            [ref]$null = $app_params.Add('confidentialApp',$O365Object.msalapplication);
        }
        #Remove ClientId
        if($app_params.ContainsKey('ClientId')){
            [ref]$null = $app_params.Remove('ClientId')
        }
    }
    if($null -ne $app_params){
        #Connect to Microsoft Graph
        $O365Object.auth_tokens.Graph = (Connect-MonkeyGraph $app_params)
    }
    if($null -ne $O365Object.auth_tokens.Graph){
        #Get Tenant Origin
        $p = @{
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $O365Object.tenantOrigin = Get-MonkeyGraphAADTenantDetail @p
        #Remove device code if exists
        if($app_params.ContainsKey('DeviceCode')){
            [ref]$null = $app_params.Remove('DeviceCode')
        }
        if(-NOT $app_params.ContainsKey('Silent')){
            #Add silent auth
            [ref]$null = $app_params.Add('Silent',$true)
        }
        #Connect to Resource management
        $O365Object.auth_tokens.ResourceManager = (Connect-MonkeyResourceManagement $app_params)
    }
    else{
        #Probably cancelled connection
        return
    }
    #Check if connected
    if($null -ne $O365Object.auth_tokens.ResourceManager){
        $msg = @{
            MessageData = ($message.SuccessfullyConnectedTo -f "Resource Manager");
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('SuccessFullyConnected');
        }
        Write-Information @msg
        #Add authentication args to O365Object
        $auth_param = @{}
        foreach($p in $app_params.GetEnumerator()){
            [void]$auth_param.Add($p.Key,$p.Value);
        }
        $O365Object.authentication_args = $auth_param
    }
    #Select tenant
    if($null -eq $O365Object.TenantId -and $null -ne $O365Object.auth_tokens.ResourceManager){
        $reconnect = Select-MonkeyTenant
        if($null -ne $reconnect){
            #If reconnect is true, then a new tenant was selected by the user
            if($reconnect){
                Connect-MonkeyCloud
                return
            }
            else{
                #Probably cancelled connection
                return
            }
        }
    }
    if($null -ne $O365Object.auth_tokens.ResourceManager -and $null -ne $O365Object.auth_tokens.Graph){
        #Connect to MSGraph
        $O365Object.auth_tokens.MSGraph = (Connect-MonkeyMSGraph $app_params)
        #Connect to Azure Portal
        $O365Object.auth_tokens.AzurePortal = (Connect-MonkeyAzurePortal $app_params)
        #Connect to PIM
        $O365Object.auth_tokens.MSPIM = (Connect-MonkeyPIM $app_params)
        #Get Tenant Information
        $O365Object.Tenant = Get-TenantInformation
    }
    #Set Azure AD connections to True if connection is present
    if($null -ne $O365Object.auth_tokens.MSGraph -and $null -ne $O365Object.auth_tokens.Graph){
        $O365Object.onlineServices.AzureAD = $True
    }
    #Check if Azure services is selected
    if($O365Object.initParams.Instance -eq "Azure"){
        Connect-MonkeyAzure -parameters $app_params
        #Set Azure connections to True if connection and subscription are present
        if($null -ne $O365Object.auth_tokens.ResourceManager -and $null -ne $O365Object.auth_tokens.Graph -and $null -ne $O365Object.auth_tokens.MSGraph -and $null -ne $O365Object.subscriptions){
            $O365Object.onlineServices.Azure = $True
        }
        else{
            #Probably cancelled operation or user is not assigned to any subscription
            return
        }
    }
    #Check if Microsoft 365 is selected
    elseif($O365Object.initParams.Instance -eq "Microsoft365"){
        Connect-MonkeyM365 -parameters $app_params
    }
    #Update object
    $O365Object.AuthType = $O365Object.auth_tokens.Values.GetEnumerator() | Select-Object -ExpandProperty AuthType -Unique -ErrorAction Ignore
    #Get licensing information
    $O365Object.Licensing = Get-MonkeySKUInfo
    #Get actual userId
    $O365Object.userId = Get-MonkeyAzUserId
    #Get AzureAd Licensing
    $O365Object.AADLicense = Get-M365AADLicense
    #Get Plugins
    $O365Object.Plugins = Get-MonkeyPlugin
    #Get Azure AD permissions
    if($O365Object.isConfidentialApp){
        $user_permissions = Get-MonkeyMSGraphServicePrincipalDirectoryRole -principalId $O365Object.clientApplicationId
        if($user_permissions){
            $O365Object.aadPermissions = $user_permissions
        }
    }
    else{
        $user_permissions = Get-MonkeyMSGraphUserDirectoryRole -UserId $O365Object.userId
        if($user_permissions){
            $O365Object.aadPermissions = $user_permissions
        }
    }
    #Check if user can request MFA for users
    #Check Global Admin permissions
    $ga = Test-MonkeyAADIAM -RoleTemplateId 62e90394-69f5-4237-9190-012177145e10
    #Check Authentication administrator permissions
    $aa = Test-MonkeyAADIAM -RoleTemplateId c4e39bd9-1100-46d3-8c65-fb160da0071f
    if($ga){
        $O365Object.canRequestMFAForUsers = $true
    }
    elseif($aa){
        $O365Object.canRequestMFAForUsers = $true
    }
    else{
        $O365Object.canRequestMFAForUsers = $false
    }
}

<#
if($null -ne $O365Object.o365_sessions){
    $O365Object.o365_sessions.GetEnumerator() | % {if($null -ne $_.value){Remove-PSSession $_.value}}
}
$O365Object.exo_msal_application = $null;
$O365Object.application_args = $null;
$O365Object.Tenant = $null;
$O365Object.TenantId = $null;
$O365Object.msal_application_args = $null;
Initialize-AuthenticationParam
$app = Connect-MonkeyCloud
#>