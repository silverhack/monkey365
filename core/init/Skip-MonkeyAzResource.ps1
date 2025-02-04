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

Function Skip-MonkeyAzResource{
    <#
        .SYNOPSIS
        Skipping Azure resources from being scanned
        .DESCRIPTION
        Skipping Azure resources from being scanned
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Skip-MonkeyAzResource
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    Begin{
        #Set var
        $az_exclusion_file = $null
        $all_exclusions = @()
        if($null -ne $O365Object.excludedResources -and $null -ne $O365Object.all_resources){
            if($O365Object.excludedResources.Exists){
                try{
                    $az_exclusion_file = (Get-Content $O365Object.excludedResources.FullName -Raw) | ConvertFrom-Json
                }
                catch{
                    $msg = @{
                        MessageData = $_;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('UnabletoGetExclusions');
                    }
                    Write-Warning @msg
                }
            }
            else{
                throw ("{0} exclusion file not found" -f $O365Object.excludeResources.FullName)
            }
        }
    }
    Process{
        #Validate file
        if($null -ne $az_exclusion_file -and $null -ne $az_exclusion_file.Psobject.Properties.Item('exclusions') -and $null -ne $az_exclusion_file.exclusions){
            foreach($exclusion in $az_exclusion_file.exclusions){
                if($exclusion.PsObject.Properties.Item('code') -and $exclusion.PsObject.Properties.Item('suppress')){
                    $suppress = $exclusion.suppress
                    if($null -ne $suppress -and $suppress.PsObject.Properties.Item('pattern') -and $suppress.PsObject.Properties.Item('justification')){
                        $all_exclusions+=$exclusion
                    }
                }
            }
        }
    }
    End{
        #Skipping elements
        if($all_exclusions.Count -gt 0){
            foreach($exclusion in $all_exclusions){
                $pattern = $exclusion.suppress.pattern
                $match = $O365Object.all_resources | Where-Object {$_.Id -like $pattern}
                if($match){
                    $message = ("Excluding {0} Azure resource(s) with pattern {1}. The following justification was included: {2}" -f @($match).Count, $exclusion.suppress.pattern, $exclusion.suppress.justification)
                    $msg = @{
                        MessageData = $message;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('ExcludeAzureResourceFromScanning');
                    }
                    #Write-Warning @msg
                    Write-Warning $message
                    #Remove elements
                    $O365Object.all_resources = $O365Object.all_resources | Where-Object {$_.Id -notlike $pattern}
                }
            }
        }
    }
}

