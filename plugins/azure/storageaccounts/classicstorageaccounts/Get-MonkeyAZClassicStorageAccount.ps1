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


Function Get-MonkeyAZClassicStorageAccount{
    <#
        .SYNOPSIS
		Plugin to get Classic Storage Account information from Azure

        .DESCRIPTION
		Plugin to get Classic Storage Account information from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZClassicStorageAccount
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Service Management Auth
        $sm_auth = $O365Object.auth_tokens.ServiceManagement
        #Get Config
        $classicStorageConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureClassicStorage"} | Select-Object -ExpandProperty resource
        #Get from resources
        $storageAccounts = $O365Object.all_resources | Where-Object {$_.type -match 'Microsoft.ClassicStorage/storageAccounts'}
        if(-NOT $storageAccounts){continue}
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure classic storage accounts", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureClassicStorageAccountInfo');
        }
        Write-Information @msg
        if($storageAccounts){
            #Create array
            $AllClassicStorageAccounts = @()
            #Get info for each storage account
            foreach($str in $storageAccounts){
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$str.id, `
                            $classicStorageConfig.api_version)
                #Launch query
                $params = @{
                    Authentication = $sm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $storageAccount = Get-MonkeyRMObject @params
                #Get Data
                $new_str_account = New-Object -TypeName PSCustomObject
                $new_str_account | Add-Member -type NoteProperty -name id -value $str.id
                $new_str_account | Add-Member -type NoteProperty -name name -value $str.name
                $new_str_account | Add-Member -type NoteProperty -name location -value $str.location
                $new_str_account | Add-Member -type NoteProperty -name properties -value $str.properties
                $new_str_account | Add-Member -type NoteProperty -name creationTime -value $storageAccount.properties.creationTime
                $new_str_account | Add-Member -type NoteProperty -name accountType -value $storageAccount.properties.accountType
                $new_str_account | Add-Member -type NoteProperty -name geoPrimaryRegion -value $storageAccount.properties.geoPrimaryRegion
                $new_str_account | Add-Member -type NoteProperty -name statusOfPrimaryRegion -value $storageAccount.properties.statusOfPrimaryRegion
                $new_str_account | Add-Member -type NoteProperty -name geoSecondaryRegion -value $storageAccount.properties.geoSecondaryRegion
                $new_str_account | Add-Member -type NoteProperty -name statusOfSecondaryRegion -value $storageAccount.properties.statusOfSecondaryRegion
                $new_str_account | Add-Member -type NoteProperty -name provisioningState -value $storageAccount.properties.provisioningState
                $new_str_account | Add-Member -type NoteProperty -name rawObject -value $storageAccount
                #Get Endpoints
                $queue = $storageAccount.properties.endpoints | Where-Object {$_ -like "*queue*"}
                $table = $storageAccount.properties.endpoints | Where-Object {$_ -like "*table*"}
                $file = $storageAccount.properties.endpoints | Where-Object {$_ -like "*file*"}
                $blob = $storageAccount.properties.endpoints | Where-Object {$_ -like "*blob*"}
                #Add to object
                $new_str_account | Add-Member -type NoteProperty -name queueEndpoint -value $queue
                $new_str_account | Add-Member -type NoteProperty -name tableEndpoint -value $table
                $new_str_account | Add-Member -type NoteProperty -name fileEndpoint -value $file
                $new_str_account | Add-Member -type NoteProperty -name blobEndpoind -value $blob
                #End endpoints
                $new_str_account | Add-Member -type NoteProperty -name status -value $storageAccount.properties.status
                #Get Storage account keys
                $URI = ("{0}{1}/listKeys?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$str.id, `
                            $classicStorageConfig.api_version)
                $params = @{
                    Authentication = $sm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Headers = @{'x-ms-version' = '2020-02-10'}
                    Method = "POST";
                }
                $strkeys = Get-MonkeyRMObject @params
                if($strkeys.primaryKey){
                    #Get Shared Access Signature
                    $QueueSAS = Get-SASUri -HostName $queue -accessKey $strkeys.primaryKey
                    if($QueueSAS){
                        #Get Queue diagnostig settings
                        $params = @{
                            Url = $QueueSAS;
                            Method = "GET";
                            UserAgent = $O365Object.UserAgent;
                        }
                        [xml]$QueueDiagSettings = Invoke-UrlRequest @params
                        if($QueueDiagSettings){
                            #Add to psobject
                            $new_str_account | Add-Member -type NoteProperty -name queueLogVersion -value $QueueDiagSettings.StorageServiceProperties.Logging.Version
                            $new_str_account | Add-Member -type NoteProperty -name queueLogReadEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Read
                            $new_str_account | Add-Member -type NoteProperty -name queueLogWriteEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Write
                            $new_str_account | Add-Member -type NoteProperty -name queueLogDeleteEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Delete
                            $new_str_account | Add-Member -type NoteProperty -name queueRetentionPolicyEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                            if($QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                $new_str_account | Add-Member -type NoteProperty -name queueRetentionPolicyDays -value $QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                            }
                            else{
                                $new_str_account | Add-Member -type NoteProperty -name queueRetentionPolicyDays -value $null
                            }
                        }
                    }
                    #Get Shared Access Signature
                    $tableSAS = Get-SASUri -HostName $table -accessKey $strkeys.primaryKey
                    if($tableSAS){
                        #Get Queue diagnostig settings
                        $params = @{
                            Url = $tableSAS;
                            Method = "GET";
                            UserAgent = $O365Object.UserAgent;
                        }
                        [xml]$TableDiagSettings = Invoke-UrlRequest @params
                        if($TableDiagSettings){
                            #Add to psobject
                            $new_str_account | Add-Member -type NoteProperty -name tableLogVersion -value $TableDiagSettings.StorageServiceProperties.Logging.Version
                            $new_str_account | Add-Member -type NoteProperty -name tableLogReadEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Read
                            $new_str_account | Add-Member -type NoteProperty -name tableLogWriteEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Write
                            $new_str_account | Add-Member -type NoteProperty -name tableLogDeleteEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Delete
                            $new_str_account | Add-Member -type NoteProperty -name tableRetentionPolicyEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                            if($TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                $new_str_account | Add-Member -type NoteProperty -name tableRetentionPolicyDays -value $TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                            }
                            else{
                                $new_str_account | Add-Member -type NoteProperty -name tableRetentionPolicyDays -value $null
                            }
                        }
                    }
                    #Get Shared Access Signature
                    $fileSAS = Get-SASUri -HostName $file -accessKey $strkeys.primaryKey `

                    if($fileSAS){
                        #Get Queue diagnostig settings
                        $params = @{
                            Url = $fileSAS;
                            Method = "GET";
                            UserAgent = $O365Object.UserAgent;
                        }
                        [xml]$FileDiagSettings = Invoke-UrlRequest @params
                        if($FileDiagSettings){
                            #Add to psobject
                            $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsVersion -value $FileDiagSettings.StorageServiceProperties.HourMetrics.Version
                            $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsEnabled -value $FileDiagSettings.StorageServiceProperties.HourMetrics.Enabled
                            $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsIncludeAPIs -value $FileDiagSettings.StorageServiceProperties.HourMetrics.IncludeAPIs
                            $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyEnabled -value $FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Enabled
                            if($FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Days){
                                $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyDays -value $FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Days
                            }
                            else{
                                $new_str_account | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyDays -value $null
                            }
                            #Add to psobject
                            $new_str_account | Add-Member -type NoteProperty -name fileMinuteMetricsVersion -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.Version
                            $new_str_account | Add-Member -type NoteProperty -name fileMinuteMetricsEnabled -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.Enabled
                            $new_str_account | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyEnabled -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Enabled
                            if($FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Days){
                                $new_str_account | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyDays -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Days
                            }
                            else{
                                $new_str_account | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyDays -value $null
                            }
                        }
                    }
                    #Get Shared Access Signature
                    $blobSAS = Get-SASUri -HostName $blob -accessKey $strkeys.primaryKey `

                    if($blobSAS){
                        #Get Blob diagnostig settings
                        $params = @{
                            Url = $blobSAS;
                            Method = "GET";
                            UserAgent = $O365Object.UserAgent;
                        }
                        [xml]$BlobDiagSettings = Invoke-UrlRequest @params
                        if($BlobDiagSettings){
                            #Add to psobject
                            $new_str_account | Add-Member -type NoteProperty -name blobLogVersion -value $BlobDiagSettings.StorageServiceProperties.Logging.Version
                            $new_str_account | Add-Member -type NoteProperty -name blobLogReadEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Read
                            $new_str_account | Add-Member -type NoteProperty -name blobLogWriteEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Write
                            $new_str_account | Add-Member -type NoteProperty -name blobLogDeleteEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Delete
                            $new_str_account | Add-Member -type NoteProperty -name blobRetentionPolicyEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                            if($BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                $new_str_account | Add-Member -type NoteProperty -name blobRetentionPolicyDays -value $BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                            }
                            else{
                                $new_str_account | Add-Member -type NoteProperty -name blobRetentionPolicyDays -value $null
                            }
                        }
                    }
                }
                #Add to array
                $AllClassicStorageAccounts+= $new_str_account
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoClassicStorageAccounts -f $O365Object.current_subscription.DisplayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureClassicStorageAccountInfo');
            }
            Write-Warning @msg
            break;
        }
    }
    End{
        if($AllClassicStorageAccounts){
            $AllClassicStorageAccounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicStorageAccounts')
            [pscustomobject]$obj = @{
                Data = $AllClassicStorageAccounts
            }
            $returnData.az_classic_storage_accounts = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Classic storage accounts", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureClassicStorageAccountEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
