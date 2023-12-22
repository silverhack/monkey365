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

Function Invoke-DumpExcel{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-DumpExcel
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [HashTable] $ObjectData
    )
    Begin{
        Write-Warning "Excel output has been deprecated and will be removed in next release"
        if($null -ne $O365Object.internal_config.excelSettings){
            $ExcelSettings = $O365Object.internal_config.excelSettings
            $TableFormatting = $ExcelSettings.tableFormatting.Style
            $HeaderStyle = $ExcelSettings.HeaderStyle
            #Check if translate data exists
            $dumpFormatFile = $ExcelSettings.dumpformat
            #Check if path is rooted or not
            $isRootDumpFile = [System.IO.Path]::IsPathRooted($dumpFormatFile)
            if(-NOT $isRootDumpFile){
                $dumpFileFormat = ("{0}/{1}" -f $O365Object.Localpath, $dumpFormatFile)
            }
            else{
                $dumpFileFormat = $ExcelSettings.dumpformat
            }
            #Load Var
            Import-JsonToVariable -path $dumpFileFormat -varname dexcel -Scope Global
            #Set Debug mode
            try{
                $isDebug = [System.Convert]::ToBoolean($ExcelSettings.Debug)
            }
            catch{
                $isDebug = $false;
            }
            #Set ReportName
            if($ExcelSettings.ReportName){
                if($null -ne $O365Object.current_subscription){
                    $reportName = ("{0}: {1}" -f $ExcelSettings.ReportName, $O365Object.current_subscription.displayName)
                }
                elseif($null -ne $O365Object.Tenant){
                    $reportName = ("{0}: {1}" -f $ExcelSettings.ReportName, $O365Object.Tenant.TenantName)
                }
                else{
                    $reportName = ("{0}" -f $ExcelSettings.ReportName)
                }
            }
            else{
                $reportName = ("{0}" -f "Monkey365 Excel Dump")
            }
            #Set HyperLinks
            if($ExcelSettings.HyperLinkcompanyName){
                $hyperLinks = $ExcelSettings.HyperLinkcompanyName
            }
            else{
                $hyperLinks = @()
            }
            #Get CompanyLogo
            if($ExcelSettings.CompanyLogo){
                $isRootFile = [System.IO.Path]::IsPathRooted($ExcelSettings.CompanyLogo)
                if(-NOT $isRootFile){
                    $CompanyLogo = ("{0}/{1}" -f $O365Object.Localpath, $ExcelSettings.CompanyLogo)
                }
                else{
                    $CompanyLogo = $ExcelSettings.CompanyLogo
                }
                #Check if file exists
                [bool]$exists = [System.IO.File]::Exists($CompanyLogo)
                if(-NOT $exists){
                    $CompanyLogo = [string]::Empty
                }
            }
            #Set Table Formatting
            if($TableFormatting){
                $FormatTable = $TableFormatting
            }
            else{
                $FormatTable = $false
            }
            #Get Index data
            if($ExcelSettings.CompanyLogoFront){
                $isRootFile = [System.IO.Path]::IsPathRooted($ExcelSettings.CompanyLogoFront)
                if(-NOT $isRootFile){
                    $CompanyLogoFront = ("{0}/{1}" -f $O365Object.Localpath, $ExcelSettings.CompanyLogoFront)
                }
                else{
                    $CompanyLogoFront = $ExcelSettings.CompanyLogoFront
                }
                #Check if file exists
                [bool]$exists = [System.IO.File]::Exists($CompanyLogoFront)
                if(-NOT $exists){
                    $CompanyLogoFront = [string]::Empty
                }
            }
            if($null -ne $ExcelSettings.psobject.Properties.Item('CompanyUserTopLeft') -and [string]::IsNullOrEmpty($ExcelSettings.CompanyUserTopLeft) -ne $true){
                $isRootFile = [System.IO.Path]::IsPathRooted($ExcelSettings.CompanyUserTopLeft)
                if(-NOT $isRootFile){
                    $CompanyUserTopLeft = ("{0}/{1}" -f $O365Object.Localpath, $ExcelSettings.CompanyUserTopLeft)
                }
                else{
                    $CompanyUserTopLeft = $ExcelSettings.CompanyUserTopLeft
                }
                #Check if file exists
                [bool]$exists = [System.IO.File]::Exists($CompanyUserTopLeft)
                if(-NOT $exists){
                    $CompanyUserTopLeft = [string]::Empty
                }
            }
            else{
                $CompanyUserTopLeft = $null
            }
            #Get UserPrincipalName
            if($O365Object.userPrincipalName){
                $upn = $O365Object.userPrincipalName
            }
            else{
                $upn = [string]::Empty
            }

        }
        #Get a new PsObject with Excel format data
        $allSheets = @()
        foreach($elem in $ObjectData.GetEnumerator()){
            $newSheet = New-ExcelDataObject -elem $elem
            if($newSheet){
                #Add to array
                $allSheets+=$newSheet
            }
        }
    }
    Process{
        if($allSheets){
            $params = @{
                Visible = $isDebug
            }
            $excel_instance = New-ExcelObject @params
            if($false -eq $excel_instance){
                return
            }
            #Get Language Settings
            [String]$Language = Get-ExcelLanguage
            if ($Language){
                #Try to get config data
                if($HeaderStyle.$($Language)){
                    #Detected language
                    $Header = $HeaderStyle.$($Language)
                }
                else{
                    $Header = [string]::Empty
                }
            }
            else{
                $Header = [string]::Empty
            }
            #Create About page
            $params = @{
                displayName = $reportName;
                HyperLinks = $hyperLinks;
                RemoveGridLines= $true;
                CompanyLogo = $CompanyLogo;
            }
            New-ExcelAbout @params
            #Add sheets to Excel
            foreach($sheet in $allSheets){
                $params = @{
                    Data = $sheet.data;
                    Title = $sheet.sheetName;
                    TableTitle = $sheet.sheetName;
                    TableStyle = $FormatTable;
                    Freeze = $True;
                }
                New-SheetFromCSV @params
            }
            #Add Some charts
            $directory_roles = $allSheets | Where-Object { $_.sheetName -eq "aad_directory_roles" } | Select-Object -ExpandProperty data -ErrorAction SilentlyContinue
            if($null -ne $directory_roles){
                $DRChart = @{}
                #Group for each object for count values
                $directory_roles.roledefinition | Group-Object displayName | ForEach-Object {$DRChart.Add($_.Name,@($_.Count))}
                if($DRChart){
                    $params = @{
                        Data = $DRChart;
                        HeaderStyle = $Header;
                        Headers = @('Type of group','Number of Members');
                        SheetName = "Directory Roles Chart";
                        TableName = "Directory Roles Table";
                        Position = @(1,1);
                        addNewChart = $true;
                        ChartType = "xlColumnClustered";
                        ChartTitle = "Directory role members";
                        ChartStyle = 34;
                        HasDataTable = $true;
                        ShowHeaders = $true;
                        ShowTotals = $true;
                    }
                    New-HashTableToWorkSheet @params
                }
            }
            #Add RBAC chart
            $RBAC = $allSheets | Where-Object { $_.sheetName -eq "az_rbac_users" } | Select-Object -ExpandProperty data -ErrorAction SilentlyContinue
            if($null -ne $RBAC){
                $RBACChart = @{}
                #Group for each object for count values
                $RBAC.roleAssignmentInfo | Group-Object RoleName | ForEach-Object {$RBACChart.Add($_.Name,@($_.Count))}
                if($RBACChart){
                    $params = @{
                        Data = $RBACChart;
                        HeaderStyle = $Header;
                        Headers = @('Role Name','Number of Members');
                        SheetName = "RBAC Chart";
                        TableName = "RBAC Table";
                        Position = @(1,1);
                        addNewChart = $true;
                        ChartType = "xlBarClustered";
                        ChartTitle = "Role Based Access Control Members";
                        ChartStyle = 34;
                        HasDataTable = $true;
                        ShowHeaders = $true;
                        ShowTotals = $true;
                    }
                    New-HashTableToWorkSheet @params
                }
            }
            #Add classic admins chart
            $classic_admins = $allSheets | Where-Object { $_.sheetName -eq "aad_classic_admins" -or $_.sheetName -eq "az_classic_admins" } | Select-Object -ExpandProperty data -ErrorAction SilentlyContinue
            if($null -ne $classic_admins){
                $ClassicChart = @{}
                #Group for each object for count values
                $classic_admins | Group-Object role | ForEach-Object {$ClassicChart.Add($_.Name,@($_.Count))}
                if($ClassicChart){
                    $params = @{
                        Data = $ClassicChart;
                        HeaderStyle = $Header;
                        Headers = @('Role Name','Number of Members');
                        SheetName = "Classic Administrators Chart";
                        TableName = "Classic Administrators Table";
                        Position = @(1,1);
                        addNewChart = $true;
                        ChartType = "xlBarClustered";
                        ChartTitle = "Classic Administrators Members";
                        ChartStyle = 34;
                        HasDataTable = $true;
                        ShowHeaders = $true;
                        ShowTotals = $true;
                    }
                    New-HashTableToWorkSheet @params
                }
            }
            #Add Baseline Data chart
            $baseline_status = $allSheets | Where-Object { $_.sheetName -eq "az_vm_security_baseline" } | Select-Object -ExpandProperty data -ErrorAction SilentlyContinue
            if($null -ne $baseline_status){
                #Group for each object for count values
                $BaselineStats = @{}
                $SecurityBaselineStats = $baseline_status | Group-Object ServerName -AsHashTable
                if($SecurityBaselineStats){
                    foreach($rule in $SecurityBaselineStats.GetEnumerator()){
                        $Critical = 0
                        $Informational = 0
                        $Warning = 0
                        foreach($element in $rule.value){
                            switch ($element.RuleSeverity) {
                                'Critical'
                                {
                                    $Critical+=1
                                }
                                'Informational'
                                {
                                    $Informational+=1
                                }
                                'Warning'
                                {
                                    $Warning+=1
                                }
                            }
                        }
                        $BaselineStats.Add($rule.Name,@($critical, $Informational, $Warning))
                    }
                }
                if($BaselineStats){
                    $params = @{
                        Data = $BaselineStats;
                        HeaderStyle = $Header;
                        Headers = @('VMName','Critical','Informational','Warning');
                        SheetName = "VM Security Baseline Chart";
                        TableName = "Security Baseline Table";
                        Position = @(1,1);
                        addNewChart = $true;
                        ChartType = "xlColumnClustered";
                        ChartTitle = "Security Baseline Status";
                        ChartStyle = 34;
                        HasDataTable = $true;
                        ShowHeaders = $true;
                        ShowTotals = $true;
                    }
                    New-HashTableToWorkSheet @params
                }
            }
            #Add Missing Patches
            $MissingPatches = $allSheets | Where-Object { $_.sheetName -eq "az_vm_missing_patches" } | Select-Object -ExpandProperty data -ErrorAction SilentlyContinue
            if($null -ne $MissingPatches){
                #Group for each object for count values
                $KBStats = @{}
                $PatchesStats = $MissingPatches | Group-Object ServerName -AsHashTable
                if($PatchesStats){
                    foreach($Kbs in $PatchesStats.GetEnumerator()){
                        $Critical = 0
                        $Moderate = 0
                        $Low = 0
                        $Important = 0
                        $Security = 0
                        $Unknown = 0
                        foreach($element in $Kbs.value){
                            switch ($element.MSRCSeverity) {
                                'Critical'
                                {
                                    $Critical+=1
                                }
                                'Security'
                                {
                                    $Security+=1
                                }
                                'Important'
                                {
                                    $Important+=1
                                }
                                'Moderate'
                                {
                                    $Moderate+=1
                                }
                                'Low'
                                {
                                    $Low+=1
                                }
                                Default
                                {
                                    $Unknown+=1
                                }
                            }
                        }
                        $KBStats.Add($Kbs.Name,@($critical, $security, $important,$moderate,$low, $Unknown))
                    }
                }
                if($KBStats){
                    $params = @{
                        Data = $KBStats;
                        HeaderStyle = $Header;
                        Headers = @('VMName','Critical','Security','Important','Moderate','Low','Unknown');
                        SheetName = "Missing Patches Chart";
                        TableName = "Missing Patches Table";
                        Position = @(1,1);
                        addNewChart = $true;
                        ChartType = "xlColumnClustered";
                        ChartTitle = "Missing Patches Status";
                        ChartStyle = 34;
                        HasDataTable = $true;
                        ShowHeaders = $true;
                        ShowTotals = $true;
                    }
                    New-HashTableToWorkSheet @params
                }
            }
        }
        #Delete Sheet1 and create index
		Remove-FirstSheet
        #Create Index page
        $params = @{
            LogoFront = $CompanyLogoFront;
            LogoTopLeft = $CompanyUserTopLeft;
            UserName = $upn;
        }
        New-ExcelIndex @params
    }
    End{
        #Create Report Folder
        $folderExists = [System.IO.DirectoryInfo]::new(("{0}{1}{2}" -f $script:Report, `
                                                                        [System.IO.Path]::DirectorySeparatorChar, `
                                                                        "excel"))
        if(-NOT $folderExists.Exists){
            $out_folder = (
                "{0}{1}{2}" -f $script:Report, `
                               [System.IO.Path]::DirectorySeparatorChar, `
                               "excel"
            )
            $job_folder = New-MonkeyFolder -destination $out_folder
        }
        else{
            $job_folder = (
                "{0}{1}{2}" -f $script:Report, `
                               [System.IO.Path]::DirectorySeparatorChar, `
                               "excel"
            )
        }
        $date = Get-Date -format "yyyyMMdd"
        $outFile = ('{0}{1}Monkey_Report_{2}' -f $job_folder, [System.IO.Path]::DirectorySeparatorChar, $date)
        Save-Excel -outFile $outFile -Force
        #Remove Excel COM object
        Remove-ExcelObject
        #Remove var
        Remove-Variable -Name dexcel -Force -ErrorAction Ignore
    }
}
