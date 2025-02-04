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

Function Get-MonkeySKUInfo{
    <#
        .SYNOPSIS

        Get the list of commercial subscriptions (SKUs)

        .DESCRIPTION

        Get the list of commercial subscriptions (SKUs)

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySKUInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param(
        [parameter(Mandatory= $false, HelpMessage= "Update the list of commercial subscriptions (SKUs) from Microsoft.com")]
        [Switch]$Update
    )
    Begin{
        $licenses = $null
        if($Update.IsPresent -and $null -ne (Get-Command -Name Get-SKUProduct -ErrorAction Ignore)){
            $licenses = Get-SKUProduct
        }
        else{
            try{
                #Get all licenses
                $json_path = ("{0}/{1}" -f $O365Object.Localpath,$O365Object.internal_config.o365.licenseInfo)
                if (!(Test-Path -Path $json_path)){
                    throw ("{0} license file not found" -f $json_path)
                }
                $licenses = (Get-Content $json_path -Raw) | ConvertFrom-Json
            }
            catch{
                $msg = @{
                    MessageData = $_;
                    functionName = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Tags = @('M365LicenseSKUError');
                }
                Write-Verbose @msg
                Break
            }
        }
    }
    Process{
        If($null -ne $licenses){
            If($null -ne $O365Object.Tenant -and $null -ne $O365Object.Tenant.psobject.Properties.Item('SKU') -and $null -ne $O365Object.Tenant.SKU){
                $current_licenses = $O365Object.Tenant.SKU | Copy-PsObject
                ForEach($license in $current_licenses){
                    $match = $licenses | Where-Object {$_.Guid -eq $license.skuId} -ErrorAction Ignore
                    If($null -ne $match){
                        $license | Add-Member -Type NoteProperty -name ProductName -value $match.ProductName
                    }
                    Else{
                        $license | Add-Member -Type NoteProperty -name ProductName -value $license.skuPartNumber
                    }
                }
                #return licenses
                return $current_licenses
            }
            Else{
                $msg = @{
                    MessageData = $message.M365LicenseInfoError;
                    functionName = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    Tags = @('M365LicenseSKUError');
                }
                Write-Debug @msg
            }
        }
        Else{
            $msg = @{
                MessageData = $message.M365LicenseInfoError;
                functionName = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                Tags = @('M365LicenseSKUError');
            }
            Write-Warning @msg
        }
    }
    End{
        #Nothing to do here
    }
}


