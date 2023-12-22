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

function Get-MonkeyAzMissingPatchesForVM{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzMissingPatchesForVM
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(HelpMessage="VM")]
        [object]$vm
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
    }
    Process{
        #https://docs.microsoft.com/en-us/azure/automation/update-management/query-logs
        $query = ("set query_take_max_records=10001;set truncationmaxsize=67108864;\nUpdate | where TimeGenerated>ago(14h) and Computer contains '{0}' and UpdateState =~ 'Needed'" -f $vm.name)
        $requestBody = @{"query" = $query;}
        #Convert to JSON data
        $MissingUpdatesJSON = $requestBody | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        #Construct Query
        $WorkSpacePath = $vm.properties.resourceDetails | Where-Object {$_.name -eq 'Reporting workspace azure id'} | Select-Object -ExpandProperty value
    }
    End{
        if($WorkSpacePath){
            $URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $WorkSpacePath, "api/query","2017-01-01-preview")
            try{
                #POST Request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "POST";
                    Data = $MissingUpdatesJSON;
                }
                $MissingPatches = Get-MonkeyRMObject @params
                $columns = $MissingPatches.tables | Where-Object {$_.TableName -eq 'Table_0'} | Select-Object -ExpandProperty Columns
                $rows = $MissingPatches.tables | Where-Object {$_.TableName -eq 'Table_0'} | Select-Object -ExpandProperty Rows
                if($rows -and $columns){
                    foreach ($update in $rows){
                        $MonkeyMissingPatchObj = New-Object -TypeName PSCustomObject
                        $MonkeyMissingPatchObj | Add-Member -type NoteProperty -name ServerName -value $vm.name
                        $MonkeyMissingPatchObj | Add-Member -type NoteProperty -name Id -value $vm.id
                        $MonkeyMissingPatchObj | Add-Member -type NoteProperty -name ResourceGroupName -value $vm.id.Split("/")[4]
                        for ($counter=0; $counter -lt $update.Length; $counter++){
                            if($columns[$counter].ColumnName -eq 'KBID'){
                                $MonkeyMissingPatchObj | Add-Member -type NoteProperty -name KBID -value ("https://support.microsoft.com/en-us/help/{0}" -f $update[$counter])
                            }
                            else{
                                $MonkeyMissingPatchObj | Add-Member -type NoteProperty -name $columns[$counter].ColumnName -value $update[$counter]
                            }
                        }
                        [void]$AllMissingPatches.Add($MonkeyMissingPatchObj)
                    }
                }
            }
            catch{
                $msg = @{
                    MessageData = ($message.UnableToCreateQuery -f $vm.name);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'error';
                    InformationAction = $InformationAction;
                    Tags = @('AzureVMInfo');
                }
                Write-Verbose @msg
                #Debug
                $msg = @{
                    MessageData = $_;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $InformationAction;
                    Tags = @('AzureVMInfo');
                }
                Write-Debug @msg

            }
        }
        else{
            $msg = @{
                MessageData = ($message.WorkSpaceIdNotFound -f $vm.name);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $InformationAction;
                Tags = @('AzureVMInfo');
            }
            Write-Verbose @msg
        }
    }
}
