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

Function Get-M365AADLicense{
    <#
        .SYNOPSIS

        Get Azure AD license

        .DESCRIPTION

        Get Azure AD license

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-M365AADLicense
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    Param()
    try{
        $aad_licenses = [ordered]@{
            azureADP1 = $null;
            azureADP2 = $null;
        }
        if($null -ne $O365Object.Tenant.SKU){
            #Check if AAD Premium P1 is enabled
            $aad_licenses.azureADP1 = $O365Object.Tenant.SKU | `
                           Where-Object {$_.servicePlans.servicePlanId -eq "41781fb2-bc02-4b7c-bd55-b576c07bb09d"}
            #Check if AAD Premium P2 is enabled
            $aad_licenses.azureADP2 = $O365Object.Tenant.SKU | Where-Object {$_.servicePlans.servicePlanId -eq "eec0eb4f-6444-4f95-aba0-50c24d67f998"}
        }
        #convert to PsObject
        New-Object -TypeName PsObject -Property $aad_licenses
    }
    catch{
        $msg = @{
            MessageData = $message.M365AADInfoError;
            functionName = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            Tags = @('M365AADInfoError');
        }
        Write-Debug @msg
        #Change message
        $msg.MessageData = $_
        Write-Debug @msg
    }
}

