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

Function New-MonkeyReportDir{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-MonkeyReportDir
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$OutDir
    )
    Begin{
        if (!(Test-Path -Path $OutDir)){
            $tmpdir = New-Item -ItemType Directory -Path $OutDir
            $msg = @{
                MessageData = ($message.NewFolderMessage -f $tmpdir.FullName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('NewDirectory');
            }
            Write-Debug @msg
        }
        $guid = Get-MonkeyGuid
        $out_directory = ("{0}/{1}" -f $OutDir,$guid)
    }
    Process{
        if (!(Test-Path -Path $out_directory)){
            try{
				$tmpdir = New-Item -ItemType Directory -Path $out_directory
				return $out_directory
			}
			catch{
                $msg = @{
                    MessageData = ($message.UnableToCreateDirectory -f $out_directory);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('NewDirectory');
                }
                Write-Warning @msg
                #Write-Debug
                $msg = @{
                    MessageData = $_;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'debug';
                    InformationAction = $InformationAction;
                    Tags = @('NewDirectory');
                }
                Write-Debug @msg
			}
        }
    }
    End{
        #Nothing to do here
    }
}
