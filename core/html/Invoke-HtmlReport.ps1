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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignment", "", Scope="Function")]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$outDir
    )
    Begin{
        #$charts = $dashboards = @()
        $tables = @()
        #$chartPath = $dashboardPath = $null;
        $tablePath = $monkeyData = $null;
        $htmlFile= $null;
        $outFile = $null;
        try{
            $monkey_version = $O365Object.internal_config.version.Monkey365Version
        }
        catch{
            $monkey_version = $null
        }
        $ruleset = Get-MonkeyRuleset
        if($null -eq $ruleset){
            $msg = @{
                MessageData = ("Unable to get Ruleset");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $script:InformationAction;
                Tags = @('UnableToGetRuleSet');
            }
            Write-Warning @msg
            return;
        }
        $rules_path = $O365Object.internal_config.ruleSettings.rules
        $conditions_path = $O365Object.internal_config.ruleSettings.conditions
        $isRoot = [System.IO.Path]::IsPathRooted($rules_path)
        if(-NOT $isRoot){
            $rules_path = ("{0}/{1}" -f $O365Object.Localpath, $rules_path)
        }
        if (!(Test-Path -Path $rules_path)){
            Write-Warning ("{0} does not exists" -f $rules_path)
            return
        }
        $isRoot = [System.IO.Path]::IsPathRooted($conditions_path)
        if(-NOT $isRoot){
            $conditions_path = ("{0}/{1}" -f $O365Object.Localpath, $conditions_path)
        }
        if (!(Test-Path -Path $conditions_path)){
            Write-Warning ("{0} does not exists" -f $conditions_path)
            return
        }
        $ruleset_ = (Get-Content $ruleset -Raw) | ConvertFrom-Json
        $all_rules = Get-RulesFromDataset -rulefile $ruleset -rulePath $rules_path
        <#
        $ruleset_ = (Get-Content $ruleset -Raw) | ConvertFrom-Json
        $jsonrules = $ruleset_.rules.psobject.Properties | Select-Object Name, Value
        $all_rules = Get-RulesFromRuleSet -ruleset $jsonrules -rulepath $rules_path -Verbose -Debug
        #>
        #Check if hashtable
        if($MonkeyExportObject.Output -is [hashtable]){
            $monkeyData = $MonkeyExportObject.Output | Convert-HashTableToPsObject -psName "Monkey365.Output"
        }
        else{
            $monkeyData = $MonkeyExportObject.Output
        }
        #Get user info
        $user_info = $MonkeyExportObject.execution_info
        #Get ruleset results
        $matched = Invoke-RuleCheck -rules $all_rules -conditionsPath $conditions_path -MonkeyData $monkeyData
        #Get JSON table options
        $tablePath = $O365Object.internal_config.htmlSettings.tableformat
        if($null -ne $tablePath){
            $isRoot = [System.IO.Path]::IsPathRooted($tablePath)
            if(-NOT $isRoot){
                $tablePath = ("{0}/{1}" -f $O365Object.Localpath, $tablePath)
            }
            if (!(Test-Path -Path $tablePath)){
                Write-Warning ("{0} does not exists" -f $tablePath)
            }
        }
        #Get table
        switch ($O365Object.Instance.ToLower()){
            'azure'{
                #Get tables
                if($null -ne $tablePath){
                    $_tables = Get-JsonFromFile -path ("{0}/azure" -f $tablePath)
                    if($_tables){
                        $tables+=$_tables
                    }
                }
            }
            'microsoft365'{
                #Get tables
                if($null -ne $tablePath){
                    $_tables = Get-JsonFromFile -path ("{0}/o365" -f $tablePath)
                    if($_tables){
                        $tables+=$_tables
                    }
                }
            }
        }
        #Check if includeAAD
        if($O365Object.IncludeAAD){
            #Get tables
            if($null -ne $tablePath){
                $_tables = Get-JsonFromFile -path ("{0}/aad" -f $tablePath)
                if($_tables){
                    $tables+=$_tables
                }
            }
        }
        #Create execution info
        $fileName = [io.path]::GetFileNameWithoutExtension($ruleset)
        $total_rules = @($all_rules).Count
        $matched_rules = @($matched).Count
        $description = $ruleset_.about

        $exec_info = [ordered]@{
            Ruleset = $fileName;
            'Ruleset Description' = $description;
            'Number of rules' = $total_rules;
            'Executed Rules' = $matched_rules;
            'Scan Date' = $MonkeyExportObject.execution_info.ScanDate;
            'Monkey Version' = $monkey_version;
        }
    }
    Process{
        #Invoke report
        if($null -ne $monkeyData){
            $param = @{
                matched = $matched;
                rules = $all_rules;
                user_info = $user_info;
                data= $monkeyData;
                exec_info = $exec_info;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
                Instance = $O365Object.Instance;
                Environment = $O365Object.Environment;
                Tenant = $O365Object.Tenant;
                tableData= $tables;
            }
            Set-Variable matched -Value $matched -Scope Global -Force
            $html_report = New-HtmlReport @param
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
