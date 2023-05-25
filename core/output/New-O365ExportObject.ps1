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


Function New-O365ExportObject{
    <#
        .SYNOPSIS
		Function to create new O365 Export object

        .DESCRIPTION
		Function to create new O365 Export object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-O365ExportObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param ()
    try{
        #Create and return a new PsObject
        $tmp_object = @{
            Environment = $O365Object.Environment;
            StartDate = $starttimer.ToLocalTime();;
            Subscription = $O365Object.current_subscription;
            Tenant = $O365Object.Tenant;
            TenantID = $O365Object.Tenant.tenantId;
            Localpath = $O365Object.Localpath;
            Output = $Script:returnData;
            Plugins = $O365Object.Plugins;
            Instance = $O365Object.Instance;
            IncludeAAD = $O365Object.IncludeAAD;
            aadpermissions = $O365Object.aadPermissions;
            execution_info = $O365Object.executionInfo;
            all_resources = $O365Object.all_resources;
        }
        $MyO365Object = New-Object -TypeName PSCustomObject -Property $tmp_object
        return $MyO365Object
    }
    catch{
        $msg = @{
            MessageData = $message.UnableToCreateMonkeyObject;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            Tags = @('MonkeyObjectError');
        }
        Write-Warning @msg
        #Write debug
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            Debug = $O365Object.debug;
            Tags = @('MonkeyObjectError');
        }
        Write-Debug @msg
    }
}
