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
    #Using MSAL authentication
    if($null -ne $O365Object.msal_application_args){
        #Connect to MSGraph
        $msg = @{
            MessageData = ($message.TokenRequestInfoMessage -f "Microsoft Graph V2")
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('TokenRequestInfoMessage');
        }
        Write-Information @msg
        $O365Object.auth_tokens.MSGraph = Connect-MonkeyMSGraph
        if($null -ne $O365Object.auth_tokens.MSGraph){
            #Check if valid TenantId
            If($null -ne $O365Object.TenantId){
                $tid = $O365Object.TenantId
            }
            else{
                $tid = $O365Object.auth_tokens.MSGraph.TenantId
            }
            #Check if valid Tenant Id
            $O365Object.isValidTenantGuid = Test-IsValidTenantId -TenantId $tid
            #Get Tenant Origin
            if($O365Object.isValidTenantGuid -eq $false){
                $msg = @{
                    MessageData = ("{0} is not a valid TenantId. Getting TenantId from Access Token" -f $O365Object.TenantId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('NonValidTenantId');
                }
                Write-Verbose @msg
                $tid = Read-JWTtoken -token $O365Object.auth_tokens.MSGraph.AccessToken | Select-Object -ExpandProperty tid -ErrorAction Ignore
            }
            else{
                $tid = $O365Object.TenantId
            }
            $p = @{
                TenantId = $tid
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Get Tenant origin
            $O365Object.tenantOrigin = Get-MonkeyMSGraphOrganization @p
            #Remove Device code
            $app_params = $O365Object.msal_application_args;
            if($app_params.ContainsKey('DeviceCode')){
                [ref]$null = $app_params.Remove('DeviceCode')
            }
            #Add silent
            if(-NOT $app_params.ContainsKey('Silent')){
                #Add silent auth
                [ref]$null = $app_params.Add('Silent',$true)
            }
            #Add params to msal auth params
            $O365Object.msal_application_args = $app_params;
        }
        else{
            #Probably cancelled connection
            return
        }
        $msg = @{
            MessageData = ($message.TokenRequestInfoMessage -f "Azure Resource Management API")
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('TokenRequestInfoMessage');
        }
        Write-Information @msg
        #Connect to Resource management
        $p = @{
            Resource = $O365Object.Environment.ResourceManager;
            AzureService = "AzurePowershell";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $O365Object.auth_tokens.ResourceManager = Connect-MonkeyGenericApplication @p
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
    #Update object
    $O365Object.AuthType = $O365Object.auth_tokens.Values.GetEnumerator() | Select-Object -ExpandProperty AuthType -Unique -ErrorAction Ignore
    #Check if connected to MSGraph and Resource Manager
    if($null -ne $O365Object.auth_tokens.ResourceManager -and $null -ne $O365Object.auth_tokens.MSGraph){
        $msg = @{
            MessageData = ($message.TokenRequestInfoMessage -f "Legacy Microsoft Graph")
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('TokenRequestInfoMessage');
        }
        Write-Information @msg
        #Connect to Microsoft legacy Graph
        $p = @{
            Resource = $O365Object.Environment.Graph;
            AzureService = "AzurePowershell";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $O365Object.auth_tokens.Graph = Connect-MonkeyGenericApplication @p
        #Connect to Azure Portal
        if($O365Object.isConfidentialApp -eq $false -and $O365Object.IncludeEntraID){
            $msg = @{
                MessageData = ($message.TokenRequestInfoMessage -f "Entra ID API")
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('TokenRequestInfoMessage');
            }
            Write-Information @msg
            $p = @{
                Resource = (Get-WellKnownAzureService -AzureService AzurePortal);
                AzureService = "AzurePowershell";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $O365Object.auth_tokens.AzurePortal = Connect-MonkeyGenericApplication @p
            #$O365Object.auth_tokens.AzurePortal = Connect-MonkeyAzurePortal
        }
        #Get Tenant Information
        $O365Object.Tenant = Get-TenantInformation
    }
    #Check if Azure services is selected
    if($O365Object.initParams.Instance -eq "Azure"){
        Connect-MonkeyAzure
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
        Connect-MonkeyM365
    }
    #Get licensing information
    $O365Object.Licensing = Get-MonkeySKUInfo
    #Get actual userId
    $authObject = $O365Object.auth_tokens.GetEnumerator() | Where-Object {$null -ne $_.Value} | Select-Object -ExpandProperty Value -First 1
    If($null -ne $authObject){
        $O365Object.userId = $authObject | Get-UserIdFromToken
    }
    #Get Azure AD permissions
    if($O365Object.isConfidentialApp){
        $app_Permissions = Get-MonkeyMSGraphObjectDirectoryRole -ObjectId $O365Object.clientApplicationId -ObjectType servicePrincipal
        if($app_Permissions){
            $O365Object.aadPermissions = $app_Permissions
        }
    }
    else{
        $user_permissions = Get-MonkeyMSGraphObjectDirectoryRole -ObjectId $O365Object.userId -ObjectType user
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
    elseif($O365Object.isConfidentialApp){
        $O365Object.canRequestMFAForUsers = $true
    }
    else{
        $O365Object.canRequestMFAForUsers = $false
    }
    #Check if requestMFA for users must be enabled by config
    try{
        $requestMFA = $O365Object.internal_config.entraId.forceRequestMFA
    }
    catch{
        $msg = @{
            MessageData = ($message.MonkeyInternalConfigError);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'verbose';
            InformationAction = $O365Object.InformationAction;
            Tags = @('Monkey365ConfigError');
        }
        Write-Verbose @msg
        $requestMFA = $false
    }
    if($requestMFA -eq $true){
        #Force request MFA for users
        $O365Object.canRequestMFAForUsers = $true;
    }
    #Check if current identity can request users and groups from Microsoft Graph
    $p = @{
        InformationAction = $O365Object.InformationAction;
        Verbose = $O365Object.verbose;
        Debug = $O365Object.Debug;
    }
    $O365Object.canRequestUsersFromMsGraph = Test-CanRequestUser @p
    $O365Object.canRequestGroupsFromMsGraph = Test-CanRequestGroup @p
    #Get information about current identity
    $O365Object.me = Get-MonkeyMe @p
    #Check if connected to Azure AD
    if($O365Object.canRequestUsersFromMsGraph -eq $false -and $null -eq $O365Object.Tenant.CompanyInfo){
        $msg = @{
            MessageData = ($message.NotConnectedTo -f "Microsoft Entra ID");
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('Monkey365GraphAPIError');
        }
        Write-Warning @msg
        $O365Object.onlineServices.EntraID = $false
    }
    else{
        $O365Object.onlineServices.EntraID = $true
    }
    #Get AzureAD Licensing
    $O365Object.AADLicense = Get-M365AADLicense
    if($null -ne $O365Object.AADLicense.azureADP2){
        $msg = @{
            MessageData = ($message.TokenRequestInfoMessage -f "Entra ID Privileged Managament Identity API")
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('TokenRequestInfoMessage');
        }
        Write-Information @msg
        #Connect to PIM
        $p = @{
            Resource = (Get-WellKnownAzureService -AzureService MSPIM);
            AzureService = "AzurePowershell";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $O365Object.auth_tokens.MSPIM = Connect-MonkeyGenericApplication @p
        #$O365Object.auth_tokens.MSPIM = Connect-MonkeyPIM
    }
    #Get collectors
    $p = @{
        Provider = $O365Object.Instance;
        Service = $O365Object.initParams.Collect;
        InformationAction = $O365Object.InformationAction;
        Verbose = $O365Object.verbose;
        Debug = $O365Object.debug;
    }
    $O365Object.Collectors = Select-MonkeyCollector @p
}