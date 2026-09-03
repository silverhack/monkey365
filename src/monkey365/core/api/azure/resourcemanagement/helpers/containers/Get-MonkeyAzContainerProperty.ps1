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

Function Get-MonkeyAzContainerProperty {
    <#
        .SYNOPSIS
		Get container name, logs, etc.., for a specified container instance

        .DESCRIPTION
		Get container name, logs, etc.., for a specified container instance

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzContainerProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-09-01"
    )
    Process{
        #Set array
		$all_containers = [System.Collections.Generic.List[System.Object]]::new()
        try{
            ForEach($containerObj in $InputObject.properties.containers.GetEnumerator()){
                $containerName = ("{0}/containers/{1}" -f $InputObject.id,$containerObj.name)
                $msg = @{
			        MessageData = ("Getting logs from {0} container" -f $containerName);
			        callStack = (Get-PSCallStack | Select-Object -First 1);
			        logLevel = 'info';
			        InformationAction = $O365Object.InformationAction;
			        Tags = @('AzureContainerLogInfo');
		        }
		        Write-Information @msg
                $logs = $containerName | Get-MonkeyAzContainerLog
                #Add to object
                $containerObj | Add-Member -MemberType NoteProperty -Name logs -Value $logs -Force
                #Add to array
                [void]$all_containers.Add($containerObj);
            }
            #return object
            return $all_containers
        }
        catch{
            Write-Verbose $_
        }
    }
}
