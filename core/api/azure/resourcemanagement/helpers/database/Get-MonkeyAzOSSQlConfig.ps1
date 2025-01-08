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

Function Get-MonkeyAzOSSQlConfig {
    <#
        .SYNOPSIS
		Get OSS sql server configuration

        .DESCRIPTION
		Get OSS sql server configuration

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzOSSQlConfig
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$Server,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2017-12-01"
    )
    Process{
        try{
            $all_config = New-Object System.Collections.Generic.List[System.Object]
            $p = @{
                Id = $Server.Id;
                Resource = "configurations";
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $config = Get-MonkeyAzObjectById @p
            if($config){
                foreach($element in $config){
                    $unit = [ordered]@{
                        serverName = $Server.name;
                        parameterName = $element.name;
                        parameterDescription = $element.Properties.description;
                        parameterValue = $element.Properties.value;
                        parameterDefaultValue = $element.Properties.defaultValue;
                        properties = $element.Properties;
                        rawObject = $element;
                    }
                    #Create PsObject
                    $_obj = New-Object -TypeName PsObject -Property $unit
                    #Add to list
                    [void]$all_config.Add($_obj)
                }
            }
            #return list
            Write-Output $all_config -NoEnumerate
        }
        catch{
            Write-Verbose $_
        }
    }
    End{
        #Nothing to do here
    }
}
