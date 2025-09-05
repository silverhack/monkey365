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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Get-FormattedMessage {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-FormattedMessage
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Log stream")]
        [System.Management.Automation.InformationRecord]$Log
    )
    Begin{
        $formattedMessage = $null
    }
    Process{
        Try{
            #Check Log Level
            If($null -eq $Log.Level -or [String]::IsNullOrEmpty($Log.Level)){
                $Log.Level = 'info'
            }
            Else{
                $Log.Level = $Log.Level.ToString().ToLower();
            }
            #Process message
            If($Log.MessageData -is [System.Management.Automation.ErrorRecord]){
                Try{
                    If($null -ne $Log.MessageData.PsObject.Properties.Item('InvocationInfo') -and $null -ne $Log.MessageData.InvocationInfo){
                        If($null -ne $Log.MessageData.InvocationInfo.PsObject.Properties.Item('PositionMessage')){
                            $position = $Log.MessageData.InvocationInfo.PositionMessage
                        }
                        Else{
                            $position = $null
                        }
                    }
                    Else{
                        $position = $null
                    }
                }
                Catch{
                    $position = $null
                }
                $formattedMessage = ("[{0}] - [{1}] - {2}. LineNumber: {3} - exception - {4} - {5}" -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData.Exception.Message, `
                                    $position, `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags))
            }
            ElseIf($Log.MessageData -is [exception]){
                Try{
                    If($null -ne $Log.MessageData.PsObject.Properties.Item('InvocationInfo')){
                        $position = $Log.MessageData.InvocationInfo.PositionMessage
                    }
                    Else{
                        $position = $null
                    }
                }
                Catch{
                    $position = $null
                }
                $formattedMessage = ("[{0}] - [{1}] - {2}. LineNumber: {3} - exception - {4} - {5}" -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData, `
                                    $position, `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags))
            }
            ElseIf($Log.MessageData -is [System.AggregateException]){
                $formattedMessage = ("[{0}] - [{1}] - {2} - {3} - {4} - {5}" -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData.Exception.InnerException.Message, `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags))
            }
            ElseIf($Log.MessageData -is [String]){
                $formattedMessage = '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData, `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags)
            }
            Else{
                $formattedMessage = '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    ($Log.MessageData | Out-String), `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags)

            }
            If($null -ne $formattedMessage){
                return $formattedMessage
            }
            Else{
                return [string]::Empty
            }
        }
        Catch{
            Write-Verbose ($Script:messages.UnableToFormatMessage -f $Log.MessageData)
        }
    }
}

