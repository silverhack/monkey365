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

function Convert-ObjectToCamelCaseObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-ObjectToCamelCaseObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeline = $True, HelpMessage="Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false,HelpMessage="Object Name")]
        [String]$psName
    )
    Process{
        ForEach($obj in @($InputObject)){
            $object = $null
            $hashTable = [System.Collections.Specialized.OrderedDictionary]::new()
            #check if PsCustomObject
            $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($obj.GetType())
            #check if PsObject
            $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($obj.GetType())
            If ($isPsCustomObject -or $isPsObject) {
                foreach ($element in $obj.Psobject.Properties.GetEnumerator()){
                    try{
                        $key = $element.Name | ConvertTo-CamelCase
                        if($null -eq $element.Value){
                            [void]$hashTable.Add($key,$element.Value);
                        }
                        ElseIf($element.Value.GetType() -eq [System.Management.Automation.PSCustomObject] -or $element.Value.GetType() -eq [System.Management.Automation.PSObject]){
                            [void]$hashTable.Add($key,(Convert-ObjectToCamelCaseObject -InputObject $element.Value));
                        }
                        ElseIf($element.Value.GetType().FullName -like "*OCSF*"){
                            if($element.Value -is [System.Enum]){
                                [void]$hashTable.Add($key,$element.Value.value__.ToString());
                            }
                            Else{
                                [void]$hashTable.Add($key,(Convert-ObjectToCamelCaseObject -InputObject ($element.Value | Select-Object *)));
                            }
                        }
                        Else{
                            if($element.Value -is [System.Enum]){
                                [void]$hashTable.Add($key,$element.Value.value__.ToString());
                            }
                            Else{
                                [void]$hashTable.Add($key,$element.Value);
                            }
                        }
                    }
                    Catch{
                        Write-Error $_
                    }
                }
                #Create custom object
                $object = New-Object PSObject -Property $hashTable
                if($null -ne $object -and $psName){
                    $object.PSObject.TypeNames.Insert(0,$psName)
                }
                $object
            }
        }
    }
}


