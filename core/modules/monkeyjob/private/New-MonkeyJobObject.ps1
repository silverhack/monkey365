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

Function New-MonkeyJobObject {
<#
        .SYNOPSIS
		Create a new Job object

        .DESCRIPTION
		Create a new Job object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyJobObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[cmdletbinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param ()
    Process{
        try{
            #Create ordered dictionary
            $new_obj = [ordered]@{
                Id = ([guid]::NewGuid()).Guid;
                Name = $null;
		        StartTime = (Get-Date).ToUniversalTime();
                RunspacePoolId = $null;
                Job = $null;
                Task = $null;
                Command  = $null;
            }
            #Create PsObject
            $MonkeyJobObject = [pscustomobject]$new_obj
            #return object
            return $MonkeyJobObject
        }
        catch{
		    Write-Verbose $script:messages.MonkeyJobObjectError
            Write-Verbose $_
        }
    }
}

