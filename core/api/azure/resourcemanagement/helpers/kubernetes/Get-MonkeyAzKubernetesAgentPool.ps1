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

Function Get-MonkeyAzKubernetesAgentPool {
    <#
        .SYNOPSIS
		Get Azure Kubernetes agent pools

        .DESCRIPTION
		Get Azure Kubernetes agent pools

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKubernetesAgentPool
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, HelpMessage="Kubernetes object")]
        [Object]$KubernetesObject,

        [Parameter(Mandatory=$False, HelpMessage="Node pool")]
        [String]$NodePool,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2023-06-01"
    )
    try{
        if($PSBoundParameters.ContainsKey('NodePool') -and $PSBoundParameters['NodePool']){
            $p = @{
			    Id = $KubernetesObject.Id;
                Resource = ('/agentPools/{0}' -f $PSBoundParameters['NodePool']);
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    Get-MonkeyAzObjectById @p
        }
        else{
            $p = @{
			    Id = $KubernetesObject.Id;
                Resource = '/agentPools';
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    Get-MonkeyAzObjectById @p
        }
    }
    catch{
        Write-Verbose $_
    }
}
