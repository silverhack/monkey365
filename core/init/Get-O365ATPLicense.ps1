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

Function Get-O365ATPLicense{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-O365ATPLicense
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    try{
        #Check if ATP is enabled
        $atp_enabled = $O365Object.Tenant.SKU | `
                       Where-Object {$_.skuPartNumber -eq "ATP_ENTERPRISE"}
        #Check if SPE_E5 is enabled
        if(-NOT $atp_enabled){
            $atp_enabled = $O365Object.Tenant.SKU | `
                           Where-Object {$_.skuPartNumber -eq "SPE_E5"}
        }
        #Check if ENTERPRISEPREMIUM is enabled
        if(-NOT $atp_enabled){
            $atp_enabled = $O365Object.Tenant.SKU | `
                           Where-Object {$_.skuPartNumber -eq "ENTERPRISEPREMIUM" -or `
                                         $_.skuPartNumber -eq "ENTERPRISEPREMIUM_NOPSTNCONF"}
        }
        #return ATP
        if($atp_enabled){
            return $true
        }
        else{
            return $false
        }
    }
    catch{
        $msg = @{
            MessageData = $message.O365ATPInfoError;
            functionName = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            Tags = @('O365ATPLicenseError');
        }
        Write-Debug @msg
        #Change message
        $msg.MessageData = $_
        Write-Debug @msg
        return $false
    }
}
