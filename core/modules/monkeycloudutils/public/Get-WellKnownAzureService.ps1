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

Function Get-WellKnownAzureService{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-WellKnownAzureService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param
    (
        # Well Known Azure service
        [Parameter(Mandatory = $false, HelpMessage = 'Well Known Azure Service')]
        [String] $AzureService
    )
    [psobject]$AzureResources = @{
        MicrosoftGraph = '14d82eec-204b-4c2f-b7e8-296a70dab67e';
        AzureCli = '04b07795-8ddb-461a-bbee-02f9e1bf7b46';
        AzurePortal = '74658136-14ec-4630-ad9b-26e160ff0fc6';
        AzurePowerShell = '1950a258-227b-4e31-a9cf-717495945fc2';
        GlobalPowerShell = '1b730954-1685-4b74-9bfd-dac224a7b894';
        AADGraphAPI = "00000002-0000-0000-c000-000000000000";
        AzureGraph = '00000003-0000-0000-c000-000000000000';
        ServiceManagement = "797f4846-ba00-4fd7-ba43-dac1f8f63013";
        SecurityPortal = "c44b4083-3bb0-49c1-b47d-974e53cbdf3c";
        LyncPortal = "d924a533-3729-4708-b3e8-1d2445af35e3";
        ExchangeOnline = "a0c73c16-a7e3-4564-9a95-2bdf47383716";
        ExchangeOnlineV2 = "fb78d390-0c51-40cd-8e17-fdbfab77341b";
        AADRM = "90f610bf-206d-4950-b61d-37fa6fd1b224";
        SharePointOnline  = "9bc3ab49-b65d-410a-85ad-de819febfddc";
        BrokerPlugin = "fc0f3af4-6835-4174-b806-f7db311fd2f3";
        Lync = "7716031e-6f8b-45a4-b82b-922b1af0fbb4";
        Intune = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547";
        Intune2 = "5926fc8e-304e-4f59-8bed-58ca97cc39a4";
        MsTeams = '2ddfbe71-ed12-4123-b99b-d5fc8a062a79';
        TeamsAdminApi = '48ac35b8-9aa8-4d74-927d-1f4a14a0b239';
        Sway = '905fcf26-4eb7-48a0-9ff0-8dcc7194b5ba';
        SwayClientId = 'bafcc1aa-3301-49be-a9bc-aa9b8e04c342';
        MicrosoftForms = 'c9a559d2-7aab-4f13-a6ed-e7e9c52aec87';
        OfficeHome = '4765445b-32c6-49b0-83e6-1d93765276ca';
        MSPIM = '01fc33a7-78ba-4d2f-a4b7-768e336e890e';
    }
    #Check if resource exists
    if($AzureResources.ContainsKey($AzureService)){
        return $AzureResources.Item($AzureService)
    }
    else{
        Write-Verbose -Message ($Script:messages.UnknownResource -f $AzureService)
    }
}
