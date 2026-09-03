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

Function New-MonkeyDiagnosticSettingObject {
<#
        .SYNOPSIS
		Create a new diagnostic setting object

        .DESCRIPTION
		Create a new diagnostic setting object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyDiagnosticSettingObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	Param (
        [parameter(Mandatory= $false, ValueFromPipeline = $True, HelpMessage="diagnostic setting object")]
        [AllowNull()]
        [Object]$InputObject
    )
    Process{
        try{
            #Create ordered dictionary
            $diagObj = [ordered]@{
                id = $null;
                name = $null;
                type = $null;
                properties = $null;
                enabled = $false;
                rawObject = $null;
            }
            If(($null -ne $InputObject) -and (($InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore) -match "Microsoft.Insights/diagnosticSettings")){
                $diagObj.id = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore;
                $diagObj.name = $InputObject | Select-Object -ExpandProperty name -ErrorAction Ignore;
                $diagObj.type = $InputObject | Select-Object -ExpandProperty type -ErrorAction Ignore;
                $diagObj.properties = $InputObject | Select-Object -ExpandProperty properties -ErrorAction Ignore;
                $diagObj.enabled = $True;
                $diagObj.rawObject = $InputObject;
            }
            #Create PsObject
            $_obj = New-Object -TypeName PsObject -Property $diagObj
            #return object
            return $_obj
        }
        catch{
            $msg = @{
			    MessageData = ($message.MonkeyObjectCreationFailed -f "Diagnostic Setting");
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'error';
			    InformationAction = $O365Object.InformationAction;
			    Tags = @('DiagnosticSettingObjectError');
		    }
		    Write-Error @msg
            $msg.MessageData = $_
            $msg.LogLevel = "Verbose"
            $msg.Tags+= "DiagnosticSettingObjectError"
            [void]$msg.Add('verbose',$O365Object.verbose)
		    Write-Verbose @msg
        }
    }
}
