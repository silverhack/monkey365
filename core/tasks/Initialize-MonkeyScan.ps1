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

Function Initialize-MonkeyScan {
    <#
        .SYNOPSIS
		Sets up a custom configuration, variables and options to create a runspacepool

        .DESCRIPTION
		Sets up a custom configuration, variables and options to create a runspacepool

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyScan
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Collections.Hashtable]])]
	Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider = "Azure",

        [Parameter(Mandatory=$false, HelpMessage="Change the threads settings. Default is 2")]
        [int32]$Throttle = 2,

        [Parameter(Mandatory=$false, HelpMessage="ApartmentState of the thread")]
        [ValidateSet("STA","MTA")]
        [String]$ApartmentState = "STA"
    )
    Begin{
        #Set scans array
        $all_scans = [System.Collections.Generic.List[System.Collections.Hashtable]]::new();
        $scanOptions = $null;
        #Set lib path
        $_path = ("{0}{1}core{2}api{3}" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        #Get all dirs
        $all_dirs = Get-MonkeyDirectory -Path $_path -Recurse
        #Get aad lib
        $aadlibs = @($all_dirs).Where({$_ -like "*EntraID*"})
        #Get Azure lib
        $azureLib = ("{0}{1}core{2}api{3}azure" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        if(-NOT [System.IO.Directory]::Exists($azureLib)){
            throw ("Unable to locate Azure lib")
        }
        $utilsLib = ("{0}{1}core{2}utils" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar)
        if(-NOT [System.IO.Directory]::Exists($utilsLib)){
            throw ("Unable to locate utils directory")
        }
        #Set vars
        try{
            $msg = @{
                MessageData = "Setting and getting variables";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365InitializeScan');
            }
            Write-Information @msg
            #Set vars
            $vars = [ordered]@{
                O365Object = $O365Object;
                WriteLog = $O365Object.WriteLog;
                Verbosity = $O365Object.VerboseOptions;
                InformationAction = $O365Object.InformationAction;
                VerbosePreference = $O365Object.VerboseOptions.VerbosePreference;
                DebugPreference = $O365Object.VerboseOptions.DebugPreference;
                returnData = $null;
                LogQueue = $null;
            }
            #Get LogQueue
            $Queue = (Get-Variable -Name MonkeyLogQueue -Scope Global -ErrorAction Ignore);
            If($null -ne $Queue){
                $vars.LogQueue = $Queue.Value;
            }
        }
        catch{
            throw ("{0}: {1}" -f "Unable to create var object",$_.Exception.Message)
        }
        #Check if collectors are available
        If($null -eq $O365Object.Collectors){
            $abort = $true
        }
        Else{
            $abort = $false
        }
    }
    Process{
        If($abort -eq $false){
            switch ($Provider.ToLower()){
                { @("azure", "entraid") -contains $_ }{
                    $libs = [System.Collections.Generic.List[System.String]]::new();
                    #All of them will have the EntraID lib
                    foreach($lib in $aadlibs){
                        [void]$libs.Add($lib)
                    }
                    $msg = @{
                        MessageData = ("Getting collectors for {0}" -f $Provider);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('Monkey365InitializeScan');
                    }
                    Write-Information @msg
                    if($_ -eq 'entraid'){
                        $collectors = @($O365Object.Collectors).Where({$_.Provider -eq 'EntraID'})
                    }
                    else{
                        $collectors = @($O365Object.Collectors).Where({$_.Provider -eq $Provider})
                        #Add Azure libs to array
                        [void]$libs.Add($azureLib)
                    }
                    if($collectors.Count -gt 0){
                        #Get dependsOn
                        $dependsOn = $collectors | Select-Object -ExpandProperty dependsOn
                        if($null -ne $dependsOn){
                            foreach($depend in @($dependsOn)){
                                $dependslibs = @($all_dirs).Where({$_ -like ("*{0}*" -f $dependsOn)})
                                if($dependslibs){
                                    foreach($lib in $dependslibs){
                                        [void]$libs.Add($lib)
                                    }
                                }
                            }
                        }
                        #Remove folders
                        $libs = @($libs).Where({($_ -notmatch "helpers") -and ($_ -notmatch "utils") -and ($_ -notmatch "csom" -and $_ -notmatch "rest")})
                        #Remove duplicate
                        $libs = $libs | Select-Object -Unique
                        #Add utils
                        $libs+=$utilsLib
                        #Get files
                        $libs = $libs | Get-MonkeyFile -Recurse
                        #remove duplicate
                        $libs = $libs | Select-Object -Unique
                        #only ps1 files
                        $libs = @($libs).Where({$_.EndsWith('ps1')})
                        #Set hashtable
                        $scanOptions = [ordered]@{
                            scanName = $Provider;
                            modules = $O365Object.runspaces_modules;
                            libCommands = $libs;
                            vars = $vars;
                            threads = $Throttle;
                            collectors = $collectors;
                            apartmentState = $ApartmentState;
                            startUpScripts = $O365Object.runspace_init;
                        }
                        [void]$all_scans.Add($scanOptions);
                    }
                    else{
                        $msg = @{
                            MessageData = ("Collectors were not found for {0}" -f $Provider);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365InitializeScan');
                        }
                        Write-Warning @msg
                    }
                }
                'microsoft365'{
                    #Group collectors into a single resource
                    $collectors = @($O365Object.Collectors).Where({$_.Provider -ne 'EntraID' -and $_.Provider -ne 'Azure'}) | Group-Object -Property Resource
                    if($null -ne $collectors){
                        foreach($service in $collectors){
                            $libs = [System.Collections.Generic.List[System.String]]::new();
                            #All of them will have the EntraID lib
                            foreach($lib in $aadlibs){
                                [void]$libs.Add($lib)
                            }
                            $msg = @{
                                MessageData = ("Getting collectors for {0}" -f $service.Name);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'info';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('Monkey365InitializeScan');
                            }
                            Write-Information @msg
                            $msg = @{
                                MessageData = ("{0} collector(s) will be loaded within runspace" -f $service.Count);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'info';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('Monkey365InitializeScan');
                            }
                            Write-Information @msg
                            $extralibs = @($all_dirs).Where({$_ -like ("*{0}*" -f $service.Name)})
                            foreach($lib in $extralibs){
                                [void]$libs.Add($lib)
                            }
                            #Get dependsOn
                            $dependsOn = $service.Group | Select-Object -ExpandProperty dependsOn
                            if($null -ne $dependsOn){
                                foreach($depend in @($dependsOn)){
                                    $dependslibs = @($all_dirs).Where({$_ -like ("*{0}*" -f $dependsOn)})
                                    if($dependslibs){
                                        foreach($lib in $dependslibs){
                                            [void]$libs.Add($lib)
                                        }
                                    }
                                }
                            }
                            $libs = @($libs).Where({($_ -notmatch "helpers") -and ($_ -notmatch "utils") -and ($_ -notmatch "csom" -and $_ -notmatch "rest")})
                            #Remove duplicate
                            $libs = $libs | Select-Object -Unique
                            #Add utils
                            $libs+=$utilsLib
                            #Get files
                            $libs = $libs | Get-MonkeyFile -Recurse
                            #remove duplicate
                            $libs = $libs | Select-Object -Unique
                            #only ps1 files
                            $libs = @($libs).Where({$_.EndsWith('ps1')})
                            #Set hashtable
                            $scanOptions = [ordered]@{
                                scanName = $service.Name;
                                modules = $O365Object.runspaces_modules;
                                libCommands = $libs;
                                vars = $vars;
                                threads = $Throttle;
                                apartmentState = $ApartmentState;
                                collectors = $service.Group;
                                startUpScripts = $O365Object.runspace_init;
                            }
                            [void]$all_scans.Add($scanOptions);
                        }
                    }
                    Else{
                        $msg = @{
                            MessageData = ("Collectors were not found for {0}" -f $Provider);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('Monkey365InitializeScan');
                        }
                        Write-Warning @msg
                    }
                }
            }
        }
        Else{
            $msg = @{
                MessageData = "Collectors were not found for any provider"
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365InitializeScan');
            }
            Write-Warning @msg
        }
    }
    End{
        Write-Output $all_scans -NoEnumerate
    }
}
