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

Function Get-MonkeyTeamsServiceDiscovery {
    <#
        .SYNOPSIS
		Get Microsoft Teams service discovery url

        .DESCRIPTION
		Get Microsoft Teams service discovery url

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyTeamsServiceDiscovery
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Teams Auth
        $TeamsAuth = $O365Object.auth_tokens.Teams
    }
    Process{
        $params = @{
            Authentication = $TeamsAuth;
            InternalPath = "TeamsTenant";
            ObjectType = 'serviceDiscovery';
            Environment = $Environment;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyTeamsObject @params
    }
    End{
        #Nothing to do here
    }
}