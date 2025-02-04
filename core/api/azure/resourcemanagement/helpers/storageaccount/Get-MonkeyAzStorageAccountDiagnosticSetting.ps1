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

Function Get-MonkeyAzStorageAccountDiagnosticSetting {
    <#
        .SYNOPSIS
		Get storage account diagnostic settings

        .DESCRIPTION
		Get storage account diagnostic settings

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountDiagnosticSetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$StorageAccount,

        [parameter(Mandatory=$false, HelpMessage="Diagnostic Setting Type")]
        [ValidateSet("file","queue","blob","table")]
        [String]$Type
    )
    Process{
        try{
            #Set new object
            $diagSettings = [PSCustomObject]@{
                logging = [PSCustomObject]@{
                    version = $null;
                    read = $null;
                    write = $null;
                    delete = $null;
                    retentionPolicy = [PSCustomObject]@{
                        enabled = $false;
                        retentionDays = $null;
                    }
                }
                hourMetrics = [PSCustomObject]@{
                    version = $null;
                    enabled = $false;
                    includeApis = $null;
                    retentionPolicy = [PSCustomObject]@{
                        enabled = $false;
                        retentionDays = $null;
                    }
                }
                minuteMetrics = [PSCustomObject]@{
                    version = $null;
                    enabled = $false;
                    includeApis = $null;
                    retentionPolicy = [PSCustomObject]@{
                        enabled = $false;
                        retentionDays = $null;
                    }
                }
            }
            $endpoint = $SAS = $diagConfig = $null
            #Get Storage keys
            $p = @{
                StorageAccount = $StorageAccount;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $key = Get-MonkeyAzStorageAccountKey @p
            #Get Endpoint
            if($Type -eq 'queue'){
                $endpoint = $StorageAccount.properties.primaryEndpoints | Select-Object -ExpandProperty queue -ErrorAction Ignore
            }
            elseif($Type -eq 'file'){
                $endpoint = $StorageAccount.properties.primaryEndpoints | Select-Object -ExpandProperty File -ErrorAction Ignore
            }
            if($Type -eq 'blob'){
                $endpoint = $StorageAccount.properties.primaryEndpoints | Select-Object -ExpandProperty blob -ErrorAction Ignore
            }
            else{
                $endpoint = $StorageAccount.properties.primaryEndpoints | Select-Object -ExpandProperty table -ErrorAction Ignore
            }
            if($null -ne $endpoint){
                #Get SAS Uri
                if($key){
                    $p = @{
                        HostName = $endpoint;
                        AccessKey = $key;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                }
                else{
                    $p = @{
                        HostName = $endpoint;
                        AccessKey = $key;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                }
                $SAS = Get-SASUri @p
            }
            if($null -ne $SAS){
                #Get diagnostig settings
                if($key){
                    $p = @{
                        Url = $SAS;
                        Method = "GET";
                        UserAgent = $O365Object.UserAgent;
                        Headers = @{ 'x-ms-version' = '2020-08-04' }
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    [xml]$diagConfig = Invoke-MonkeyWebRequest @p
                }
                elseif($null -ne $O365Object.auth_tokens.AzureStorage){
                    #SAS is not signed, try to get data with access token
                    $p = @{
                        Url = $SAS;
                        Method = "GET";
                        UserAgent = $O365Object.UserAgent;
                        Headers = @{
                            'x-ms-version' = '2020-08-04'
                            'Authorization' = ("Bearer {0}" -f $O365Object.auth_tokens.AzureStorage.AccessToken);
                        }
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
                    }
                    [xml]$diagConfig = Invoke-MonkeyWebRequest @p
                }
            }
            if($null -ne $diagConfig){
                #Get logging settings
                $diagSettings.logging.version = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/Version').'#text'
                $diagSettings.logging.read = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/Read').'#text'
                $diagSettings.logging.write = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/Write').'#text'
                $diagSettings.logging.delete = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/Delete').'#text'
                $diagSettings.logging.retentionPolicy.enabled = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/RetentionPolicy/Enabled').'#text'
                $days = $diagConfig.SelectSingleNode('/StorageServiceProperties/Logging/RetentionPolicy/Days')
                if($days){
                    $diagSettings.logging.retentionPolicy.retentionDays = $days.OuterXml
                }
                #Get hours settings
                $diagSettings.hourMetrics.version = $diagConfig.SelectSingleNode('/StorageServiceProperties/HourMetrics/Version').'#text'
                $diagSettings.hourMetrics.enabled = $diagConfig.SelectSingleNode('/StorageServiceProperties/HourMetrics/Enabled').'#text'
                $includeApi = $diagConfig.SelectSingleNode('/StorageServiceProperties/HourMetrics/IncludeAPIs')
                if($includeApi){
                    $diagSettings.hourMetrics.includeApis = $includeApi.InnerText
                }
                $diagSettings.hourMetrics.retentionPolicy.enabled = $diagConfig.SelectSingleNode('/StorageServiceProperties/HourMetrics/RetentionPolicy/Enabled').'#text'
                $days = $diagConfig.SelectSingleNode('/StorageServiceProperties/HourMetrics/RetentionPolicy/Days')
                if($days){
                    $diagSettings.hourMetrics.retentionPolicy.retentionDays = $days.OuterXml
                }
                #Get minute settings
                $diagSettings.minuteMetrics.version = $diagConfig.SelectSingleNode('/StorageServiceProperties/MinuteMetrics/Version').'#text'
                $diagSettings.minuteMetrics.enabled = $diagConfig.SelectSingleNode('/StorageServiceProperties/MinuteMetrics/Enabled').'#text'
                $includeApi = $diagConfig.SelectSingleNode('/StorageServiceProperties/MinuteMetrics/IncludeAPIs')
                if($includeApi){
                    $diagSettings.minuteMetrics.includeApis = $includeApi.InnerText
                }
                $diagSettings.minuteMetrics.retentionPolicy.enabled = $diagConfig.SelectSingleNode('/StorageServiceProperties/MinuteMetrics/RetentionPolicy/Enabled').'#text'
                $days = $diagConfig.SelectSingleNode('/StorageServiceProperties/MinuteMetrics/retentionPolicy/Days')
                if($days){
                    $diagSettings.minuteMetrics.retentionPolicy.retentionDays = $days.OuterXml
                }
            }
            return $diagSettings
        }
        catch{
            Write-Verbose $_
        }
    }
    End{
        #Nothing to do here
    }
}
