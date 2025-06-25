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

Function Get-MonkeyPowerBIBackend{
    <#
        .SYNOPSIS
        Returns PowerBI backend URL

        .DESCRIPTION
        Returns PowerBI backend URL

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBIBackend
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param ()
    Begin{
        #Getting environment
		$Environment = $O365Object.Environment
        #Set uri
        $rawQuery = ('{0}/v1.0/myorg/admin/groups?$top=1' -f $O365Object.Environment.PowerBIAPI);
        #Get Auth header
        $AuthHeader = @{
            Authorization = $O365Object.auth_tokens.PowerBI.CreateAuthorizationHeader();
        }
    }
    Process{
        $p = @{
            Url = $rawQuery;
            Headers = $AuthHeader;
            UserAgent = $O365Object.userAgent;
            Method = "GET";
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
        }
        #Get dataset info
        $_object = Invoke-MonkeyWebRequest @p
        If($null -ne $_object){
            [uri]$uri = $_object | Select-Object -ExpandProperty '@odata.context' -ErrorAction Ignore
            #return object
            ("https://{0}" -f $uri.DnsSafeHost)
        }
    }
    End{
        #Nothing to do here
    }
}

