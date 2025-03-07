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

Function Get-QueryResult{
    <#
        .SYNOPSIS
        Performs a query against a dataset

        .DESCRIPTION
        Performs a query against a dataset. The query string is in the native query syntax of PowerShell. An array is returned which can be used to iterate over all keys in the query result set.

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-QueryResult
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Rule object")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="ScriptBlock query")]
        [ScriptBlock]$Query
    )
    try{
        $result = $null
        #check if PsCustomObject
        $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($InputObject.GetType())
        #check if PsObject
        $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($InputObject.GetType())
        #Check if array
        $isArray = $InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]
        if($isPsCustomObject -or $isPsObject){
            $result = @($InputObject).Where($Query)
        }
        elseif($isArray){
            $result = $InputObject.Where($Query)
        }
        else{
            Write-Warning -Message $Script:messages.InvalidObject
        }
        #return result
        return $result
    }
    catch{
        Write-Error $_
    }
}


