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

Function Find-MonkeyAzStoragePublicBlob {
    <#
        .SYNOPSIS
		Search for public blobs for an storage account

        .DESCRIPTION
		Search for public blobs for an storage account

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Find-MonkeyAzStoragePublicBlob
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$StorageAccount
    )
    Begin{
        #Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Storage Auth
		$StorageAuth = $O365Object.auth_tokens.AzureStorage
        $allContainers = New-Object System.Collections.Generic.List[System.Object]
    }
    Process{
        $blobUri = ("https://{0}.blob.core.windows.net?restype=container&comp=list" -f $StorageAccount.Name)
        $params = @{
			Authentication = $StorageAuth;
			OwnQuery = $blobUri;
			Environment = $Environment;
			ContentType = 'application/json';
			Headers = @{ 'x-ms-version' = '2020-08-04' }
			Method = "GET";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
		}
		[xml]$blobs = Get-MonkeyRMObject @params
        if($null -ne $blobs){
            $containers = $blobs.SelectSingleNode('/EnumerationResults/Containers/Container')
            if($containers){
                foreach($container in $containers){
                    $new_container = [ordered]@{
                        storageaccount = $StorageAccount.Name;
                        storageaccountId = $StorageAccount.Id;
                        containerName = $container.Name;
                        blobname = $container.Name;
                        publicAccess = $null;
                        rawObject = $container;
                    }
                    $publicAccess = $container.SelectSingleNode('/Properties/PublicAccess')
                    if($publicAccess){
                        $new_container.publicAccess = $container.Properties.PublicAccess.'#text'
                    }
                    else{
                        $new_container.publicAccess = "Private";
                    }
                    $Object = New-Object PSObject -Property $new_container;
                    #Add to array
                    [void]$allContainers.Add($Object);
                    #Avoid throttling
                    Start-Sleep -Milliseconds 500
                }
            }
        }
        Write-Output $allContainers -NoEnumerate
    }
    End{
        #Nothing to do here
    }
}