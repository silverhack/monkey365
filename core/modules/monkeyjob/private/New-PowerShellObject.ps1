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

Function New-PowerShellObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-PowerShellObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding(SupportsShouldProcess = $True,DefaultParameterSetName='Job',ConfirmImpact="Medium")]
    [OutputType([System.Management.Automation.PowerShell])]
    Param (
            [Parameter(Mandatory=$True,position=0,ParameterSetName='Job')]
            [Object]$Job,

            [Parameter(Mandatory=$False)]
            [System.Management.Automation.Runspaces.RunspacePool]$runspacepool
    )
    Process{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        if ($PSCmdlet.ShouldProcess("ShouldProcess?")){
            Try{
                $params = Get-ParamsUsed -Job $Job
                if($null -ne $params){
                    $Powershell = [powershell]::Create()
                    #Import script or command
                    if($null -ne $Job.scriptToImport){
                        [void]$Powershell.AddScript($Job.scriptToImport)
                    }
                    else{
                        [void]$Powershell.AddCommand($Job.command)
                    }
                    #Import params if any
                    foreach($item in $params.GetEnumerator()){
		                [void]$Powershell.AddParameter($item.Key,$item.value)
                    }
                    #Check if runspacepool
		            if($runspacepool){
                        $PowerShell.RunspacePool = $runspacepool
                    }
                    #Return powershell object
                    return $Powershell
                }
                else{
                    return $null
                }
            }
            Catch{
                Write-Error $_
                return $null
            }
        }
    }
}
