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

Function Out-MonkeyData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Out-MonkeyData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$MonkeyExportObject
    )
    Begin{
        #Prepare data and export entire job to a file
        if($MyParams.saveProject -and $MonkeyExportObject.Output.psobject.Properties.GetEnumerator().moveNext()){
            $ReportPath = New-MonkeyReportDir -OutDir $O365Object.outDir
            if($ReportPath){
	            Set-Variable -Name Report -Value $ReportPath -Scope Script
                $out_folder = ('{0}/MonkeyJob' -f $ReportPath)
                $job_folder = New-MonkeyFolder -destination $out_folder
                if($null -ne $job_folder){
                    $out_file = ("{0}/MonkeyOutput" -f $job_folder.FullName)
                    Out-Compress -InputObject $MonkeyExportObject -outFile $out_file
                    if($null -ne $MonkeyExportObject.Subscription){
                        $subscriptionName = $MonkeyExportObject.Subscription.displayName
                    }
                    else{
                        $subscriptionName = $null;
                    }
                    if($null -ne $MonkeyExportObject.IncludeAAD -and $MonkeyExportObject.IncludeAAD){
                        $includeAAD = $True
                    }
                    else{
                        $includeAAD = $false
                    }
                    $metadata = [ordered]@{
                        projectId = [System.Guid]::NewGuid().Guid;
                        subscriptionName = $subscriptionName;
                        tenantID = $MonkeyExportObject.TenantID;
                        tenantName = $MonkeyExportObject.Tenant.TenantName;
                        subscriptionId = $MonkeyExportObject.Subscription.subscriptionId;
                        raw_data = $out_file;
                        Instance = $MonkeyExportObject.Instance;
                        IncludeAAD = $includeAAD;
                        jobFolder = $Script:Report;
                        date = (Get-Date).ToUniversalTime().ToString();
                    }
                    #Out to file
                    ConvertTo-Json -InputObject $metadata | `
                    Out-File -FilePath ("{0}/monkey365.json" -f $job_folder.FullName)
                }
            }
        }
    }
    Process{
        ###########################Report Options####################################
        #Prepare data and export results to multiple formats
        if($null -ne $O365Object.exportTo){
            $allowedReports = @("json","csv",'clixml','excel','html')
            $params = @{
                ReferenceObject = $O365Object.exportTo;
                DifferenceObject = $allowedReports;
                IncludeEqual= $true;
                ExcludeDifferent = $true;
            }
            $shouldExport = Compare-Object @params
            if($shouldExport -and $MonkeyExportObject.Output.psobject.Properties.GetEnumerator().moveNext()){
                if ($null -eq (Get-Variable 'Report' -Scope Script -ErrorAction 'Ignore')){
                    $ReportPath = New-MonkeyReportDir -OutDir $O365Object.outDir
		            if($ReportPath){
	                    Set-Variable -Name Report -Value $ReportPath -Scope Script
                    }
                }
            }
            #Export data into selected format
            foreach($exportTo in $O365Object.exportTo.GetEnumerator()){
                If($exportTo.ToLower() -eq "print"){
                    Export-MonkeyData -ExportTo $exportTo
                }
                elseif($null -ne (Get-Variable -Name Report -ErrorAction Ignore)){
                    $out_folder = ('{0}/{1}' -f $Script:Report, $exportTo.ToLower())
                    $job_folder = New-MonkeyFolder -destination $out_folder
                    if($job_folder){
                        $params = @{
                            #Dataset = $MonkeyExportObject.Output;
                            ExportTo = $exportTo;
                            OutDir = $job_folder;
                        }
                        Export-MonkeyData @params
                    }
                }
            }
        }
    }
    End{
    }
}
