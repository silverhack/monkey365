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

function Get-DLPSensitiveInformationGroup{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DLPSensitiveInformationGroup
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $sit_groups
    )
    Begin{
        $sit_info = New-Object System.Collections.Generic.List[System.Object]
        $new_array = @()
    }
    Process{
        foreach ($element in $sit_groups.groups){
            if($null -ne $element.Item('sensitivetypes')){
                #https://github.com/dotnet/platform-compat/blob/master/docs/DE0006.md
                $sit_dict = [ordered]@{
                    name = $element.name
                }
                foreach($grp in $element.sensitivetypes){
                    foreach($sit in $grp){
                        $new_dict = [ordered]@{}
                        foreach($elem in $sit.GetEnumerator()){
                            [void]$new_dict.Add($elem.Key, $elem.Value)
                        }
                        $new_array+= New-Object -TypeName PsObject -Property $new_dict
                    }
                    $sit_dict.sit = $new_array
                }
                $sit_info += New-Object -TypeName PsObject -Property $sit_dict
            }
        }
    }
    End{
        return $sit_info
    }
}
