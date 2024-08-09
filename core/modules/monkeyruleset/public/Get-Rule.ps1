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

Function Get-Rule{
    <#
        .SYNOPSIS
		Get rule

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Rule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
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

        [parameter(Mandatory=$false,HelpMessage="Full object")]
        [Switch]$Full,

        [parameter(Mandatory=$false,HelpMessage="Pretty table")]
        [Switch]$Pretty
    )
    Begin{
        $MyRules = $mrules = $null;
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
        #Get Command metadata
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Initialize-MonkeyRuleset")
        $newPsboundParams = [ordered]@{}
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p]){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        #Add verbose, debug
        $newPsboundParams.Add('Verbose',$Verbose)
        $newPsboundParams.Add('Debug',$Debug)
        $newPsboundParams.Add('InformationAction',$InformationAction)
    }
    Process{
        If($newPsboundParams.Count -eq 5){
            #Remove vars
            Remove-InternalVar
            #Initialize Ruleset
            [void](Initialize-MonkeyRuleset @newPsboundParams)
        }
        try{
            If($PSBoundParameters.ContainsKey('RulesPath') -and $PSBoundParameters['RulesPath'] -and !$PSBoundParameters.ContainsKey('RuleSet')){
                if($RulesPath.GetDirectories('findings').Count -gt 0){
                    $findingsPath = $RulesPath.GetDirectories('findings')
                    $all_rules = Get-File -Filter "*json" -Rulepath $findingsPath.FullName.ToString()
                    $all_rules = $all_rules | Select-Object * -Unique
                    #Get rule info
                    $MyRules = $all_rules | Get-RuleFileContent #@($all_rules).ForEach({$r = (Get-Content $_.FullName -Raw) | ConvertFrom-Json; if ($r | Test-isValidRule){$r | Add-Member -Type NoteProperty -name File -value $_ -Force; $r}})
                }
                else{
                    Write-Warning ("Findings folder was not found on {0}" -f $RulesPath.FullName)
                }
            }
            ElseIf($null -ne (Get-Variable -Name AllRules -ErrorAction Ignore)){
                $MyRules = $Script:AllRules
            }
        }
        catch{
            Write-Verbose $_.Exception.Message
        }
    }
    End{
        try{
            if($null -ne $MyRules){
                if($PSBoundParameters.ContainsKey('Full') -and $PSBoundParameters['Full'].IsPresent){
                    $MyRules
                    return
                }
                elseif($PSBoundParameters.ContainsKey('RuleSet') -and $PSBoundParameters['RuleSet']){
                    $mrules = $MyRules | Select-Object displayName,serviceType,level,IdSuffix
                }
                else{
                    $mrules = @()
                    if($PSBoundParameters.ContainsKey('Instance') -and $PSBoundParameters['Instance']){
                        $mrules += @($MyRules).Where({$_.File.FullName -notlike "*EntraID*" -and $_.File.FullName -like ("*{0}*" -f $PSBoundParameters['Instance'])})
                    }
                    if($PSBoundParameters.ContainsKey('IncludeEntraID') -and $PSBoundParameters['IncludeEntraID'].IsPresent){
                        $mrules += @($MyRules).Where({$_.File.FullName -like "*EntraID*"})
                    }
                    if($mrules.Count -gt 0){
                        $mrules = $mrules | Select-Object displayName,serviceType,level,IdSuffix
                    }
                    else{
                        $mrules = $MyRules | Select-Object displayName,serviceType,level,IdSuffix
                    }
                }
                #Check if pretty
                if($PSBoundParameters.ContainsKey('Pretty') -and $PSBoundParameters['Pretty'].IsPresent){
                    $maxWidthName = $mrules | Select-Object -ExpandProperty displayName | Group-Object {$_.Length} | Select-Object -ExpandProperty Name | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
                    $maxWidthType = $mrules | Select-Object -ExpandProperty serviceType | Group-Object {$_.Length} | Select-Object -ExpandProperty Name | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
                    $Name = @{label="Rule Name";expression={$_.displayName};Width = [int]$maxWidthName-50};
                    $ResourceName = @{label="Service";expression={$_.serviceType};Width = [int]$maxWidthType};
                    $Level = @{label="Risk";expression={$_.level};Width = 12}
                    $IdSuffix = @{label="Id";expression={$_.idSuffix}}
                    if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                        foreach($r in $mrules){
                            if($null -ne $r.level){
                                $color = $colors.Item($r.level)
                                if($color){
                                    $r.level = "$e[${color}m$($r.level)${e}[0m"
                                }
                                else{
                                    $color = 48
                                    $r.level = "$e[${color}m$($r.level)${e}[0m"
                                }
                            }
                            $green = 32
                            $r.serviceType = "$e[${green}m$($r.serviceType)${e}[0m"
                        }
                    }
                    if($windowSize -gt 160){
                        $mrules | Select-Object * | Sort-Object -Property serviceType | Format-Table $Name,$ResourceName,$Level,$IdSuffix
                    }
                    else{
                        $mrules | Select-Object * | Sort-Object -Property serviceType | Format-List
                    }
                    if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                        $message = ("There are $e[${color}m$(@($mrules).Count)${e}[0m available rules")
                    }
                    else{
                        $message = ('There are {0} available rules' -f $MyFrameworks.Count)
                    }
                    Write-Output $message
                }
                else{
                    $mrules | Select-Object displayName,serviceType,idSuffix
                }
            }
        }
        catch{
            Write-Verbose $_.Exception.Message
        }
    }
}
