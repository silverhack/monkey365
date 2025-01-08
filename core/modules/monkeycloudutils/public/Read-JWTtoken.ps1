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

function Read-JWTtoken {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Read-JWTtoken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>


    [cmdletbinding()]
    param([Parameter(Mandatory=$true)][string]$token)
    try{
        #Validate as per https://tools.ietf.org/html/rfc7519
        #Access and ID tokens are fine, Refresh tokens will not work
        if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
        #Header
        $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
        #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
        while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
        #Payload
        $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
        #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
        while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
        #Convert to Byte array
        $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
        #Convert to string array
        $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
        #Convert from JSON to PSObject
        $tokobj = $tokenArray | ConvertFrom-Json
        return $tokobj
    }
    catch{
        Write-Error $_
    }
}

