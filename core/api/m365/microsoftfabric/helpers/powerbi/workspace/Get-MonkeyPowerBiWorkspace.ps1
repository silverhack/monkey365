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

Function Get-MonkeyPowerBiWorkspace{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBiWorkspace
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$false, ValueFromPipeline = $True, ParameterSetName = 'WorkspaceId',  HelpMessage='Workspace Id')]
        [String]$Id,

        [parameter(Mandatory=$false, HelpMessage='Scope')]
        [ValidateSet("Individual","Organization")]
        [String]$Scope = "Individual",

        [parameter(Mandatory=$false, HelpMessage='Expand object')]
        [String[]]$Expand,

        [parameter(Mandatory=$False, HelpMessage='Top objects')]
        [String]$Top,

        [parameter(Mandatory=$False, HelpMessage='Skip objects')]
        [String]$Skip
    )
    Begin{
        #Getting environment
		$Environment = $O365Object.Environment
		#Get PowerBI Access Token
		$access_token = $O365Object.auth_tokens.PowerBI
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'WorkspaceId'){
            #Set param
            $p = @{
                Authentication = $access_token;
                Id = $Id;
                ObjectType = 'groups';
                Scope = $Scope;
                Expand = $Expand;
                Top = $Top;
                Environment = $Environment;
                Method = "GET";
                APIVersion = 'v1.0';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        Else{
            IF($PSBoundParameters.ContainsKey('Top') -and $PSBoundParameters['Top']){
                $_top = $PSBoundParameters['Top']
            }
            Else{
                $_top = 5000
            }
            #Set param
            $p = @{
                Authentication = $access_token;
                ObjectType = 'groups';
                Scope = $Scope;
                Expand = $Expand;
                Top = $_top;
                Environment = $Environment;
                Method = "GET";
                APIVersion = 'v1.0';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        #Get workspace info
        Get-MonkeyPowerBIObject @p
    }
    End{
        #Nothing to do here
    }
}

