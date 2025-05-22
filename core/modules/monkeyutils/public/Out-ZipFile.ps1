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


function Out-ZipFile {
    <#
        .SYNOPSIS
		Out-ZipFile

        .DESCRIPTION
		Out-ZipFile

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Out-ZipFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [Object]$InputObject,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$Path,

        [Parameter(Mandatory=$true)]
        [String]$ZipFile
    )
    Begin{
        $zipMS = [System.IO.MemoryStream]::new()
        $zipArchive = [System.IO.Compression.ZipArchive]::new($zipMS,[System.IO.Compression.ZipArchiveMode]::Create,$true)
    }
    Process{
        foreach($f in $InputObject){
            [uri]$baseuri = [uri]::new($Path)
            [uri]$fulluri = [uri]::new($f)
            $relativeuri = $baseuri.MakeRelativeUri($fulluri)
            [byte[]]$fileToZipBytes = [System.IO.File]::ReadAllBytes($f)
            $zipFileEntry = $zipArchive.CreateEntry($relativeuri.ToString(), [System.IO.Compression.CompressionLevel]::Optimal)
            $zipEntryStream = $zipFileEntry.Open()
            $zipFileBinary = [System.IO.BinaryWriter]::new($zipEntryStream)
            $zipFileBinary.Write($fileToZipBytes)
            $zipFileBinary.Dispose()
        }
        $zipArchive.Dispose()
    }
    End{
        if($zipMS.Length -gt 0){
            $outTo = ('{0}/{1}' -f $Path, $ZipFile)
            $fileStream = [System.IO.FileStream]::new($outTo,[System.IO.FileMode]::Create)
            [void]$zipMS.Seek(0,[System.IO.SeekOrigin]::Begin)
            [void]$zipMS.CopyTo($fileStream)
            $zipMS.Flush()
            $zipMS.Close()
            $zipMS.Dispose()
            $fileStream.Close()
            $fileStream.Dispose()
        }
    }
}

