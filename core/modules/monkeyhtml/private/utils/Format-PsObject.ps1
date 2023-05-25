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
        elseIf ($InputObject -is [String] -and $InputObject -eq [String]::Empty){
            return "NotSet"
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
                    Write-Verbose ("The error was: {0}" -f $_)
                }
            }
            #Convert to PsObject and return object
            $new_object = [pscustomobject]$objHashTable
            #return object
            return $new_object
        }
        ## Iterate over all child objects in cases in which InputObject is an array
        ElseIf ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]){
            $collection = @(
                foreach ($object in $InputObject){
                    Format-PsObject $object
                }
            )
            Write-Output $collection -NoEnumerate
        }
        ElseIf ($InputObject.GetType() -eq [System.Management.Automation.PSCustomObject] -or $InputObject.GetType() -eq [System.Management.Automation.PSObject]) {
            ## Iterate over all properties and convert it to a new PsObject
            $objHashTable = [ordered]@{}
            ForEach ($property in $InputObject.PSObject.Properties){
                try{
                    $objHashTable[$property.Name] = Format-PsObject $property.Value
                }
                catch{
                    if($null -ne $property){
                        Write-Verbose ("Unable to format {0}" -f $property.Name)
                    }
                    else{
                        Write-Verbose "Null property found"
                    }
                    Write-Verbose ("The error was: {0}" -f $_)
                }
            }
            #Convert to PsObject and return object
            $new_object = [pscustomobject]$objHashTable
            #return object
            return $new_object
        }
        Else {##Object isn't an array, hashtable, collection, etc... Cast object
            try{
                If([bool]::TryParse($InputObject, [ref]$out)){
                    if($InputObject.ToString().ToLower() -eq "true"){
                        return "Enabled"
                    }
                    elseif($InputObject.ToString().ToLower() -eq "false"){
                        return "Disabled"
                    }
                }
                Elseif($null -ne ($InputObject.ToString() -as [System.URI]) -and $null -ne ($InputObject.ToString() -as [System.URI]).AbsoluteURI){
                    $uri = $InputObject.ToString() -as [System.URI]
                    return ("{0}://{1}{2}{3}" -f $uri.Scheme,$uri.DnsSafeHost,$uri.AbsolutePath,[uri]::EscapeDataString($uri.Query))
                }
                Elseif($InputObject -is [string]){
                    return [System.Security.SecurityElement]::Escape($InputObject)
                }
                else{
                    return $InputObject
                }
            }
            catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}