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

Function Resolve-MonkeySPSClaim{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-MonkeySPSClaim
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory=$true, HelpMessage="Claim")]
        [string]$claim
    )
    try{
        $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Method Name="DecodeClaim" Id="204" ObjectPathId="151"><Parameters><Parameter Type="String">${claim}</Parameter></Parameters></Method></Actions><ObjectPaths><Constructor Id="151" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>' -replace '\${claim}',$claim)
        #Set object metadata
        $objectMetadata = @{
            CheckValue = 1;
            isEqualTo =204;
            GetValue = 2;
        }
        $param = @{
            Authentication = $Authentication;
            Content_Type = 'application/json; charset=utf-8';
            Data = $body_data;
            objectMetadata= $objectMetadata;
        }
        #call SPS
        $resolved_claim = Invoke-MonkeySPSDefaultUrlRequest @param
        return $resolved_claim
    }
    catch{
        $msg = @{
            MessageData = ("Unable to resolve claim {0}" -f $claim);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('ResolvePSPClaimError');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        Write-Verbose @msg
    }
}
