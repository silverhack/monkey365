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

Function ConvertTo-Hashtable{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-ToHashtable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$objects
    )
    Process{
        foreach($object in $objects){
            if($object -is [psobject]){
                $hashtable = @{}
                foreach ( $key in $object.psobject.properties) {
                    if($null -eq $key.Value){
                        $hashtable[$key.Name.ToString()] = $null
                    }
                    elseif($key.Value -is [Hashtable]){
                        $hashtable[$key.Name.ToString()] = $key.Value
                    }
                    elseif($key.Value -is [psobject]){
                        $hashtable[$key.Name.ToString()] = $key.Value
                    }
                    elseif($key.Value -is [array]){
                        $hashtable[$key.Name.ToString()] = ConvertTo-Hashtable $key.Value
                    }
                    else{
                        $hashtable[$key.Name.ToString()] = $key.Value
                    }
                }
            }
            $hashtable
        }
    }
}



