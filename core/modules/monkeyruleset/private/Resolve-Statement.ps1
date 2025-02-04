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

Function Resolve-Statement{
    <#
        .SYNOPSIS
        Resolve statement

        .DESCRIPTION
        Resolve statement

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-Statement
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$True,HelpMessage="Statement")]
        [Object]$Statement
    )
    Begin{
        $option = $null
    }
    Process{
        If($null -ne $Statement.PsObject.Properties.Item('conditions') -and $null -ne $Statement.PsObject.Properties.Item('whereObject')){
            $option = 'whereObject'
        }
        elseif($null -ne $Statement.PsObject.Properties.Item('conditions') -and $null -ne $Statement.PsObject.Properties.Item('getValue')){
            $option = 'getValue'
        }
        elseif($null -ne $Statement.PsObject.Properties.Item('conditions')){
            $option = 'condition'
        }
        elseif($null -ne $Statement.PsObject.Properties.Item('include')){
            $option = 'include'
        }
        elseif($null -ne $Statement.PsObject.Properties.Item('getValue')){
            $option = 'getValue'
        }
        elseif($null -eq $Statement.PsObject.Properties.Item('conditions') -and $null -ne $Statement.PsObject.Properties.Item('whereObject')){
            $option = 'whereObjectPipelineOut'
        }
        else{
            Write-Warning "Statement not recognized"
        }
    }
    End{
        Switch($option){
            'condition'
            {
                $condition = Get-Condition -Condition $Statement
                if($condition){
                    ConvertFrom-Condition @condition
                }
            }
            'include'
            {
                Resolve-Include -Statement $Statement
            }
            'whereObjectPipelineOut'
            {
                $whereObject = $Statement.whereObject
                New-Variable -Name queryIsOpen -Value $True -Scope Script -Force
                #Potential where Object outside pipeline
                ('$_.{0}.Where({{' -f $whereObject)
            }
            'whereObject'
            {
                $whereObject = $Statement.whereObject
                $condition = Get-Condition -Condition $Statement
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
                $getValue = $Statement.getValue
                if($null -ne $getValue){
                    #Get element and conditions
                    $objectsToCheck = Get-ElementsToCheck -Path $getValue
                    #Get Condition
                    $condition = Get-Condition -Condition $Statement
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


