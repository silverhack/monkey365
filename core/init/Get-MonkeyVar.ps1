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

Function Get-MonkeyVar{
    <#
        .SYNOPSIS
            Returns a collection of variables that can be imported into the background runspace
        .DESCRIPTION
            Returns a collection of variables
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyVar
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [OutputType([System.Collections.Hashtable])]
    [cmdletbinding()]
    Param
    ()
    try{
        #Set vars
        $vars = @{
            O365Object = $O365Object;
            WriteLog = $O365Object.WriteLog;
            Verbosity = $O365Object.VerboseOptions;
            InformationAction = $O365Object.InformationAction;
            returnData = $null;
            LogQueue = $null;
        }
        #Get LogQueue
        $Queue = (Get-Variable -Name LogQueue -ErrorAction Ignore);
        if($null -ne $Queue){
            $vars.LogQueue = $Queue.Value;
        }
        #Return object
        return $vars
    }
    Catch{
        throw ("{0}: {1}" -f "Unable to create var object",$_.Exception.Message)
    }
}
