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

Function Get-ImmutableId{
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $true, ValueFromPipeline = $True, HelpMessage= "Input Object")]
        [Object]$InputObject,

        [parameter(Mandatory= $true, HelpMessage= "TenantId")]
        [System.String]$TenantId,

        [parameter(Mandatory= $true, HelpMessage= "Properties")]
        [System.Array]$Properties
    )
    Begin{
        $stringParts = [System.Collections.Generic.List[System.String]]::new()
        $immutableId = [System.String]::Empty
    }
    Process{
        #Add always TenantId
        [void]$stringParts.Add($TenantId);
        #Iterate for each property
        If(($InputObject.psobject.Methods.Where({$_.MemberType -eq 'ScriptMethod' -and $_.Name -eq 'GetPropertyByPath'})).Count -gt 0){
            ForEach($property in $PSBoundParameters['Properties'].GetEnumerator()){
                $value = $InputObject.GetPropertyByPath($property);
                If($value){
                    [void]$stringParts.Add($value);
                }
            }
            $immutableId = (@($stringParts) -join '|')
            If($immutableId -eq [System.String]::Empty){
                Write-Warning ("Unable to get inmutable Id. Empty string returned")
            }
            Else{
                return ($immutableId | Get-HashFromString)
            }
        }
        Else{
            Write-Warning "GetPropertyByPath method was not loaded"
        }
    }
}