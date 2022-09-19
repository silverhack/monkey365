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

Function Select-MonkeyTenant{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Select-MonkeyTenant
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        $selected_Tenant = $null
        $bypassSelection = $false
        $tparam = @{
            AuthObject = $o365_connections.ResourceManager
            Endpoint = $O365Object.Environment.ResourceManager
            TenantId = [string]::Empty
        }
        $tenants = Get-TenantsForUser @tparam
    }
    Process{
        if($null -ne $tenants){
            if(@($tenants).Count -eq 1 -and $tenants.tenantId -ne 'F8CDEF31-A31E-4B4A-93E4-5F571E91255A'){
                $selected_Tenant = $tenants
                $O365Object.TenantId = $selected_Tenant.tenantId
                $bypassSelection = $True
            }
            elseif($PSEdition -eq "Desktop"){
                $selected_Tenant = $tenants | Out-GridView -Title "Choose a Tenant ..." -OutputMode Single
                if($selected_Tenant){
                    Write-Information ("You have selected {0} Tenant" -f $selected_Tenant.DisplayName) -InformationAction $InformationAction
                }
            }
            else{
                $selected_Tenant = Select-MonkeyTenantConsole -Tenants $tenants
            }
        }
    }
    End{
        if($null -eq $selected_Tenant){
            #Tenant not selected. Probably cancelled
            return $false
        }
        elseif($selected_Tenant -and $bypassSelection -eq $false){
            #Authenticate with selected TenantId
            $O365Object.TenantId = $selected_Tenant.tenantId
            $O365Object.Tenant = $selected_Tenant
            <#
            if(-NOT $MyParams.ContainsKey('TenantId')){
                #Add TenantId
                [ref]$null = $MyParams.Add('TenantId',$selected_Tenant.tenantId)
            }
            else{
                $MyParams.TenantId = $selected_Tenant.tenantId
            }
            #>
            if(-NOT $O365Object.application_args.ContainsKey('TenantId')){
                #Add TenantId
                [ref]$null = $O365Object.application_args.Add('TenantId',$selected_Tenant.tenantId)
            }
            else{
                $O365Object.application_args.TenantId = $selected_Tenant.tenantId
            }
            #remove AuthenticationContext if exists
            if($O365Object.application_args.ContainsKey('authContext')){
                [ref]$null = $O365Object.application_args.Remove('authContext')
            }
            #Connect-MonkeyCloud -Silent
            return $True
        }
        else{
            #Detected single Tenant
            $msg = @{
                MessageData = ("Working on {0} tenant" -f $selected_Tenant.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $script:InformationAction;
                Tags = @('SingleTenant');
            }
            Write-Information @msg
        }
    }
}
