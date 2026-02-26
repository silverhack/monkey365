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

Function Get-NewFilter{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-NewFilter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True,HelpMessage="Element to check")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$LeftItem,

        [parameter(Mandatory=$True,HelpMessage="Operator")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Operator,

        [parameter(Mandatory=$True,HelpMessage="Right item")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$RightItem
    )
    Process{
        $tmp_filter = $nullLeft = $pipeline = $null;
        If([string]::IsNullOrEmpty($LeftItem)){
            $nullLeft = $True
        }
        If($LeftItem -eq '{$_}'){
            $pipeline = $True
        }
        $LeftCastValue = Convert-Value -Value $LeftItem;
        $RightCastValue = Convert-Value -Value $RightItem;
        If([string]::IsNullOrEmpty($Operator)){
            If($nullLeft){
                $tmp_filter = ('$null')
            }
            Elseif($pipeline){
                $tmp_filter = '$_'
            }
            Elseif($LeftCastValue -is [System.Collections.IEnumerable] -and $LeftCastValue -isnot [System.String]){
                $tmp_filter = ('@({0})' -f ('"' + ($LeftCastValue -join '","')+ '"'))
            }
            ElseIf($LeftCastValue -is [System.String] -and $LeftCastValue.Contains('@')){
                $tmp_filter = ("$_.'{0}'" -f $LeftItem)
            }
            Else{
                $tmp_filter = ('$_.{0}' -f $LeftItem)
            }
        }
        Elseif($LeftCastValue -is [System.Collections.IEnumerable] -and $LeftCastValue -isnot [System.String]){
            If($RightCastValue -is [System.String]){
                $leftCondition = Get-CastValue -InputObject $LeftCastValue
                $tmp_filter = ('{0} -{1} $_.{2}' -f $leftCondition, $Operator, $RightCastValue)
            }
            Else{
                $leftCondition = Get-CastValue -InputObject $LeftItem
                $rightCondition = Get-CastValue -InputObject $RightItem
                $tmp_filter = ('{0} -{1} {2}' -f $leftCondition, $Operator, $rightCondition)
            }
        }
        ElseIf([string]::IsNullOrEmpty($RightCastValue)){
            If($nullLeft){
                $tmp_filter = ('$null -{0} $null' -f $Operator)
            }
            ElseIf($pipeline){
                $tmp_filter = ('$_ -{0} $null' -f $Operator)
            }
            Else{
                $tmp_filter = ('$null -{0} $_.{1}' -f $Operator, $LeftItem)
            }
        }
        ElseIf($RightCastValue -is [string]){
            $rightCondition = Get-CastValue -InputObject $RightCastValue
            If($nullLeft){
                $tmp_filter = ('$null -{0} $_.{1}' -f $Operator, $RightCastValue)
            }
            ElseIf($pipeline){
                $tmp_filter = ('$_ -{0} $_.{1}' -f $Operator, $RightCastValue)
            }
            ElseIf($LeftItem.Contains('@odata.type')){
                #First remove odata.type
                $leftQuery = $LeftItem -replace ".@odata.type",""
                If($leftQuery.Contains('.')){
                    $_leftItem = [System.Text.StringBuilder]::new()
                    ForEach($part in $leftQuery.Split('.')){
                        [void]$_leftItem.Append($part);
                        [void]$_leftItem.Append('.')
                    }
                    $tmp_filter = ('$_.{0}"{1}" -{2} {3}' -f $_leftItem.ToString(),'@odata.type', $Operator, $rightCondition)
                }
                Else{
                    $tmp_filter = ('$_.{0}."{1}" -{2} {3}' -f $leftQuery,'@odata.type', $Operator, $rightCondition)
                }
            }
            ElseIf($Operator.ToLower() -eq 'in' -or $Operator.ToLower() -eq 'notin'){
                $tmp_filter = ('"{0}" -{1} $_.{2}' -f $LeftItem, $Operator, $RightCastValue)
            }
            Else{
                $tmp_filter = ('$_.{0} -{1} {2}' -f $LeftItem, $Operator, $rightCondition)
            }
        }
        ElseIf($RightCastValue -is [Boolean]){
            If($nullLeft){
                $tmp_filter = ('$null -{0} ${1}' -f $Operator, $RightCastValue)
            }
            ElseIf($pipeline){
                $tmp_filter = ('$_ -{0} ${1}' -f $Operator, $RightCastValue)
            }
            ElseIf($LeftItem.Contains('@')){
                $tmp_filter = ('$_."{0}" -{1} {2}' -f $LeftItem, $Operator, $RightCastValue)
            }
            Else{
                $tmp_filter = ('$_.{0} -{1} ${2}' -f $LeftItem, $Operator, $RightCastValue)
            }
        }
        ElseIf($RightCastValue -is [System.Collections.IEnumerable] -and $RightCastValue -isnot [System.String]){
            $rightCondition = Get-CastValue -InputObject $RightItem
            If($nullLeft){
                $tmp_filter = ('$null -{0} {1}' -f $Operator,$rightCondition)
            }
            ElseIf($pipeline){
                $tmp_filter = ('$_ -{0} {1}' -f $Operator,$rightCondition)
            }
            Else{
                $tmp_filter = ('$_.{0} -{1} {2}' -f $LeftItem, $Operator,$rightCondition)
            }
        }
        Else{
            If($nullLeft){
                $tmp_filter = ('$null -{0} $_.{1}' -f $Operator, $RightCastValue)
            }
            ElseIf($pipeline){
                $tmp_filter = ('$_ -{0} $_.{1}' -f $Operator, $RightCastValue)
            }
            ElseIf($LeftItem.Contains('@')){
                $tmp_filter = ('$_."{0}" -{1} {2}' -f $LeftItem, $Operator, $RightCastValue)
            }
            Else{
                $tmp_filter = ('$_.{0} -{1} {2}' -f $LeftItem, $Operator, $RightCastValue)
            }
        }
        If($tmp_filter){
            return $tmp_filter
        }
        Else{
            Write-Warning -Message ("The filter is not valid")
            return $null;
        }
    }
}

