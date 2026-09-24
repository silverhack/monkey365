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

Function New-InitialSessionState{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-InitialSessionState
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.InitialSessionState])]
    Param
    (
        [Parameter(HelpMessage="variables to import into sessionState")]
        [Object]$ImportVariables,

        [Parameter(HelpMessage="modules to import into sessionState")]
        [Object]$ImportModules,

        [Parameter(HelpMessage="Functions to import from PS1 files into sessionState")]
        [Object]$ImportCommands,

        [Parameter(HelpMessage="Functions as StatementAst to import into sessionState")]
        [Object]$ImportCommandsAst,

        [Parameter(HelpMessage="Startup scripts (*ps1 files) to execute")]
        [System.Object[]]$StartUpScripts,

        [Parameter(HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "MTA",

        [Parameter(Mandatory=$False, HelpMessage='ThrowOnRunspaceOpenError')]
        [Switch]$ThrowOnRunspaceOpenError
    )
    Begin{
        try{
            $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        }
        catch{
            $sessionstate = $null
        }
    }
    Process{
        If($null -ne $sessionstate -and $sessionstate -is [System.Management.Automation.Runspaces.InitialSessionState]){
            If($ImportVariables){
                $all_scopes = [System.Management.Automation.ScopedItemOptions]::AllScope
                $allVars = [System.Collections.Generic.List[System.Management.Automation.Runspaces.SessionStateVariableEntry]]::new();
                $all_vars = [System.Collections.ArrayList]::new()
                #Set a Hashset collection of existing variables
                $existing = [System.Collections.Generic.HashSet[string]]([System.StringComparer]::OrdinalIgnoreCase)
                #Populate hashset
                @($sessionState.Variables.Name).ForEach({[void]$existing.Add($_)})
                If(([System.Collections.IDictionary]).IsAssignableFrom($ImportVariables.GetType())){
                    Foreach ($var in $ImportVariables.GetEnumerator()){
                        If($null -eq $var.Value){
                            Write-Verbose ($Script:messages.NullVariableMessage -f $var.Name)
                            continue
                        }
                        Else{
                            If($existing.Add($var.Name)){
                                $_newVar = New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $var.Name, $var.Value, $null
                                #Add var
                                $sessionState.Variables.Add($_newVar)
                            }
                        }
                    }
                }
                Else{
                    ForEach ($varname in $ImportVariables){
                        If ($MyInvocation.CommandOrigin -eq 'Runspace') {
                            $localVar = Get-Variable $varname -ErrorAction Ignore | Where-Object { $_.Options -notmatch 'Constant' }
                            If($null -ne $localVar){
                                [void]$all_vars.Add($localVar)
                            }
                        }
                        ElseIf($null -ne $PSCmdlet.SessionState.PSVariable.Get($varname)){
                            $localVar = $PSCmdlet.SessionState.PSVariable.Get($varname)
                            If($null -ne $localVar){
                                [void]$all_vars.Add($localVar)
                            }
                        }
                        Else{
                            $localVar = Get-Variable -Name $varname -ErrorAction Ignore
                            If($null -ne $localVar){
                                [void]$all_vars.Add($localVar)
                            }
                        }
                    }
                    If ($all_vars.Count -gt 0){
                        #Add vars into session state
                        ForEach ($var in $all_vars){
                            $varToImport = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($var.Name, `
                                                                                                                   $var.Value, `
                                                                                                                   $var.Description, `
                                                                                                                   $all_scopes)
                            #Add var
                            $sessionState.Variables.Add($varToImport)
                        }
                    }
                }
            }
            #Check if should import modules
            If($ImportModules){
                If(([System.Collections.IDictionary]).IsAssignableFrom($ImportModules.GetType())){
                    $ImportModules = $ImportModules.Values
                }
                ForEach($module in $ImportModules){
                    $moduleToImport = Resolve-Path -Path $module -ErrorAction Ignore
                    If($null -ne $moduleToImport){
                        Write-Verbose ($Script:messages.ImportingModuleMessage -f $module)
                        $moduleToImport = $moduleToImport.Path.TrimEnd('\')
                        If (Test-Path -Path $moduleToImport -PathType Container){
                            #folder containing one or more scripts/modules
                            [void]$sessionstate.ImportPSModulesFromPath($moduleToImport);
                        }
                        Else{
                            #script, binary file, etc..
                            [void]$sessionstate.ImportPSModule($moduleToImport);
                        }
                    }
                    Else{
                        #Check if file or module exists
                        If (Test-Path -Path $module){
                            Write-Verbose ($Script:messages.ImportingModuleMessage -f $module)
                            [void]$sessionstate.ImportPSModule($module);
                        }
                        Else{
                            Write-Warning ($Script:messages.ModuleNotExists -f $module)
                        }
                    }
                }
            }
            If($ImportCommands){
                $CommandsToImport = $ImportCommands | Find-FunctionFromFile -FindAll
                $allcommands = [System.Collections.Generic.List[System.Management.Automation.Runspaces.SessionStateFunctionEntry]]::new();
                $_commands = @($CommandsToImport).Where({$null -ne $_ -and $_ -is [System.Management.Automation.Language.FunctionDefinitionAst]});
                ForEach($_command in $_commands.GetEnumerator()){
                    Write-Verbose ($Script:messages.ImportingFunctionMessage -f $_command.Name)
                    $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $_command.Name, $_command.Body.GetScriptBlock()                    
                    [void]$allcommands.Add($SessionStateFunction);
                }
                # Add all entries
                ForEach($cmd in $allcommands.GetEnumerator()){
                    $sessionstate.Commands.Add($cmd)                    
                }
                <#
                ForEach($fnc in @($CommandsToImport).Where({$null -ne $_})){
                    If($fnc -is [System.Management.Automation.Language.FunctionDefinitionAst]){
                        Write-Verbose ($Script:messages.ImportingFunctionMessage -f $fnc.Name)
                        $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $fnc.Name, $fnc.Body.GetScriptBlock()
                        #Create a SessionStateFunction
                        $sessionstate.Commands.Add($SessionStateFunction)
                    }
                }
                #>
            }
            If($ImportCommandsAst){
                $allcommands = [System.Collections.Generic.List[System.Management.Automation.Runspaces.SessionStateFunctionEntry]]::new();
                $_commands = @($ImportCommandsAst).Where({$null -ne $_ -and $_ -is [System.Management.Automation.Language.StatementAst]});
                ForEach($_command in $_commands.GetEnumerator()){
                    Write-Verbose ($Script:messages.ImportingStatementAstMessage -f $_command.Name)
                    $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $_command.Name, $_command.Body.GetScriptBlock()                    
                    [void]$allcommands.Add($SessionStateFunction);
                }
                # Add all entries
                ForEach($cmd in $allcommands.GetEnumerator()){
                    $sessionstate.Commands.Add($cmd)                    
                }
                <#
                ForEach($fnc in @($ImportCommandsAst).Where({$null -ne $_})){
                    If($fnc -is [System.Management.Automation.Language.StatementAst]){
                        $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $fnc.Name, $fnc.Body.GetScriptBlock()
                        Write-Verbose ($Script:messages.ImportingStatementAstMessage -f $fnc.Name)
                        #Create a SessionStateFunction
                        $sessionstate.Commands.Add($SessionStateFunction)
                    }
                }
                #>
            }
            #Check if startup scripts
            If($StartUpScripts){
                ForEach($scp in $StartUpScripts){
                    If([System.IO.File]::Exists($scp)){
                        [void]$sessionstate.StartupScripts.Add($scp)
                    }
                    Else{
                        Write-Warning ($Script:messages.FileNotExists -f $scp)
                        continue
                    }
                }
            }
            #Check for ThrowOnRunspaceOpenError flag
            If($ThrowOnRunspaceOpenError){
                $sessionstate.ThrowOnRunspaceOpenError = $ThrowOnRunspaceOpenError
            }
            #Define ApartmentState
            $sessionstate.ApartmentState = [System.Threading.ApartmentState]::$ApartmentState
        }
    }
    End{
        return $sessionstate
    }
}
