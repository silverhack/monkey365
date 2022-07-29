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


Function Get-MonkeyMsolDomain{
    <#
        .SYNOPSIS
		Get domain through Office 365 legacy API

        .DESCRIPTION
		Get domain through Office 365 legacy API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMsolDomain
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    try{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.Graph
        #Get xml file
        $xmlfile = ("{0}/core/api/o365/LegacyO365/ws/domain/envelope.xml" -f $O365Object.Localpath)
        if (!(Test-Path -Path $xmlfile)){
            $msg = @{
                MessageData = ("{0} xml does not exists" -f $xmlfile);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('EnvelopeFileNotFound');
            }
            Write-Warning @msg
            return
        }
        [XML]$envelope = Get-Content $xmlfile
        #Get Object
        $param = @{
            Authentication = $graphAuth;
            Environment = $Environment;
            Envelope = $envelope;
        }
        [xml]$object = Get-LegacyO365Object @param
        if($null -ne $object){
            return $object.Envelope.Body.ListDomainsResponse.ListDomainsResult.ReturnValue.Domain
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get domain information");
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('LegacyO365DomainInfoFailed');
        }
        Write-Warning @msg
        Write-Debug $_
    }
}
