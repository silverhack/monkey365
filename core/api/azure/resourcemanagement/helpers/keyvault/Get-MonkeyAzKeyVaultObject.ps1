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
        [Parameter(Mandatory=$True, ParameterSetName = 'KeyVault')]
        [Object]$KeyVault,

        [parameter(Mandatory=$false, HelpMessage="Object Type")]
        [ValidateSet("keys","secrets","certificates")]
        [String]$ObjectType = "keys",

        [Parameter(Mandatory=$false)]
        [Switch]$GetProperties,

        [Parameter(Mandatory=$false)]
        [Switch]$RotationPolicy
    )
    try{
        $objects = $null;
        $Auth = $O365Object.auth_tokens.AzureVault
        #set Uri
        If($ObjectType -eq 'keys'){
            [URI]$URI = ("{0}keys?api-version={1}" -f $KeyVault.Properties.vaultUri,'7.4')
        }
        ElseIf($ObjectType -eq 'secrets'){
            [URI]$URI = ("{0}secrets?api-version={1}" -f $KeyVault.Properties.vaultUri,'7.4')
        }
        Else{
            [URI]$URI = ("{0}certificates?api-version={1}" -f $KeyVault.Properties.vaultUri,'7.4')
        }
        #Get object
        if($null -ne $Auth -and $null -ne $URI){
            $params = @{
				Authentication = $Auth;
				OwnQuery = $URI;
				Environment = $O365Object.Environment;
				ContentType = 'application/json';
				Method = "GET";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
			}
			$objects = Get-MonkeyRMObject @params
        }
        If($null -ne $objects){
            ForEach($obj in @($objects)){
                #Set expiration Time
                If($null -eq $obj.attributes.psobject.Properties.Item('exp')){
                    $obj.attributes | Add-Member -Type NoteProperty -Name exp -Value $null
                }
                #Set days since last update
                Try{
                    $updated = $obj.attributes.updated
                    $updatedTime = (([System.DateTimeOffset]::FromUnixTimeSeconds($updated)).DateTime).ToString("s")
                    $today = Get-Date
                    $timeSpan = New-TimeSpan -Start $updatedTime -End $today
                    $obj.attributes | Add-Member -Type NoteProperty -Name daysSinceLastUpdate -Value $timeSpan.Days
                }
                Catch{
                    $obj.attributes | Add-Member -Type NoteProperty -Name daysSinceLastUpdate -Value $null
                }
            }
            If($GetProperties.IsPresent){
                foreach($obj in @($objects)){
                    #Construct URI
                    $query = $URI.Query
                    if($null -ne $obj.Psobject.Properties.Item('kid')){
                        $newUri = ("{0}{1}" -f $obj.kid,$query)
                    }
                    elseif($null -ne $obj.Psobject.Properties.Item('id')){
                        $newUri = ("{0}{1}" -f $obj.id,$query)
                    }
                    else{
                        $newUri = $null;
                    }
                    if($null -ne $newUri){
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
                        if($properties){
                            $obj | Add-Member -Type NoteProperty -Name properties -Value $properties
                        }
                    }
                }
            }
            If($RotationPolicy.IsPresent -and $ObjectType -eq "keys"){
                foreach($obj in @($objects)){
                    #Construct URI
                    $query = $URI.Query
                    if($null -ne $obj.Psobject.Properties.Item('kid')){
                        $newUri = ("{0}/rotationpolicy{1}" -f $obj.kid,$query)
                    }
                    elseif($null -ne $obj.Psobject.Properties.Item('id')){
                        $newUri = ("{0}/rotationpolicy{1}" -f $obj.id,$query)
                    }
                    else{
                        $newUri = $null;
                    }
                    if($null -ne $newUri){
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
                        if($rotationPolicy){
                            $obj | Add-Member -Type NoteProperty -Name rotationPolicy -Value $_rotationPolicy
                        }
                        Else{
                            $obj | Add-Member -Type NoteProperty -Name rotationPolicy -Value $null
                        }
                    }
                }
            }
            #return data
            return $objects
        }
    }
    catch{
        Write-Verbose $_
    }
}
