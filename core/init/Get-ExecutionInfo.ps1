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

Function Get-ExecutionInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ExecutionInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    if($O365Object.Tenant){
        $b64 = $displayName = $userPrincipalName = $null
        $default_domain = $O365Object.Tenant.CompanyInfo.verifiedDomains | Where-Object {$_.default -eq $true} -ErrorAction Ignore
        $user_permissions = $O365Object.aadPermissions
        $subscription_info = $O365Object.current_subscription
        $tenant_info = $O365Object.Tenant
        if($user_permissions){
            #Get UPN and DisplayName
            $displayName = $user_permissions.displayName
            if($O365Object.isConfidentialApp){
                $userPrincipalName = $user_permissions.appId;
            }
            else{
                $userPrincipalName = $user_permissions.userPrincipalName;
            }
        }
        #Try to get user's picture
        if([string]::IsNullOrEmpty($O365Object.TenantId) -or $O365Object.TenantId -eq [System.Guid]::Empty){
            $current_tenantId = "/myOrganization"
        }
        else{
            $current_tenantId = $O365Object.TenantId
        }
        $auth_token = $O365Object.auth_tokens.Graph.CreateAuthorizationHeader()
        try{
            if($O365Object.isConfidentialApp -eq $false){
                $uri = ("{0}/{1}/users/{2}/thumbnailPhoto?api-version={3}" -f $O365Object.Environment.Graph, $current_tenantId, $O365Object.userId, "1.6")
                $param = @{
                    Url = $uri;
                    Method = 'Get';
                    Headers = @{Authorization=$auth_token};
                    Content_Type = 'image/jpeg';
                    UserAgent = $O365Object.UserAgent;
                    GetBytes = $true
                }
                [byte[]]$bytes = Invoke-UrlRequest @param
                #[byte[]]$bytes = (Invoke-WebRequest $uri -Method Get -Headers @{Authorization=$auth_token}).Content;
                if($null -ne $bytes){
                    $b64 = [Convert]::ToBase64String($bytes)
                }
            }
            else{
                $b64 = $null
            }
        }
        catch{
            $b64 = $null
        }
        if($null -ne $b64){
            $user_pic = ('data:image/png;base64,{0}' -f $b64)
        }
        else{
            $user_pic = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjwhLS0gR2VuZXJhdG9yOiBBZG9iZSBJbGx1c3RyYXRvciAxNy4xLjAsIFNWRyBFeHBvcnQgUGx1Zy1JbiAuIFNWRyBWZXJzaW9uOiA2LjAwIEJ1aWxkIDApICAtLT4NCjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+DQo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IiBoZWlnaHQ9IjUwcHgiIHdpZHRoPSI1MHB4IiB2aWV3Qm94PSIwIDAgNTAgNTAiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIG9wYWNpdHk9IjAuMSIgZmlsbD0iI0ZGRkZGRiIgcG9pbnRzPSIwLDAgNTAsMCA1MCw1MCAwLDUwICIvPg0KPHBvbHlnb24gb3BhY2l0eT0iMC4xIiBmaWxsPSIjMkIzMTM3IiBwb2ludHM9IjAsMCA1MCwwIDUwLDUwIDAsNTAgIi8+DQo8Zz4NCgk8cGF0aCBmaWxsPSIjNTlCNEQ5IiBkPSJNMzEuOSwxNS4xYzAsMy43LTMuMSw2LjktNi45LDYuOXMtNi45LTMuMS02LjktNi45czMuMS02LjksNi45LTYuOUMyOC43LDguMiwzMS45LDExLjQsMzEuOSwxNS4xIi8+DQoJPHBvbHlnb24gZmlsbD0iIzU5QjREOSIgcG9pbnRzPSIzMCwyNC40IDI1LDMxLjQgMjAsMjQuNCAxMi43LDI0LjQgMTIuNyw0MS44IDM3LjIsNDEuOCAzNy4yLDI0LjQgCSIvPg0KCTxwYXRoIG9wYWNpdHk9IjAuMiIgZmlsbD0iI0ZGRkZGRiIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAgICAiIGQ9Ik0xOC4xLDE1LjFjMCwzLjcsMyw2LjgsNi44LDYuOWwxLjYtMTMuNQ0KCQljLTAuNS0wLjEtMS0wLjEtMS41LTAuMUMyMS4xLDguMiwxOC4xLDExLjQsMTguMSwxNS4xIi8+DQoJPHBvbHlnb24gb3BhY2l0eT0iMC4yIiBmaWxsPSIjRkZGRkZGIiBlbmFibGUtYmFja2dyb3VuZD0ibmV3ICAgICIgcG9pbnRzPSIyMCwyNC40IDEyLjcsMjQuNCAxMi43LDQxLjggMjIuNCw0MS44IDIzLjksMjkuOSAJIi8+DQo8L2c+DQo8L3N2Zz4NCg=='
        }
        #Get Roles
        if($O365Object.Instance -eq "Azure" -and $null -ne $O365Object.azPermissions){
            $roles = $O365Object.azPermissions.roleAssignmentInfo | Select-Object -ExpandProperty RoleName -ErrorAction Ignore
        }
        elseif($O365Object.Instance -ne "Azure" -and $null -ne $O365Object.aadPermissions){
            $roles = $O365Object.aadPermissions.directoryRoleInfo | Select-Object -ExpandProperty AssignedRole -ErrorAction Ignore
        }
        else{
            $msg = @{
                MessageData = "Unable to get user's permissions";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365IAMError');
            }
            Write-Warning @msg
            $roles = $null;
        }
        #Get Profile
        if($O365Object.Instance -eq "Azure"){
            $user_profile = [ordered]@{
                Domain = $default_domain.name;
                "Tenant Id" = $tenant_info.TenantID;
                "Tenant Name" = $tenant_info.TenantName;
                "Subscription Id" = $subscription_info.subscriptionId;
                "Subscription Name" = $subscription_info.displayName;
            }
        }
        else{
            $user_profile = [ordered]@{
                Domain = $default_domain.name;
                "Tenant Id" = $tenant_info.TenantID;
                "Tenant Name" = $tenant_info.TenantName;
            }
        }
        #Create object
        $execution_info = [pscustomobject]@{
            Domain = $default_domain.name;
            userPrincipalName = $userPrincipalName;
            displayName = $displayName;
            permissions = $user_permissions;
            roles = $roles;
            ScanDate = $O365Object.startDate.ToLocalTime();
            subscription = $subscription_info;
            tenant = $tenant_info;
            userpic = $user_pic;
            profile = $user_profile;
        }
        #return object
        return $execution_info
    }
}
