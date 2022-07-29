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




Function Get-MonkeyAZStorageAccount{
    <#
        .SYNOPSIS
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .DESCRIPTION
		Plugin extract Storage Account information from Azure
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-https-stor-acct
        https://docs.microsoft.com/en-us/azure/azure-policy/scripts/ensure-store-file-enc

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZStorageAccount
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
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Azure Storage Auth
        $StorageAuth = $O365Object.auth_tokens.AzureStorage
        #Get Config
        $AzureStorageAccountConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureStorage"} | Select-Object -ExpandProperty resource
        #Get Storage accounts
        $storage_accounts = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Storage/storageAccounts'}
        if(-NOT $storage_accounts){continue}
        #Set arrays
        $AllStorageAccounts = @()
        $AllStorageAccountsPublicBlobs= @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Storage accounts", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureStorageAccountsInfo');
        }
        Write-Information @msg
        #Get all alerts
        $current_date = [datetime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $90_days = [datetime]::Now.AddDays(-89).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $tmp_filter = ("eventTimestamp ge \'{0}\' and eventTimestamp le \'{1}\'" -f $90_days, $current_date)
        $filter = [System.Text.RegularExpressions.Regex]::Unescape($tmp_filter)
        $URI = ('{0}{1}/providers/microsoft.insights/eventtypes/management/values?api-Version={2}&$filter={3}' `
                -f $O365Object.Environment.ResourceManager,$O365Object.current_subscription.id,'2017-03-01-preview', $filter)

        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $URI;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        $all_alerts = Get-MonkeyRMObject @params
        if($storage_accounts){
            foreach($str_account in $storage_accounts){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $str_account.name, "Storage account");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureStorageAccountInfo');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager, `
                            $str_account.id,$AzureStorageAccountConfig.api_version)

                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $StorageAccount = Get-MonkeyRMObject @params
                if($StorageAccount.id){
                    $msg = @{
                        MessageData = ($message.StorageAccountFoundMessage -f $StorageAccount.name, $StorageAccount.location);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $InformationAction;
                        Tags = @('AzureStorageAccountInfo');
                    }
                    Write-Verbose @msg
                    #Get Key rotation info
                    $last_rotation_dates = $all_alerts | Where-Object {$_.resourceId -eq $StorageAccount.id -and $_.authorization.action -eq "Microsoft.Storage/storageAccounts/regenerateKey/action" -and $_.status.localizedValue -eq "Succeeded"} | Select-Object -ExpandProperty eventTimestamp
                    $last_rotated_date = $last_rotation_dates | Select-Object -First 1
                    #Iterate through properties
                    foreach ($properties in $StorageAccount.properties){
                        $StrAccount = New-Object -TypeName PSCustomObject
                        $StrAccount | Add-Member -type NoteProperty -name id -value $StorageAccount.id
                        $StrAccount | Add-Member -type NoteProperty -name name -value $StorageAccount.name
                        $StrAccount | Add-Member -type NoteProperty -name location -value $StorageAccount.location
                        $StrAccount | Add-Member -type NoteProperty -name tags -value $StorageAccount.tags
                        $StrAccount | Add-Member -type NoteProperty -name rawObject -value $StorageAccount
                        $StrAccount | Add-Member -type NoteProperty -name properties -value $properties
                        $StrAccount | Add-Member -type NoteProperty -name ResourceGroupName -value $StorageAccount.id.Split("/")[4]
                        $StrAccount | Add-Member -type NoteProperty -name Kind -value $StorageAccount.kind
                        $StrAccount | Add-Member -type NoteProperty -name SkuName -value $StorageAccount.sku.name
                        $StrAccount | Add-Member -type NoteProperty -name SkuTier -value $StorageAccount.sku.tier
                        $StrAccount | Add-Member -type NoteProperty -name CreationTime -value $properties.creationTime
                        $StrAccount | Add-Member -type NoteProperty -name primaryLocation -value $properties.primaryLocation
                        $StrAccount | Add-Member -type NoteProperty -name statusofPrimary -value $properties.statusOfPrimary
                        $StrAccount | Add-Member -type NoteProperty -name supportsHttpsTrafficOnly -value $properties.supportsHttpsTrafficOnly
                        $StrAccount | Add-Member -type NoteProperty -name blobEndpoint -value $properties.primaryEndpoints.blob
                        $StrAccount | Add-Member -type NoteProperty -name queueEndpoint -value $properties.primaryEndpoints.queue
                        $StrAccount | Add-Member -type NoteProperty -name tableEndpoint -value $properties.primaryEndpoints.table
                        $StrAccount | Add-Member -type NoteProperty -name fileEndpoint -value $properties.primaryEndpoints.file
                        $StrAccount | Add-Member -type NoteProperty -name webEndpoint -value $properties.primaryEndpoints.web
                        $StrAccount | Add-Member -type NoteProperty -name dfsEndpoint -value $properties.primaryEndpoints.dfs
                        #Translate Key rotation info
                        if($last_rotation_dates.count -ge 2){
                            $StrAccount | Add-Member -type NoteProperty -name isKeyRotated -value $true
                            $StrAccount | Add-Member -type NoteProperty -name lastRotatedKeys -value $last_rotated_date
                        }
                        else{
                            $StrAccount | Add-Member -type NoteProperty -name isKeyRotated -value $false
                            $StrAccount | Add-Member -type NoteProperty -name lastRotatedKeys -value $null
                        }
                        #Check if using Own key
                        if($properties.encryption.keyvaultproperties){
                            $StrAccount | Add-Member -type NoteProperty -name keyvaulturi -value $properties.encryption.keyvaultproperties.keyvaulturi
                            $StrAccount | Add-Member -type NoteProperty -name keyname -value $properties.encryption.keyvaultproperties.keyname
                            $StrAccount | Add-Member -type NoteProperty -name keyversion -value $properties.encryption.keyvaultproperties.keyversion
                            $StrAccount | Add-Member -type NoteProperty -name usingOwnKey -value $true
                        }
                        else{
                            $StrAccount | Add-Member -type NoteProperty -name usingOwnKey -value $false
                        }
                        #Getting storage service conf
                        $str_service_uri = ("https://{0}.blob.core.windows.net?restype=service&comp=properties" -f $StorageAccount.name)
                        $params = @{
                            Authentication = $StorageAuth;
                            OwnQuery = $str_service_uri;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Headers = @{'x-ms-version' = '2020-08-04'}
                            Method = "GET";
                        }
                        [xml]$str_service_data = Get-MonkeyRMObject @params
                        if($str_service_data){
                            #Get logging properties
                            $str_logging = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty Logging
                            #Get deletion retention policy
                            $str_deleteRetentionPolicy = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty deleteRetentionPolicy
                            #Get CORS
                            $str_cors = $str_service_data.StorageServiceProperties | Select-Object -ExpandProperty Cors
                            #Add to storage account object
                            if($str_cors){
                                $StrAccount | Add-Member -type NoteProperty -name cors -value $str_cors
                            }
                            if($str_deleteRetentionPolicy){
                                $StrAccount | Add-Member -type NoteProperty -name deleteRetentionPolicy -value $str_deleteRetentionPolicy
                            }
                            #Add logging
                            if($str_logging){
                                $StrAccount | Add-Member -type NoteProperty -name logging -value $str_logging
                            }
                        }
                        #Search for public blobs
                        #If no public blobs were returned the request will raise a HTTP/1.1 403 AuthorizationPermissionMismatch
                        $blob_container_uri = ("https://{0}.blob.core.windows.net?restype=container&comp=list" -f $StorageAccount.name)
                        $params = @{
                            Authentication = $StorageAuth;
                            OwnQuery = $blob_container_uri;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Headers = @{'x-ms-version' = '2020-08-04'}
                            Method = "GET";
                        }
                        [xml]$blobs = Get-MonkeyRMObject @params
                        $all_blobs = $blobs.EnumerationResults.Containers.Container #| Where-Object {$_.Properties.PublicAccess}
                        if($all_blobs){
                            foreach($public_container in $all_blobs){
                                $container = New-Object -TypeName PSCustomObject
                                $container | Add-Member -type NoteProperty -name storageaccount -value $StorageAccount.name
                                $container | Add-Member -type NoteProperty -name containername -value $public_container.name
                                $container | Add-Member -type NoteProperty -name blobname -value $public_container.name
                                $container | Add-Member -type NoteProperty -name rawObject -value $public_container
                                if($public_container.properties.publicaccess){
                                    $container | Add-Member -type NoteProperty -name publicaccess -value $public_container.properties.publicaccess
                                }
                                else{
                                    $container | Add-Member -type NoteProperty -name publicaccess -value "private"
                                }
                                #Add to array
                                $AllStorageAccountsPublicBlobs+=$container
                            }
                        }
                        #Get Encryption Status
                        if($properties.encryption.services.blob){
                            $StrAccount | Add-Member -type NoteProperty -name isBlobEncrypted -value $properties.encryption.services.blob.enabled
                            $StrAccount | Add-Member -type NoteProperty -name lastBlobEncryptionEnabledTime -value $properties.encryption.services.blob.lastEnabledTime
                        }
                        if($properties.encryption.services.file){
                            $StrAccount | Add-Member -type NoteProperty -name isFileEncrypted -value $properties.encryption.services.file.enabled
                            $StrAccount | Add-Member -type NoteProperty -name lastFileEnabledTime -value $properties.encryption.services.file.lastEnabledTime
                        }
                        else{
                            $StrAccount | Add-Member -type NoteProperty -name isEncrypted -value $false
                            $StrAccount | Add-Member -type NoteProperty -name lastEnabledTime -value $false
                        }
                        #Get Network Configuration Status
                        if($properties.networkAcls){
                            $fwconf = $properties.networkAcls
                            if($fwconf.bypass -eq 'AzureServices'){
                                $StrAccount | Add-Member -type NoteProperty -name AllowAzureServices -value $true
                            }
                            else{
                                $StrAccount | Add-Member -type NoteProperty -name AllowAzureServices -value $false
                            }
                            if(-NOT $fwconf.virtualNetworkRules -AND -NOT $fwconf.ipRules -AND $fwconf.defaultAction -eq 'Allow'){
                                $StrAccount | Add-Member -type NoteProperty -name AllowAccessFromAllNetworks -value $true
                            }
                            else{
                                $StrAccount | Add-Member -type NoteProperty -name AllowAccessFromAllNetworks -value $false
                            }
                        }
                        #Get Data protection for storage account
                        $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $StorageAccount.id, "blobServices/default", "2021-06-01")
                        $param = @{
                            Authentication = $rm_auth;
                            OwnQuery = $uri;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Headers = @{'x-ms-version' = '2020-08-04'}
                            Method = "GET";
                        }
                        $storage_data_protection = Get-MonkeyRMObject @param
                        if($storage_data_protection){
                            $StrAccount | Add-Member -type NoteProperty -name dataProtection -value $storage_data_protection
                        }
                        #Get ATP for Storage Account
                        $uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $StorageAccount.id, "providers/Microsoft.Security/advancedThreatProtectionSettings/current", "2017-08-01-preview")
                        $params = @{
                            Authentication = $rm_auth;
                            OwnQuery = $uri;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Headers = @{'x-ms-version' = '2020-08-04'}
                            Method = "GET";
                        }
                        $StrAccountATPInfo = Get-MonkeyRMObject @params
                        if($StrAccountATPInfo){
                            $StrAccount | Add-Member -type NoteProperty -name AdvancedProtectionEnabled -value $StrAccountATPInfo.properties.isEnabled
                            $StrAccount | Add-Member -type NoteProperty -name ATPRawObject -value $StrAccountATPInfo
                        }
                        #Get Diagnostic data for storage account
                        $URI_keys = ("{0}{1}/listKeys?api-version={2}" -f $O365Object.Environment.ResourceManager, `
                                                                        $StorageAccount.id,
                                                                        $AzureStorageAccountConfig.api_version)
                        $params = @{
                            Authentication = $rm_auth;
                            OwnQuery = $URI_keys;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Headers = @{'x-ms-version' = '2020-08-04'}
                            Method = "POST";
                        }
                        $strkeys = Get-MonkeyRMObject @params
                        #get key1
                        $key1 = $strkeys.keys | Where-Object {$_.keyName -eq 'key1'} | Select-Object -ExpandProperty value
                        if($key1){
                            $queueEndpoint = $properties.primaryEndpoints.queue
                            $blobEndpoint = $properties.primaryEndpoints.blob
                            $tableEndpoint = $properties.primaryEndpoints.table
                            $fileEndpoint = $properties.primaryEndpoints.file
                            #Get Shared Access Signature
                            $QueueSAS = Get-SASUri -HostName $queueEndpoint -accessKey $key1
                            if($QueueSAS){
                                #Get Queue diagnostig settings
                                $params = @{
                                    Url = $QueueSAS;
                                    Method = "GET";
                                    UserAgent = $O365Object.UserAgent;
                                    Headers = @{'x-ms-version' = '2020-08-04'}
                                }
                                [xml]$QueueDiagSettings = Invoke-UrlRequest @params
                                if($QueueDiagSettings){
                                    #Add to psobject
                                    $StrAccount | Add-Member -type NoteProperty -name queueLogVersion -value $QueueDiagSettings.StorageServiceProperties.Logging.Version
                                    $StrAccount | Add-Member -type NoteProperty -name queueLogReadEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Read
                                    $StrAccount | Add-Member -type NoteProperty -name queueLogWriteEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Write
                                    $StrAccount | Add-Member -type NoteProperty -name queueLogDeleteEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.Delete
                                    $StrAccount | Add-Member -type NoteProperty -name queueRetentionPolicyEnabled -value $QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                                    if($QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                        $StrAccount | Add-Member -type NoteProperty -name queueRetentionPolicyDays -value $QueueDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                                    }
                                    else{
                                        $StrAccount | Add-Member -type NoteProperty -name queueRetentionPolicyDays -value $null
                                    }
                                }
                            }
                            #Get Shared Access Signature
                            $tableSAS = Get-SASUri -HostName $tableEndpoint -accessKey $key1
                            if($tableSAS){
                                #Get Queue diagnostig settings
                                $params = @{
                                    Url = $tableSAS;
                                    Method = "GET";
                                    UserAgent = $O365Object.UserAgent;
                                    Headers = @{'x-ms-version' = '2020-08-04'}
                                }
                                [xml]$TableDiagSettings = Invoke-UrlRequest @params
                                if($TableDiagSettings){
                                    #Add to psobject
                                    $StrAccount | Add-Member -type NoteProperty -name tableLogVersion -value $TableDiagSettings.StorageServiceProperties.Logging.Version
                                    $StrAccount | Add-Member -type NoteProperty -name tableLogReadEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Read
                                    $StrAccount | Add-Member -type NoteProperty -name tableLogWriteEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Write
                                    $StrAccount | Add-Member -type NoteProperty -name tableLogDeleteEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.Delete
                                    $StrAccount | Add-Member -type NoteProperty -name tableRetentionPolicyEnabled -value $TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                                    if($TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                        $StrAccount | Add-Member -type NoteProperty -name tableRetentionPolicyDays -value $TableDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                                    }
                                    else{
                                        $StrAccount | Add-Member -type NoteProperty -name tableRetentionPolicyDays -value $null
                                    }
                                }
                            }
                            #Get Shared Access Signature
                            $fileSAS = Get-SASUri -HostName $fileEndpoint -accessKey $key1
                            if($fileSAS){
                                #Get Queue diagnostig settings
                                $params = @{
                                    Url = $fileSAS;
                                    Method = "GET";
                                    UserAgent = $O365Object.UserAgent;
                                    Headers = @{'x-ms-version' = '2020-08-04'}
                                }
                                [xml]$FileDiagSettings = Invoke-UrlRequest @params
                                if($FileDiagSettings){
                                    #Add to psobject
                                    $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsVersion -value $FileDiagSettings.StorageServiceProperties.HourMetrics.Version
                                    $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsEnabled -value $FileDiagSettings.StorageServiceProperties.HourMetrics.Enabled
                                    $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsIncludeAPIs -value $FileDiagSettings.StorageServiceProperties.HourMetrics.IncludeAPIs
                                    $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyEnabled -value $FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Enabled
                                    if($FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Days){
                                        $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyDays -value $FileDiagSettings.StorageServiceProperties.HourMetrics.RetentionPolicy.Days
                                    }
                                    else{
                                        $StrAccount | Add-Member -type NoteProperty -name fileHourMetricsRetentionPolicyDays -value $null
                                    }
                                    #Add to psobject
                                    $StrAccount | Add-Member -type NoteProperty -name fileMinuteMetricsVersion -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.Version
                                    $StrAccount | Add-Member -type NoteProperty -name fileMinuteMetricsEnabled -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.Enabled
                                    $StrAccount | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyEnabled -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Enabled
                                    if($FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Days){
                                        $StrAccount | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyDays -value $FileDiagSettings.StorageServiceProperties.MinuteMetrics.RetentionPolicy.Days
                                    }
                                    else{
                                        $StrAccount | Add-Member -type NoteProperty -name fileMinuteMetricsRetentionPolicyDays -value $null
                                    }
                                }
                            }
                            #Get Shared Access Signature
                            $blobSAS = Get-SASUri -HostName $blobEndpoint -accessKey $key1
                            if($blobSAS){
                                #Get Blob diagnostig settings
                                $params = @{
                                    Url = $blobSAS;
                                    Method = "GET";
                                    UserAgent = $O365Object.UserAgent;
                                    Headers = @{'x-ms-version' = '2020-08-04'}
                                }
                                [xml]$BlobDiagSettings = Invoke-UrlRequest @params
                                if($BlobDiagSettings){
                                    #Add to psobject
                                    $StrAccount | Add-Member -type NoteProperty -name blobLogVersion -value $BlobDiagSettings.StorageServiceProperties.Logging.Version
                                    $StrAccount | Add-Member -type NoteProperty -name blobLogReadEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Read
                                    $StrAccount | Add-Member -type NoteProperty -name blobLogWriteEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Write
                                    $StrAccount | Add-Member -type NoteProperty -name blobLogDeleteEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.Delete
                                    $StrAccount | Add-Member -type NoteProperty -name blobRetentionPolicyEnabled -value $BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Enabled
                                    if($BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days){
                                        $StrAccount | Add-Member -type NoteProperty -name blobRetentionPolicyDays -value $BlobDiagSettings.StorageServiceProperties.Logging.RetentionPolicy.Days
                                    }
                                    else{
                                        $StrAccount | Add-Member -type NoteProperty -name blobRetentionPolicyDays -value $null
                                    }
                                }
                            }
                        }
                    }
                    #Decore Object
                    $StrAccount.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccount')
                    #Add to Object
                    $AllStorageAccounts+=$StrAccount
                }
            }
        }
    }
    End{
        if($AllStorageAccounts){
            $AllStorageAccounts.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts')
            [pscustomobject]$obj = @{
                Data = $AllStorageAccounts
            }
            $returnData.az_storage_accounts = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage accounts", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureStorageAccountsEmptyResponse');
            }
            Write-Warning @msg
        }
        if($AllStorageAccountsPublicBlobs){
            #Add public blobs
            $AllStorageAccountsPublicBlobs.PSObject.TypeNames.Insert(0,'Monkey365.Azure.StorageAccounts.PublicBlobs')
            [pscustomobject]$obj = @{
                Data = $AllStorageAccountsPublicBlobs
            }
            $returnData.az_storage_public_blobs = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Storage Accounts Public blobs", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureStorageAccountPublicBlobEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
