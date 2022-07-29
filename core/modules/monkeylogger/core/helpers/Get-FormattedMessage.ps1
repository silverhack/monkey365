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
        [System.Management.Automation.InformationRecord] $Log
    )
    Begin{
        $formattedMessage = $null
        #Check Log Level
        if($null -eq $Log.Level -or [String]::IsNullOrEmpty($Log.Level)){
            $Log.Level = 'info'
        }
        else{
            $Log.Level = $Log.Level.ToString().ToLower();
        }
        $formattedMessage = $null
    }
    Process{
        try{
            if($Log.MessageData -is [System.Management.Automation.ErrorRecord]){
                try{
                    if($null -ne $Log.MessageData.PsObject.Properties.Item('InvocationInfo') -and $null -ne $Log.MessageData.InvocationInfo){
                        if($null -ne $Log.MessageData.InvocationInfo.PsObject.Properties.Item('PositionMessage')){
                            $position = $Log.MessageData.InvocationInfo.PositionMessage
                        }
                        else{
                            $position = $null
                        }
                    }
                    else{
                        $position = $null
                    }
                }
                catch{
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
            elseif($Log.MessageData -is [exception]){
                try{
                    if($null -ne $Log.MessageData.PsObject.Properties.Item('InvocationInfo')){
                        $position = $Log.MessageData.InvocationInfo.PositionMessage
                    }
                    else{
                        $position = $null
                    }
                }
                catch{
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
            elseif($Log.MessageData -is [System.AggregateException]){
                $formattedMessage = ("[{0}] - [{1}] - {2} - {3} - {4} - {5}" -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData.Exception.InnerException.Message, `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags))
            }
            elseif($Log.MessageData -is [String]){
                $formattedMessage = '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    $Log.MessageData, `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags)
            }
            else{
                $formattedMessage = '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                                    $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                                    $Log.Source, `
                                    ($Log.MessageData | Out-String), `
                                    $Log.Level.ToString().ToLower(), `
                                    $Log.Computer, `
                                    [system.String]::Join(", ", $Log.Tags)

            }
        }
        catch{
            Write-Verbose ("Unable to format message {0}" -f $Log.MessageData)
        }
    }
    End{
        if($formattedMessage){
            return $formattedMessage
        }
        else{
            return [string]::Empty
        }
    }
}
