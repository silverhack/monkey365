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

Function Get-MonkeyGraphAADProfilePhoto {
    <#
        .SYNOPSIS
        Get user's profile photo from Entra ID

        .DESCRIPTION
        Get user's profile photo from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADProfilePhoto
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [String]$UserId
    )
    Begin{
        #Get instance
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        #Set null
        $profilePhoto = $null
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        $ObjectId = ('{0}/thumbnailPhoto' -f $UserId)
        $params = @{
            Authentication = $AADAuth;
            ObjectType = 'users';
            ObjectId = $ObjectId;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $aadConf.api_version;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $profilePhoto = Get-MonkeyGraphObject @params
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
