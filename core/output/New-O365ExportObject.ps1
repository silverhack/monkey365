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


Function New-O365ExportObject{
    <#
        .SYNOPSIS
		Function to create new O365 Export object

        .DESCRIPTION
		Function to create new O365 Export object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-O365ExportObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider = "Azure"
    )
    try{
        #Check if data is Dictionary
        If(([System.Collections.IDictionary]).IsAssignableFrom($Script:ReturnData.GetType())){
            $dataset = $Script:ReturnData | Convert-HashTableToPsObject -psName "Monkey365Output"
        }
        ElseIf ($Script:ReturnData.GetType() -eq [System.Management.Automation.PSCustomObject] -or $Script:ReturnData.GetType() -eq [System.Management.Automation.PSObject]) {
            $dataset = $Script:ReturnData
        }
        Else{
            Write-Warning "Unable to convert Dataset"
            $dataset = $null
        }
        If($dataset){
            $dataset.PSObject.TypeNames.Insert(0,"Monkey365Output")
            switch ($Provider.ToLower()){
                { @("microsoft365", "entraid") -contains $_ }{
                    $_object = [PsCustomObject]@{
                        Environment = $O365Object.Environment;
                        cloudEnvironment = $O365Object.cloudEnvironment;
                        StartDate = $O365Object.startDate.ToLocalTime();
                        Tenant = $O365Object.Tenant;
                        TenantID = $O365Object.TenantId;
                        Localpath = $O365Object.Localpath;
                        Output = $dataset;
                        Collectors = $O365Object.Collectors;
                        Instance = $O365Object.Instance;
                        IncludeEntraID = $O365Object.IncludeEntraID;
                        aadpermissions = $O365Object.aadPermissions;
                        executionInfo = $O365Object.executionInfo;
                    }
                    return $_object
                }
                'azure'{
                    $_object = [PsCustomObject]@{
                        Environment = $O365Object.Environment;
                        cloudEnvironment = $O365Object.cloudEnvironment;
                        StartDate = $O365Object.startDate.ToLocalTime();
                        Tenant = $O365Object.Tenant;
                        TenantID = $O365Object.TenantId;
                        Subscription = $O365Object.current_subscription;
                        Localpath = $O365Object.Localpath;
                        Output = $dataset;
                        Collectors = $O365Object.Collectors;
                        Instance = $O365Object.Instance;
                        IncludeEntraID = $O365Object.IncludeEntraID;
                        aadpermissions = $O365Object.aadPermissions;
                        executionInfo = $O365Object.executionInfo;
                        allResources = $O365Object.all_resources;
                    }
                    return $_object
                }
                Default{
                    $_object = [PsCustomObject]@{
                        Environment = $O365Object.Environment;
                        cloudEnvironment = $O365Object.cloudEnvironment;
                        StartDate = $O365Object.startDate.ToLocalTime();
                        Tenant = $O365Object.Tenant;
                        TenantID = $O365Object.TenantId;
                        Localpath = $O365Object.Localpath;
                        Output = $dataset;
                        Collectors = $O365Object.Collectors;
                        Instance = $O365Object.Instance;
                        IncludeEntraID = $O365Object.IncludeEntraID;
                        aadpermissions = $O365Object.aadPermissions;
                        executionInfo = $O365Object.executionInfo;
                        allResources = $O365Object.all_resources;
                    }
                    return $_object
                }
            }
        }
    }
    catch{
        throw ("{0}. {1}" -f $message.UnableToCreateMonkeyObject,$_.Exception.Message)
    }
}
