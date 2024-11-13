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

Function Test-MandatoryParameter{
    <#
        .SYNOPSIS
        Test for mandatory parameters

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-MandatoryParameter
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param ()
    try{
        #Find empty analysis parameter
        if(($null -eq $O365Object.initParams.Collect -or $O365Object.initParams.Collect.Count -eq 0) -and $null -eq $O365Object.IncludeEntraID){
            throw ("[EmptyParameterError] Please select a valid option with the -Analysis flag or use the -IncludeEntraId. For more information, please see https://silverhack.github.io/monkey365/ or use Get-Help Invoke-Monkey365 -Detailed")
        }
        #Find duplicates in analysis parameter
        $duplicateValue = $O365Object.initParams.Collect | Group-Object | Where-Object -Property Count -gt 1
        if($duplicateValue){
            throw ("[DuplicateValueError] Duplicate values were found: {0}" -f ($duplicateValue.Name -join ', '))
        }
        #Check if instance or EntraId was selected
        if($null -eq $O365Object.Instance -and $null -eq $O365Object.IncludeEntraID){
            throw ("[InstanceError] Unable to execute Monkey365. Please select a valid environment with -Instance parameter or use the -IncludeEntraId. For more information, please see https://silverhack.github.io/monkey365/ or use Get-Help Invoke-Monkey365 -Detailed")
        }
    }
    catch{
        throw ("[ParameterError] {0}: {1}" -f "Unable to start",$_.Exception.Message)
    }
}
