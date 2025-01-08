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

Function Get-HtmlColClass{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HtmlColClass
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$size
    )
    Process{
        try{
            switch ($size.ToLower()) {
                'large' { return 'justify-content-center col-12 col-lg-12 col-xl-12 grid-margin' }
                'medium' {return 'justify-content-center col-12 col-lg-6 col-xl-4 grid-margin'}
                'small' {return 'justify-content-center col-12 col-lg-4 col-xl-4 grid-margin' }
                Default { return 'justify-content-center col-12 col-lg-12 col-xl-12 grid-margin' }
            }
        }
        catch{
            return 'justify-content-center col-12 col-lg-12 col-xl-12'
        }
    }
}

