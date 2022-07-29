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

Function New-O365PsSession{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-O365PsSession
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Scope="Function")]
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Authentication Object')]
        [object]$Authentication,

        [Parameter(Mandatory = $false, HelpMessage = 'UserPrincipalName')]
        [String]$userPrincipalName,

        [Parameter(Mandatory=$false, HelpMessage="Resource")]
        [string] $resource,

        [Parameter(Mandatory=$false, HelpMessage="Resource")]
	    [string] $configuration_name = "Microsoft.Exchange"
    )
    Process{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        if ($PSCmdlet.ShouldProcess("ShouldProcess?")){
            try{
                $Authorization = "Bearer {0}" -f $Authentication.AccessToken
                $Password = ConvertTo-SecureString -AsPlainText $Authorization -Force
                $Ctoken = New-Object System.Management.Automation.PSCredential -ArgumentList $userPrincipalName, $Password
                $SessionOption = New-PSSessionOption -IdleTimeout 18000000
                $p = @{
                    ConfigurationName = $configuration_name;
                    ConnectionUri = ("{0}?BasicAuthToOAuthConversion=true" -f $Resource);
                    Credential = $Ctoken;
                    Authentication = "Basic";
                    AllowRedirection = $true;
                    SessionOption = $SessionOption
                }
                $PsSession = New-PSSession @p
                #return pssession
                return $PsSession
            }
            catch{
                $msg = @{
                    MessageData = $_;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    Tags = @('PsSessionError');
                }
                Write-Debug @msg
            }
        }
    }
}
