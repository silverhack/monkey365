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

Function Format-PsObject {
    <#
        .SYNOPSIS
            Cast PsObjects

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-PsObject
            Version     : 1.0

            Since it is unknown what exists in the InputObject, this function will not have a standard return type.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ParameterSetName='InputObject', position=0, ValueFromPipeline=$true, HelpMessage="Object")]
        [AllowEmptyString()]
        [AllowNull()]
        $InputObject
    )
    Begin{
        #Refs
        $out = $null
    }
    Process{
        ##Return null if the InputObject is null or is an empty string
        If ($null -eq $InputObject) {
            return "NotSet"
        }
        ElseIf ($InputObject -is [String] -and $InputObject -eq [String]::Empty){
            return "NotSet"
        }
        ElseIf (([System.Management.Automation.PSCustomObject]).IsAssignableFrom($InputObject.GetType()) -or ([System.Management.Automation.PSObject]).IsAssignableFrom($InputObject.GetType())) {
            ## Iterate over all properties and convert it to a new PsObject
            $objHashTable = [ordered]@{}
            ForEach ($property in $InputObject.PSObject.Properties){
                Try{
                    $objHashTable[$property.Name] = Format-PsObject $property.Value
                }
                Catch{
                    If($null -ne $property){
                        Write-Verbose ("Unable to format {0}" -f $property.Name)
                    }
                    Else{
                        Write-Verbose "Null property found"
                    }
                    Write-Verbose $_
                }
            }
            #Convert to PsCustomObject
            $newObj = New-Object -TypeName PSCustomObject -Property $objHashTable
            return $newObj
        }
        #Check if dictionary
        If(([System.Collections.IDictionary]).IsAssignableFrom($InputObject.GetType())){
            ## Iterate over all properties and convert it to a new PsObject
            $objHashTable = [ordered]@{}
            $keys = $InputObject.Keys;
            ForEach($key in $keys){
                Try{
                    $objHashTable[$key] = Format-PsObject $InputObject[$key]
                }
                Catch{
                    Write-Verbose $_
                }
            }
            If($objHashTable.Count -gt 0){
                #Convert to PsCustomObject
                $newObj = New-Object -TypeName PSCustomObject -Property $objHashTable
                return $newObj
            }
            Else{
                return "NotSet"
            }
        }
        ## Iterate over all child objects in cases in which InputObject is an array
        ElseIf ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]){
            $collection = @(
                foreach ($object in $InputObject){
                    Format-PsObject $object
                }
            )
            If($collection.Count -gt 0){
                Write-Output $collection -NoEnumerate
            }
            Else{
                return "NotSet"
            }
        }
        Else {##Object isn't an array, hashtable, collection, etc... Cast object
            Try{
                If([bool]::TryParse($InputObject, [ref]$out)){
                    If($InputObject.ToString().ToLower() -eq "true"){
                        return "Enabled"
                    }
                    ElseIf($InputObject.ToString().ToLower() -eq "false"){
                        return "Disabled"
                    }
                }
                ElseIf($null -ne ($InputObject.ToString() -as [System.URI]) -and $null -ne ($InputObject.ToString() -as [System.URI]).AbsoluteURI){
                    $uri = $InputObject.ToString() -as [System.URI]
                    return ("{0}://{1}{2}{3}" -f $uri.Scheme,$uri.DnsSafeHost,$uri.AbsolutePath,[uri]::EscapeDataString($uri.Query))
                }
                ElseIf($InputObject -is [string]){
                    return [System.Security.SecurityElement]::Escape($InputObject)
                }
                Else{
                    return $InputObject
                }
            }
            Catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}