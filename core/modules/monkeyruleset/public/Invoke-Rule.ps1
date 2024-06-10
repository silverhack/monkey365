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

Function Invoke-Rule{
    <#
        .SYNOPSIS
        Scan a dataset with a rule

        .DESCRIPTION
        Scan a dataset with a rule

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-Rule
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False, ValueFromPipeline = $True, HelpMessage="Dataset")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="Rule Object")]
        [Object]$Rule,

        [parameter(Mandatory=$False, HelpMessage="Rules Path")]
        [String]$RulesPath,

        [Parameter(Mandatory=$false, HelpMessage="Set the output timestamp format as unix timestamps instead of iso format")]
        [Switch]$UnixTimestamp
    )
    Begin{
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
        if($PSBoundParameters.ContainsKey('InputObject') -and $PSBoundParameters['InputObject']){
            New-Dataset -InputObject $InputObject
        }
        If($PSBoundParameters.ContainsKey('RulesPath')){
            Set-InternalVar -RulesPath $PSBoundParameters['RulesPath']
        }
    }
    Process{
        if(($Rule | Test-isValidRule) -and $null -ne (Get-Variable -Name Dataset -ErrorAction Ignore)){
            #Set new obj
            $tmp_object = [ordered]@{}
            foreach($elem in $Rule.Psobject.Properties){
                [void]$tmp_object.Add($elem.Name,$elem.Value)
            }
            $ShadowRule = New-Object -TypeName PSCustomObject -Property $tmp_object
            $ShadowRule = Build-Query -InputObject $ShadowRule
            #Get element
            $ObjectsToCheck = Get-ElementsToCheck -Path $ShadowRule.path
            if($null -ne $ObjectsToCheck -and $null -ne $ShadowRule){
                if($null -ne $ObjectsToCheck.PsObject.Properties.Item('Data')){
                    $matched_elements = Invoke-UnitRule -InputObject $ShadowRule -ObjectsToCheck $ObjectsToCheck.Data
                }
                Else{
                    $matched_elements = Invoke-UnitRule -InputObject $ShadowRule -ObjectsToCheck $ObjectsToCheck
                }
            }
            else{
                Write-Warning ("{0} was not found on dataset or query was invalid" -f $ShadowRule.path)
                $matched_elements = $null
            }
            #Check for removeIfNotExists exception rule
            if($null -ne $ShadowRule -and [bool]$ShadowRule.PSObject.Properties['removeIfNotExists']){
                if($ShadowRule.removeIfNotExists.ToString().ToLower() -eq "true"){
                    if($null -eq $matched_elements){
                        continue
                    }
                }
            }
            if($null -ne $ShadowRule){
                #Create finding object
                $p =  @{
                    InputObject = $ShadowRule;
                    affectedObjects = $matched_elements;
                    Resources = $ObjectsToCheck;
                    UnixTimestamp = $PSBoundParameters['UnixTimestamp'];
                }
                $findingObj = New-MonkeyFindingObject @p
                if(!$matched_elements -and $null -ne $findingObj){
                    $findingObj.level = "Good"
                }
                #Add status code
                $findingObj.statusCode = $findingObj.level | Get-StatusCode
                Write-Output $findingObj
            }
        }
        Else{
            Write-Warning $Script:messages.InvalidObject
        }
    }
    End{
        #Nothing to do here
    }
}