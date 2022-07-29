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

Function New-MonkeyFolder{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyFolder
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Directory name")]
        [String]$destination
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        $tmpdir = $null
    }
    Process{
        if ($PSCmdlet.ShouldProcess($destination,'Create new directory')){
            if (!(Test-Path -Path $destination)){
                try{
                    $tmpdir = New-Item -ItemType Directory -Path $destination
                }
                catch{
                    Write-Warning -Message ($Script:messages.FailedToCreateDirectory -f $destination);
                    Write-Verbose $_
                    $tmpdir = $null
                }
            }
            else{
                Write-Warning -Message ($Script:messages.DirectoryAlreadyExists -f $destination);
                $tmpdir = $destination
            }
        }
    }
    End{
        return $tmpdir
    }
}
