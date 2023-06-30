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

Function Initialize-MonkeyParameter{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyParameter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="PsBoundParameters")]
        [object]$MyParams
    )
    Begin{
        #Init params
        $init_params = @(
            'auditorName','threads','PromptBehavior',
            'Environment','Instance', 'ruleset','ExportTo',
            'Analysis','WriteLog','TenantId','ClientId',
            'IncludeAzureAD','ImportJob',
            'SaveProject','ResolveTenantDomainName',
            'ResolveTenantUserName','ExcludePlugin',
            'ExcludedResources'
        )
        #Set init params
        foreach ($param in $init_params){
            if ($false -eq $MyParams.ContainsKey($param)){
                $MyParams.($param) = $null
            }
        }
        #Set Output Dir
        if($false -eq $MyParams.ContainsKey('OutDir')){
            $MyParams.OutDir = ("{0}/monkey-reports" -f $ScriptPath)
        }
        #Set Environment
        if($null -eq $MyParams.Environment){
            $MyParams.Environment = $Environment
        }
        #Set Prompt
        if($null -eq $MyParams.PromptBehavior){
            $MyParams.PromptBehavior = 'Auto'
        }
        #Add threads to params if not exists
        if($null -eq $MyParams.Threads){
            $MyParams.threads = 2
        }
        #Add auditorName if not exists
        if($null -eq $MyParams.auditorName){
            $MyParams.auditorName = $env:USERNAME
        }
        #TODO Set instance
        if($null -eq $MyParams.Instance -and $null -ne $MyParams.IncludeAzureAD){
            $MyParams.Instance = 'AzureAD'
        }
        #Set Verbose and Debug options
        if($false -eq $MyParams.ContainsKey('Verbose')){
            $MyParams.Verbose = $false
        }
        if($false -eq $MyParams.ContainsKey('Debug')){
            $MyParams.Debug = $false
        }
        #Set informationAction
        if($false -eq $MyParams.ContainsKey('InformationAction')){
            $MyParams.InformationAction = 'SilentlyContinue'
        }
    }
    Process{
        #Override params with environment vars if any
        #Check if username and password
        if ((Test-Path env:MONKEY_ENV_MONKEY_USER) -and (Test-Path env:MONKEY_ENV_MONKEY_PASSWORD)){
            try{
                [securestring]$pass = ConvertTo-SecureString $env:MONKEY_ENV_MONKEY_PASSWORD -AsPlainText -Force
                [pscredential]$InputObject = New-Object System.Management.Automation.PSCredential ($env:MONKEY_ENV_MONKEY_USER, $pass)
                $MyParams.UserCredentials = $InputObject
            }
            catch{
                Write-Error $_
            }
        }
        #Check if TenantID
        if (Test-Path env:MONKEY_ENV_TENANT_ID){
            $MyParams.TenantID = $env:MONKEY_ENV_TENANT_ID
        }
        #Check if AuthMode
        if (Test-Path env:MONKEY_ENV_AUTH_MODE){
            $MyParams.AuthMode = $env:MONKEY_ENV_AUTH_MODE
        }
        #Check if subscriptions
        if (Test-Path env:MONKEY_ENV_SUBSCRIPTIONS){
            $MyParams.subscriptions = $env:MONKEY_ENV_SUBSCRIPTIONS
        }
        #Check if analysis
        if (Test-Path env:MONKEY_ENV_ANALYSIS){
            $analysis = @()
            foreach($element in $env:MONKEY_ENV_ANALYSIS.Split(',')){
                $analysis+=$element
            }
            if('all' -in $analysis){
                [void]$analysis.Clear();
                $analysis+='all'
            }
            if($analysis.Count -gt 0){
                #Remove duplicate before adding data to analysis var
                $MyParams.Analysis = $analysis | Sort-Object -Property @{Expression={$_.Trim()}} -Unique
            }
        }
        #Check if exportTo
        if (Test-Path env:MONKEY_ENV_EXPORT_TO){
            $exportTo = @()
            foreach($element in $env:MONKEY_ENV_EXPORT_TO.Split(',')){
                $exportTo+=$element
            }
            if($exportTo.Count -gt 0){
                #Remove duplicate before adding data to exportTo var
                $MyParams.exportTo = $exportTo | Sort-Object -Property @{Expression={$_.Trim()}} -Unique
            }
        }
        #Check if writelog
        if (Test-Path env:MONKEY_ENV_WRITELOG){
            try{
                $MyParams.WriteLog = [System.Convert]::ToBoolean($env:MONKEY_ENV_WRITELOG)
            }
            catch{
                $MyParams.WriteLog = $false
            }
        }
        #Check if Verbose
        if (Test-Path env:MONKEY_ENV_VERBOSE){
            try{
                $MyParams.Verbose = [System.Convert]::ToBoolean($env:MONKEY_ENV_VERBOSE)
            }
            catch{
                $MyParams.Verbose = $false
            }
        }
        #Check if Debug
        if (Test-Path env:MONKEY_ENV_DEBUG){
            try{
                $MyParams.Debug = [System.Convert]::ToBoolean($env:MONKEY_ENV_DEBUG)
            }
            catch{
                $MyParams.Debug = $false
            }
        }
    }
    End{
        return $MyParams
    }
}
