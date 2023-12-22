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
        [parameter(Mandatory=$true, HelpMessage="Conditions")]
        [Object]$Conditions
    )
    $finalquery = [System.String]::Empty
    foreach($nquery in $Conditions){
        if($null -ne $nquery.Psobject.Properties.Item('statements')){
            $statements = @()
            #Check if operator
            $operator = $nquery | Select-Object -ExpandProperty operator -ErrorAction Ignore
            #Check if connect operator
            $connectOperator = $nquery | Select-Object -ExpandProperty connectOperator -ErrorAction Ignore
            foreach($statement in $nquery.statements){
                $query = Resolve-Statement -Statement $statement
                if($query){
                    $statements+=$query
                }
            }
            if(@($statements).Count -eq 1 -and $null -eq $operator){
                $q = (@($statements) -join ' ')
                if($null -ne $connectOperator -and $null -ne (Get-LogicalOperator $connectOperator)){
                    $q = ("-{0} ({1})" -f $connectOperator,$q)
                }
                $finalquery = ("{0} {1}" -f $finalquery,$q)
            }
            elseif($null -ne $operator -and $null -ne (Get-LogicalOperator $operator)){
                $q = (@($statements).ForEach({"($_)"}) -join (' -{0} ' -f $operator))
                #Check if connect operator
                if($null -ne $connectOperator -and $null -ne (Get-LogicalOperator $connectOperator)){
                    $q = ("-{0} ({1})" -f $connectOperator,$q)
                }
                $finalquery = ("{0} {1}" -f $finalquery,$q)
            }
            else{
                Write-Warning "Unable to convert query"
            }
        }
    }
    $finalquery.Trim()
}
