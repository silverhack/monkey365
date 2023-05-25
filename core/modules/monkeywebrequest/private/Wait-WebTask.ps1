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

function Wait-WebTask{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Wait-WebTask
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Threading.Tasks.Task[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Threading.Tasks.Task[]]$Task
    )
    Begin{
        $Tasks = @()
    }
    Process {
        $Tasks+=$Task
    }
    End{
        try{
            While (-not [System.Threading.Tasks.Task]::WaitAll($Tasks, 10000)) {}
            #$Tasks.ForEach( { $_.GetAwaiter()})
            $Tasks.ForEach( { $_})
        }
        catch{
            $param = @{
                Task = $_;
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            Get-WebTaskException @param
        }
    }
}
