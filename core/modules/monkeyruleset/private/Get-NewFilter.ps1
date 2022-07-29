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

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$element_to_check,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$verb,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$value
    )
    Process{
        $tmp_filter = $null;
        #Pass value and try to cast to a real reference
        $converted_value = Convert-Value -value $value;
        if([string]::IsNullOrEmpty($verb)){
            $tmp_filter = ('$_.{0}' -f $element_to_check)
        }
        elseif($converted_value -is [string]){
            $tmp_filter = ('$_.{0} -{1} "{2}"' -f $element_to_check, $verb, $converted_value)
        }
        elseif($converted_value -is [Boolean]){
            $tmp_filter = ('$_.{0} -{1} ${2}' -f $element_to_check, $verb, $converted_value)
        }
        elseif([string]::IsNullOrEmpty($converted_value)){
            $tmp_filter = ('$_.{0} -{1} $null' -f $element_to_check, $verb)
        }
        elseif($converted_value -is [System.Array]){
            #$tmp_filter = ('$_.{0} -{1} ("{2}")' -f $element_to_check, $verb,(@($converted_value) -join ','))
            $tmp_filter = ('$_.{0} -{1} ({2})' -f $element_to_check, $verb,('"' + ($converted_value -join -join '","')+ '"'))
        }
        else{
            $tmp_filter = ('$_.{0} -{1} {2}' -f $element_to_check, $verb, $converted_value)
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
