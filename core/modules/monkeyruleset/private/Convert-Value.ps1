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

Function Convert-Value{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-Value
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Object to evaluate")]
        [AllowNull()]
        [AllowEmptyString()]
        [Object]$Value
    )
    Begin{
        #Refs
        $out = $null
        [int]$int_min_value = [int32]::MinValue;
        [double]$double_min_value  = [double]::MinValue;
        [int64]$integer64_minimum = [int64]::MinValue;
        [datetime]$datetime_min_value  = [datetime]::MinValue
        [String[]]$formats = "MM/dd/yyyy", "dd/MM/yyyy h:mm:ss", "MM/dd/yyyy hh:mm tt", "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
    }
    Process{
        #End refs
        [bool]$integer = [int]::TryParse($Value, [ref]$int_min_value);
        [bool]$integer64 = [int64]::TryParse($Value, [ref]$integer64_minimum);
        [bool]$double = [Double]::TryParse($Value,[ref]$double_min_value);
        [bool]$isdatetime = [datetime]::TryParseExact($Value, $formats,[System.Globalization.CultureInfo]::InvariantCulture,[System.Globalization.DateTimeStyles]::None, [ref]$datetime_min_value);
        #Evaluate value
        If([bool]::TryParse($Value, [ref]$out)){
            return [System.Convert]::ToBoolean($Value);
        }
        elseif($integer -eq $True){
            return [System.Convert]::ToInt32($Value);
        }
        elseif($double -eq $True){
            return [System.Convert]::ToDouble($Value);
        }
        elseif($integer64 -eq $True){
            return [System.Convert]::ToInt64($Value);
        }
        elseif($isdatetime -eq $True){
            [System.Convert]::ToDateTime($Value);
        }
        elseif($null -ne $Value -and [string]::IsNullOrWhiteSpace($Value)){
            return $Value.ToString()
        }
        elseif([string]::IsNullOrEmpty($Value)){
            return $null
        }
        elseif($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]){
            Write-Output $Value -NoEnumerate
        }
        else{
            return [System.Convert]::ToString($Value);
        }
    }
    End{
        #nothing to do here
    }
}


