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
    [OutputType([System.Management.Automation.PSObject])]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Configuration")]
        [Object] $Configuration
    )
    Try{
        #Check If only exceptions must be logged
        If($null -eq $Configuration.psobject.properties.Item('onlyExceptions')){
            $Configuration | Add-Member -Type NoteProperty -name onlyExceptions -value $false -Force
        }
        #Check If debug
        If($null -eq $Configuration.psobject.properties.Item('includeDebug')){
            $Configuration | Add-Member -Type NoteProperty -name includeDebug -value $false -Force
        }
        #Check If includeError
        If($null -eq $Configuration.psobject.properties.Item('includeError')){
            $Configuration | Add-Member -Type NoteProperty -name includeError -value $false -Force
        }
        #Check If includeInfo
        If($null -eq $Configuration.psobject.properties.Item('includeInfo')){
            $Configuration | Add-Member -Type NoteProperty -name includeInfo -value $false -Force
        }
        #Check If includeVerbose
        If($null -eq $Configuration.psobject.properties.Item('includeVerbose')){
            $Configuration | Add-Member -Type NoteProperty -name includeVerbose -value $false -Force
        }
        #Check If includeWarning
        If($null -eq $Configuration.psobject.properties.Item('includeWarning')){
            $Configuration | Add-Member -Type NoteProperty -name includeWarning -value $false -Force
        }
        #Check If includeExceptions
        If($null -eq $Configuration.psobject.properties.Item('includeExceptions')){
            $Configuration | Add-Member -Type NoteProperty -name includeExceptions -value $false -Force
        }
        return $Configuration
    }
    Catch{
        $p = @{
            Message = $_.Exception.Message;
            Tags = @('Initialize-Configuration');
            logLevel = 'Error';
            callStack = (Get-PSCallStack | Select-Object -First 1);
        }
        Write-Error @p
        #Set verbose
        $p.Message = $_
        Write-Verbose @p
    }
}




