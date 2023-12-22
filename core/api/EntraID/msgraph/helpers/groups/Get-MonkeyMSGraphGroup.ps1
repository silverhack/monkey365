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

Function Get-MonkeyMSGraphGroup {
    <#
        .SYNOPSIS
		Get Azure AD group

        .DESCRIPTION
		Get Azure AD group

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphGroup
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'GroupId', ValueFromPipeline = $True)]
        [String]$GroupId,

        [Parameter(Mandatory=$false, ParameterSetName = 'GroupName', ValueFromPipeline = $True)]
        [String]$GroupName,

        [Parameter(Mandatory=$false)]
        [String]$Expand,

        [Parameter(Mandatory=$false)]
        [String]$Filter,

        [Parameter(Mandatory=$false)]
        [String[]]$Select,

        [parameter(Mandatory=$false)]
        [String]$Top,

        [Parameter(Mandatory=$false)]
        [Switch]$Count,

        [parameter(Mandatory = $false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'GroupId'){
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'groups';
                ObjectId = $GroupId;
                Environment = $Environment;
                ContentType = 'application/json';
                Select = $Select;
                Expand = $Expand;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $group = Get-MonkeyMSGraphObject @params
        }
        elseif($PSCmdlet.ParameterSetName -eq 'GroupName'){
            #Set filter
            $filter = ("startswith(displayName,'{0}')" -f $GroupName)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'groups';
                Filter = $filter;
                Environment = $Environment;
                ContentType = 'application/json';
                Expand = $Expand;
                Select = $Select;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $group = Get-MonkeyMSGraphObject @params
        }
        else{
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'groups';
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                Expand = $Expand;
                Filter = $Filter;
                Select = $Select;
                Top = $Top;
                Count = $Count;
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $group = Get-MonkeyMSGraphObject @params
        }
        #return data
        if($group){
            return $group
        }
    }
    End{
        #Nothing to do here
    }
}