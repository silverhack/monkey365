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

Function Select-MonkeyAzureSubscription{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Select-MonkeyAzureSubscription
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Begin{
        $param = $O365Object.application_args.Clone()
        #Create Array for subscriptions
        $AllSubscriptions = @()
        #Create selected subscriptions and sub vars
        $selected_subscriptions = $sub = $null
        $param.TenantId = $O365Object.TenantId
        if($O365Object.isUsingAdalLib){
            $auth_context = Get-MonkeyADALAuthenticationContext -TenantID $param.TenantId
            if($null -eq $param.Item('AuthContext')){
                [ref]$null = $param.Add('AuthContext',$auth_context)
            }
            else{
                $param.AuthContext = $auth_context
            }
        }
        if($null -ne $Script:o365_connections.ResourceManager){
            $sparam = @{
                AuthObject = $Script:o365_connections.ResourceManager
                Endpoint = $O365Object.Environment.ResourceManager
            }
            $sub = Get-MonkeySubscriptionInfo @sparam
        }
        if($null -ne $sub){
            if($null -ne $O365Object.Tenant -and $O365Object.Tenant.psobject.Properties.Item('TenantName')){
                Write-Information -MessageData ("Subscription was found on {0} Tenant" -f $O365Object.Tenant.TenantName) -InformationAction $InformationAction
            }
            elseif ($O365Object.psobject.Properties.Item('TenantId')){
                Write-Information -MessageData ("subscription was found on {0} Tenant" -f $O365Object.tenantId) -InformationAction $InformationAction
            }
            else{
                Write-Information -MessageData ("Subscription {0} was found" -f $sub.DisplayName) -InformationAction $InformationAction
            }
            $sub | Add-Member -type NoteProperty -name TenantID -value $O365Object.TenantId -Force
            if($null -ne $O365Object.Tenant){
                $sub | Add-Member -type NoteProperty -name TenantName -value $O365Object.Tenant.TenantName -Force
                $sub | Add-Member -type NoteProperty -name Tenant -value $O365Object.Tenant -Force
            }
            $AllSubscriptions+=$sub
        }
        else{
            $msg = @{
                MessageData = ($message.AzureSubscriptionNotFound -f $O365Object.TenantId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSubscriptionNotFound');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($AllSubscriptions.Count -gt 0){
            if($AllSubscriptions.Count -eq 1){
                $selected_subscriptions = $AllSubscriptions
            }
            elseif($O365Object.initParams.ContainsKey('all_subscriptions') -and $O365Object.initParams.all_subscriptions -eq $true){
                $selected_subscriptions = $AllSubscriptions
            }
            elseif($O365Object.initParams.ContainsKey('subscriptions')){
                $selected_subscriptions = @()
                foreach($subscriptionId in $O365Object.initParams.subscriptions.Split(' ')){
                    $sub = $AllSubscriptions | Where-Object {$_.subscriptionId -eq $subscriptionId} | Select-Object * -ErrorAction Ignore
                    if($sub){$selected_subscriptions += $sub}
                }
            }
            else{
                if($PSEdition -eq "Desktop"){
                    $selected_subscriptions = $AllSubscriptions | Out-GridView -Title "Choose a Source Subscription ..." -PassThru
                }
                else{
                    $selected_subscriptions = Select-MonkeySubscriptionConsole -Subscriptions $AllSubscriptions
                }
            }
        }
    }
    End{
        if($null -ne $selected_subscriptions){
            return $selected_subscriptions
        }
    }
}
