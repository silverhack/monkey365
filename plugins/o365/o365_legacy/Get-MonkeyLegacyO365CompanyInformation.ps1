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


Function Get-MonkeyLegacyO365CompanyInformation{
    <#
        .SYNOPSIS
		Plugin to get information about company information using legacy O365 API

        .DESCRIPTION
		Plugin to get information about company information using legacy O365 API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyLegacyO365CompanyInformation
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
        #Begin Block

    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Company information", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('LegacyCompanyInfo');
        }
        Write-Information @msg
        $company_information = Get-MonkeyMsolCompanyInformation
    }
    End{
        if($company_information){
            $company_information.PSObject.TypeNames.Insert(0,'Monkey365.Legacy.CompanyInformation')
            [pscustomobject]$obj = @{
                Data = $company_information
            }
            $returnData.o365_company_information = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Company information", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('LegacyCompanyInformationEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
