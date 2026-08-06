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

function ConvertTo-Query{
    <#
        .SYNOPSIS
        Returns a scriptblock object that represents the compiled query

        .DESCRIPTION
        Returns a scriptblock object that represents the compiled query

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-Query
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ScriptBlock])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Query object")]
        [Object]$InputObject
    )
    Process{
        $operator = $connectOperator = $null;
        #$finalquery = [System.String]::Empty
        $finalquery = [System.Text.StringBuilder]::new()
        Foreach($query in @($InputObject)){
            If($null -ne $query -and $null -ne $query.Psobject.Properties.Item('filter') -and $null -ne $query.filter){
                $filters = [System.Collections.Generic.List`1[String]]::new()
                #Get ConnectOperator
                $connectOperator = $query | Select-Object -ExpandProperty connectOperator -ErrorAction Ignore
                #Check if operator
                $operator = $query | Select-Object -ExpandProperty operator -ErrorAction Ignore
                ForEach($filter in $query.filter){
                    $newFilter = $filter | Resolve-Filter
                    If($newFilter){
                        #Check if connectOperator is present
                        $connectOp = $filter | Select-Object -ExpandProperty connectOperator -ErrorAction Ignore
                        If($null -ne $connectOp -and $null -ne (Get-LogicalOperator $connectOp)){
                            $q = ("-{0} {1}" -f $connectOp,$newFilter);
                            [void]$filters.Add($q);
                        }
                        ElseIf($filter.conditions.Count -gt 1){
                            $q = ("({0})" -f $newFilter);
                            [void]$filters.Add($q);
                        }
                        Else{
                            [void]$filters.Add($newFilter);
                        }
                    }
                }
                If($filters.Count -eq 1){
                    $q = (@($filters) -join ' ')
                    If($null -ne $connectOperator -and $null -ne (Get-LogicalOperator $connectOperator)){
                        $q = (" -{0} ({1})" -f $connectOperator,$q)
                    }
                    If($q.Length -gt 0){
                        [void]$finalquery.Append($q);
                    }
                }
                ElseIf($filters.Count -gt 1){
                    $q = [System.String]::Empty;
                    If($null -ne $connectOperator -and $null -ne (Get-LogicalOperator $connectOperator) -and $null -ne $operator -and $null -ne (Get-LogicalOperator $operator)){
                        $q = ("({0})" -f (@($filters -join (' -{0} ' -f $operator))))
                        $q = (" -{0} {1}" -f $connectOperator, $q)
                    }
                    ElseIf($null -ne $operator -and $null -ne (Get-LogicalOperator $operator)){
                        If(@($InputObject).Count -gt 1){
                            $q = ("({0})" -f (@($filters -join (' -{0} ' -f $operator))))
                        }
                        Else{
                            $q = ("{0}" -f (@($filters -join (' -{0} ' -f $operator))))
                        }
                    }
                    Else{
                        If($null -ne (Get-Variable -Name queryIsOpen -ErrorAction Ignore) -and $queryIsOpen){
                            $q = ("{0}" -f (@($filters) -join ' '))
                        }
                        Else{
                            $q = ("({0})" -f (@($filters) -join ' '))
                        }
                    }
                    If($q.Length -gt 0){
                        [void]$finalquery.Append($q);
                    }
                }
                Else{
                    Write-Warning -Message $Script:messages.BuildQueryGenericErrorMessage
                    Write-Warning ($InputObject | ConvertTo-Json -Depth 20 | Out-String)
                }
            }
            Else{
                Write-Warning -Message ($Script:messages.UnableToGetObjectProperty -f 'filter')
            }
        }
        If($null -ne (Get-Variable -Name queryIsOpen -ErrorAction Ignore) -and $queryIsOpen){
            #$finalquery = ("{0}}})" -f $finalquery,$q)
            [void]$finalquery.Append('})');
            If($null -ne (Get-Variable -Name atLeast -ErrorAction Ignore) -and $atLeast){
                [void]$finalquery.Append(('.Count -gt {0}' -f $atLeast));
            }
            Remove-Variable -Name queryIsOpen -Scope Script -Force -ErrorAction Ignore
        }
        If($finalquery.Length -gt 0){
            $finalquery.ToString().Trim();
        }
    }
}

