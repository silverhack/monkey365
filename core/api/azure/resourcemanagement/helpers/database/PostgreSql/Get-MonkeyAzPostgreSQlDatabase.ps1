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

Function Get-MonkeyAzPostgreSQlDatabase {
    <#
        .SYNOPSIS
		Get sql databases from Azure

        .DESCRIPTION
		Get sql databases from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzPostgreSQlDatabase
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
        [String]$APIVersion = "2024-11-01-preview"
    )
    Process{
        try{
            $all_databases = New-Object System.Collections.Generic.List[System.Object]
            $p = @{
			    Id = ($Server.Id).Substring(1);
                Resource = "databases";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $databases = Get-MonkeyAzObjectById @p
            if($databases){
                foreach($database in $databases){
                    $new_db = New-MonkeyDatabaseObject -Database $database
                    #add to array
                    [void]$all_databases.Add($new_db)
                }
            }
            #return object
            Write-Output $all_databases -NoEnumerate
        }
        catch{
            Write-Verbose $_
        }
    }
}
