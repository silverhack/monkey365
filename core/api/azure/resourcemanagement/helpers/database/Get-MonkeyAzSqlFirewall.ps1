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

Function Get-MonkeyAzSqlFirewall {
    <#
        .SYNOPSIS
		Get firewall config for sql server

        .DESCRIPTION
		Get firewall config for sql server

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSqlFirewall
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$Server,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2020-11-01-preview"
    )
    Process{
        try{
            #Set array
            $all_fw_rules = New-Object System.Collections.Generic.List[System.Object]
            $p = @{
                Id = $Server.Id;
                Resource = "firewallrules";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $fw_rules = Get-MonkeyAzObjectById @p
            if($fw_rules){
                foreach($fwrule in $fw_rules){
                    $rule = [ordered]@{
                        ServerName = $Server.Name;
                        Location = $Server.location;
                        ResourceGroupName = $Server.Id.Split("/")[4];
                        RuleName = $fwrule.Name;
                        StartIpAddress = $fwrule.Properties.startIpAddress;
                        EndIpAddress = $fwrule.Properties.endIpAddress;
                        rawObject = $fwrule;
                    }
                    #New Obj
                    $Object = New-Object PSObject -Property $rule
                    #Add to list
                    [void]$all_fw_rules.Add($Object)
                }
            }
            Write-Output $all_fw_rules -NoEnumerate
        }
        catch{
            Write-Verbose $_
        }
    }
    End{
        #Nothing to do here
    }
}

