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

Function Get-DashboardHtmlTable{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DashboardHtmlTable
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
            [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
            [Object]$table_data
        )
    Begin{
        $div_attributes = [ordered]@{
            class = 'justify-content-center col-12 col-lg-12 col-xl-12';
        }
        $div_element = @{
            tagname = 'div';
            attributes = $div_attributes;
        }
        $returnObject = $null;
        $new_Dashboard_Col = $null;
        $table_raw_data = $data.GetPropertyByPath($table_data.data)
        $properties = $table_data.translate
        $new_table = New-Object -TypeName PSCustomObject
        if($null -ne $table_data.GetPropertyByPath($table_data.style)){
            $new_table | Add-Member -type NoteProperty -name style -value $table_data.style -Force
        }
        else{
            $new_table | Add-Member -type NoteProperty -name style -value "Normal"
        }
        if($null -ne $table_raw_data){
            if($null -ne $table_data.GetPropertyByPath('attributes')){
                $table_raw_data = $table_raw_data.data | Select-Object $table_data.attributes
            }
            else{
                $table_raw_data = $table_raw_data.data
            }
        }
    }
    Process{
        if($null -ne $table_raw_data){
            $returnObject = @()
            foreach($unit_elem in $table_raw_data.GetEnumerator()){
                $new_element = New-Object -TypeName PSCustomObject
                foreach($elem in $unit_elem.psobject.properties){
                    $new_name = $properties | Select-Object -ExpandProperty $elem.Name -ErrorAction Ignore
                    if($null -ne $new_name){
                        $new_element | Add-Member -type NoteProperty -name $new_name -value $elem.Value
                    }
                    else{
                        $new_element | Add-Member -type NoteProperty -name $elem.Name -value $elem.Value
                    }
                }
                $returnObject+=$new_element
            }
            if($null -ne $returnObject){
                $returnObject = [pscustomobject]@{
                    data = $returnObject
                }
            }
        }
        if($null -ne $returnObject){
            if($table_data.box){
                #Get Title
                if($null -ne ($table_data.box.psobject.properties.Item('title'))){
                    $title = $table_data.box.title;
                }
                else{
                    $title = "";
                }
                #Get subtitle
                if($null -ne ($table_data.box.psobject.properties.Item('subtitle'))){
                    $subtitle = $table_data.box.subtitle;
                }
                else{
                    $subtitle = "";
                }
                #Get img
                if($null -ne ($table_data.box.psobject.properties.Item('img'))){
                    $img = $table_data.box.img;
                }
                else{
                    $img = "";
                }
                #Get i class
                if($null -ne ($table_data.box.psobject.properties.Item('i_class'))){
                    $i_class = $table_data.box.i_class;
                }
                else{
                    $i_class = "";
                }
                $boxArgs = @{
                    defaultCard = $True;
                    card_class = 'monkey-card';
                    title_header = $title;
                    subtitle = $subtitle;
                    img = $img;
                    i_class = $i_class;
                    body = (Get-HtmlTableFromObject -issue $returnObject -table_class "monkey-table break-word-table table-striped responsive")
                }
                #Create a new card
                $new_Dashboard_Card = Get-HtmlCard @boxArgs
                if($new_Dashboard_Card){
                    #Create col and add data
                    $div_element.attributes.class = (Get-HtmlColClass -size $table_data.size)
                    $div_element.appendObject = $new_Dashboard_Card
                    $new_Dashboard_Col = New-HtmlTag @div_element
                }
            }
        }
    }
    End{
        if($null -ne $new_Dashboard_Col){
            return $new_Dashboard_Col
        }
        else{
            return $null
        }
    }
}


