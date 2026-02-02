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

function ConvertFrom-Condition{
    <#
        .SYNOPSIS
        Returns an array object that represents the compiled query

        .DESCRIPTION
        Returns an array object that represents the compiled query

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertFrom-Condition
            Version     : 1.0

        .LINK11
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Conditions")]
        [Object]$Conditions,

        [parameter(Mandatory=$false, HelpMessage="Operator")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$Operator,

        [parameter(Mandatory=$false, HelpMessage="Logical Not operator")]
        [AllowNull()]
        [AllowEmptyString()]
        [String]$LogicalNotOperator,

        [parameter(Mandatory=$false, HelpMessage="Right to left order")]
        [AllowNull()]
        [AllowEmptyString()]
        [Switch]$RightToLeft
    )
    Begin{
        $query = [System.String]::Empty
        $opCheck = $lnot = $null
        $arrQuery = [System.Collections.Generic.List[System.String]]::new()
        if($PSBoundParameters.ContainsKey('Operator') -and ![System.String]::IsNullOrEmpty($PSBoundParameters['Operator'])){
            $opCheck = Get-LogicalOperator -InputObject $PSBoundParameters['Operator']
        }
        if($PSBoundParameters.ContainsKey('LogicalNotOperator') -and ![System.String]::IsNullOrEmpty($PSBoundParameters['LogicalNotOperator'])){
            $lnot = Get-LogicalNotOperator -InputObject $PSBoundParameters['LogicalNotOperator']
        }
    }
    Process{
        If($Conditions.Item(0) -is [String]){
            $tmp = [System.Collections.Generic.List[System.Object[]]]::new()
            [void]$tmp.Add($Conditions)
            $Conditions = $tmp
        }
        Foreach($condition in $Conditions.GetEnumerator()){
            If ($condition -is [System.Collections.IEnumerable] -and $condition -isnot [string]){
                $newCondition = [System.Collections.Generic.List[System.String]]::new();
                ForEach($cond in $condition){
                    [void]$newCondition.Add($cond);
                }
                If($newCondition.Count -gt 3){
                    $op = $newCondition[1];
                    $invalidQuery = (@($newCondition) -join ' ')
                    Write-Warning -Message ($Script:messages.StatementErrorMessage -f $op,$invalidQuery)
                }
                If($newCondition.Count -eq 2){
                    [void]$newCondition.Insert(0,$null)
                }
                If($newCondition[0] -eq [String]::Empty){
                    $newCondition[0]= $null
                }
                #Get valid operator
                $validcmpOperator = Get-ComparisonOperator -InputObject $newCondition
                If($null -ne $validcmpOperator -and $validcmpOperator -eq 1){
                    $filter = [ordered]@{
                        LeftItem = $newCondition[0];
                        Operator = $newCondition[1];
                        RightItem = $newCondition[2];
                    }
                    $q = Get-NewFilter @filter
                    [void]$arrQuery.Add($q)
                }
                Else{
                    $op = $newCondition[1];
                    $invalidQuery = (@($newCondition) -join ' ')
                    Write-Warning -Message ($Script:messages.StatementErrorMessage -f $op,$invalidQuery)
                }
            }
            Else{
                $invalidQuery = (@($condition) -join ' ')
                Write-Warning -Message ($Script:messages.StatementErrorMessage -f $null,$invalidQuery)
            }
        }
    }
    End{
        <#
        If((!$PSBoundParameters.ContainsKey('Operator') -or [System.String]::IsNullOrEmpty($PSBoundParameters['Operator'])) -and $arrQuery.Count -gt 0){
            Write-Warning -Message $Script:messages.OperatorNotFoundErrorMessage
        }
        #>
        If(($PSBoundParameters.ContainsKey('Operator') -and $PSBoundParameters['Operator']) -and $null -ne $opCheck -and $arrQuery.Count -gt 0){
            $query = (@($arrQuery) -join (' -{0} ' -f $PSBoundParameters['Operator']))
        }
        Elseif($arrQuery.Count -eq 1){
            $query = (@($arrQuery) -join ' ')
        }
        Else{
            Write-Warning -Message $Script:messages.ConditionErrorGenericMessage
            return $null
        }
        #Check if logical Not
        if($null -ne $query -and $null -ne $lnot){
            if($LogicalNotOperator -eq 'not'){
                $query = ("-{0} ({1})" -f $LogicalNotOperator,$query)
            }
            else{
                $query = ("{0}({1})" -f $LogicalNotOperator,$query)
            }
        }
        return $query
    }
}

