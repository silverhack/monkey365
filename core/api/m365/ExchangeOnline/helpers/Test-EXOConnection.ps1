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

Function Test-EXOConnection{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-EXOConnection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Compliance Center")]
        [Switch]$ComplianceCenter
    )
    try{
        $exo_session = $false
        if (-not $PSBoundParameters.ContainsKey('ComplianceCenter')) {
            #Check if already connected to Exchange Online
            if($null -eq (Get-Command -Name Get-ExoMonkeyActiveSyncOrganizationSettings -ErrorAction Ignore)){
                $msg = @{
                    MessageData = "Not connected to Exchange Online";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('ExoConnectionError');
                }
                Write-Warning @msg
                $exo_session = $false;
            }
            else{
                $exo_session = $true;
            }
        }
        else{
            #Check if already connected to Exchange Online Compliance Center
            if($null -eq (Get-Command -Name Get-AdminAuditLogConfig -ErrorAction Ignore)){
                $msg = @{
                    MessageData = "Not connected to Exchange Online Compliance Center";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('ExoConnectionError');
                }
                Write-Warning @msg
                $exo_session = $false;
            }
            else{
                $exo_session = $true;
            }
        }
        return $exo_session
    }
    catch{
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'verbose';
            InformationAction = $InformationAction;
            Tags = @('ExoConnectionError');
        }
        Write-Verbose @msg
        return $false
    }
}


