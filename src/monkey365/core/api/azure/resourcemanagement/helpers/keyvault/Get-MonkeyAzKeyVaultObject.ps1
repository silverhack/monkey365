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

Function Get-MonkeyAzKeyVaultObject {
    <#
        .SYNOPSIS
		Get Azure keyvault object (key, secret, certificate)

        .DESCRIPTION
		Get Azure keyvault object (key, secret, certificate)

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzKeyVaultObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True,ValueFromPipeline = $True, HelpMessage="Vault object")]
        [Object]$KeyVault,

        [parameter(Mandatory=$false, HelpMessage="Object Type")]
        [ValidateSet("keys","secrets","certificates")]
        [String]$ObjectType = "keys",

        [Parameter(Mandatory=$false)]
        [Switch]$GetProperties,

        [Parameter(Mandatory=$false)]
        [Switch]$RotationPolicy
    )
    Process{
        Try{
            #Set array
            $allObjects = [System.Collections.Generic.List[System.Object]]::new()
            #Set null
            $objects = $null;
            $Auth = $O365Object.auth_tokens.AzureVault
            #set Uri
            Switch($ObjectType.ToLower()){
                'keys'{
                    [URI]$uri = ("{0}keys?api-version={1}" -f $KeyVault.properties.vaultUri,'7.4')
                }
                'secrets'{
                    [URI]$uri = ("{0}secrets?api-version={1}" -f $KeyVault.properties.vaultUri,'7.4')
                }
                'certificates'{
                    [URI]$uri = ("{0}certificates?api-version={1}" -f $KeyVault.properties.vaultUri,'7.4')
                }
                default{
                    [URI]$uri = ("{0}keys?api-version={1}" -f $KeyVault.properties.vaultUri,'7.4')
                }
            }
            #Get object
            If($null -ne $Auth -and $null -ne $URI){
                $p = @{
				    Authentication = $Auth;
				    OwnQuery = $URI;
				    Environment = $O365Object.Environment;
				    ContentType = 'application/json';
				    Method = "GET";
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
			    }
			    $objects = Get-MonkeyRMObject @p
                ForEach($object in @($objects).Where({$null -ne $_})){
                    #Check if key is not managed key
                    $managedKey = $object | Select-Object -ExpandProperty managed -ErrorAction Ignore
                    #Set expiration Time
                    If($null -eq $object.attributes.psObject.Properties.Item('exp')){
                        $object.attributes | Add-Member -Type NoteProperty -Name exp -Value $null
                    }
                    #Set days since last update, expiration in months, etc..
                    Try{
                        $updated = $object.attributes.updated
                        $updatedTime = (([System.DateTimeOffset]::FromUnixTimeSeconds($updated)).DateTime).ToString("s")
                        $today = Get-Date
                        $timeSpan = New-TimeSpan -Start $updatedTime -End $today
                        $object.attributes | Add-Member -Type NoteProperty -Name daysSinceLastUpdate -Value $timeSpan.Days -Force
                        #Set expiration date in months
                        $exp = $object.attributes.exp
                        $expiryTime = (([System.DateTimeOffset]::FromUnixTimeSeconds($exp)).DateTime).ToString("s")
                        $today = Get-Date
                        $timeSpan = New-TimeSpan -Start $today -End $expiryTime
                        $months = [Math]::Round($timeSpan.TotalDays / 30, 1)
                        $object.attributes | Add-Member -Type NoteProperty -Name expireinMonths -Value $months -Force
                        $object.attributes | Add-Member -Type NoteProperty -Name expirationDate -Value $expiryTime -Force
                    }
                    Catch{
                        $object.attributes | Add-Member -Type NoteProperty -Name daysSinceLastUpdate -Value $null -Force
                        $object.attributes | Add-Member -Type NoteProperty -Name expireinMonths -Value $null -Force
                        $object.attributes | Add-Member -Type NoteProperty -Name expirationDate -Value $null -Force
                    }
                    If($PSBoundParameters.ContainsKey('GetProperties') -and $PSBoundParameters['GetProperties'].IsPresent){
                        #Construct URI
                        $query = $URI.Query
                        If($null -ne $object.Psobject.Properties.Item('kid')){
                            $newUri = ("{0}{1}" -f $object.kid,$query)
                        }
                        ElseIf($null -ne $object.Psobject.Properties.Item('id')){
                            $newUri = ("{0}{1}" -f $object.id,$query)
                        }
                        Else{
                            $newUri = $null;
                        }
                        If($null -ne $newUri){
                            $p = @{
				                Authentication = $Auth;
				                OwnQuery = $newUri;
				                Environment = $O365Object.Environment;
				                ContentType = 'application/json';
				                Method = "GET";
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
			                }
			                $properties = Get-MonkeyRMObject @p
                            $object | Add-Member -Type NoteProperty -Name properties -Value $properties -Force
                        }
                    }
                    If($PSBoundParameters.ContainsKey('RotationPolicy') -and $PSBoundParameters['RotationPolicy'].IsPresent -and $ObjectType.ToLower() -eq "keys"){
                        If($null -eq $managedKey){
                            #Construct URI
                            $query = $uri.Query
                            If($null -ne $object.Psobject.Properties.Item('kid')){
                                $newUri = ("{0}/rotationpolicy{1}" -f $object.kid,$query)
                            }
                            ElseIf($null -ne $object.Psobject.Properties.Item('id')){
                                $newUri = ("{0}/rotationpolicy{1}" -f $object.id,$query)
                            }
                            Else{
                                $newUri = $null;
                            }
                            If($null -ne $newUri){
                                $p = @{
				                    Authentication = $Auth;
				                    OwnQuery = $newUri;
				                    Environment = $O365Object.Environment;
				                    ContentType = 'application/json';
				                    Method = "GET";
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
			                    }
			                    $_rotationPolicy = Get-MonkeyRMObject @p
                                $object | Add-Member -Type NoteProperty -Name rotationPolicy -Value $_rotationPolicy -Force
                            }
                        }
                    }
                    If($managedKey -and $ObjectType.ToLower() -eq 'keys'){
                        continue
                    }
                    #Add to array
                    [void]$allObjects.Add($object);
                }
            }
            Write-Output $allObjects -NoEnumerate
        }
        Catch{
            Write-Verbose $_
        }
    }
}
