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
        [String]$LeftItem,

        [parameter(Mandatory=$True,HelpMessage="Operator")]
        [String]$Operator,

        [parameter(Mandatory=$True,HelpMessage="Right item")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$RightItem
    )
    Process{
        $tmp_filter = $nullLeft = $pipeline = $null;
        if([string]::IsNullOrEmpty($LeftItem)){
            $nullLeft = $True
        }
        if($LeftItem -eq '{$_}'){
            $pipeline = $True
        }
        #Pass value and try to cast to a real reference
        $converted_value = Convert-Value -Value $RightItem;
        if([string]::IsNullOrEmpty($Operator)){
            if($nullLeft){
                $tmp_filter = ('$null')
            }
            Elseif($pipeline){
                $tmp_filter = '$_'
            }
            else{
                $tmp_filter = ('$_.{0}' -f $LeftItem)
            }
        }
        elseif([string]::IsNullOrEmpty($converted_value)){
            if($nullLeft){
                $tmp_filter = ('$null -{0} $null' -f $Operator)
            }
            Elseif($pipeline){
                $tmp_filter = ('$_ -{0} $null' -f $Operator)
            }
            else{
                $tmp_filter = ('$null -{0} $_.{1}' -f $Operator, $LeftItem)
            }
        }
        elseif($converted_value -is [string]){
            if($nullLeft){
                $tmp_filter = ('$null -{0} ''{1}''' -f $Operator, [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value))
            }
            Elseif($pipeline){
                $tmp_filter = ('$_ -{0} ''{1}''' -f $Operator, [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value))
            }
            else{
                $tmp_filter = ('$_.{0} -{1} ''{2}''' -f $LeftItem, $Operator, [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value))
            }
        }
        elseif($converted_value -is [Boolean]){
            if($nullLeft){
                $tmp_filter = ('$null -{0} ${1}' -f $Operator, $converted_value)
            }
            Elseif($pipeline){
                $tmp_filter = ('$_ -{0} ${1}' -f $Operator, $converted_value)
            }
            else{
                $tmp_filter = ('$_.{0} -{1} ${2}' -f $LeftItem, $Operator, $converted_value)
            }
        }
        elseif($converted_value -is [System.Array]){
            if($nullLeft){
                $tmp_filter = ('$null -{0} ({1})' -f $Operator,('"' + ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value) -join -join '","')+ '"'))
            }
            Elseif($pipeline){
                $tmp_filter = ('$_ -{0} ({1})' -f $Operator,('"' + ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value) -join -join '","')+ '"'))
            }
            else{
                $tmp_filter = ('$_.{0} -{1} ({2})' -f $LeftItem, $Operator,('"' + ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($converted_value) -join -join '","')+ '"'))
            }
        }
        else{
            if($nullLeft){
                $tmp_filter = ('$null -{0} {1}' -f $Operator, $converted_value)
            }
            Elseif($pipeline){
                $tmp_filter = ('$_ -{0} {1}' -f $Operator, $converted_value)
            }
            else{
                $tmp_filter = ('$_.{0} -{1} {2}' -f $LeftItem, $Operator, $converted_value)
            }
        }
        if($tmp_filter){
            return $tmp_filter
        }
        else{
            Write-Warning -Message ("The filter is not valid")
            return $null;
        }
    }
}

