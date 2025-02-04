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


Function Update-MonkeyCSOMObject{
    <#
        .SYNOPSIS
		Remove special chars in a particular object, such as: Web, List, Folder or List Item

        .DESCRIPTION
		Remove special chars in a particular object, such as: Web, List, Folder or List Item

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-MonkeyCSOMObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $true, HelpMessage="SharePoint Object")]
        [Object]$Object
    )
    Process{
        try{
            $_object = New-Object -TypeName PSCustomObject
            foreach($elem in $Object.psobject.properties){
                if($elem.Name.Contains("$")){
                    $_object | Add-Member NoteProperty -name $elem.Name.Split('$')[0] -value $elem.Value -Force
                }
                else{
                    $_object | Add-Member NoteProperty -name $elem.Name -value $elem.Value -Force
                }
            }
            return $_object
        }
        catch{
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('CSOMCleanObjectError');
            }
            Write-Verbose @msg
        }
    }
}

