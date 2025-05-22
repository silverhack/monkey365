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

Function Request-MonkeyAzDiagnosticSetting {
    <#
        .SYNOPSIS
		Get diagnostic settings for a resource Id

        .DESCRIPTION
		Get diagnostic settings for a resource Id

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Request-MonkeyAzDiagnosticSetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Resource object")]
        [Object]$InputObject
    )
    Process{
        try{
            $p = @{
				Id = $InputObject.Id;
				Resource = "providers/microsoft.insights/diagnosticSettings";
				APIVersion = "2021-05-01-preview";
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
			}
            Get-MonkeyAzObjectById @p
        }
        catch{
            Write-Verbose $_
        }
    }
}
