Function Get-OsInfo {
    [CmdletBinding(ConfirmImpact = 'None')]
    [OutputType([System.Management.Automation.PSObject])]
    param ()
    Begin{
        #Set null
        $files = $null;
        #Get RootPath
        $rootPath = ( Split-Path -Path $PSCmdlet.MyInvocation.PSCommandPath -Parent)
        #Get Files
        If ($PSVersionTable.PSEdition -eq 'Desktop'){
            $MsalLibPath = ("{0}/lib/desktop" -f $rootPath)
            $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        }
        Elseif (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Unix')){
            $MsalLibPath = ("{0}/lib/netcore" -f $rootPath)
            $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        }
        Elseif (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Win32NT')){
            $MsalLibPath = ("{0}/lib/desktop" -f $rootPath)
            $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        }
        Else{
            Write-Warning -Message 'Unable to determine if OS is Windows or Linux. Loading MSAL Core'
            $MsalLibPath = ("{0}/lib/netcore" -f $rootPath)
            $files = [System.IO.Directory]::EnumerateFiles($MsalLibPath,"*.dll","AllDirectories")
        }
        #Set ScriptBlock
        $ScriptBlock = {
            $files = $args[0]
            $Assemblies = [System.Collections.Generic.List[string]]::new()
            if($null -ne $files){
                foreach ($file in $files) {
                    $Assemblies.Add($file)
                }
            }
            $params = @{
                LiteralPath = $Assemblies;
                IgnoreWarnings = $true;
                WarningVariable = "warnVar";
                WarningAction = "SilentlyContinue"
            }
            Add-Type @params | Out-Null
            #Create app
            $client_options = [Microsoft.Identity.Client.PublicClientApplicationOptions]::new()
            $client_options.RedirectUri = "http://localhost"
            $client_options.ClientId = [System.Guid]::NewGuid()
            $client_options.AzureCloudInstance = [Microsoft.Identity.Client.AzureCloudInstance]::AzurePublic
            $application_builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($client_options)
            $app = $application_builder.Build()
            #set new Obj
            $osObj = [PsCustomObject]@{
                IsSystemWebViewAvailable = [Microsoft.Identity.Client.OsCapabilitiesExtensions]::IsSystemWebViewAvailable($app);
                IsUserInteractive = [Microsoft.Identity.Client.OsCapabilitiesExtensions]::IsUserInteractive($app);
                IsEmbeddedWebViewAvailable = [Microsoft.Identity.Client.OsCapabilitiesExtensions]::IsEmbeddedWebViewAvailable($app);
            }
            #return Obj
            return $osObj
        }
    }
    Process{
        if($null -ne $files){
            if($null -ne (Get-Command -Name PowerShell -ErrorAction Ignore)){
                PowerShell -args @($files) -Command $ScriptBlock
            }
            elseif($null -ne (Get-Command -Name pwsh -ErrorAction Ignore)){
                pwsh -args @($files) -Command $ScriptBlock
            }
            else{
                Write-Warning "PowerShell not installed"
            }
        }
        else{
            throw ("Unable to load MSAL library")
        }
    }
    End{
        #Nothing to do here
    }
}