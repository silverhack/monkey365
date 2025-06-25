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
    Begin{
        #Get default domain
        if($null -ne $O365Object.Tenant.CompanyInfo){
            $defaultDomain = $O365Object.Tenant.CompanyInfo.verifiedDomains.Where({$_.isDefault -eq $true})
            if($defaultDomain){
                $domainName = $defaultDomain.name
            }
        }
        else{
            $domainName = $null
        }
        #Get TenantId
        if($null -ne $O365Object.Tenant.TenantId){
            $tenantId = $O365Object.Tenant.TenantId
        }
        elseif($null -ne $O365Object.TenantId){
            $tenantId = $O365Object.TenantId
        }
        else{
            $tenantId = $null;
        }
        #Get Tenant Name
        if($null -ne $O365Object.Tenant.TenantName){
            $tenantName = $O365Object.Tenant.TenantName
        }
        else{
            $tenantName = $null;
        }
        #Set hashtable
        if($O365Object.Instance -eq "Azure"){
            $user_profile = [ordered]@{
                Domain = $domainName;
                "TenantId" = $tenantId;
                "Tenant Name" = $tenantName;
                "SubscriptionId" = $O365Object.current_subscription.subscriptionId;
                "Subscription Name" = $O365Object.current_subscription.displayName;
            }
        }
        else{
            $user_profile = [ordered]@{
                Domain = $domainName;
                "TenantId" = $tenantId;
                "Tenant Name" = $tenantName;
            }
        }
        #Set psObject
        $execution_info = [pscustomobject]@{
            Domain = $domainName;
            userPrincipalName = if($O365Object.isConfidentialApp){$O365Object.me.appId}else{$O365Object.me.userPrincipalName};
            displayName = $O365Object.me.displayName;
            permissions = if($null -ne $O365Object.aadPermissions){$O365Object.aadPermissions}else{$null};
            roles = $null;
            ScanDate = $O365Object.startDate.ToLocalTime();
            subscription = if($null -ne $O365Object.current_subscription){$O365Object.current_subscription}else{$null};
            tenant = if($null -ne $O365Object.Tenant){$O365Object.Tenant}else{$null};
            userpic = $null;
            profile = $user_profile;
        }
    }
    Process{
        #Get roles
        if($O365Object.Instance -eq "Azure" -and $null -ne $O365Object.azPermissions){
            $roles = $O365Object.azPermissions | Select-Object -Unique -ExpandProperty RoleName -ErrorAction Ignore
        }
        elseif($O365Object.Instance -ne "Azure" -and $null -ne $O365Object.aadPermissions){
            $roles = $O365Object.aadPermissions | Select-Object -ExpandProperty displayName -ErrorAction Ignore
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
        #Append roles to PsObject
        $execution_info.roles = $roles;
        #Get Profile pic
        if($O365Object.isConfidentialApp){
            $p = @{
                ApplicationId = $O365Object.clientApplicationId;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $pic = Get-MonkeyMSGraphProfilePhoto @p
        }
        else{
            $p = @{
                UserId = $O365Object.userId;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $pic = Get-MonkeyMSGraphProfilePhoto @p
        }
        if($null -ne $pic){
            $user_pic = ('data:image/png;base64,{0}' -f $pic)
            $execution_info.userpic = $user_pic
        }
        else{
            $user_pic = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjwhLS0gR2VuZXJhdG9yOiBBZG9iZSBJbGx1c3RyYXRvciAxNy4xLjAsIFNWRyBFeHBvcnQgUGx1Zy1JbiAuIFNWRyBWZXJzaW9uOiA2LjAwIEJ1aWxkIDApICAtLT4NCjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+DQo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IiBoZWlnaHQ9IjUwcHgiIHdpZHRoPSI1MHB4IiB2aWV3Qm94PSIwIDAgNTAgNTAiIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiB4bWw6c3BhY2U9InByZXNlcnZlIj4NCjxwb2x5Z29uIG9wYWNpdHk9IjAuMSIgZmlsbD0iI0ZGRkZGRiIgcG9pbnRzPSIwLDAgNTAsMCA1MCw1MCAwLDUwICIvPg0KPHBvbHlnb24gb3BhY2l0eT0iMC4xIiBmaWxsPSIjMkIzMTM3IiBwb2ludHM9IjAsMCA1MCwwIDUwLDUwIDAsNTAgIi8+DQo8Zz4NCgk8cGF0aCBmaWxsPSIjNTlCNEQ5IiBkPSJNMzEuOSwxNS4xYzAsMy43LTMuMSw2LjktNi45LDYuOXMtNi45LTMuMS02LjktNi45czMuMS02LjksNi45LTYuOUMyOC43LDguMiwzMS45LDExLjQsMzEuOSwxNS4xIi8+DQoJPHBvbHlnb24gZmlsbD0iIzU5QjREOSIgcG9pbnRzPSIzMCwyNC40IDI1LDMxLjQgMjAsMjQuNCAxMi43LDI0LjQgMTIuNyw0MS44IDM3LjIsNDEuOCAzNy4yLDI0LjQgCSIvPg0KCTxwYXRoIG9wYWNpdHk9IjAuMiIgZmlsbD0iI0ZGRkZGRiIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAgICAiIGQ9Ik0xOC4xLDE1LjFjMCwzLjcsMyw2LjgsNi44LDYuOWwxLjYtMTMuNQ0KCQljLTAuNS0wLjEtMS0wLjEtMS41LTAuMUMyMS4xLDguMiwxOC4xLDExLjQsMTguMSwxNS4xIi8+DQoJPHBvbHlnb24gb3BhY2l0eT0iMC4yIiBmaWxsPSIjRkZGRkZGIiBlbmFibGUtYmFja2dyb3VuZD0ibmV3ICAgICIgcG9pbnRzPSIyMCwyNC40IDEyLjcsMjQuNCAxMi43LDQxLjggMjIuNCw0MS44IDIzLjksMjkuOSAJIi8+DQo8L2c+DQo8L3N2Zz4NCg=='
            $execution_info.userpic = $user_pic
        }
    }
    End{
        #return object
        return $execution_info
    }
}

