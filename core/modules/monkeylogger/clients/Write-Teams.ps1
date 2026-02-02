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
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Log stream")]
        [System.Management.Automation.InformationRecord]$Log,

        [Parameter(Mandatory=$True, HelpMessage="Configuration file")]
        [Object]$Configuration
    )
    Begin{
        $WebHook = $json_body = $null;
    }
    Process{
        Try{
            #Get formatted message
            $formattedMessage = $Log | Get-FormattedMessage
            #Get WebHoot
            $WebHook = $Configuration | Select-Object -ExpandProperty webHook -ErrorAction Ignore
            #Construct message
            $json_body = [Ordered]@{
                "@type" = "MessageCard";
                "@context" = "<http://schema.org/extensions>";
                "summary" = "Monkey365 Teams message";
                "themeColor" = '0078D7';
                "title" = "Monkey365";
                "text" = $formattedMessage;
            } | ConvertTo-Json -Depth 20
            #Send message to Teams channel
            If($null -ne $WebHook -and $null -ne $json_body){
                Try {
                    $p = @{
                        Uri = $WebHook;
                        Method = 'Post';
                        Body = $json_body;
                        ContentType = 'application/json';
                        UseBasicParsing = $True;

                    }
                    Invoke-WebRequest @p
                }
                Catch {
                    $p = @{
                        MessageData = $_.Exception;
                        Tags = @('TeamsRequestError');
                        logLevel = 'Error';
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                    }
                    Write-Error @param
                }
            }
        }
        Catch{
            $p = @{
                MessageData = $_.Exception;
                Tags = @('TeamsFormatError');
                logLevel = 'Error';
                callStack = (Get-PSCallStack | Select-Object -First 1);
            }
            Write-Error @p
        }
    }
    End{
        #Nothing to do here
    }
}