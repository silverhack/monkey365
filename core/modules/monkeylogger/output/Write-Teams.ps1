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

Function Write-Teams {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Write-Teams
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $false,ValueFromPipeLineByPropertyName = $True)]
        [System.Management.Automation.InformationRecord] $Log,

        [parameter(ValueFromPipeline = $false,ValueFromPipeLineByPropertyName = $True)]
        [object] $Configuration
    )
    Begin{
        #$body = $null
        $shouldPublish = Confirm-Publication -Log $Log -Configuration $Configuration
        if($shouldPublish){
            $formattedMessage = Get-FormattedMessage -Log $Log
        }
        else{
            $formattedMessage = $null
        }
    }
    Process{
        if($null -ne $formattedMessage){
            try{
                $WebHook = $Configuration.webHook
                #Construct message
                $json_body = [Ordered]@{
                    "@type" = "MessageCard";
                    "@context" = "<http://schema.org/extensions>";
                    "summary" = "Monkey365 Teams message";
                    "themeColor" = '0078D7';
                    "title" = "Monkey365";
                    "text" = $formattedMessage;
                } | ConvertTo-Json -Depth 20
            }
            catch{
                $param = @{
                    MessageData = $_.Exception;
                    Tags = @('TeamsFormatError');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Debug @param
                #Set verbose
                $param.MessageData = $_.Exception.Message
                Write-Verbose @param
                $WebHook = $null
            }
        }
        else{
            $WebHook = $null;
        }
    }
    End{
        #Send message to slack channel
        if($null -ne $WebHook -and $null -ne $json_body){
            try {
                $param = @{
                    uri = $WebHook;
                    Method = 'Post';
                    body = $json_body;
                    ContentType = 'application/json';
                }
                Invoke-RestMethod @param
            }
            catch {
                $param = @{
                    MessageData = $_.Exception;
                    Tags = @('TeamsRequestError');
                    logLevel = 'Error';
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                }
                Write-Debug @param
                #Set verbose
                $param.MessageData = $_.Exception.Message
                Write-Verbose @param
            }
        }
    }
}
