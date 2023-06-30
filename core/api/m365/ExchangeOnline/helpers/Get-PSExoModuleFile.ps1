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

Function Get-PSExoModuleFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoModuleFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param ()
    try{
        #Get environment
        $Environment = $O365Object.Environment
        #Get Auth token
        $exoAuth = $O365Object.auth_tokens.ExchangeOnline
        #Get Module file
        $param = @{
            Authentication = $exoAuth;
            Environment = $Environment;
            ObjectType = 'EXOModuleFile';
            ExtraParameters = "Version=3.5.0";
            Method = "GET";
            RemoveOdataHeader = $true;
            APIVersion = 'v1.0';
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $moduleFile = Get-PSExoAdminApiObject @param
        if($moduleFile){
            return $moduleFile
        }
    }
    catch{
        Write-Verbose $_
    }
}
