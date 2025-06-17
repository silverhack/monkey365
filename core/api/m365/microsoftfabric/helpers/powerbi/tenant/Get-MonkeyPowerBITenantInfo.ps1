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

Function Get-MonkeyPowerBITenantInfo{
    <#
        .SYNOPSIS
        Returns organization's tenant Info

        .DESCRIPTION
        Returns organization's tenant Info

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBITenantInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param ()
    Begin{
        #Getting environment
		$Environment = $O365Object.Environment
		#Get PowerBI Access Token
		$access_token = $O365Object.auth_tokens.PowerBI
        $rawQuery = ("{0}/v1/admin/tenantsettings" -f $O365Object.Environment.PowerBIAPI)
    }
    Process{
        $p = @{
            Authentication = $access_token;
            RawQuery = $rawQuery;
            Environment = $Environment;
            Method = "GET";
            APIVersion = 'v1.0';
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
        }
        #Get dataset info
        Get-MonkeyPowerBIObject @p
    }
    End{
        #Nothing to do here
    }
}

