Set-StrictMode -Version Latest

# Ensure TLS 1.2 is enabled
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

#Add method to disable SSL certificate validation
$certCallback=@"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                    delegate
                    (
                        Object obj,
                        X509Certificate certificate,
                        X509Chain chain,
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@

if(-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type){
    Add-Type $certCallback
}

$monkeyPublicPath = ("{0}/public" -f $PSScriptRoot)

$monkeyPrivatePath = ("{0}/private" -f $PSScriptRoot)

#Load public files
$monkeyFiles = Get-ChildItem -Path $monkeyPublicPath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

#Load private files
$monkeyFiles = Get-ChildItem -Path $monkeyPrivatePath -Recurse -File -Include "*.ps1"

foreach($monkeyFile in $monkeyFiles){
    . $monkeyFile.FullName
}

$script:messages = Get-LocalizedData -DefaultUICulture 'es-ES'