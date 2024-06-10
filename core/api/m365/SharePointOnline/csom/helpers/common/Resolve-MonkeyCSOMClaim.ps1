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

Function Resolve-MonkeyCSOMClaim{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-MonkeyCSOMClaim
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory=$true, ValueFromPipeline = $true, HelpMessage="Claim")]
        [String]$Claim
    )
    Process{
        try{
            $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Method Name="DecodeClaim" Id="204" ObjectPathId="151"><Parameters><Parameter Type="String">${claim}</Parameter></Parameters></Method></Actions><ObjectPaths><Constructor Id="151" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /></ObjectPaths></Request>' -replace '\${claim}',$PSBoundParameters['Claim'])
            #Set object metadata
            $objectMetadata = @{
                CheckValue = 1;
                isEqualTo =204;
                GetValue = 2;
            }
            #Get params
            $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMDefaultRequest" -Params $PSBoundParameters
            #Add authentication header if missing
            if(!$p.ContainsKey('Authentication')){
                if($null -ne $O365Object.auth_tokens.SharePointOnline){
                    [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointOnline);
                }
                Else{
                    Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
                    break
                }
            }
            #Add Data
            [void]$p.Add('Data',$body_data);
            #Add Object metadata
            [void]$p.Add('ObjectMetadata',$objectMetadata);
            #Add ContentType
            [void]$p.Add('ContentType','application/json; charset=utf-8');
            #Execute query
            Invoke-MonkeyCSOMDefaultRequest @p
        }
        catch{
            $msg = @{
                MessageData = ("Unable to resolve claim {0}" -f $PSBoundParameters['Claim']);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365CSOMClaimError');
            }
            Write-Warning @msg
            #Set verbose
            $msg.MessageData = $_
            $msg.logLevel = 'Verbose'
            [void]$msg.Add('Verbose',$O365Object.verbose)
            Write-Verbose @msg
        }
    }
}
