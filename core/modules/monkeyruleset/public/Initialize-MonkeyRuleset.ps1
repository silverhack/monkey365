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

Function Initialize-MonkeyRuleset{
    <#
        .SYNOPSIS
		Initialize ruleset

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyRuleset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [parameter(Mandatory=$True, ParameterSetName = 'RuleSet', HelpMessage="Ruleset File")]
        [String]$Ruleset,

        [parameter(Mandatory=$True, ParameterSetName = 'RuleSetObject', HelpMessage="Ruleset Object File")]
        [Object]$RulesetObject,

        [parameter(Mandatory=$False, HelpMessage="Rules Path")]
        [String]$RulesPath
    )
    Begin{
        #Remove vars
        Remove-InternalVar
        $Verbose = $Debug = $False;
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
        #Get rules path
        If(!$PSBoundParameters.ContainsKey('RulesPath') -and $PSBoundParameters.ContainsKey('Ruleset')){
            try{
                $initPath = [System.IO.DirectoryInfo]::new($Ruleset);
                if($initPath){
                    $initPath = $initPath.Parent.Parent
                    $initPath.FullName.ToString() | Set-InternalVar
                }
            }
            catch{
                Write-Verbose ($Script:messages.UnableToLoad -f "init path", $_.Exception.Message)
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'RuleSetObject' -and ($PSBoundParameters.ContainsKey('RulesPath') -and $PSBoundParameters['RulesPath'])){
            $RulesPath |Set-InternalVar
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'Ruleset' -and ($PSBoundParameters.ContainsKey('RulesPath') -and $PSBoundParameters['RulesPath'])){
            $RulesPath |Set-InternalVar
        }
        Else{
            Write-Warning ($Script:messages.NotEnoughInformation -f "rules")
        }
        #Get Rules
        $newPsboundParams = [ordered]@{}
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Import-MonkeyRuleset")
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters.Item($p))
                }
            }
            #Add verbose, informationaction,etc..
            [void]$newPsboundParams.Add('InformationAction',$InformationAction);
            [void]$newPsboundParams.Add('Verbose',$Verbose);
            [void]$newPsboundParams.Add('Debug',$Debug);
        }
        #Import ruleset
        Import-MonkeyRuleset @newPsboundParams
    }
    End{
        if($null -eq (Get-Variable -Name SecBaseline -ErrorAction Ignore) -or $null -eq (Get-Variable -Name FindingsPath -ErrorAction Ignore) -or $null -eq (Get-Variable -Name ConditionsPath -ErrorAction Ignore) -or $null -eq (Get-Variable -Name RulesetsPath -ErrorAction Ignore)){
            Write-Warning -Message $Script:messages.UnableToInitializeRuleset
            return $False
        }
        else{
            $all_rules = Get-RulesFromRuleSet
            if($all_rules){
                New-Variable -Name AllRules -Value $all_rules -Scope Script -Force
                return $True
            }
        }
    }
}

