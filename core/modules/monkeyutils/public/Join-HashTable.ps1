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

Function Join-HashTable {
    <#
        .SYNOPSIS
		Combine two hashtables

        .DESCRIPTION
		Combine two hashtables

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Join-HashTable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseLiteralInitializerForHashtable", "", Scope="Function")]
	[CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [System.Collections.Hashtable]$HashTable,

        [parameter(Mandatory=$false, HelpMessage="Object you want to append or update")]
        [System.Collections.Hashtable]$JoinHashTable
    )
    Begin{
        if(($HashTable.GetType()).FullName -eq "System.Collections.Hashtable+SyncHashtable"){
            $newHashTable = [System.Collections.Hashtable]::Synchronized(@{})
        }
        else{
            $newHashTable = [System.Collections.Hashtable]::new()
        }
    }
    Process{
        if($PSBoundParameters.ContainsKey('JoinHashTable') -and $PSBoundParameters['JoinHashTable']){
            foreach($key in $JoinHashTable.Keys){
                if($HashTable.ContainsKey($key)){
                    [void]$HashTable.Remove($key)
                }
            }
            #Add elements from join hashtable
            foreach($elem in $JoinHashTable.GetEnumerator()){
                [void]$newHashTable.Add($elem.Name,$elem.Value);
            }
        }
        #Add all elements from original hashtable into new hashtable
        foreach($elem in $HashTable.GetEnumerator()){
            [void]$newHashTable.Add($elem.Name,$elem.Value);
        }
    }
    End{
        $newHashTable
    }
}
