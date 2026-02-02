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

Function Update-MonkeyAsset{
    <#
        .SYNOPSIS
        Update assets from external source

        .DESCRIPTION
        Update assets from external source

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-MonkeyAsset
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'Assets')]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="GitHub release url")]
        [String]$Url,

        [Parameter(Mandatory=$false, HelpMessage="Check integrity with SHA256")]
        [Switch]$SHA256,

        [Parameter(Mandatory=$false, HelpMessage="Check integrity with SHA512")]
        [Switch]$SHA512,

        [Parameter(Mandatory=$false, HelpMessage="Add a file with version ID")]
        [Switch]$IncludeVersionId,

        [parameter(Mandatory= $true, HelpMessage= "Directory output")]
        [System.IO.DirectoryInfo]$Output
    )
    Begin{
        #Add System.IO.Compression
        Add-Type -Assembly 'System.IO.Compression'
        $zip = $shaZip = $content = $method = $cryptography = $Hash = $version = $vId = $null;
        #Create dictionary with cryptograpy items
        $crypto = @{
            sha256 = [System.Security.Cryptography.SHA256]::Create();
            sha512 = [System.Security.Cryptography.SHA512]::Create();
        }
        # Ensure that SHA256 is used if integrity mechanism is not provided
        $method = $PSBoundParameters.Keys.Where({$_ -like '*SHA*'})
        If($method.Count -eq 0){
            $method = "sha256"
        }
        Write-Information ("Using {0} method" -f $method.ToLower()) -InformationAction $InformationPreference
        $cryptography = $crypto.Item($method.ToLower());
        #Check if cryptography is null
        If($null -eq $cryptography){
            Write-Warning "Unable to determine integrity check method. Using default SHA256 method"
            $cryptography = $crypto.Item('sha256');
            $method = "sha256"
        }
        If($Url.Contains('api.github.com')){
            $repoUrl = $Url;
        }
        Else{
            Try{
                $repoUrl = ("https://api.github.com/repos/{0}/{1}/releases/latest" -f $Url.Split('/')[-2],$Url.Split('/')[-1])
            }
            Catch{
                Write-Error $_
                return $null
            }
        }
        #Set headers
        $headers =  @{
            Accept = "application/json";
        }
        #Get release
        Try{
            If($null -ne $repoUrl){
                $param = @{
                    Uri = $repoUrl;
                    Headers = $headers;
                    UserAgent = "Monkey365";
                    UseBasicParsing = $true;
                }
                $latest = Invoke-WebRequest @param -ErrorAction Ignore
                If($null -ne $latest -and $latest.StatusCode -eq [System.Net.HttpStatusCode]::OK){
                    Try{
                        $content = $latest.Content | ConvertFrom-Json -ErrorAction Ignore
                    }
                    Catch{
                        Write-Warning ("Unable to get JSON content from {0}" -f $Url)
                    }
                }
            }
        }
        Catch{
            Write-Warning $_.Exception.Message
        }
    }
    Process{
        Try{
            If($null -ne $content){
                $vId = $content| Select-Object -ExpandProperty id -ErrorAction Ignore
                $vfile = ("{0}/version" -f $Output.FullName);
                If([System.IO.File]::Exists($vfile)){
                    Try{
                        $version = [System.IO.File]::ReadAllText($vfile);
                    }
                    Catch{
                        Write-Error $_.Exception
                        return $false
                    }
                }
                If($vId -eq $version){
                    $p = @{
                        Message = "All resources are up to date"
                        Verbose = If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose'].IsPresent){$PSBoundParameters['Verbose'].IsPresent}Else{$false}
                    }
                    Write-Verbose @p
                    return $true
                }
                Else{
                    $tagName = $content | Select-Object -ExpandProperty name -ErrorAction Ignore
                    Write-Information ("Using latest release: {0}" -f $tagName) -InformationAction $InformationPreference
                    #Get assets url
                    $assetsUrl = $content.assets.Where({$_.name -like '*zip*' -and $_.content_type -eq 'application/zip'}) | Select-Object -ExpandProperty browser_download_url -ErrorAction Ignore
                    If($assetsUrl){
                        Write-Information ("Downloading content from {0}" -f $assetsUrl) -InformationAction $InformationPreference
                        $param = @{
                            Uri = $assetsUrl;
                            UserAgent = "Monkey365";
                            UseBasicParsing = $true;
                        }
                        $zip = Invoke-WebRequest @param -ErrorAction Ignore
                        $array = $zip.RawContentStream.ToArray()
                        [byte[]]$checksum = $cryptography.ComputeHash($array);
                        $shaZip = [System.BitConverter]::ToString($checksum).Replace('-', [String]::Empty).ToLowerInvariant()
                    }
                    Else{
                        Write-Warning ("a File with extension zip was not found in {1}" -f $assetsUrl)
                        return $false
                    }
                    #Get SHA from file
                    $shaurl = $content.assets.Where({$_.name -like ('*{0}*' -f $method.ToLower())}) | Select-Object -ExpandProperty browser_download_url -ErrorAction Ignore
                    If($shaurl){
                        Write-Information ("Downloading content from {0}" -f $shaurl) -InformationAction $InformationPreference
                        $param = @{
                            Uri = $shaurl;
                            UserAgent = "Monkey365";
                            UseBasicParsing = $true;
                        }
                        $shaFile = Invoke-WebRequest @param -ErrorAction Ignore
                        $sr = [System.IO.StreamReader]::new($shaFile.RawContentStream);
                        $Hash = $sr.ReadToEnd();
                        $Hash = $Hash.Trim()
                        $sr.Close();
                        $sr.Dispose();
                    }
                    Else{
                        Write-Warning ("a File with extension {0} was not found in {1}" -f $method.ToLower(),$assetsUrl)
                        return $false
                    }
                }
            }
            If($null -ne $assetsUrl -and $null -ne $Hash -and $null -ne $shaZip){
                Write-Information ("Verifying that {0} checksum for {1} is valid" -f $method.ToUpper(), $assetsUrl) -InformationAction $InformationPreference
                If(-NOT $Hash.Equals($shaZip)){
                    Write-Warning ("{0} checksum of {1} is not valid" -f $method.ToUpper(), $assetsUrl)
                    return $false
                }
                Write-Information ("{0} checksum of {1} is valid" -f $method.ToUpper(), $assetsUrl) -InformationAction $InformationPreference
                $zipArchive = [System.IO.Compression.ZipArchive]::new($zip.RawContentStream,[System.IO.Compression.ZipArchiveMode]::Read)
                $allEntries = $zipArchive.Entries.Where({$_.FullName -notlike "*.git*" -and $_.FullName -ne "README.md"});
                Foreach($entry in $allEntries){
                    Try{
                        If([String]::IsNullOrEmpty($entry.Name) -and $entry.FullName.EndsWith('/')){
                            $destination = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Output.FullName,$entry.FullName))
                            $directory = [System.IO.Path]::GetDirectoryName($destination);
                            If(![System.IO.Directory]::Exists($directory)){
                                Write-Information ("Creating directory {0}" -f $directory) -InformationAction $InformationPreference
                                [void][System.IO.Directory]::CreateDirectory($directory);
                            }
                        }
                        Else{
                            $destination = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Output.FullName,$entry.FullName))
                            $fileStream = [System.IO.FileStream]::new($destination,[System.IO.FileMode]::OpenOrCreate)
                            $stream = $entry.Open();
                            [void]$stream.CopyToAsync($fileStream).GetAwaiter().GetResult();
                            $fileStream.Close()
                            $fileStream.Dispose()
                        }
                    }
                    Catch{
                        Write-Warning $_.Exception.Message
                    }
                }
                If($IncludeVersionId.IsPresent){
                    $versionId = $content| Select-Object -ExpandProperty id -ErrorAction Ignore
                    If($versionId){
                        $outVersionFile = ("{0}{1}version" -f $Output.FullName,[System.IO.Path]::DirectorySeparatorChar)
                        Write-Information ("Writing version file to {0}" -f $outVersionFile) -InformationAction $InformationPreference
                        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
                        [System.IO.File]::WriteAllLines($outVersionFile, $versionId, $Utf8NoBomEncoding);
                    }
                }
                return $true
            }
        }
        Catch{
            Write-Error $_.Exception.Message
            return $false
        }
    }
    End{
        #Nothing to do here
    }
}
