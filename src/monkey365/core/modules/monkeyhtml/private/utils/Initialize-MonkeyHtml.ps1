Function Initialize-MonkeyHtml{
    <#
        .SYNOPSIS
        Utility to set script vars and options to generate HTML report

        .DESCRIPTION
        Utility to set script vars and options to generate HTML report

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-MonkeyHtml
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Report Object")]
        [Object]$Report,

        [parameter(Mandatory= $true, ParameterSetName = 'ConfigFile', HelpMessage= "json config")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The HTML config does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Leaf) ){
                throw "The HTML config argument must be a json file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.json)"){
                throw "The file specified in the config argument must be of type json"
            }
            return $true
        })]
        [System.IO.FileInfo]$ConfigFile,

        [Parameter(Mandatory=$true, ParameterSetName = 'cdn_branch', HelpMessage="Load resources from external source")]
        [Parameter(Mandatory=$true, ParameterSetName = 'cdn_latest', HelpMessage="Load resources from external source")]
        [Parameter(Mandatory=$true, ParameterSetName = 'cdn_tag', HelpMessage="Load resources from external source")]
        [System.Uri]$Repository,

        [Parameter(Mandatory=$true, ParameterSetName = 'LocalCDN', HelpMessage="Load resources from local source")]
        [System.Uri]$LocalRepository,

        [Parameter(Mandatory=$false, ParameterSetName = 'cdn_branch', HelpMessage="Repository branch")]
        [String]$Branch,

        [parameter(Mandatory= $false, ParameterSetName = 'cdn_latest', HelpMessage= "Use latest version")]
        [Switch]$Latest,

        [parameter(Mandatory= $false, ParameterSetName = 'cdn_tag', HelpMessage= "Use latest release tag")]
        [Switch]$LatestTag,

        [Parameter(Mandatory=$true, ParameterSetName = 'Config', HelpMessage="Config object")]
        [Object]$Config,

        [Parameter(Mandatory=$false, HelpMessage="Local assets path")]
        [Parameter(Mandatory=$true, ParameterSetName = 'Config', HelpMessage="Config object")]
        [System.IO.DirectoryInfo]$AssetsPath,

        [Parameter(Mandatory=$true, HelpMessage="Execution info object")]
        [Object]$ExecutionInfo,

        [Parameter(Mandatory=$true, HelpMessage="Rules")]
        [Object]$Rules,

        [Parameter(Mandatory=$true, HelpMessage="Ruleset info")]
        [Object]$RulesetInfo,

        [Parameter(Mandatory=$false, HelpMessage="Instance")]
        [String]$Instance,

        [parameter(Mandatory= $true, HelpMessage= "Directory output")]
        [ValidateScript({
            If( -Not (Test-Path -Path $_) ){
                throw ("The directory does not exist in {0}" -f (Split-Path -Path $_))
            }
            If(-Not (Test-Path -Path $_ -PathType Container) ){
                throw "The OutDir argument must be a directory. Files are not allowed."
            }
            return $true
        })]
        [System.IO.DirectoryInfo]$OutDir
    )
    Process{
        Try{
            Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "HTML Template")
            #main template
            [xml]$html = '<html lang="en"></html>'
            #Set variable template for using in whole script
            Set-Variable -Name Template -Value $html -Scope Script -Force
            Set-Variable -Name Report -Value $PSBoundParameters['Report'] -Scope Script -Force
            Set-Variable -Name Rules -Value $PSBoundParameters['Rules'] -Scope Script -Force
            Set-Variable -Name ExecutionInfo -Value $PSBoundParameters['ExecutionInfo'] -Scope Script -Force
            Set-Variable -Name RulesetInfo -Value $PSBoundParameters['RulesetInfo'] -Scope Script -Force
            Set-Variable -Name Instance -Value $PSBoundParameters['Instance'] -Scope Script -Force
            Set-Variable -Name OutDir -Value $PSBoundParameters['OutDir'] -Scope Script -Force
            #Set execution mode
            Set-Variable -Name mode -Value $PSCmdlet.ParameterSetName.ToLower() -Scope Script -Force
            #Get Config file
            Switch($PSCmdlet.ParameterSetName.ToLower()){
                'configfile'{
                    Try{
                        $_config = Get-Content $PSBoundParameters['ConfigFile'] -raw | ConvertFrom-Json
                        Set-Variable -Name Config -Value $_config -Scope Script -Force
                        Set-Variable -Name LocalPath -Value $ConfigFile.Directory.Parent.FullName -Scope Script -Force
                        Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "Config file")
                        Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "Local path")
                    }
                    Catch{
                        throw ("[MonkeyHtmlError] {0}: {1}" -f $Script:messages.ConfigFileErrorMessage,$_.Exception.Message)
                    }
                }
                #Get config obj
                'config'{
                    Set-Variable -Name Config -Value $PSBoundParameters['Config'] -Scope Script -Force
                    Set-Variable -Name LocalPath -Value $AssetsPath.FullName -Scope Script -Force
                    Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "Config Object")
                    Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "Local path")
                }
                { @("cdn_branch", "cdn_latest", "cdn_tag") -contains $_ }{
                    #Set null
                    $baseUrl = $null;
                    #Set internal variable
                    Set-Variable -Name Repository -Value $PSBoundParameters['Repository'] -Scope Script -Force
                    #Set base url
                    $_url = ("{0}/assets/config.json" -f $PSBoundParameters['Repository']);
                    #Get latest tagged version
                    Switch($PSCmdlet.ParameterSetName.ToLower()){
                        'cdn_branch'{
                            #Set internal Var
                            Set-Variable -Name Branch -Value $Branch -Scope Script -Force
                            #Get baseurl
                            $baseUrl = Convert-UrlToJsDelivr -Url $_url -Branch $PSBoundParameters['Branch']
                        }
                        'cdn_latest'{
                            #Set internal Var
                            Set-Variable -Name UseLatest -Value $true -Scope Script -Force
                            #Get baseurl
                            $baseUrl = Convert-UrlToJsDelivr -Url $_url -Latest
                        }
                        'cdn_tag'{
                            $tag = Get-MonkeyLatestReleaseFromGitHub -Url $PSBoundParameters['Repository']
                            If($null -ne $tag){
                                #Set internal Var
                                Set-Variable -Name GitHubTag -Value $tag -Scope Script -Force
                                #Get baseurl
                                $baseUrl = Convert-UrlToJsDelivr -Url $_url -Tag $tag
                            }
                            Else{
                                Write-Warning ("Unable to get latest Tag from {0} repository" -f $PSBoundParameters['Repository'])
                            }
                        }
                    }
                    If($null -ne $baseUrl){
                        Try{
                            $rawContent = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
                            If($rawContent.StatusCode -eq [System.Net.HttpStatusCode]::OK){
                                $_config = $rawContent.Content | ConvertFrom-Json
                                Set-Variable -Name Config -Value $_config -Scope Script -Force
                                Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "repository config object")
                                Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "repository")
                            }
                        }
                        Catch{
                            throw ("[MonkeyHtmlError] {0}: {1}" -f $Script:messages.ConfigFileErrorMessage,$_.Exception.Message)
                        }
                    }
                }
                'localcdn'{
                    Try{
                        $_url = ("{0}/assets/config.json" -f $PSBoundParameters['LocalRepository']);
                        $param = @{
                            Uri = $_url;
                            UserAgent = "Monkey365";
                            UseBasicParsing = $true;
                        }
                        $rawContent = Invoke-WebRequest @param -ErrorAction Ignore
                        If($null -ne $rawContent -and $rawContent.StatusCode -eq 200){
                            $sr = [System.IO.StreamReader]::new($rawContent.RawContentStream);
                            $configObj = $sr.ReadToEnd() | ConvertFrom-Json
                            $sr.Close();
                            $sr.Dispose();
                            If($null -ne $configObj){
                                Set-Variable -Name Config -Value $configObj -Scope Script -Force
                                Set-Variable -Name Repository -Value $PSBoundParameters['LocalRepository'] -Scope Script -Force
                                Set-Variable -Name Branch -Value "localCDN" -Scope Script -Force
                                Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "repository config object")
                                Write-Verbose ($Script:messages.InitializeVarsInfoMessage -f "repository")
                            }
                        }
                    }
                    Catch{
                        throw ("[MonkeyHtmlError] {0}: {1}" -f $Script:messages.ConfigFileErrorMessage,$_.Exception.Message)
                    }
                }
            }
            return $true
        }
        Catch{
            Write-Error $_
            return $false
        }
    }
}