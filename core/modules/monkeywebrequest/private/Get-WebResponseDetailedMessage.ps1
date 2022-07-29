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

Function Get-WebResponseDetailedMessage{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-WebResponseDetailedMessage
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$response
    )
    Process{
        if($response -is [System.Net.HttpWebResponse]){
            try{
                #Write response headers
                Write-Debug -Message ($script:messages.ResponseHeaders -f $response.Headers)
                #Write Status Code
                Write-Debug -Message ($script:messages.StatusCode -f $response.StatusCode)
                #Write Server Header
                Write-Debug -Message ($script:messages.ServerHeader -f $response.ResponseUri)
            }
            catch{
                Write-Debug -Message $script:messages.UnableToGetHttpWebResponse
            }
        }
        else{
            Write-Debug -Message ($script:messages.UnknownHttpWebResponse -f $response)
        }
    }
}
