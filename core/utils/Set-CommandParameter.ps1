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

Function Set-CommandParameter{
    <#
        .SYNOPSIS
        Set valid parameters for specific command

        .DESCRIPTION
        Set valid parameters for specific command

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Set-CommandParameter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseLiteralInitializerForHashtable', '', Justification = 'PSUseLiteralInitializerForHashtable ')]
    [cmdletbinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [parameter(Mandatory=$True, HelpMessage='Command')]
        [String]$Command,

        [parameter(Mandatory=$True, HelpMessage='Parameters')]
        [Object]$Params
    )
    Begin{
        #Set new dict
        $newPsboundParams = [System.Collections.Hashtable]::new()
    }
    Process{
        try{
            #Get command metadata
            $CommandMetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name $PSBoundParameters['Command'])
            $param = $CommandMetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters['Params'].ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters['Params'][$p])
                }
            }
            #Add verbose, debug, etc..
            [void]$newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
            [void]$newPsboundParams.Add('Verbose',$O365Object.verbose)
            [void]$newPsboundParams.Add('Debug',$O365Object.debug)
            #return parameters
            return $newPsboundParams
        }
        Catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('CommandMetadataError');
            }
            Write-Error @msg
        }
    }
    End{
        #Nothing to do here
    }
}

