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

Function Split-Array {
    <#
        .SYNOPSIS
		Separates elements into small arrays

        .DESCRIPTION
		Separates elements into small arrays

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Split-Array
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.object[]])]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
        ,
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Elements
    )
    Begin {
        $queue = [System.Collections.Generic.Queue[object]]::new($Elements)
    }
    Process {
        $queue.Enqueue($InputObject)
        if ($queue.Count -eq $Elements) {
            , $queue.ToArray()
            $queue.Clear()
        }
    }
    End {
        if ($queue.Count) {
          , $queue.ToArray()
        }
    }
}

