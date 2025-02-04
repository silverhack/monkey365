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

Function Get-IssueLevelSpanClass{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-IssueLevelSpanClass
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$level
    )
    Process{
        switch ($level.ToLower()) {
            'medium' { return 'fa finding-badge finding-badge-warning' }
            'info' {return 'fa finding-badge finding-badge-info'}
            'low' {return 'fa finding-badge finding-badge-low'}
            'good' {return 'fa finding-badge finding-badge-good' }
            'high' { return 'fa finding-badge finding-badge-danger' }
            'critical' { return 'fa finding-badge finding-badge-critical' }
            Default { return 'fa finding-badge finding-badge-unknown' }
        }
    }
}


