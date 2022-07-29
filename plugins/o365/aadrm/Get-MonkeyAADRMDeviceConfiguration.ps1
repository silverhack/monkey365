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


Function Get-MonkeyAADRMDeviceConfiguration{
    <#
        .SYNOPSIS
		Plugin to get information about AADRM Device config

        .DESCRIPTION
		Plugin to get information about AADRM Device config

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAADRMDeviceConfiguration
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
        #Get Access Token from AADRM
        $access_token = $O365Object.auth_tokens.AADRM
        #Get AADRM Url
        $url = $O365Object.Environment.aadrm_service_locator
        if($null -ne $access_token){
            #Set Authorization Header
            $AuthHeader = ("MSOID {0}" -f $access_token.AccessToken)
            $requestHeader = @{"Authorization" = $AuthHeader}
        }
        #Create AADRM object
        $aadrm_feature_status = New-Object -TypeName PSCustomObject
    }
    Process{
        if($requestHeader -and $url){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Office 365 Rights Management: Device Configuration", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AADRMDeviceConfig');
            }
            Write-Information @msg
            $url = ("{0}/DevicePlatforms" -f $url)
            $params = @{
                Url = $url;
                Method = 'Get';
                Content_Type = 'application/json; charset=utf-8';
                Headers = $requestHeader;
                disableSSLVerification = $true;
            }
            #call AADRM endpoint
            $AADRM_Devices = Invoke-UrlRequest @params
            #Construct psobject
            foreach($device in $AADRM_Devices){
                switch ($device.key) {
                        0
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name Windows -value $device.value
                        }
                        1
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name WindowsStore -value $device.value
                        }
                        2
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name WindowsPhone -value $device.value
                        }
                        3
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name Mac -value $device.value
                        }
                        4
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name iOS -value $device.value
                        }
                        5
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name Android -value $device.value
                        }
                        6
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name Web -value $device.value
                        }
                        Default
                        {
                            $aadrm_feature_status | Add-Member -type NoteProperty -name Unknown -value $device.value -Force
                        }
                }
            }
        }
    }
    End{
        if($aadrm_feature_status){
            $aadrm_feature_status.PSObject.TypeNames.Insert(0,'Monkey365.AADRM.DevicePlatform')
            [pscustomobject]$obj = @{
                Data = $aadrm_feature_status
            }
            $returnData.o365_aadrm_device_platform = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Office 365 Rights Management: Device Configuration", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AADRMDeviceEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
