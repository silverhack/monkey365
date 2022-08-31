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

Function Initialize-MonkeyVar{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyVar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Params')]
        [object]$MyParams
    )
    #Set script path var
    $ScriptPath = (Get-Item $PSScriptRoot).parent.parent.FullName
    Set-Variable -Name ScriptPath -Value $ScriptPath -Scope Script
    #Initialize Monkey 365 returnData synchronized variable
    Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
    #Set OnlineServices
    $onlineServices = @{
        EXO = $false;
        Compliance = $false;
        O365 = $false;
        AADRM = $false;
        Teams = $false;
        SPS = $false;
        Intune = $false;
        Azure = $false;
        Forms = $false
    }
    Set-Variable OnlineServices -Value $onlineServices -Scope Script -Force
    #Set Connections var
    $connections = [hashtable]::Synchronized(@{
        Graph = $null;
        Intune = $null;
        ExchangeOnline = $null;
        ResourceManager = $null;
        ServiceManagement = $null;
        SecurityPortal = $null;
        AzureVault = $null;
        LogAnalytics = $null;
        AzureStorage = $null;
        ComplianceCenter = $null;
        AzurePortal = $null;
        Yammer = $null;
        Forms = $null;
        Lync= $null;
        SharePointAdminOnline = $null;
        SharePointOnline = $null;
        OneDrive = $null;
        AADRM = $null;
        MSGraph = $null;
        Teams = $null;
    });
    #Set connections variable
    Set-Variable o365_connections -Value $connections -Scope Script -Force

    $o365_sessions = @{
        ExchangeOnline = $false;
        ComplianceCenter = $false;
        Lync = $false;
        AADRM = $false;
    }
    #Set sessions variable
    Set-Variable o365_sessions -Value $o365_sessions -Scope Script -Force
    ################### VERBOSE OPTIONS #######################
    #Check verbose options
    if($MyParams.Verbose){
        $VerboseOptions=@{Verbose=$true}
    }
    else{
        $VerboseOptions=@{Verbose=$false}
    }
    #Check Debug options
    if($MyParams.Debug){
        $VerboseOptions.Add("Debug",$true)
    }
    else{
        $VerboseOptions.Add("Debug",$false)
    }
    #Set verboseOptions script var
    Set-Variable VerboseOptions -Value $VerboseOptions -Scope Script -Force
    Set-Variable Verbosity -Value $VerboseOptions -Scope Script -Force
    ######################## END VERBOSE OPTIONS #############################
    ################### LOG, CONSOLE OPTIONS #######################
    if($null -ne $MyParams.informationAction){
        Set-Variable InformationAction -Value $MyParams.informationAction -Scope Script -Force
    }
    else{
        Set-Variable InformationAction -Value "SilentlyContinue" -Scope Script -Force
    }
    #set the default connection limit
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 1000;
    [System.Net.ServicePointManager]::MaxServicePoints = 1000;
    try{
        #https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.reuseport(v=vs.110).aspx
        [System.Net.ServicePointManager]::ReusePort = $true;
    }
    catch{
        $msg = @{
            MessageData = ($message.ReusePortErrorMessage);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('ReusePortError');
        }
        Write-Warning @msg
    }
}
