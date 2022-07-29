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

Function New-ExcelDataObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-ExcelDataObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Low")]
    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [Object]$elem,

            [Parameter(Mandatory = $false, HelpMessage = 'Force to avoid confirm prompt')]
            [switch]$Force
    )
    Begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        $properties = $null;
        $returnObject = $null;
        $data = $null;
        if($null -ne (Get-Variable -Name dexcel -ErrorAction Ignore)){
            $data = $dexcel | Select-Object -ExpandProperty $elem.name -ErrorAction Ignore
            if($null -ne $data){
                $data | Add-Member -type NoteProperty -name raw_data -value $elem.value.Data -Force
                if($data.psobject.properties.item('fields')){
                    $properties = $data.fields
                }
                if(!$data.sheetName){
                    $data | Add-Member -type NoteProperty -name sheetName -value $elem.name -Force
                }
            }
        }
        if($null -eq $data){
            $data = New-Object -TypeName PSCustomObject
            $data | Add-Member -type NoteProperty -name sheetName -value $elem.name -Force
            $data | Add-Member -type NoteProperty -name raw_data -value $elem.value.Data -Force
        }
    }
    Process{
        if ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")){
            $ConfirmPreference = 'None'
            if($properties){
                $returnObject = @()
                foreach($element in $elem.value.Data){
                    try{
                        $new_element = New-Object -TypeName PSCustomObject
                        foreach($prop in $properties){
                            $value = $element.GetPropertyByPath($prop)
                            $new_element | Add-Member -type NoteProperty -name $prop -value $value
                        }
                        $returnObject+=$new_element
                    }
                    catch{
                        Write-Verbose $_
                        Write-Debug $element
                    }
                }
            }
            else{
                $returnObject = $elem.value.Data
            }
        }
    }
    End{
        if($null -ne $returnObject){
            $data | Add-Member -type NoteProperty -name data -value $returnObject -Force
            return $data
        }
        else{
            return $null
        }
    }
}
