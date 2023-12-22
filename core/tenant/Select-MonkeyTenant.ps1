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
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param()
    Begin{
        $selected_Tenant = $tenants = $null
        $bypassSelection = $false
        $p = @{
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $tenants = Get-MonkeyAzTenant @p
    }
    Process{
        if($null -ne $tenants){
            #Check for tenantId property
            if($null -eq ($tenants | Select-Object -ExpandProperty tenantId -ErrorAction Ignore)){
                foreach ($t in @($tenants)){
                    if($t.PsObject.Properties.Item('objectId')){
                        $t | Add-Member -type NoteProperty -name tenantId -value $t.objectId -Force
                    }
                }
            }
            if(@($tenants).Count -eq 1 -and $tenants.tenantId -ne 'F8CDEF31-A31E-4B4A-93E4-5F571E91255A'){
                $selected_Tenant = $tenants
                $O365Object.TenantId = $selected_Tenant.tenantId
                $bypassSelection = $True
            }
            elseif($PSEdition -eq "Desktop"){
                $selected_Tenant = $tenants | Out-GridView -Title "Choose a Tenant ..." -OutputMode Single
                if($selected_Tenant){
                    $msg = @{
                        MessageData = ($message.EntraIDSelectedTenantInfo -f $selected_Tenant.displayName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('EntraIDTenantInfo');
                    }
                    Write-Information @msg
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
            #Check if already connected
            if($selected_Tenant.tenantId -ne $O365Object.tenantOrigin.objectId){
                <#
                if($null -eq $O365Object.application_args.Item('TenantId')){
                    #Add TenantId
                    [ref]$null = $O365Object.application_args.Add('TenantId',$selected_Tenant.tenantId)
                }
                else{
                    $O365Object.application_args.TenantId = $selected_Tenant.tenantId
                }
                #>
                #Because a new tenant was selected, a new application should be created
                Initialize-AuthenticationParam
                return $True
            }
        }
        else{
            #Detected single Tenant
            $msg = @{
                MessageData = ("Working on {0} tenant" -f $selected_Tenant.displayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SingleTenant');
            }
            Write-Information @msg
        }
    }
}
