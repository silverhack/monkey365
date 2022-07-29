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

Function Get-O365LicenseSKU{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-O365LicenseSKU
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    try{
        #Get all licenses
        $json_path = ("{0}/{1}" -f $O365Object.Localpath,$O365Object.internal_config.o365.licenseInfo)
        if (!(Test-Path -Path $json_path)){
            throw ("{0} license file does not exists" -f $json_path)
        }
        $licenses = (Get-Content $json_path -Raw) | ConvertFrom-Json
        if($null -ne $O365Object.Tenant -and $O365Object.Tenant.psobject.Properties.Item('SKU')){
            $current_licenses = Copy-psObject -object $O365Object.Tenant.SKU
            foreach($license in $current_licenses){
                $match = $licenses | Where-Object {$_.Guid -eq $license.skuId} -ErrorAction Ignore
                if($null -ne $match){
                    $license | Add-Member -Type NoteProperty -name ProductName -value $match.ProductName
                }
                else{
                    $license | Add-Member -Type NoteProperty -name ProductName -value $license.skuPartNumber
                }
            }
            return $current_licenses
        }
        else{
            $msg = @{
                MessageData = $message.O365LicenseInfoError;
                functionName = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                Tags = @('O365LicenseSKUError');
            }
            Write-Debug @msg
        }
    }
    catch{
        $msg = @{
            MessageData = $message.O365LicenseInfoError;
            functionName = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            Tags = @('O365LicenseSKUError');
        }
        Write-Debug @msg
        #Change message
        $msg.MessageData = $_
        Write-Debug @msg
        return $false
    }
}
