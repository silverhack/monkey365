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


Function Get-MonkeyMsolDomainPasswordPolicy{
    <#
        .SYNOPSIS
		Get domain password policy through Office 365 legacy API

        .DESCRIPTION
		Get domain password policy through Office 365 legacy API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMsolDomainPasswordPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="Domain")]
        [string]$domain
    )
    try{
        $domains = $null
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.Graph
        #Get xml file
        $xmlfile = ("{0}/core/api/o365/LegacyO365/ws/passwordpolicy/envelope.xml" -f $O365Object.Localpath)
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
        #Get Domains
        if (-not $PSBoundParameters.ContainsKey('domain')) {
            $domains = Get-MonkeyMsolDomain
            if($null -ne $domains){
                $default_domain = $domains | Where-Object {$_.isDefault -eq $True} -ErrorAction Ignore
                if($default_domain){
                    $domain = $default_domain.Name.ToString()
                }
                else{
                    Write-Warning "Default domain was not found"
                }
            }
        }
        if($null -ne $domain){
            [XML]$envelope = Get-Content $xmlfile
            $namespace = $envelope.DocumentElement.NamespaceURI
            $ns = New-Object System.Xml.XmlNamespaceManager($envelope.NameTable)
            $ns.AddNamespace("s", $namespace)
            #Get body and set envelope values
            $body = $envelope.SelectSingleNode('//s:Body',$ns)
            $body.GetPasswordPolicy.request.DomainName = $domain
            #Get Object
            $param = @{
                Authentication = $graphAuth;
                Environment = $Environment;
                Envelope = $envelope;
            }
            [xml]$object = Get-LegacyO365Object @param
            if($null -ne $object){
                return $object.Envelope.Body.GetPasswordPolicyResponse.GetPasswordPolicyResult.ReturnValue
            }
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get domain password policy information");
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('LegacyO365DPPFailed');
        }
        Write-Warning @msg
        Write-Debug $_
    }
}
