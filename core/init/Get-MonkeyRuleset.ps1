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

Function Get-MonkeyRuleset{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRuleset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    Begin{
        $ruleSet = $rulesPath = $null;
        if($O365Object.Instance -or $O365Object.IncludeAAD -eq $true){
            if($null -ne $O365Object.initParams.ruleset){
                $ruleSet = $O365Object.initParams.ruleset
            }
            else{
                if($null -ne $O365Object.Instance -and $O365Object.Instance.ToLower() -eq "azure"){
                    $ruleSet = $O365Object.internal_config.ruleSettings.azureDefaultRuleset
                }
                elseif($null -ne $O365Object.Instance -and $O365Object.Instance.ToLower() -eq "microsoft365"){
                    $ruleSet = $O365Object.internal_config.ruleSettings.m365DefaultRuleset
                }
                else{
                    #Probably Azure AD
                    $ruleSet = $O365Object.internal_config.ruleSettings.m365DefaultRuleset
                }
            }
        }
    }
    Process{
        if($null -ne $ruleSet){
            $isRoot = [System.IO.Path]::IsPathRooted($ruleSet)
            if(-NOT $isRoot){
                $rulesPath = ("{0}/{1}" -f $O365Object.Localpath, $ruleSet)
            }
            else{
                $rulesPath = $ruleSet
            }
            if (!(Test-Path -Path $rulesPath)){
                Write-Warning ("{0} does not exists" -f $rulesPath)
                return
            }
        }
    }
    End{
        if($null -ne $rulesPath){
            return (Get-ChildItem $rulesPath)
        }
    }
}
