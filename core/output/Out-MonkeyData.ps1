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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PsUseDeclaredVarsMoreThanAssignments", "", Scope="Function")]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True,HelpMessage="Binary data")]
        [Object]$OutData
    )
    Process{
        try{
            #Get provider
            $provider = $O365Object.Instance
            if($null -eq $provider -and $O365Object.IncludeEntraID){
                $provider = 'EntraID'
            }
            #Get export object
            $MonkeyExportObject = New-O365ExportObject -Provider $provider
            #Create report folder
            if(($O365Object.saveProject -or $null -ne $O365Object.exportTo -or $O365Object.exportTo.Where({$_.ToLower() -ne 'print'}).Count -gt 0) -and ($null -eq $O365Object.initParams.ImportJob)){
                #Set a new path for report folder
                $_path = ("{0}/{1}" -f $O365Object.OutDir,(New-MonkeyGuid))
                $ReportPath = New-MonkeyFolder -destination $_path
                Set-Variable -Name Report -Value $ReportPath.FullName -Scope Script -Force
                #Write verbose message
                $msg = @{
                    MessageData = ($message.ProjectDirectoryInfoMessage -f $ReportPath.FullName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365DirectoryInfo');
                }
                Write-Verbose @msg
            }
            #Prepare data and export entire job to a file
            if($O365Object.saveProject -and $OutData.Keys.GetEnumerator().moveNext()){
                $metadata = New-MetadataObject -Provider $provider
                #Write info message
                $msg = @{
                    MessageData = ($message.MetadataInfoMessage -f $provider);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365MetadataInfo');
                }
                Write-Verbose @msg
                #Set job folder
                $out_folder = ('{0}/MonkeyJob' -f $ReportPath)
                $job_folder = New-MonkeyFolder -destination $out_folder
                #Write info message
                $msg = @{
                    MessageData = ($message.ProjectDirectoryInfoMessage -f $out_folder);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365DirectoryInfo');
                }
                Write-Verbose @msg
                $out_file = ("{0}/MonkeyOutput" -f $job_folder.FullName)
                #Write verbose message
                $msg = @{
                    MessageData = ($message.SaveDataToInfoMessage -f $out_file);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365DirectoryInfo');
                }
                Write-Verbose @msg
                #Save file
                Out-Gzip -InputObject $MonkeyExportObject -outFile $out_file
                #Add out_file and report to metadata
                $metadata.raw_data = $out_file;
                $metadata.jobFolder = $Script:Report;
                $jobFileName = ("{0}/monkey365.json" -f $job_folder.FullName);
                #Write verbose message
                $msg = @{
                    MessageData = ($message.SaveDataToInfoMessage -f $jobFileName);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365DirectoryInfo');
                }
                Write-Verbose @msg
                #Out to file
                ConvertTo-Json -InputObject $metadata | `
                Out-File -FilePath $jobFileName
            }
            #Export data into selected format
            if($null -ne $O365Object.exportTo){
                #Get matched rules
                if($null -ne $O365Object.ruleset -and $null -ne $O365Object.rulesPath){
                    #Flat internal object
                    $dataset = [ordered]@{}
                    foreach($elem in $MonkeyExportObject.Output.GetEnumerator()){
                        [void]$dataset.Add($elem.Key,$elem.Value.Data)
                    }
                    $dataset = New-Object -TypeName PSCustomObject -Property $dataset
                    if($dataset){
                        $p = @{
                            Ruleset = $O365Object.ruleset;
                            RulesPath = $O365Object.rulesPath;
                            Verbose = $O365Object.verbose;
                            InformationAction = $O365Object.InformationAction;
                            Debug = $O365Object.debug;
                        }
                        $matchedRules = Invoke-RuleScan -InputObject $dataset @p
                    }
                }
                foreach($exportTo in $O365Object.exportTo.GetEnumerator()){
                    Export-MonkeyData -ExportTo $exportTo
                }
            }
            if($MyParams.Compress -and $null -ne (Get-Variable -Name Report -Scope Script -ErrorAction Ignore)){
                if (-not ([System.Management.Automation.PSTypeName]'System.IO.Compression').Type){
                    Add-Type -Assembly 'System.IO.Compression'
                }
                $all_files = Get-MonkeyFile -Path $Script:Report -Pattern * -Recurse
                if($all_files){
                    #Set file name
                    $zipFileName = ("Monkey365-{0:yyyy-MM-dd_hh-mm-ss-tt}.zip" -f [Datetime]::Now)
                    #Create zip folder
                    $out_zip = ('{0}/zip' -f $Script:Report)
                    $zip_folder = New-MonkeyFolder -destination $out_zip
                    $msg = @{
                        MessageData = ($message.CompressingJob -f $zip_folder);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('Monkey365ZipDirectoryInfo');
                    }
                    Write-Verbose @msg
                    #Compress data
                    Out-ZipFile -InputObject $all_files -Path $zip_folder -ZipFile $zipFileName
                }
            }
        }
        catch{
            Write-Error $_
        }
        Finally{
            #Remove Report variable
            if($null -ne (Get-Variable -Name Report -Scope Script -ErrorAction Ignore)){
                Remove-Variable -Name Report -Scope Script -Force
            }
            #Remove dataset
            Remove-Variable -Name dataset -Force -ErrorAction Ignore
            #Remove matched rules
            Remove-Variable -Name matchedRules -Force -ErrorAction Ignore
        }
    }
}
