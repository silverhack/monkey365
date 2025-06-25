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

Function Get-MonkeyPowerBIDataset{
    <#
        .SYNOPSIS
        Returns a list of datasets for the organization

        .DESCRIPTION
        Returns a list of datasets for the organization

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBiDataset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$False, ValueFromPipeline = $True, ParameterSetName = 'DatasetId',  HelpMessage='Dataset Id')]
        [string]$Id,

        [parameter(Mandatory=$False, HelpMessage='Scope')]
        [ValidateSet("Individual","Organization")]
        [String]$Scope = "Individual",

        [Parameter(Mandatory = $false, HelpMessage='Object Path')]
        [String]$ObjectPath,

        [parameter(Mandatory=$False, HelpMessage='Filter')]
        [String]$Filter,

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
        If($PSCmdlet.ParameterSetName -eq 'DatasetId'){
            #Set param
            $p = @{
                Authentication = $access_token;
                ObjectType = 'datasets';
                ObjectId = $Id;
                Scope = $Scope;
                ObjectPath = $ObjectPath;
                Environment = $Environment;
                Method = "GET";
                APIVersion = 'v1.0';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        Else{
            #Set param
            $p = @{
                Authentication = $access_token;
                ObjectType = 'datasets';
                Scope = $Scope;
                Environment = $Environment;
                Filter = $Filter;
                Top = $Top;
                Skip = $Skip;
                Method = "GET";
                APIVersion = 'v1.0';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
        }
        #Get dataset info
        Get-MonkeyPowerBIObject @p
    }
    End{
        #Nothing to do here
    }
}

