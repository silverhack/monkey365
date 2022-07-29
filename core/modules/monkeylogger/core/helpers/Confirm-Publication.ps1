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

Function Confirm-Publication {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Confirm-Publication
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Log object")]
        [System.Management.Automation.InformationRecord] $Log,

        [Parameter(Mandatory=$false, HelpMessage="Configuration")]
        [object] $Configuration
    )
    try{
        $publish = $true
        #Check Log Level
        if($null -eq $Log.Level -or [String]::IsNullOrEmpty($Log.Level)){
            $LogLevel = 'info'
        }
        else{
            $LogLevel = $Log.Level.ToString().ToLower();
        }
        if($Configuration.psobject.properties.Item('onlyExceptions')){
            if($Configuration.onlyExceptions -eq $true){
                if($Log.MessageData -is [exception] -or $Log.MessageData -is [System.AggregateException] -or $Log.MessageData -is [System.Management.Automation.ErrorRecord]){
                    return $true
                }
                else{
                    return $false
                }
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeDebug')) -and $Configuration.includeDebug -eq $false){
            if($LogLevel -eq "debug"){
                $publish = $false
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeError')) -and $Configuration.includeError -eq $false){
            if($LogLevel -eq "error" -or $Log.MessageData -is [System.Management.Automation.ErrorRecord]){
                $publish = $false
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeInfo')) -and $Configuration.includeInfo -eq $false){
            if($LogLevel -eq "info"){
                $publish = $false
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeVerbose')) -and $Configuration.includeVerbose -eq $false){
            if($LogLevel -eq "verbose"){
                $publish = $false
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeWarning')) -and $Configuration.includeWarning -eq $false){
            if($LogLevel -eq "warning"){
                $publish = $false
            }
        }
        if($null -ne ($Configuration.psobject.properties.Item('includeExceptions')) -and $Configuration.includeExceptions -eq $false){
            if($Log.MessageData -is [System.Management.Automation.ErrorRecord] -or $Log.MessageData -is [System.AggregateException] -or $Log.MessageData -is [exception]){
                $publish = $false
            }
        }
        return $publish
    }
    catch{
        $param = @{
            MessageData = $_;
            Tags = @('WriteFileError');
            logLevel = 'Error';
            callStack = (Get-PSCallStack | Select-Object -First 1);
        }
        Write-Debug @param
        #Set verbose
        $param.MessageData = $_.Exception.Message
        Write-Verbose @param
        return $false
    }
}



