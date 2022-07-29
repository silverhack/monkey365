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

Function Get-MonkeyAzureSubscription {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzureSubscription
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    $param = $O365Object.application_args.Clone()
    $AuthResponses = @()
    #Create Array for subscriptions
    $AllSubscriptions = @()
    #Create selected subscriptions var
    $selected_subscriptions = $null
    if($O365Object.initParams.ContainsKey('TenantId')){
        $tid = $O365Object.initParams.TenantId
    }
    else{
        $tid = [string]::Empty
    }
    $tparam = @{
        AuthObject = $o365_connections.ResourceManager
        Endpoint = $O365Object.Environment.ResourceManager
        TenantId = $tid
    }
    $tenants = Get-TenantsForUser @tparam
    #Connecting to Tenant
    foreach($tenant in $tenants){
        $param.TenantId = $tenant.tenantId
        if($O365Object.isUsingAdalLib){
            $auth_context = Get-MonkeyADALAuthenticationContext -TenantID $param.TenantId
            if($null -eq $param.Item('AuthContext')){
                [ref]$null = $param.Add('AuthContext',$auth_context)
            }
            else{
                $param.AuthContext = $auth_context
            }
        }
        <#
        else{
            if($O365Object.isConfidentialApp -eq $false){
                if(!$O365Object.initParams.ContainsKey('TenantId')){
                    #Not passed TenantId. Trying to scan all tenants for subscriptions
                    #Get msal application arga
                    $new_app_params = $O365Object.msal_application_args.Clone()
                    if($null -eq $new_app_params.Item('TenantId')){
                        [ref]$null = $new_app_params.Add('TenantId',$param.TenantId)
                    }
                    else{
                        $new_app_params.TenantId = $param.TenantId
                    }
                    #Get new application
                    $new_app = New-MonkeyMsalApplication @new_app_params
                    #Add to params
                    $param.publicApp = $new_app;
                    $param.PromptBehavior = "Auto";
                }
            }
        }
        #>
        $AuthResult = (ConnectTo-ResourceManagement $param)
        if($AuthResult){
            Write-Information -MessageData ("Adding {0} tenant displayName..." -f $tenant.displayName) -InformationAction $InformationAction
            #Add tenant information to AuthResult object
            $AuthResult | Add-Member -type NoteProperty -name Tenant -value $tenant -Force
            $AuthResponses += $AuthResult
        }
    }
    if($AuthResponses){
        $O365Object.AuthResponses = $AuthResponses
        #Getting subscriptions
        foreach($auth in $AuthResponses){
            $sparam = @{
                AuthObject = $auth
                Endpoint = $O365Object.Environment.ResourceManager
            }
            $sub = Get-MonkeySubscriptionInfo @sparam
            if($null -ne $sub){
                if($auth.tenant.displayName){
                    Write-Information -MessageData ("Subscription was found on {0} Tenant" -f $auth.tenant.displayName) -InformationAction $InformationAction
                }
                elseif ($auth.TenantId){
                    Write-Information -MessageData ("subscription was found on {0} Tenant" -f $auth.tenantId) -InformationAction $InformationAction
                }
                else{
                    Write-Information -MessageData ("Subscription was found" -f $sub.DisplayName) -InformationAction $InformationAction
                }
                $sub | Add-Member -type NoteProperty -name TenantID -value $auth.TenantID -Force
                $sub | Add-Member -type NoteProperty -name TenantName -value $auth.tenant.displayName -Force
                $sub | Add-Member -type NoteProperty -name Tenant -value $auth.tenant -Force
                $AllSubscriptions+=$sub
            }
        }
    }
    if($AllSubscriptions){
        if($AllSubscriptions.Count -eq 1){
            $selected_subscriptions = $AllSubscriptions
        }
        elseif($O365Object.initParams.ContainsKey('all_subscriptions') -and $O365Object.initParams.all_subscriptions -eq $true){
            $selected_subscriptions = $AllSubscriptions
        }
        elseif($O365Object.initParams.ContainsKey('subscriptions')){
            foreach($subscriptionId in $O365Object.initParams.subscriptions.Split(' ')){
                $sub = $AllSubscriptions | Where-Object {$_.subscriptionId -eq $subscriptionId} | Select-Object * -ErrorAction Ignore
                if($sub){$selected_subscriptions += $sub}
            }
        }
        else{
            <#
            $title = "Subscription Selection"
            $message = "Select subscription"
            # Build the choices menu
            $choices = @()
            $yesToAll = New-Object System.Management.Automation.Host.ChoiceDescription "Select &All","Select all subscriptions."
            $choices+=$yesToAll
            For($index = 0; $index -lt $AllSubscriptions.Count; $index++){
                $choices += New-Object System.Management.Automation.Host.ChoiceDescription ("&{0}" -f $index+1, ($AllSubscriptions[$index]).DisplayName), ($AllSubscriptions[$index]).DisplayName
            }
            $options = [System.Management.Automation.Host.ChoiceDescription[]]$choices
            $result = $host.ui.PromptForChoice($title, $message, $options, 0)
            if($result -eq 0){
                $selected_subscriptions = $AllSubscriptions
            }
            else{
                $selected_subscriptions = $AllSubscriptions[$result-1]
            }
            #>
            if($PSEdition -eq "Desktop"){
                $selected_subscriptions = $AllSubscriptions | Out-GridView -Title "Choose a Source Subscription ..." -PassThru
            }
            else{
                $choices = @()
                For($index = 0; $index -lt $AllSubscriptions.Count; $index++){
                    $AllSubscriptions[$index] | Add-Member -type NoteProperty -name Id -value $index -Force
                    [psobject]$s = @{
                        id = $index+1
                        displayName = $AllSubscriptions[$index].displayName
                    }
                    $choices+=$s
                }
                while ($true) {
                    $choices | Select-Object Id,DisplayName | Format-Table -AutoSize | Out-Host
                    $sbsID = Read-Host "Enter the [ID] number to select a subscription. Type 0 or Q to quit. Type A for all"
                    if ($sbsID -eq '0' -or $sbsID -eq 'Q') { break }  # exit from the loop, user quits
                    if ($sbsID -eq 'A') {$selected_subscriptions = $AllSubscriptions; break }  # exit from the loop, user quits
                    # test if the input is numeric and is in range
                    $badInput = $true
                    if ($sbsID -notmatch '\D') {    # if the input does not contain an non-digit
                        $index = [int]$sbsID - 1
                        if ($index -ge 0 -and $index -lt $AllSubscriptions.Count) {
                            $badInput = $false
                            # everything OK, you now have the index to do something with the selected user
                            Write-Information ("You have selected {0}" -f $AllSubscriptions[$index].DisplayName) -InformationAction $InformationAction
                            $selected_subscriptions = $AllSubscriptions[$index]
                            break
                        }
                    }
                    # if you received bad input, show a message, wait a couple
                    # of seconds so the message can be read and start over
                    if ($badInput) {
                        Write-Warning "Bad input received. Please type only a valid number from the [ID] column."
                        Start-Sleep -Seconds 4
                    }
                }
            }
        }
        if($null -ne $selected_subscriptions){
            return $selected_subscriptions
        }
    }
    else{
        Write-Warning "No valid subscriptions were found"
    }
}
