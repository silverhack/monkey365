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

Function Import-MonkeyJob{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-MonkeyJob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        #Set O365Instance to null
        $O365Object.Instance = $null
        $selected_job = $null;
        $raw_data = $null;
        $allJobs = @()
        if (!(Test-Path -Path $MyParams.OutDir)){
            Write-Warning ("{0} does not exists" -f $MyParams.OutDir)
            return
        }
        $all_files = [System.IO.Directory]::EnumerateFiles($MyParams.OutDir,"*.json","AllDirectories")
        $all_jobs_metadata = $all_files.Where({$_ -like "*monkey365.json*"})
        $allJobs = $all_jobs_metadata.ForEach({[System.IO.File]::ReadAllText($_, [Text.Encoding]::UTF8) | ConvertFrom-Json})
    }
    Process{
        if($allJobs.Count -ge 1){
            if($PSEdition -eq "Desktop"){
                $selected_job = $allJobs | Sort-Object {[system.datetime]::parse($_.date)} -Descending | Out-GridView -Title "Choose a job ..." -OutputMode Single
                if($selected_job){
                    Write-Information ("You have selected {0} job" -f $selected_job.projectId) -InformationAction $InformationAction
                }
            }
            else{
                $selected_job = Import-MonkeyJobConsole -Jobs $allJobs
            }
        }
        #Read data
        if($selected_job){
            $raw_data = Read-Compress -Filename $selected_job.raw_data
        }
    }
    End{
        if($null -ne $raw_data){
            #Set new O365Object
            $MyParams.Instance = $raw_data.Instance;
            $MyParams.IncludeEntraID = $raw_data.IncludeEntraID;
            #Create O365 object
            New-O365Object
            try{
                if($raw_data.Instance -eq 'Azure'){
                    $O365Object.Environment = $raw_data.Environment;
                    $O365Object.cloudEnvironment = $raw_data.cloudEnvironment;
                    $O365Object.startDate = $raw_data.StartDate;
                    $O365Object.Tenant = $raw_data.Tenant;
                    $O365Object.TenantId = $raw_data.TenantId;
                    $O365Object.current_subscription = $raw_data.Subscription;
                    $O365Object.Collectors = $raw_data.Collectors;
                    $O365Object.Instance = $raw_data.Instance;
                    $O365Object.IncludeEntraID = $raw_data.IncludeEntraID;
                    $O365Object.aadpermissions = $raw_data.aadpermissions;
                    $O365Object.executionInfo = $raw_data.executionInfo;
                    $O365Object.all_resources = $raw_data.allResources;
                }
                else{
                    $O365Object.Environment = $raw_data.Environment;
                    $O365Object.cloudEnvironment = $raw_data.cloudEnvironment;
                    $O365Object.startDate = $raw_data.StartDate;
                    $O365Object.Tenant = $raw_data.Tenant;
                    $O365Object.TenantId = $raw_data.TenantId;
                    $O365Object.Collectors = $raw_data.Collectors;
                    $O365Object.Instance = $raw_data.Instance;
                    $O365Object.IncludeEntraID = $raw_data.IncludeEntraID;
                    $O365Object.aadpermissions = $raw_data.aadpermissions;
                    $O365Object.executionInfo = $raw_data.executionInfo;
                }
                #Set new variables
                Set-Variable returnData -Value $raw_data.Output -Scope Script -Force
                Set-Variable Report -Value $selected_job.jobFolder -Scope Script -Force
                Out-MonkeyData -OutData $Script:returnData
            }
            catch{
                $msg = @{
                    MessageData = ("Unable to import job");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $script:InformationAction;
                    Tags = @('UnableToImportJob');
                }
                Write-Warning @msg
                $msg = @{
                    MessageData = ($_.Exception);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $script:InformationAction;
                    Tags = @('UnableToImportJob');
                }
                Write-Verbose @msg
                $msg = @{
                    MessageData = ($_.Exception.StackTrace);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $script:InformationAction;
                    Tags = @('UnableToImportJob');
                }
                Write-Debug @msg
            }
        }
    }
}

