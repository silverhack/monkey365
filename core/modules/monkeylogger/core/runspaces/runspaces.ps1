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

Function New-LoggerSessionState{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-LoggerSessionState
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.InitialSessionState])]
    Param
    (
        [Parameter(HelpMessage="Variables to import into sessionState")]
        [hashtable]
        $ImportVariables,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]
        $ApartmentState = "STA"
    )
    $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    if($ImportVariables){
        #Add vars into session state
        foreach ($var in $ImportVariables.GetEnumerator()){
            $sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $var.Name, `
                                                                                                                                             $var.Value, `
                                                                                                                                             $null, `
                                                                                                                                             ([System.Management.Automation.ScopedItemOptions]::AllScope)))
        }
    }
    #Define ApartmentState
    $sessionstate.ApartmentState = [System.Threading.ApartmentState]::$ApartmentState
    return $sessionstate
}
