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

Function Export-MonkeyData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Export-MonkeyData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Output formats')]
        [String]$ExportTo,

        [Parameter(Mandatory = $false, HelpMessage = 'Output Directory')]
        [String]$OutDir
    )
    #Export data
    switch ($ExportTo) {
        'CSV'
        {
            foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                if($unit_element.Name -and $unit_element.value.Data){
                    $csv_file = ("{0}/{1}.csv" -f $OutDir,$unit_element.Name)
                    $msg = @{
                        MessageData = ($message.ExportDataToMessage -f $csv_file,'csv');
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $InformationAction;
                        Tags = @('NewCSVFile');
                    }
                    Write-Debug @msg
                    $params = @{
                        Object = $unit_element.value.Data;
                        OutFile = $csv_file;
                    }
                    Out-CSV @params
                }
            }
        }
        'JSON'
        {
            foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                if($unit_element.Name -and $unit_element.value.Data){
                    $json_file = ("{0}/{1}.json" -f $OutDir,$unit_element.Name)
                    $msg = @{
                        MessageData = ($message.ExportDataToMessage -f $json_file,'json');
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $InformationAction;
                        Tags = @('NewJSONFile');
                    }
                    Write-Debug @msg
                    try{
                        $params = @{
                            Object = $unit_element.value.Data;
                            OutFile = $json_file;
                        }
                        Out-JSON @params
                    }
                    catch{
                        $msg = @{
                            MessageData = ($message.UnableToExport -f $json_file,'json');
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            InformationAction = $InformationAction;
                            Tags = @('UnableToExport');
                        }
                        Write-Debug @msg
                    }
                }
            }
        }
        'CLIXML'
        {
            foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                if($unit_element.Name -and $unit_element.value.Data){
                    $xml_file = ("{0}/{1}.xml" -f $OutDir,$unit_element.Name)
                    $msg = @{
                        MessageData = ($message.ExportDataToMessage -f $xml_file,'xml');
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $InformationAction;
                        Tags = @('NewXMLFile');
                    }
                    Write-Debug @msg
                    $params = @{
                        Object = $unit_element.value.Data;
                        OutFile = $xml_file;
                    }
                    Out-XML @params
                }
            }
        }
        'EXCEL'
        {
            Invoke-DumpExcel -ObjectData $MonkeyExportObject.Output
            <#
            if ($PSEdition -eq 'Core'){
                Write-Warning -Message ("Exporting data to Excel format is not supported on {0}" -f [System.Environment]::OSVersion.VersionString)
            }
            else{
                Invoke-DumpExcel -ObjectData $Dataset
            }
            #>
        }
        "HTML"
        {
            Invoke-HtmlReport -OutDir $OutDir
        }
        "PRINT"
        {
            return $MonkeyExportObject.Output
        }
    }
}
