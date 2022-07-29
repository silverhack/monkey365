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

function Get-MonkeyADObjectByObjectId {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADObjectByObjectId
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
            [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0,ParameterSetName='Url')]
            [String[]]$ObjectId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get instance
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        #Get Config
        $AADConfig = $O365Object.internal_config.azuread
        $Body = @{
            "objectIds" = @($ObjectId);
            "includeDirectoryObjectReferences" = "true"
        }
        $JsonData = $Body | ConvertTo-Json
        #Set null
        $object = $null
    }
    Process{
        $params = @{
            Authentication = $AADAuth;
            ObjectType = "getObjectsByObjectIds";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "POST";
            Data = $jsonData;
            APIVersion = $AADConfig.api_version;
        }
        $object = Get-MonkeyGraphObject @params
    }
    End{
        return $object
    }
}
