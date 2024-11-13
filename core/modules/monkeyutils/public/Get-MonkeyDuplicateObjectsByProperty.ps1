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


Function Get-MonkeyDuplicateObjectsByProperty{
    <#
        .SYNOPSIS
		Get duplicate objects based on specific property

        .DESCRIPTION
		Get duplicate objects based on specific property

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyDuplicateObjectsByProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Reference Object")]
        [System.Collections.Generic.List[System.Management.Automation.PSObject]]$ReferenceObject,

        [parameter(Mandatory=$true, HelpMessage="Object Property")]
        [String]$Property
    )
    Process{
        $duplicateObjects = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
        Try{
            $Objects = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new();
            #Iterate objects
            Foreach($obj in $ReferenceObject){
                if($Objects.Count -gt 0){
                    $match = $Objects.Where({$_.$($Property) -eq $obj.$($Property)})
                    if($match){
                        Write-Verbose -Message ("duplicate entry found {0}" -f $obj.$($Property));
                        [void]$duplicateObjects.Add($obj)
                    }
                    else{
                        [void]$Objects.Add($obj)
                    }
                }
                Else{
                    [void]$Objects.Add($obj)
                }
            }
            return $duplicateObjects
        }
        Catch{
            Write-Error $_
            return , $duplicateObjects
        }
    }
}