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

Function Resolve-Filter{
    <#
        .SYNOPSIS
        Resolve Filter

        .DESCRIPTION
        This funcion will try to resolve custom filters dynamically

        .INPUTS
        Array of conditions and approved PowerShell operators
        $filter = @([PsCustomObject]@{condition =  @(@(1,"eq",1),@(2,"ne",1));"operator"="and"})

        .OUTPUTS
        ScriptBlock with valid filter
        {1 -eq 1 -and 2 -ne 1}

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-Filter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Filter")]
        [Object]$InputObject
    )
    Begin{
        $option = $null
    }
    Process{
        If($null -ne $InputObject.PsObject.Properties.Item('conditions') -and $null -ne $InputObject.PsObject.Properties.Item('whereObject')){
            $option = 'whereObject'
        }
        ElseIf($null -ne $InputObject.PsObject.Properties.Item('conditions') -and $null -ne $InputObject.PsObject.Properties.Item('getValue')){
            $option = 'getValue'
        }
        ElseIf($null -ne $InputObject.PsObject.Properties.Item('conditions')){
            $option = 'condition'
        }
        ElseIf($null -ne $InputObject.PsObject.Properties.Item('include')){
            $option = 'include'
        }
        ElseIf($null -ne $InputObject.PsObject.Properties.Item('getValue')){
            $option = 'getValue'
        }
        ElseIf($null -eq $InputObject.PsObject.Properties.Item('conditions') -and $null -ne $InputObject.PsObject.Properties.Item('whereObject')){
            $option = 'whereObjectPipelineOut'
        }
        Else{
            Write-Warning $Script:messages.UnrecognizedFilter
        }
    }
    End{
        Switch($option){
            'condition'
            {
                $condition = $InputObject | Get-Condition
                if($condition){
                    ConvertFrom-Condition @condition
                }
            }
            'include'
            {
                $InputObject | Resolve-Include
            }
            'whereObjectPipelineOut'
            {
                $whereObject = $InputObject.whereObject
                New-Variable -Name queryIsOpen -Value $True -Scope Script -Force
                #Potential where Object outside pipeline
                ('$_.{0}.Where({{' -f $whereObject)
            }
            'whereObject'
            {
                $whereObject = $InputObject.whereObject
                $condition = $InputObject | Get-Condition
                if($condition){
                    $query = ConvertFrom-Condition @condition
                    if($null -ne $whereObject -and $null -ne $query){
                        ('$_.{0}.Where({{{1}}})' -f $whereObject,$query)
                    }
                }
                Else{
                    New-Variable -Name queryIsOpen -Value $True -Scope Script -Force
                    #Potential where Object outside pipeline
                    ('${0}.Where({' -f $whereObject)
                }
            }
            'getValue'
            {
                $objectsToCheck = $getValue = $condition = $safeQuery = $rst = $null;
                $getValue = $InputObject.getValue
                if($null -ne $getValue){
                    #Get element and conditions
                    $objectsToCheck = $getValue | Get-ObjectFromDataset
                    #Get Condition
                    $condition = $InputObject | Get-Condition
                }
                if($condition){
                    $query = ConvertFrom-Condition @condition
                }
                if($null -ne $query){
                    $safeQuery = $query | ConvertTo-SecureScriptBlock
                }
                if($null -ne $safeQuery -and $null -ne $objectsToCheck){
                    $rst = Get-QueryResult -InputObject $objectsToCheck -Query $safeQuery
                }
                if($null -ne $rst){
                    if(@($rst).Count -gt 0){
                        '$true'
                    }
                    else{
                        '$false'
                    }
                }
            }
        }
    }
}
