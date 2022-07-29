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

function Clear-MonkeyADALTokenCache{
    <#
     .SYNOPSIS
     Clear AccessToken local cache

     .DESCRIPTION
     The Clear-MonkeyADALATokenCache function lets you clear OAuth 2.0 AccessToken local cache for
     all authorities

     .EXAMPLE
     Clear-MonkeyADALATokenCache

     This example clear local accesstoken cache for all authorities.
    #>
    # https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.tokencache?view=azure-dotnet
    try{
        $cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared
        if($cache){
            #Clear cache
            $null = $cache.Clear()
            Write-Debug -Message $script:messages.ClearAdalCacheMessage;
        }
    }
    catch{
        Write-Error -Message $_
    }
}
