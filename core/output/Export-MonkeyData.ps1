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
        [Parameter(Mandatory = $true, HelpMessage = 'Output format')]
        [String]$ExportTo
    )
    #Export data
    switch ($ExportTo) {
        'CSV'
        {
            Write-Warning "CSV RAW output has been deprecated and will be upgraded two releases later (0.91.4). Please, check https://github.com/silverhack/monkey365/issues/76"
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            if($OutDir){
                foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                    if($unit_element.Name -and $unit_element.value.Data){
                        $csv_file = ("{0}/{1}.csv" -f $OutDir,$unit_element.Name)
                        $msg = @{
                            MessageData = ($message.ExportDataToInfo -f $csv_file,'csv');
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('NewCSVFile');
                        }
                        Write-Verbose @msg
                        $params = @{
                            Object = $unit_element.value.Data;
                            OutFile = $csv_file;
                        }
                        Out-CSV @params
                    }
                }
            }
        }
        'JSON'
        {
            Write-Warning "JSON RAW output has been deprecated and will be upgraded two releases later (0.91.4). Please, check https://github.com/silverhack/monkey365/issues/76"
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            if($OutDir){
                foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                    if($unit_element.Name -and $unit_element.value.Data){
                        $json_file = ("{0}/{1}.json" -f $OutDir,$unit_element.Name)
                        $msg = @{
                            MessageData = ($message.ExportDataToInfo -f $json_file,'json');
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('NewJSONFile');
                        }
                        Write-Verbose @msg
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
                                InformationAction = $O365Object.InformationAction;
                                Debug = $O365Object.debug;
                                Tags = @('UnableToExport');
                            }
                            Write-Debug @msg
                        }
                    }
                }
            }
        }
        'CLIXML'
        {
            Write-Warning "CLIXML RAW output has been deprecated and will be removed two releases later (0.91.4). Please, check https://github.com/silverhack/monkey365/issues/76"
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            if($OutDir){
                foreach($unit_element in $MonkeyExportObject.Output.GetEnumerator()){
                    if($unit_element.Name -and $unit_element.value.Data){
                        $xml_file = ("{0}/{1}.xml" -f $OutDir,$unit_element.Name)
                        $msg = @{
                            MessageData = ($message.ExportDataToInfo -f $xml_file,'xml');
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('NewXMLFile');
                        }
                        Write-Verbose @msg
                        $params = @{
                            Object = $unit_element.value.Data;
                            OutFile = $xml_file;
                        }
                        Out-XML @params
                    }
                }
            }
        }
        "HTML"
        {
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            if($OutDir){
                Invoke-HtmlReport -OutDir $OutDir
            }
        }
        "PRINT"
        {
            return $MonkeyExportObject.Output
        }
    }
}
