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

Function Get-MonkeyServiceManagementObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyServiceManagementObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType
    )
    Begin{
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
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "Service management API")
            return
        }
        #Write Progress information
        $statusBar=@{
                Activity = "Azure Service Management Query"
                CurrentOperation=""
                Status="Script started"
        }
        [String]$startCon = ("Starting Azure Service Management Rest Query on {0} to get {1}" -f $Environment.ServiceManagement, $ObjectType)
        $statusBar.Status = $startCon
        #$AuthHeader = $Authentication.Result.CreateAuthorizationHeader()
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        $URI = '{0}/{1}/services/{2}' -f $Environment.ServiceManagement, $Authentication.subscriptionId, $ObjectType
    }
    Process{
        try{
            if($URI){$requestHeader = @{"x-ms-version" = "2014-10-01";"Authorization" = $AuthHeader}}
            Write-Progress @statusBar
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URI)
            $ServicePoint.ConnectionLimit = 1000;
            $param = @{
                Url = $URI;
                Headers = $requestHeader;
                Method = 'Get';
                ContentType = $ContentType;
                UserAgent = $O365Object.UserAgent;
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            $AllObjects = Invoke-MonkeyWebRequest @param
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
        catch{
            Write-Verbose $_
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
    }
    End{
        if($AllObjects){
            Write-Progress -Activity ("Azure request for object type {0}" -f $ObjectType.Trim()) -Completed -Status "Status: Completed"
            return $AllObjects
        }

    }

}


