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

Function Format-Command{
    <#
        .SYNOPSIS

        Format command

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-Command
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, HelpMessage="Command")]
        [String]$Command,

        [Parameter(Mandatory=$false, HelpMessage="arguments")]
        [Object]$Arguments,

        [Parameter(Mandatory=$false)]
        $InputObject
    )
    try{
        $cmd = ("{0}" -f $Command);
        if($PSBoundParameters.ContainsKey('InputObject')){
            $cmd = ("{0} {1}" -f $cmd,$InputObject);
        }
        if($PSBoundParameters.ContainsKey('Arguments')){
            Foreach($arg in $PSBoundParameters['Arguments']) {
                If ($arg -is [Object[]]) {
                    Foreach($arg_ in $arg) {
                        $cmd = ("{0} {1}" -f $cmd,$arg_);
                    }
                }
                elseif($arg -is [System.Collections.Specialized.OrderedDictionary] -or $arg -is [System.Collections.Hashtable]){
                    $arg.GetEnumerator() | ForEach-Object {
                        $cmd = ("{0} -{1} {2}" -f $cmd,$_.Name,$_.Value);
                    }
                }
                Else {
                    $cmd = ("{0} {1}" -f $cmd,$arg);
                }
            }
        }
        return $cmd
    }
    catch{
        Write-Error $_
        return $null
    }

}
