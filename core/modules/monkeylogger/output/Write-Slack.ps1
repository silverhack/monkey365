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

Function Write-Slack {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Write-Slack
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

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
                $raw_body = @{
                    text = $formattedMessage
                    color = "#142954"
                }
                #Check if extra parameters
                switch ($Configuration.PSObject.Properties.name){
                    'channel'     {$raw_body.channel = $Configuration.channel }
                    'username'    {$raw_body.username = $Configuration.username}
                    'iconurl'     {$raw_body.icon_url = $Configuration.iconurl}
                    'icon_emoji'   {$raw_body.icon_emoji  = $Configuration.icon_emoji}
                    'linknames'   {$raw_body.link_names = 1}
                    'parse'       {$raw_body.parse = $Configuration.Parse}
                    'UnfurlLinks' {$raw_body.unfurl_links = $Configuration.UnfurlLinks}
                    'UnfurlMedia' {$raw_body.unfurl_media = $Configuration.UnfurlMedia}
                }
                $body = $raw_body | ConvertTo-Json
            }
            catch{
                $param = @{
                    MessageData = $_.Exception;
                    Tags = @('SlackFormatError');
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
        if($null -ne $WebHook -and $null -ne $body){
            try {
                $param = @{
                    uri = $WebHook;
                    Method = 'Post';
                    body = $body;
                    ContentType = 'application/json';
                }
                Invoke-RestMethod @param
            }
            catch {
                $param = @{
                    MessageData = $_.Exception;
                    Tags = @('SlackRequestError');
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
