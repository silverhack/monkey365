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

Function Invoke-RuleCheck{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-RuleCheck
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Array]$rules,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$MonkeyData,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$conditionsPath
    )
    Begin{
        #Create array of matched rules
        $matched_rules = @()
        #$affected_assets = @()
        foreach($rule in $rules){
            Write-Verbose -Message ($Script:messages.BuildQueryMessage -f $rule.issue_name)
            $conditions = $rule.conditions
            if($conditions){
                $params = @{
                    conditions = $conditions;
                    conditions_path = $conditionsPath;
                }
                $query = Build-Query @params
                if($query){
                    $rule | Add-Member -type NoteProperty -name query -value $query
                }
                else{
                    $rule | Add-Member -type NoteProperty -name query -value $null
                }
            }
        }
        #Create new array
        $all_rules = @()
        #Remove elements that are not present in dataset
        $all_paths = $rules | Select-Object -ExpandProperty path | Select-Object -Unique
        foreach($elem in $all_paths){
            $exists = $MonkeyData | Select-Object -ExpandProperty $elem -ErrorAction Ignore
            if($null -eq $exists){
                #removing rule
                Write-Verbose -Message ($Script:messages.UnitItemNotFound -f $elem)
                $all_rules += $elem
            }
        }
        $rules = $rules | Where-Object {$_.path -notin $all_rules}
    }
    Process{
        foreach($rule in $rules){
            if($null -ne $rule.query){
                #Get element
                $elements = $MonkeyData | Select-Object -ExpandProperty $rule.path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Data -ErrorAction SilentlyContinue
                $isNull = Test-IsNull -object $elements
                if($isNull -eq $false){
                    $number_of_elements = @($elements).Count
                    #Get Matched elements
                    try{
                        if($null -ne $rule.display_path -and $rule.display_path -ne $rule.path){
                            #Get subelements
                            $elements = $elements.GetPropertyByPath($rule.display_path)
                        }
                        $matched_elements = $elements | Where-Object $rule.query -ErrorAction Ignore;
                    }
                    catch{
                        Write-Verbose -Message ($Script:messages.FailedQueryMessage -f $rule.query, $rule.issue_name)
                        Write-Debug $_
                        $matched_elements = $null
                        continue;
                    }
                    #Check for moreThan exception rule
                    if($rule.psobject.properties.Name.Contains('moreThan')){
                        $count = @($matched_elements).Count
                        if($count -le $rule.moreThan){
                            $matched_elements = $null
                        }
                    }
                    #Check for lessThan exception rule
                    if($rule.psobject.properties.Name.Contains('lessThan')){
                        $count = @($matched_elements).Count
                        if($null -eq $count){$count = 1}
                        if($count -gt $rule.lessThan){
                            $matched_elements = $null
                        }
                    }
                    #Check for removeIfNotExists exception rule
                    if($rule.psobject.properties.Name.Contains('removeIfNotExists')){
                        if($rule.removeIfNotExists.ToString().ToLower() -eq "true"){
                            if($null -eq $matched_elements){
                                continue
                            }
                        }
                    }
                    #Check for shouldExists exception rule
                    if($rule.psobject.properties.Name.Contains('shouldExist')){
                        if($rule.shouldExist.ToString().ToLower() -eq "true"){
                            if($null -eq $matched_elements){
                                if($rule.psobject.properties.Name.Contains('returnObject')){
                                    $new_monkey_object = New-Object -TypeName PSCustomObject
                                    foreach($element in $rule.returnObject.psobject.properties){
                                        $new_monkey_object | Add-Member -Type NoteProperty -name $element.Name -value $element.Value
                                    }
                                    $matched_elements = $new_monkey_object
                                }
                                elseif($null -ne $rule.psobject.properties.Item('showAll')){
                                    if($rule.showAll.ToString().ToLower() -eq "true"){
                                        $matched_elements = $elements
                                    }
                                }
                            }
                            else{
                                continue
                            }
                        }
                    }
                    if($matched_elements){
                        #Clone object
                        $affected_resources = Copy-psObject -object $matched_elements
                        if($null -eq $affected_resources){
                            Write-Warning -Message ($Script:messages.UnableToCloneObject -f "affected resources")
                        }
                        $rule | Add-Member -Type NoteProperty -name affected_resources_count -value (@($affected_resources).Count) -Force
                        #Add metadata to current rule
                        $rule | Add-Member -Type NoteProperty -name affected_resources -value $affected_resources -Force
                        $rule | Add-Member -Type NoteProperty -name resources -value $number_of_elements -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix1 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix2 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix3 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name raw_resources -value $affected_resources -Force
                        $matched_rules+=$rule;
                    }
                    else{
                        $raw_resources = Copy-psObject -object $elements
                        #Add metadata to existing rule
                        $rule | Add-Member -Type NoteProperty -name affected_resources_count -value "0" -Force
                        $rule | Add-Member -Type NoteProperty -name affected_resources -value $null -Force
                        $rule | Add-Member -Type NoteProperty -name resources -value $number_of_elements
                        $rule | Add-Member -Type NoteProperty -name level -value "Good" -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix1 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix2 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name id_suffix3 -value (Get-NewIDSuffix -suffix $rule.id_suffix) -Force
                        $rule | Add-Member -Type NoteProperty -name raw_resources -value $raw_resources -Force
                        $matched_rules+=$rule;
                    }
                }
                else{
                    Write-Warning -Message ($Script:messages.ElementNotFound -f $rule.path)
                }
            }
        }
    }
    End{
        return $matched_rules
    }
}
