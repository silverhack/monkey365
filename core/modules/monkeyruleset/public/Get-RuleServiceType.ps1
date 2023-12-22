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

Function Get-RuleServiceType{
    <#
        .SYNOPSIS
		Get rule's service type

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-RuleServiceType
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "json file with all rules")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The ruleset does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Leaf) ){
                throw "The ruleSet argument must be a json file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.json)"){
                throw "The file specified in the ruleset argument must be of type json"
            }
            return $true
        })]
        [System.IO.FileInfo]$RuleSet,

        [parameter(Mandatory=$false,HelpMessage="Path to rules")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The directory does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Container) ){
                throw "The RulesPath argument must be a directory. Files are not allowed."
            }
            return $true
        })]
        [System.IO.DirectoryInfo]$RulesPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Azure','Microsoft365')]
        $Instance,

        [Parameter(Mandatory=$false, HelpMessage="Include Azure AD")]
        [Switch]
        $IncludeEntraID,

        [parameter(Mandatory=$false,HelpMessage="Pretty table")]
        [Switch]$Pretty
    )
    Begin{
        #Remove vars
        Remove-InternalVar
        $MyRules = $null;
        $colors = [ordered]@{
            info = 36;
            low = 34;
            medium = 33;
            high = 31;
            critical = 35;
            good = 32;
        }
        $e = [char]27
        #Get window size
        if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
            $windowSize = $Host.UI.RawUI.WindowSize.Width
        }
        else{
            $windowSize = [int32]::MaxValue
        }
        $Verbose = $False;
        $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
    }
    Process{
        $newPsboundParams = [ordered]@{}
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-Rule")
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p) -and $p -ne 'Pretty'){
                    $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
                }
            }
            #Add InformationAction, verbose, etc
            [void]$newPsboundParams.Add('InformationAction',$InformationAction);
            [void]$newPsboundParams.Add('Verbose',$Verbose);
            [void]$newPsboundParams.Add('Debug',$Debug);
            #Get all rules
            $all_rules = Get-Rule @newPsboundParams
        }
    }
    End{
        $ResourceName = @{label="Service";expression={$_.Name}};
        $Count = @{label="Rules";expression={$_.Count}}
        $all_resources = $all_rules | Group-Object -Property serviceType | Sort-Object -Descending Count | Select-Object $ResourceName,$Count
        #Check if pretty
        if($PSBoundParameters.ContainsKey('Pretty') -and $PSBoundParameters['Pretty'].IsPresent){
            if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                $green = $colors.Item('good')
                $yellow = $colors.Item('medium')
                foreach($r in $all_resources){
                    $r.Service = "$e[${green}m$($r.Service)${e}[0m"
                    $r.Rules = "$e[${yellow}m$($r.Rules)${e}[0m"
                }
            }
            Write-Output $all_resources
            if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                $message = ("There are $e[${yellow}m$(@($all_resources).Count)${e}[0m available services")
            }
            else{
                $message = ('There are {0} available services' -f @($all_resources).Count)
            }
            Write-Output $message
        }
        else{
            Write-Output $all_resources
            Write-Output ('There are {0} available services' -f @($all_resources).Count)
        }
    }
}
