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

Function Write-Debug {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Write-Debug
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidOverwritingBuiltInCmdlets", "", Scope="Function")]
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=113424', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('Msg')]
        [Alias('MessageData')]
        [AllowEmptyString()]
        [System.Object]
        ${Message},

        [Parameter(Mandatory=$false, HelpMessage="Tags")]
        [string[]]
        ${Tags},

        [Parameter(Mandatory=$false, HelpMessage="Foreground Color")]
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor,

        [Parameter(Mandatory=$false, HelpMessage="Background Color")]
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,

        [Parameter(Mandatory=$false, HelpMessage="Message body")]
        [Object]$Body,

        [Parameter(Mandatory=$false, HelpMessage="CallStack")]
        [System.Management.Automation.CallStackFrame]
        $callStack,

        [Parameter(Mandatory=$false, HelpMessage="Function name")]
        [String]$functionName,

        [Parameter(Mandatory=$false, HelpMessage="Log Level")]
        [String]$logLevel,

        [Parameter(Mandatory=$false, HelpMessage="channel output")]
        [String[]]$channel,

        [Parameter(Mandatory=$false, HelpMessage="Function name")]
        [object]$Caller,

        [Parameter(Mandatory=$false, HelpMessage="No new line")]
        [Switch]$NoNewline
    )

    begin
    {
        try {
            $newPsboundParams = [ordered]@{}
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Microsoft.PowerShell.Utility\Write-Debug")
            if($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    if($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            #Get CallStack info
            $TmpCommand = (Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1).Command
            if($null -ne $callStack -and $callStack.Command.Length -gt 0){
                $Command = $callStack.Command;
            }
            elseif($null -ne $callStack -and $callStack.FunctionName.Length -gt 0){
                $Command = $callStack.FunctionName;
            }
            elseif($functionName){
                $Command = $functionName
            }
            elseif($TmpCommand){
                $Command = $TmpCommand
            }
            else{
                $Command = 'unknown';
            }
            #Check Log Level
            if (-not $PSBoundParameters.ContainsKey('logLevel')) {
                $PSBoundParameters.Add('logLevel','debug')
            }
            #Check if Debug is present in psboundparameters
            if(!$PSBoundParameters.ContainsKey('Debug')){
                [void]$PSBoundParameters.Add('Debug',$false);
            }
            #Check if verbosity variable is present
            elseif($null -ne (Get-Variable -Name Verbosity -ErrorAction Ignore)){
                if($Verbosity -is [hashtable] -and $Verbosity.ContainsKey("Debug")){
                    $PSBoundParameters['Debug'] = $verbosity.Debug
                }
            }
            else{
                #Check if verbose variable is present
                if($null -ne (Get-Variable -Name Verbose -ErrorAction Ignore)){
                    #override default option
                    $PSBoundParameters['Debug'] = $script:Debug
                }
            }
            #Change debugpreference
            if($PSBoundParameters['Debug']){
                $DebugPreference = 'Continue'
            }
            #Create msg object
            $msg = [System.Management.Automation.InformationRecord]::new($Message,$Command)
            $msg | Add-Member -type NoteProperty -name ForegroundColor -value $PSBoundParameters['ForegroundColor']
            $msg | Add-Member -type NoteProperty -name BackgroundColor -value $PSBoundParameters['BackgroundColor']
            $msg | Add-Member -type NoteProperty -name level -value $PSBoundParameters.logLevel
            $msg | Add-Member -type NoteProperty -name Debug -value $PSBoundParameters.Debug
            $msg | Add-Member -type NoteProperty -name channel -value $channel
            #Add tags
            if($Tags){
                foreach ($tag in $Tags){$msg.tags.Add($tag)}
            }
            #Get formatted message
            $formattedMessage = Get-FormattedMessage -Log $msg
            <#
            #Set color
            if (-NOT $PSBoundParameters.ContainsKey('ForegroundColor')){
                $ForegroundColor = [ConsoleColor]::Yellow
            }
            #>
            #Add to queue
            if($null -ne (Get-Variable -Name LogQueue -ErrorAction Ignore)){
                $LogQueue.Add($msg)
            }
            #Set message options
            $msgObject = [System.Management.Automation.HostInformationMessage]@{
                Message         = $formattedMessage
                ForegroundColor = $ForegroundColor
                BackgroundColor = $BackgroundColor
                NoNewline       = $NoNewline.IsPresent
            }
            $newPsboundParams.Message = $msgObject
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @newPsboundParams }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }
    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}
<#

.ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Debug
.ForwardHelpCategory Cmdlet

#>



