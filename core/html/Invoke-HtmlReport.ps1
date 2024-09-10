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

Function Invoke-HtmlReport{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-HtmlReport
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [object]$OutDir
    )
    Begin{
        $monkeyData = $exec_info = $htmlFile = $null;
        try{
            $all_rules = Get-Rule
            if($null -ne (Get-Variable -Name monkeyExportObject -ErrorAction Ignore) -and $null -ne (Get-Variable -Name matchedRules -ErrorAction Ignore)){
                $exec_info = [ordered]@{
                    Ruleset = (Get-Framework);
                    'Ruleset Description' = (Get-Ruleset -Info).about;
                    'Number of rules' = @($all_rules).Count;
                    'Executed Rules' = @($matchedRules).Count;
                    'Scan Date' = $MonkeyExportObject.executionInfo.ScanDate;
                    'Monkey Version' = Get-MonkeyVersion;
                }
                #Check if hashtable
                If($MonkeyExportObject.Output -is [hashtable]){
                    $monkeyData = New-Object -TypeName PsObject -Property $MonkeyExportObject.Output;
                }
                else{
                    $monkeyData = $MonkeyExportObject.Output
                }
            }
        }
        catch{
            throw ("{0}" -f $_.Exception.Message)
        }
    }
    Process{
        #Invoke report
        if($null -ne $monkeyData){
            $p = @{
                matched = $matchedRules;
                rules = $all_rules;
                user_info = $O365Object.executionInfo;
                data= $monkeyData;
                exec_info = $exec_info;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
                Instance = $O365Object.Instance;
                Environment = $O365Object.Environment;
                Tenant = $O365Object.Tenant;
                tableData= $O365Object.dataMappings;
            }
            $html_report = New-HtmlReport @p
            if($html_report){
                #write JS
                #$Output = $html_report -replace '\${Scripts}', $script:javascript
                $Output = $html_report
            }
            #Set html declaration
            $htmlFile = $Output.Insert(0,"<!DOCTYPE html>`n")
            #Set out file
            $outFile = ("{0}{1}Monkey365.html" -f $outDir, [System.IO.Path]::DirectorySeparatorChar)
            #Expand archives
            $assets = ("{0}{1}assets.zip" -f $O365Object.Localpath, [System.IO.Path]::DirectorySeparatorChar)
            [bool]$assetsExists = [System.IO.File]::Exists($assets)
            if(-NOT $assetsExists){
                Write-Warning ("Assets files were not found on {0}" -f $assets)
            }
            else{
                Expand-Archive -Path $assets -DestinationPath $outDir -Force
            }
        }
    }
    End{
        if($null -ne $htmlFile -and $null -ne $outFile){
            Out-File -InputObject $htmlFile -FilePath $outFile -Encoding utf8
        }
    }
}
