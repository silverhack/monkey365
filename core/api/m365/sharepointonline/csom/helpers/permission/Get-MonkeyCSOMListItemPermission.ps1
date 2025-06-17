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

Function Get-MonkeyCSOMListItemPermission{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMListItemPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$true, ParameterSetName = 'List', ValueFromPipeline = $true, HelpMessage="Web Object")]
        [Object]$List,

        [parameter(Mandatory=$true, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Include lists")]
        [Switch]$ExcludeFolders,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Begin{
        #Get permission params
        $permParam = Set-CommandParameter -Command "Get-MonkeyCSOMPermission" -Params $PSBoundParameters
        $job_params = @{
            Command = "Get-MonkeyCSOMPermission";
            Arguments = $permParam;
            Runspacepool = $O365Object.monkey_runspacePool;
			ReuseRunspacePool = $true;
			Debug = $O365Object.debug;
			Verbose = $O365Object.verbose;
			MaxQueue = $O365Object.MaxQueue;
			BatchSleep = $O365Object.BatchSleep;
			BatchSize = $O365Object.BatchSize;
            Throttle = $O365Object.nestedRunspaceMaxThreads;
        }
    }
    Process{
        $p = Set-CommandParameter -Command "Get-MonkeyCSOMListItem" -Params $PSBoundParameters
        $listItems = Get-MonkeyCSOMListItem @p
        #Check if folders should be excluded
        if($PSBoundParameters.ContainsKey('ExcludeFolders') -and $PSBoundParameters['ExcludeFolders'].IsPresent){
            $listItems = @($listItems).Where({$_.FileSystemObjectType -eq [FileSystemObjectType]::File -and ($_.FileLeafRef -ne "Forms") -and (-Not($_.FileLeafRef.StartsWith("_")))});
        }
        if(@($listItems).Count -gt 0){
            if($PSBoundParameters.ContainsKey('IncludeInheritedPermission') -and $PSBoundParameters['IncludeInheritedPermission'].IsPresent){
               $listItems | Invoke-MonkeyJob @job_params
            }
            Else{
                $items = @($listItems).Where({$_ | Test-HasUniqueRoleAssignment})
                if(@($items).Count -gt 0){
                    $items | Invoke-MonkeyJob @job_params
                }
            }
            #Sleep
            Start-Sleep -Milliseconds 500
        }
    }
}
