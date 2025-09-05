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

Function Get-ScriptBlockParam{
    <#
        .SYNOPSIS
        Get parameters from ScriptBlock

        .DESCRIPTION
        Get parameters from ScriptBlock

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ScriptBlockParam
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$true, HelpMessage = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    Begin{
        #Set array list
        $sbParams = [System.Collections.ArrayList]::new()
        $values = [System.Collections.ArrayList]::new()
        #Set dict
        $rawParameters = [ordered]@{}
        $parameters = @{}
    }
    Process{
        Try{
            #Get tokenized object and removes newline command and comments
            $tokenizedObject = @(Get-TokenizedObject @PSBoundParameters).Where({$_.Type -ne 'NewLine' -and  $_.Type -ne 'Comment' -and $_.Type -ne 'Command'})
            #Get all command parameters
            $commandParameters = @($tokenizedObject).Where({$_.Type -eq "CommandParameter"}) | Select-Object -ExpandProperty Content -ErrorAction Ignore
            #Add all params from ScriptBlock to array
            If(@($tokenizedObject).Count -gt 0){
                $_values = $tokenizedObject | Select-Object -ExpandProperty Content -ErrorAction Ignore
                ForEach($_val in $_values){[void]$sbParams.Add($_val)}
                #Iterate over all params
                ForEach($_param in $commandParameters){
                    #Get Index
                    $index = $sbParams.IndexOf($_param);
                    For($i=$index+1;$i -lt $tokenizedObject.Count;$i++){
                        IF($tokenizedObject[$i].Type -eq 'CommandParameter'){break}
                        IF($tokenizedObject[$i].Type -eq "Number"){
                            [void]$values.Add([Int]$tokenizedObject[$i].Content.Trim())
                        }
                        ElseIf($tokenizedObject[$i].Type -eq "Variable"){
                            #Check If Bool
                            If([bool]::TryParse($tokenizedObject[$i].Content,[ref]$null)){
                                $out = $null;
                                [void][bool]::TryParse($tokenizedObject[$i].Content, [ref]$out);
                                [void]$values.Add($out)
                            }
                            Else{
                                [void]$values.Add(('${0}' -f $tokenizedObject[$i].Content))
                            }
                        }
                        Else{
                            [void]$values.Add($tokenizedObject[$i].Content.Trim())
                        }
                    }
                    [void]$rawParameters.Add($_param.Replace('-','').Replace(':',''),$values.ToArray())
                    [void]$values.Clear()
                }
                #Get real param
                ForEach ($p in $rawParameters.GetEnumerator()){
                    $val = $p.Value;
                    IF($val.Count -eq 1){
                        [void]$parameters.Add($p.Name,$val[0])
                    }
                    ElseIf($val -match "@\("){
                        $newArray = [System.Collections.ArrayList]::new()
                        ForEach($elem in $val){
                            If($elem -notmatch "@\(" -and $elem -notmatch "," -and $elem -notmatch "\)"){
                                [void]$newArray.Add($elem);
                            }
                        }
                        [void]$parameters.Add($p.Name,$newArray)
                    }
                    ElseIf($val -match "@\{"){
                        $newDict = @{}
                        $dictString = $val -join ""
                        $dictString = $dictString.Replace('@{','').Replace('}','').Split(';');
                        ForEach($element in @($dictString)){
                            $keyVal = $element.Split('=');
                            If($keyVal.Count -eq 2){
                                If($keyVal[1].StartsWith('$_')){
                                    [void]$newDict.Add($keyval[0],$keyVal[1]);
                                }
                                Else{
                                    [void]$newDict.Add($keyval[0],("{0}" -f $keyVal[1]));
                                }
                            }
                        }
                        [void]$parameters.Add($p.Name,$newDict)
                    }
                    Else{
                        Write-Verbose $Script:messages.UnableToGetParamFromSB
                        [void]$parameters.Add($p.Name,[String]::Empty)
                    }
                }
            }
        }
        Catch{
            Write-Error $_.Exception
        }
        #return dictionary
        return $parameters
    }
}
