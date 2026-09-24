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

Function Get-MonkeyAzSQlServerAdmin {
    <#
        .SYNOPSIS
		Get sql server administrator from Azure

        .DESCRIPTION
		Get sql server administrator from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSQlServerAdmin
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
	[CmdletBinding(DefaultParameterSetName = 'SQL')]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Server Object")]
        [Object]$InputObject,

        [Parameter(Mandatory=$false, ParameterSetName = 'oss', HelpMessage="OSS server")]
        [Switch]$OSSSql,

        [Parameter(Mandatory=$false, ParameterSetName = 'eidonly', HelpMessage="EntraID Only Authentication")]
        [Switch]$EntraIDOnly,

        [Parameter(Mandatory=$false, ParameterSetName = 'eidonlymysql', HelpMessage="EntraID Only Authentication for Mysql")]
        [Switch]$EntraIDOnlyForMysql,

        [Parameter(Mandatory=$false, ParameterSetName = 'eidonlypostgre', HelpMessage="EntraID Only Authentication for Mysql")]
        [Switch]$EntraIDGroupSyncForPostgreSQL,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-08-01"
    )
    Process{
        If($PSCmdlet.ParameterSetName -eq 'oss'){
            $p = @{
                Id = ($InputObject.Id).Substring(1);
                Resource = "administrators";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'eidonly'){
            $p = @{
                Id = ($InputObject.Id).Substring(1);
                Resource = "azureADOnlyAuthentications/default";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'eidonlymysql'){
            $p = @{
                Id = ($InputObject.Id).Substring(1);
                Resource = "configurations/aad_auth_only";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'eidonlypostgre'){
            $p = @{
                Id = ($InputObject.Id).Substring(1);
                Resource = "configurations/pgaadauth.enable_group_sync";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        Else{
            $p = @{
                Id = ($InputObject.Id).Substring(1);
                Resource = "administrators/activeDirectory";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        #execute command
        Get-MonkeyAzObjectById @p
    }
}
