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

Function Get-DLPSensitiveInformation{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DLPSensitiveInformation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
    param(
        [parameter(Mandatory=$true, HelpMessage="Rule")]
        [Object]$Rule
    )
    Begin{
        $sit_info = $null;
        $isGroup = $content = $false;
        #New array
        $sit_info = [System.Collections.Generic.List[System.Object]]::new()
        #Check if group
        if($Rule.ContentContainsSensitiveInformation){
            $isGroup = $Rule.ContentContainsSensitiveInformation.Where({([System.Collections.IDictionary]).IsAssignableFrom($_.GetType()) -and $_.ContainsKey('groups')})
            $content = $true
        }
    }
    Process{
        if($isGroup){
            foreach ($element in $Rule.ContentContainsSensitiveInformation.groups){
                if($null -ne $element.Item('sensitivetypes')){
                    #https://github.com/dotnet/platform-compat/blob/master/docs/DE0006.md
                    $sit_dict = [ordered]@{
                        name = $element.name;
                        sit = [System.Collections.Generic.List[System.Object]]::new();
                    }
                    foreach($grp in $element.sensitivetypes){
                        foreach($sit in $grp){
                            $new_dict = [ordered]@{}
                            foreach($elem in $sit.GetEnumerator()){
                                [void]$new_dict.Add($elem.Key, $elem.Value)
                            }
                            #Create Obj
                            $sitObj = New-Object -TypeName PsObject -Property $new_dict
                            #Add to array
                            [void]$sit_dict.sit.Add($sitObj)
                        }
                    }
                    #CreateObj
                    $dictToObj = New-Object -TypeName PsObject -Property $sit_dict
                    #Add to array
                    [void]$sit_info.Add($dictToObj)
                }
            }
        }
        elseif($content){
            $sit_dict = [ordered]@{
                name = $Rule.name;
                sit = [System.Collections.Generic.List[System.Object]]::new();
            }
            foreach ($sit in $Rule.ContentContainsSensitiveInformation){
                $new_dict = [ordered]@{}
                foreach($elem in $sit.GetEnumerator()){
                    [void]$new_dict.Add($elem.Key, $elem.Value)
                }
                #Create Obj
                $sitObj = New-Object -TypeName PsObject -Property $new_dict
                #Add to array
                [void]$sit_dict.sit.Add($sitObj)
            }
            #CreateObj
            $dictToObj = New-Object -TypeName PsObject -Property $sit_dict
            #Add to array
            [void]$sit_info.Add($dictToObj)
        }
        elseif($Rule.IsAdvancedRule){
            $msg = @{
                MessageData = ("Advanced DLP rule detected");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('O365DLPInfo');
            }
            Write-Information @msg
            try{
                $advancedRule = $Rule.AdvancedRule | ConvertFrom-Json
                if($advancedRule){
                    #Get Groups
                    $sitGroup = $advancedRule.Condition.SubConditions.Where({$null -ne $_.PsObject.Properties.Item('ConditionName') -and $_.ConditionName -eq 'ContentContainsSensitiveInformation'}) | Select-Object -ExpandProperty Value -ErrorAction Ignore
                    if($sitGroup){
                        foreach ($element in $sitGroup.groups){
                            if($null -ne $element.PsObject.Properties.Item('sensitivetypes')){
                                #https://github.com/dotnet/platform-compat/blob/master/docs/DE0006.md
                                $sit_dict = [ordered]@{
                                    name = $element.name;
                                    sit = [System.Collections.Generic.List[System.Object]]::new();
                                }
                                foreach($grp in $element.sensitivetypes){
                                    foreach($sit in $grp){
                                        #Add to array
                                        [void]$sit_dict.sit.Add($sit)
                                    }
                                }
                                #CreateObj
                                $dictToObj = New-Object -TypeName PsObject -Property $sit_dict
                                #Add to array
                                [void]$sit_info.Add($dictToObj)
                            }
                        }
                    }
                }
            }
            catch{
                $msg = @{
                    MessageData = ("Unable to get advanced rule for {0}" -f $Rule.Name);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SecComplianceDLPConnectionError');
                }
                Write-Warning @msg
                Write-Error $_
            }
        }
    }
    End{
        return $sit_info
    }
}
