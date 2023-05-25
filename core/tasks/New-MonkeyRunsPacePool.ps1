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

Function New-MonkeyRunsPacePool {
    <#
        .SYNOPSIS
		Create a new runspacePool

        .DESCRIPTION
		Create a new runspacePool

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyRunsPacePool
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.RunspacePool])]
	Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","AzureAD","Microsoft365")]
        [String]$Provider = "Azure",

        [Parameter(Mandatory=$false, HelpMessage="Change the threads settings. Default is 2")]
        [int32]$Throttle = 2,

        [Parameter(Mandatory=$false, HelpMessage="Plugins to load")]
        [Object]$Plugins
    )
    Begin{
        $vars = $ast_plugins = $runspacepool = $null
        #Initialize vars
        if($null -ne (Get-Variable -Name O365Object -ErrorAction Ignore)){
            $vars = Get-MonkeyVar
        }
        <#
        #Get Plugins
        if(-NOT $PSBoundParameters.ContainsKey('Plugins')){
            if($null -ne $O365Object.Plugins -and $null -ne (Get-Command -Name "Get-AstFunction" -ErrorAction Ignore)){
                $pl = $O365Object.Plugins | Select-Object -ExpandProperty File;
                $localparams = @{
                    objects = $pl;
                    recursive = $false;
                }
                $ast_plugins = Get-AstFunction @localparams
            }
        }
        else{
            if($null -ne (Get-Command -Name "Get-AstFunction" -ErrorAction Ignore)){
                $localparams = @{
                    objects = $Plugins;
                    recursive = $false;
                }
                $ast_plugins = Get-AstFunction @localparams
            }
        }
        #>
    }
    Process{
        switch ($Provider.ToLower()){
            { @("azure", "azuread") -contains $_ }{
                $StartUpScripts = $O365Object.runspace_init;
            }
            'microsoft365'{
                $StartUpScripts = $O365Object.exo_runspace_init;
            }
            'Default'{
                $StartUpScripts = $O365Object.runspace_init;
            }
        }
        if($null -ne $vars -and $null -ne $O365Object.libutils){
            try{
                $localparams = @{
                    ImportVariables = $vars;
                    ImportModules = $O365Object.runspaces_modules;
                    ImportCommands = $O365Object.libutils;
                    ApartmentState = "STA";
                    ThrowOnRunspaceOpenError = $true;
                    StartUpScripts = $StartUpScripts;
                    Throttle = $Throttle;
                }
                #Get runspace pool
                $runspacepool = New-RunspacePool @localparams
            }
            catch{
                $msg = @{
                    MessageData = ($message.RunspacePoolErrorMessage -f $_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('Monkey365RunspaceError');
                }
                Write-Warning @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.RunspacePoolError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365RunspaceError');
            }
            Write-Warning @msg
        }
    }
    End{
        if($null -ne $runspacepool){
            return $runspacepool
        }
    }
}