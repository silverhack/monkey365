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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        $InputObject
    )
    Begin{
        #Refs
        $out = $null
    }
    Process {
        ##Return null if the InputObject is null or is an empty string
        If ($Null -eq $InputObject) {
            Return "NotSet"
        }
        If ($InputObject -is [String] -and $InputObject -eq [String]::Empty){
            return "NotSet"
        }
        ## Iterate over all child objects in cases in which InputObject is an array
        If ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                ForEach ($object in $InputObject) {
                    Format-PsObject -InputObject $object
                }
            )
            ## Return the array but don't enumerate it
            Write-Output -NoEnumerate -InputObject $collection
        }
        ElseIf ($InputObject.GetType() -eq [System.Management.Automation.PSCustomObject] -or $InputObject.GetType() -eq [System.Management.Automation.PSObject]) {
            ## Iterate over all properties and convert it to a new PsObject
            $hash = [ordered]@{ }
            ForEach ($property in $InputObject.PSObject.Properties){
                try{
                    if($null -eq $property.Value){
                        $hash[$property.Name] = "NotSet"
                    }
                    elseif($property.Value -is [String] -and $property.Value -eq [String]::Empty){
                        $hash[$property.Name] = "NotSet"
                    }
                    elseif($property.Value -is [System.Collections.IEnumerable]){
                        $hash[$property.Name] = Format-PsObject -InputObject $property.Value
                    }
                    elseif($property.Value.GetType() -eq [System.Management.Automation.PSCustomObject] -or $property.Value.GetType() -eq [System.Management.Automation.PSObject]){
                        $hash[$property.Name] = Format-PsObject -InputObject $property.Value
                    }
                    elseIf([bool]::TryParse($property.Value, [ref]$out)){
                        if($property.Value.ToString().ToLower() -eq "true"){
                            $hash[$property.Name] = "Enabled"
                        }
                        elseif($property.Value.ToString().ToLower() -eq "false"){
                            $hash[$property.Name] = "Disabled"
                        }
                    }
                    elseIf($null -ne ([string]$property.Value -as [System.URI]) -and $null -ne ([string]$property.Value -as [System.URI]).AbsoluteURI){
                        $uri = $property.Value.ToString() -as [System.URI]
                        $hash[$property.Name] = ("{0}://{1}{2}{3}" -f $uri.Scheme,$uri.DnsSafeHost,$uri.AbsolutePath,[uri]::EscapeDataString($uri.Query))
                    }
                    elseif($property.Value -is [System.String]){
                        $hash[$property.Name] = [System.Security.SecurityElement]::Escape($property.Value)
                    }
                    else{
                        $hash[$property.Name] = $property.Value
                    }
                }
                catch{
                    Write-Verbose ("Unable to format {0}" -f $property.Name)
                    if($null -ne $property.Value){
                        Write-Verbose ("ObjectType is {0}" -f $property.Value.GetType())
                    }
                    elseif($property.Value -is [System.Collections.IEnumerable]){
                        Write-Verbose ("Object is enumerable")
                    }
                    else{
                        Write-Verbose ("Null object detected for {0}" -f $property.Name)
                    }
                    Write-Verbose ("The error was: {0}" -f $_)
                    If($property.Value -is [System.Collections.IEnumerable]){
                        $collection = @(
                            ForEach ($object in $property.Value) {
                                Format-PsObject -InputObject $object
                            }
                        )
                        $hash[$property.Name] = $collection
                    }
                }
            }
            $new_object = [pscustomobject]$hash
            Write-Output $new_object
        }
        Else {
            ##Object isn't an array, hashtable, collection, etc... Cast object
            try{
                If ($Null -eq $InputObject) {
                    "NotSet"
                }
                If ($InputObject -is [String] -and $InputObject -eq [String]::Empty){
                    "NotSet"
                }
                elseIf([bool]::TryParse($InputObject, [ref]$out)){
                    if($InputObject.ToString().ToLower() -eq "true"){
                        "Enabled"
                    }
                    elseif($InputObject.ToString().ToLower() -eq "false"){
                        "Disabled"
                    }
                }
                elseif($null -ne ($InputObject.ToString() -as [System.URI]) -and $null -ne ($InputObject.ToString() -as [System.URI]).AbsoluteURI){
                    $uri = $InputObject.ToString() -as [System.URI]
                    ("{0}://{1}{2}{3}" -f $uri.Scheme,$uri.DnsSafeHost,$uri.AbsolutePath,[uri]::EscapeDataString($uri.Query))
                }
                elseif($InputObject -is [string]){
                    [System.Security.SecurityElement]::Escape($InputObject)
                }
                else{
                    $InputObject
                }
            }
            catch{
                Write-Verbose $_
            }
        }
    }
}
