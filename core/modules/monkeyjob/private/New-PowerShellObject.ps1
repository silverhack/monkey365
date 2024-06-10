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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PowerShell])]
    Param (
        [Parameter(Mandatory=$True,position=0, ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True,position=1,ParameterSetName='Command')]
        [String]$Command,

        [Parameter(Mandatory=$false,position=2, ValueFromPipeline=$true)]
        [Object]$InputObject,

        [Parameter(Mandatory=$False, position=3,HelpMessage="RunspacePool")]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,

        [Parameter(Mandatory=$false,position=4,HelpMessage="arguments")]
        [Object] $Arguments
    )
    Process{
        try{
            $Pipeline = [System.Management.Automation.PowerShell]::Create()
            if($RunspacePool){
                $Pipeline.RunspacePool = $RunspacePool
            }
            #Add scriptblock
            if($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
                [void]$Pipeline.AddScript($ScriptBlock,$True)
            }
            elseif($PSCmdlet.ParameterSetName -eq 'Command'){
                [void]$Pipeline.AddCommand($Command)
            }
            #Add inputobject if any
            if($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $PSBoundParameters['InputObject']){
                [void]$Pipeline.AddArgument($InputObject)
                #[void]$Pipeline.AddParameter("InputObject",$InputObject)
            }
            #Add arguments
            if($PSBoundParameters.ContainsKey('Arguments')){
                Foreach($argInput in $PSBoundParameters['Arguments']) {
                    If ($argInput -is [Object[]]) {
                        Foreach($arg_ in $argInput) {
                            [void]$Pipeline.AddArgument($arg_)
                        }
                    }
                    ElseIf(([System.Collections.IDictionary]).IsAssignableFrom($argInput.GetType())){
                        [void]$Pipeline.AddParameters($argInput)
                    }
                    Else {
                        [void]$Pipeline.AddArgument($argInput)
                    }
                }
            }
            New-Variable -Name Pipeline -Value $Pipeline -Scope Global -Force
            #return object
            return $Pipeline
        }
        catch{
            Write-Error $_
        }
    }
}