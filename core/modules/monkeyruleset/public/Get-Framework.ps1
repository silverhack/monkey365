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

Function Get-Framework{
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
            File Name	: Get-Framework
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory= $true, ParameterSetName='RuleSet', HelpMessage= "json file with all rules")]
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

        [parameter(Mandatory=$true, ParameterSetName='RulesPath', HelpMessage="Path to rules")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The directory does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Container) ){
                throw "The RulesPath argument must be a directory. Files are not allowed."
            }
            return $true
        })]
        [System.IO.DirectoryInfo]$RulesPath
    )
    try{
        #Set colors
        $colors = [ordered]@{
            info = 36;
            low = 34;
            medium = 33;
            high = 31;
            critical = 35;
            good = 32;
        }
        $e = [char]27;
        #$Tab = [char]9;
        $color = $colors.Item('good')
        if($PSCmdlet.ParameterSetName -eq 'RulesPath'){
            if($RulesPath.GetDirectories('rulesets').Count -gt 0){
                $rulesetPath = $RulesPath.GetDirectories('rulesets')
                $allRulesets = Get-File -Filter "*json" -Rulepath $rulesetPath.FullName.ToString()
                $allRulesets = $allRulesets | Select-Object * -Unique
                #Get file info
                $MyFrameworks = @($allRulesets).ForEach({$f = (Get-Content $_.FullName -Raw) | ConvertFrom-Json; if ($f | Test-isValidRuleSet){$f}})
                if($MyFrameworks.Count -gt 0){
                    if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                        $message = ("There are $e[${color}m$($MyFrameworks.Count)${e}[0m available frameworks")
                    }
                    else{
                        $message = ('There are {0} available frameworks' -f $MyFrameworks.Count)
                    }
                    Write-Output $message
                    $color = $colors.Item('medium')
                    $allFrameworks = @()
                    foreach($rs in @($MyFrameworks)){
                        try{
                            $fname = $rs.framework | Select-Object -ExpandProperty Name -ErrorAction Ignore
                            $fversion = $rs.framework | Select-Object -ExpandProperty version -ErrorAction Ignore
                            $rulesCount = $rs.rules.Psobject.Properties.Name.Count
                            #Check if extends
                            if($null -ne $rs.Psobject.Properties.Item('extends') -and $rs.extends){
                                foreach($ele in @($rs.extends)){
                                    $f = ("{0}/{1}" -f $rulesetPath.FullName.ToString(),$ele)
                                    if([System.IO.File]::Exists($f)){
                                        $newRule = Get-Content $f -Raw | ConvertFrom-Json -ErrorAction Ignore
                                        if($newRule){
                                            $rulesCount+=$newRule.rules.Psobject.Properties.Name.Count
                                        }
                                    }
                                    else{
                                        Write-Warning ("{0} was not found" -f $f)
                                    }
                                }
                            }
                            if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                                $framework = ("{0} {1}" -f $fname,$fversion)
                                $frameworkname = ("$e[${color}m$($framework)${e}[0m")
                            }
                            else{
                                $frameworkname = ("{0} {1}" -f $fname,$fversion)
                            }
                            $obj = [PsCustomObject]@{
                                displayName = $frameworkname;
                                Rules = $rulesCount;
                            }
                            $allFrameworks+=$obj
                        }
                        catch{
                            Write-Error $_
                        }
                    }
                    $allFrameworks
                }
            }
        }
        Else{
            $myRuleSet = $null;
            if($PSCmdlet.ParameterSetName -eq 'RuleSet'){
                $myRuleSet = Get-MonkeyRuleSet -Ruleset $PSBoundParameters['RuleSet']
            }
            Else{
                If($null -ne (Get-Variable -Name SecBaseline -ErrorAction Ignore)){
                    $myRuleSet = $Script:SecBaseline
                }
            }
            if($null -ne $myRuleSet){
                try{
                    $fname = $myRuleSet.framework | Select-Object -ExpandProperty Name -ErrorAction Ignore
                    $fversion = $myRuleSet.framework | Select-Object -ExpandProperty version -ErrorAction Ignore
                    ("{0} {1}" -f $fname,$fversion)
                }
                catch{
                    Write-Error $_
                }
            }
        }
    }
    catch{
        Write-Verbose $_.Exception.Message
    }
}

