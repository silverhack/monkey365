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

Function Import-O365Lib{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Import-O365Lib
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    if($null -eq (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
        #Create a new O365 object
        New-O365Object
    }
    try{
        #Import MSAL MODULES
        foreach($mod in $O365Object.msal_modules){
            $tmp_module = ("{0}/{1}" -f $O365Object.Localpath, $mod)
            Import-Module $tmp_module.ToString() -Force -Scope Global
        }
    }
    catch{
        $msg = @{
            MessageData = $_
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            Tags = @('UnableToLoadMSAL');
        }
        Write-Warning @msg
    }
}
