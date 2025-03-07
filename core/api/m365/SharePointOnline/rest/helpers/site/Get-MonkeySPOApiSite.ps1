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

Function Get-MonkeySPOApiSite{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPOApiSite
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Auth Object")]
        [Object]$Authentication,

        [Parameter(Mandatory=$false, HelpMessage="Scan sub sites")]
        [Switch]$ScanSubSites
    )
    Begin{
        #Set False
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #Set new List
        $all_sites = New-Object System.Collections.Generic.List[System.Object]
        #Set Query
        if($PSBoundParameters.ContainsKey('ScanSubSites') -and $PSBoundParameters.ScanSubSites){
            $QueryText = '(contentclass:STS_Site contentclass:STS_Web)';
        }
        else{
            $QueryText = '(contentclass:STS_Site)';
        }
        #Auth object
        $p = @{
            Authentication = $Authentication;
            Endpoint = $Authentication.Resource;
            QueryText = $QueryText;
            Verbose = $Verbose;
            Debug = $Debug;
            InformationAction = $InformationAction;
        }
        $raw_sites = Invoke-MonkeySPOApiSearch @p
    }
    Process{
        if($null -ne $raw_sites){
            foreach($rows in $raw_sites.PrimaryQueryResult.RelevantResults.Table.Rows){
                foreach($row in $rows){
                    #Parse element
                    $new_dict = @{}
                    foreach($element in $row.Cells){
                        try{
                            $valueType = $element.ValueType.Split('.')[1]
                        }
                        catch{
                            $valueType = "null"
                        }
                        if($null -eq $element.Value){
                            $new_dict.Add($element.Key,$null)
                        }
                        else{
                            $value = [System.Management.Automation.LanguagePrimitives]::ConvertTo($element.Value, $valueType)
                            $new_dict.Add($element.Key,$value)
                        }
                    }
                    #Create new psObject
                    $sps_object = New-Object PSObject -Property $new_dict
                    #Add to list
                    [void]$all_sites.Add($sps_object)
                }
            }
        }
    }
    End{
        return $all_sites
    }
}


