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

Function Get-MonkeyAzVMExtension {
    <#
        .SYNOPSIS
		Get VM extension

        .DESCRIPTION
		Get VM extension

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzVMExtension
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="VM Object")]
        [String]$Id,

        [Parameter(Mandatory=$false, HelpMessage="VM Object")]
        [Switch]$Detailed,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-10-01"
    )
    Process{
        $allExtensions = [System.Collections.Generic.List[System.Object]]::new()
        $p = @{
			Id = $Id;
            Resource = "extensions";
            ApiVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
		}
		$extensions = Get-MonkeyAzObjectById @p
        #Check if detailed
        If($PSBoundParameters.ContainsKey('Detailed') -and $PSBoundParameters['Detailed'].IsPresent){
            ForEach($extension in @($extensions)){
                $p = @{
                    Id = $extension.id;
                    Expand = 'InstanceView';
                    ApiVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $newExtension = Get-MonkeyAzObjectById @p
                If($newExtension){
                    [void]$allExtensions.Add($newExtension);
                }
            }
        }
        Else{
            ForEach($extension in @($extensions)){
                [void]$allExtensions.Add($extension);
            }
        }
        #Return object
        return $allExtensions
    }
}
