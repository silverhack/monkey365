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

Function Get-MonkeyAzDatabaseBackupConfiguration {
    <#
        .SYNOPSIS
		Get backup settings for sql database

        .DESCRIPTION
		Get backup settings for sql database

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDatabaseBackupConfiguration
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'ShortTermRetentionPolicy')]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$Database,

        [Parameter(Mandatory=$false, ParameterSetName = 'ShortTermRetentionPolicy')]
        [SWitch]$ShortTermRetentionPolicy,

        [Parameter(Mandatory=$false, ParameterSetName = 'LongTermRetentionBackup')]
        [SWitch]$LongTermRetentionBackup,

        [Parameter(Mandatory=$false, ParameterSetName = 'LongTermRetentionBackup')]
        [SWitch]$onlyLatestPerDatabase,

        [parameter(Mandatory= $false, ParameterSetName = 'LongTermRetentionBackup', HelpMessage= "Database state")]
        [ValidateSet("Live","Deleted")]
        [String]$DatabaseState= "Live",

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2024-05-01-preview"
    )
    Process{
        try{
            #Set default params
            $p = @{
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            If($PSCmdlet.ParameterSetName -eq 'ShortTermRetentionPolicy'){
                #Add Id
                [void]$p.Add('Id',$Database.Id);
                #Add resource
                [void]$p.Add('Resource','backupShortTermRetentionPolicies')
            }
            Else{
                #Get location
                $location = $Database.location;
                $server = $Database.id.Split('/')[8]
                $subscriptionId = $Database.id.Split('/')[2]
                $resourceGroupName = $Database.id.Split('/')[4]
                $uri = ("/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Sql/locations/{2}/longTermRetentionServers/{3}/longTermRetentionBackups" -f $subscriptionId,$resourceGroupName,$location,$server)
                #Add resource
                [void]$p.Add('Id',$uri)
                #Add extra params if any
                $extraParam = [ordered]@{}
                If($onlyLatestPerDatabase.IsPresent){
                    [void]$extraParam.Add('onlyLatestPerDatabase','true')
                }
                If($PSBoundParameters.ContainsKey('DatabaseState') -and $DatabaseState){
                    [void]$extraParam.Add('databaseState',$DatabaseState)
                }
                #Add to param
                [void]$p.Add('ExtraParameters',$extraParam)
            }
            #Execute query
            Get-MonkeyAzObjectById @p
        }
        catch{
            Write-Verbose $_
        }
    }
    End{
        #Nothing to do here
    }
}

