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

Function Get-MonkeyMSGraphProfilePhoto {
    <#
        .SYNOPSIS
		Get Profile photo

        .DESCRIPTION
		Get Profile photo

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphProfilePhoto
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId,

        [Parameter(Mandatory=$True, ParameterSetName = 'ServicePrincipalId', ValueFromPipeline = $True)]
        [String]$ServicePrincipalId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("48x48","64x64","96x96","120x120","240x240","360x360","432x432","504x504","648x648")]
        [String]$Size = "48x48",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        #Set null
        $profilePhoto = $null
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $ObjectId = ('{0}/photos/{1}/$value' -f $UserId,$Size)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'users';
                ObjectId = $ObjectId;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $profilePhoto = Get-MonkeyMSGraphObject @params
        }
        elseif($PSCmdlet.ParameterSetName -eq 'ServicePrincipalId'){
            $ObjectId = ('{0}/info/logoUrl' -f $ServicePrincipalId)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'servicePrincipals';
                ObjectId = $ObjectId;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $logoUrl = Get-MonkeyMSGraphObject @params
            if($null -ne $logoUrl){
                #Get profile Photo
                $p = @{
                    Url = $logoUrl;
                    Content_Type = 'image/jpg';
                    Method = "GET";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $profilePhoto = Invoke-UrlRequest @p
            }
        }
    }
    End{
        #return data
        if($null -ne $profilePhoto){
            #Get Base64
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($profilePhoto);
            #Create memoryStream
            $ms = [System.IO.MemoryStream]::new($bytes)
            #return B64
            [System.Convert]::ToBase64String($ms.ToArray())
        }
    }
}