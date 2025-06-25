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

Function Get-ObjectCompliance {
    <#
        .SYNOPSIS
		Get compliance for object

        .DESCRIPTION
		Get compliance for object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ObjectCompliance
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Compliance Object")]
        [AllowNull()]
        [Object]$InputObject
    )
    Process{
        Try{
            $msg = [System.Collections.Generic.List[System.String]]::new()
            foreach($obj in @($InputObject)){
                if($null -ne $obj){
                    $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($obj.GetType())
                    #check if PsObject
                    $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($obj.GetType())
                    If($obj -is [string]){
                        [void]$msg.Add($obj);
                    }
                    Elseif($isPsCustomObject -or $isPsObject){
                        Foreach($element in $obj.PsObject.Properties){
                            [void]$msg.Add($element.Value);
                        }
                    }
                    ElseIf ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]){
                        Foreach($element in $obj){
                            [void]$msg.Add($element);
                        }
                    }
                }
            }
            #return Object
            (@($msg) -join ' | ');
        }
        Catch{
            Write-Error $_
        }
    }
}
