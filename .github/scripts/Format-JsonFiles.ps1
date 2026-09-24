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

<#
.SYNOPSIS
Formats valid JSON files with consistent indentation.

.DESCRIPTION
Validates each JSON document with System.Text.Json and serializes it with
consistent indentation. Property order and values are preserved. When
-CamelCase is specified, object-property names are converted recursively by
using a snake_case-aware camel-case naming policy. JSON string values are not
changed.

Output uses two-space indentation, LF line endings, one final newline, and
UTF-8 encoding without a byte-order mark (BOM).

When Check is specified, no files are written and the script exits with code
zero when all files are correctly formatted or code one when a file requires
an update or could not be processed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Full Directory containing JSON files')]
    [System.String]$RootPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Search subdirectories')]
    [switch]$Recurse,

    [Parameter(Mandatory = $false, HelpMessage = 'Report required changes without writing files')]
    [switch]$Check,

    [Parameter(Mandatory = $false, HelpMessage = 'Convert JSON object-property names to camel case')]
    [switch]$CamelCase
)
Begin{
    $scriptFailed = $false

    Function ConvertTo-StrictJsonText {
        param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $True, HelpMessage = 'Json Text')]
            [Alias('Text')]
            [System.String]$InputObject
        )
        Process{
            # Some legacy rule files contain literal line breaks and tabs in quoted
            # Markdown strings. JSON requires every control character inside a string
            # to be escaped. Repair only those characters; whitespace outside strings
            # is left untouched for the JSON parser.
            $builder = [System.Text.StringBuilder]::new($InputObject.Length)
            $insideString = $false
            $quoteCharacter = [char]0
            $escaped = $false
            $index = 0
            While ($index -lt $InputObject.Length) {
                $character = $InputObject[$index]
                If (-not $insideString) {
                    If ($character -eq '"' -or $character -eq "'") {
                        # JSON5-style single-quoted strings occur in a small number of
                        # legacy rules. Convert their delimiters to JSON double quotes.
                        $quoteCharacter = $character
                        [void]$builder.Append('"')
                        $insideString = $true
                        $index++
                        continue
                    }
                    If ([char]::IsLetter($character) -or $character -in '_', '$') {
                        $identifierStart = $index
                        $index++
                        While (
                            $index -lt $InputObject.Length -and
                            ([char]::IsLetterOrDigit($InputObject[$index]) -or $InputObject[$index] -in '_', '$', '-')
                        ) {
                            $index++
                        }

                        $identifier = $InputObject.Substring($identifierStart, $index - $identifierStart)
                        $lookAhead = $index
                        While ($lookAhead -lt $InputObject.Length -and [char]::IsWhiteSpace($InputObject[$lookAhead])) {
                            $lookAhead++
                        }

                        If ($lookAhead -lt $InputObject.Length -and $InputObject[$lookAhead] -eq ':') {
                            [void]$builder.Append('"').Append($identifier).Append('"')
                        }
                        Else {
                            [void]$builder.Append($identifier)
                        }
                        continue
                    }

                    [void]$builder.Append($character)
                    $index++
                    continue
                }
                If ($quoteCharacter -eq '"' -and $escaped) {
                    [void]$builder.Append($character)
                    $escaped = $false
                    $index++
                    continue
                }
                If ($quoteCharacter -eq '"' -and $character -eq '\') {
                    [void]$builder.Append($character)
                    $escaped = $true
                    $index++
                    continue
                }
                If ($character -eq $quoteCharacter) {
                    If (
                        $quoteCharacter -eq "'" -and
                        $index + 1 -lt $InputObject.Length -and
                        $InputObject[$index + 1] -eq "'"
                    ) {
                        # Two apostrophes represent one apostrophe in legacy strings.
                        [void]$builder.Append("'")
                        $index += 2
                        continue
                    }

                    [void]$builder.Append('"')
                    $insideString = $false
                    $quoteCharacter = [char]0
                    $index++
                    continue
                }
                If ($quoteCharacter -eq "'" -and $character -eq '"') {
                    [void]$builder.Append('\"')
                    $index++
                    continue
                }
                If ($quoteCharacter -eq "'" -and $character -eq '\') {
                    # Backslashes are literal in the legacy single-quoted form.
                    [void]$builder.Append('\\')
                    $index++
                    continue
                }
                $codePoint = [int]$character
                If ($codePoint -eq 8) {
                    [void]$builder.Append('\b')
                }
                ElseIf ($codePoint -eq 9) {
                    [void]$builder.Append('\t')
                }
                ElseIf ($codePoint -eq 10) {
                    [void]$builder.Append('\n')
                }
                ElseIf ($codePoint -eq 12) {
                    [void]$builder.Append('\f')
                }
                ElseIf ($codePoint -eq 13) {
                    [void]$builder.Append('\r')
                }
                ElseIf ($codePoint -lt 32) {
                    [void]$builder.Append(('\u{0:x4}' -f $codePoint))
                }
                Else {
                    [void]$builder.Append($character)
                }
                $index++
            }
            #return text
            $builder.ToString()
        }
    }
    Function ConvertTo-CamelCase {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $True, HelpMessage = 'Property Name')]
            [Alias('Name')]
            [System.String]$InputObject
        )
        Process{
            $camelCasePolicy = [System.Text.Json.JsonNamingPolicy]::CamelCase
            $segments = @($InputObject.Split('_', [System.StringSplitOptions]::RemoveEmptyEntries))
            If ($segments.Count -le 1) {
                return $camelCasePolicy.ConvertName($InputObject)
            }

            $convertedName = $camelCasePolicy.ConvertName($segments[0])
            ForEach ($segment in $segments[1..($segments.Count - 1)]) {
                $convertedSegment = $camelCasePolicy.ConvertName($segment)
                If ($convertedSegment.Length -eq 1) {
                    $convertedName += $convertedSegment.ToUpperInvariant()
                }
                Else {
                    $convertedName += $convertedSegment.Substring(0, 1).ToUpperInvariant()
                    $convertedName += $convertedSegment.Substring(1)
                }
            }
            #return converted property
            return $convertedName
        }
    }

    Function Write-JsonElement {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [System.Text.Json.Utf8JsonWriter]$Writer,

            [Parameter(Mandatory = $true)]
            [System.Text.Json.JsonElement]$Element
        )
        Try{
            Switch ($Element.ValueKind) {
                ([System.Text.Json.JsonValueKind]::Object) {
                    $Writer.WriteStartObject()
                    ForEach ($property in $Element.EnumerateObject()) {
                        $propertyName = $property.Name | ConvertTo-CamelCase
                        $Writer.WritePropertyName($propertyName)
                        Write-JsonElement -Writer $Writer -Element $property.Value
                    }
                    $Writer.WriteEndObject()
                }
                ([System.Text.Json.JsonValueKind]::Array) {
                    $Writer.WriteStartArray()
                    ForEach ($item in $Element.EnumerateArray()) {
                        Write-JsonElement -Writer $Writer -Element $item
                    }
                    $Writer.WriteEndArray()
                }
                Default {
                    $Element.WriteTo($Writer)
                }
            }
        }
        Catch{
            Write-Error "Unable to convert JsonElement '$($Element)': $($_.Exception.Message)"
        }
    }

    Function Format-JsonText {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $True, HelpMessage = 'Full File Name')]
            [Alias('File')]
            [System.String]$InputObject,

            [Parameter(Mandatory = $false, HelpMessage = 'Convert To CamelCase')]
            [switch]$CamelCase
        )
        Process{
            Try{
                $originalText = [System.IO.File]::ReadAllText($InputObject) | ConvertTo-StrictJsonText;
                # Explicit strict parsing: comments and trailing commas are rejected.
                $documentOptions = [System.Text.Json.JsonDocumentOptions]::new()
                $documentOptions.AllowTrailingCommas = $false
                $documentOptions.CommentHandling = [System.Text.Json.JsonCommentHandling]::Disallow
                $document = [System.Text.Json.JsonDocument]::Parse($originalText, $documentOptions)
                Try {
                    $serializerOptions = [System.Text.Json.JsonSerializerOptions]::new()
                    $serializerOptions.WriteIndented = $true
                    If($CamelCase.IsPresent){
                        # Naming policies apply to .NET object properties, not to property
                        # names already stored in a JsonElement, so apply the policy while
                        # recursively writing the parsed JSON tree.
                        $stream = [System.IO.MemoryStream]::new()
                        Try {
                            $writerOptions = [System.Text.Json.JsonWriterOptions]::new()
                            $writerOptions.Indented = $true
                            $writer = [System.Text.Json.Utf8JsonWriter]::new($stream, $writerOptions)
                            Try {
                                $options = @{
                                    Writer = $writer;
                                    Element = $document.RootElement;
                                }
                                Write-JsonElement @options
                                $writer.Flush()
                                $formattedText = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
                            }
                            Finally {
                                $writer.Dispose()
                            }
                        }
                        Finally {
                            $stream.Dispose()
                        }
                    }
                    Else{
                        $formattedText = [System.Text.Json.JsonSerializer]::Serialize(
                            $document.RootElement,
                            $serializerOptions
                        )
                    }
                }
                Finally {
                    $document.Dispose()
                }
                # JsonSerializer uses the platform newline. Repository JSON is normalized
                # to LF with exactly one final newline.
                $formattedText = $formattedText -replace "`r`n", "`n"
                $formattedText.TrimEnd("`r", "`n") + "`n"
            }
            Catch{
                Write-Error "Unable to format JSON file '$($InputObject)': $($_.Exception.Message)"
            }
        }
    }
    $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false, $true)
    $changedFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
}
Process{
    Try{
        If(Test-Path -LiteralPath $PSBoundParameters['RootPath']){
            $options = @{
                LiteralPath = $PSBoundParameters['RootPath'];
                File = $true;
                Recurse = $Recurse.IsPresent;
                ErrorAction = 'Stop';
            }
            $jsonFiles = Get-ChildItem @options | Where-Object { $_.Extension -eq '.json' -and $_.FullName -notmatch '[\\/]\.git[\\/]'} | Select-Object -ExpandProperty FullName
            Write-Host "Processing Json files: $($jsonFiles.Count)"
            ForEach ($jsonFile in $jsonFiles) {
                Try {
                    $options = @{
                        CamelCase = $CamelCase.IsPresent;
                    }
                    $formattedText = $jsonFile | Format-JsonText @options
                    $expectedBytes = $utf8WithoutBom.GetBytes($formattedText)
                    $actualBytes = [System.IO.File]::ReadAllBytes($jsonFile)
                    If ([System.Linq.Enumerable]::SequenceEqual($actualBytes, $expectedBytes)) {
                        continue
                    }
                    $relativePath = Resolve-Path -Path $jsonFile -Relative
                    [void]$changedFiles.Add($relativePath)
                    If (-not $Check) {
                        [System.IO.File]::WriteAllBytes($jsonFile, $expectedBytes)
                    }
                }
                Catch{
                    throw "Unable to format JSON file '$($jsonFile)': $($_.Exception.Message)"
                }
            }
        }
        Else{
            throw "Cannot find path '$($PSBoundParameters['RootPath'])'"
        }
    }
    Catch{
        $scriptFailed = $true
        Write-Error $_.Exception.Message
    }
}
End{
    If ($Check -and $changedFiles.Count -gt 0) {
        $changeList = $changedFiles | ForEach-Object { " - $_" }
        Write-Output "JSON files require formatting:`n$($changeList -join "`n")"
    }
    $action = If ($Check) { 'Checked' } Else { 'Formatted' }
    Write-Host "$action JSON files: $($jsonFiles.Count)"
    Write-Host "Files changed: $($changedFiles.Count)"

    If ($Check) {
        If ($scriptFailed -or $changedFiles.Count -gt 0) {
            exit 1
        }
        exit 0
    }
}
