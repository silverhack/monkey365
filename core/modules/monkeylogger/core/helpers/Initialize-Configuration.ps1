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

Function Initialize-Configuration {
    <#
        .SYNOPSIS
        Check for missing parameters in configuration

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
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Configuration")]
        [object] $Configuration
    )
    try{
        #Check if only exceptions must be logged
        if($null -eq $Configuration.psobject.properties.Item('onlyExceptions')){
            $Configuration | Add-Member -Type NoteProperty -name onlyExceptions -value $false -Force
        }
        #Check if debug
        if($null -eq $Configuration.psobject.properties.Item('includeDebug')){
            $Configuration | Add-Member -Type NoteProperty -name includeDebug -value $false -Force
        }
        #Check if includeError
        if($null -eq $Configuration.psobject.properties.Item('includeError')){
            $Configuration | Add-Member -Type NoteProperty -name includeError -value $false -Force
        }
        #Check if includeInfo
        if($null -eq $Configuration.psobject.properties.Item('includeInfo')){
            $Configuration | Add-Member -Type NoteProperty -name includeInfo -value $false -Force
        }
        #Check if includeVerbose
        if($null -eq $Configuration.psobject.properties.Item('includeVerbose')){
            $Configuration | Add-Member -Type NoteProperty -name includeVerbose -value $false -Force
        }
        #Check if includeWarning
        if($null -eq $Configuration.psobject.properties.Item('includeWarning')){
            $Configuration | Add-Member -Type NoteProperty -name includeWarning -value $false -Force
        }
        #Check if includeExceptions
        if($null -eq $Configuration.psobject.properties.Item('includeExceptions')){
            $Configuration | Add-Member -Type NoteProperty -name includeExceptions -value $false -Force
        }
        return $Configuration
    }
    catch{
        $param = @{
            MessageData = $_;
            Tags = @('Initialize-Configuration');
            logLevel = 'Error';
            callStack = (Get-PSCallStack | Select-Object -First 1);
        }
        Write-Debug @param
        #Set verbose
        $param.MessageData = $_.Exception.Message
        Write-Verbose @param
    }
}




