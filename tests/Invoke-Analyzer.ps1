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
Runs PSScriptAnalyzer and writes pipeline-friendly result artifacts.

.DESCRIPTION
Loads tests/monkey365pssa.config.ps1, applies command-line overrides, runs
PSScriptAnalyzer, and returns diagnostic records. Use -OutputFormat Nunit or
-OutputFormat SARIF to convert the results and optionally write them to
-Output. Existing output files require -Force before they can be replaced.

.PARAMETER Path
One or more directories to analyze. This parameter is required. PowerShell
files ending in .ps1, .psm1, or .psd1 are selected; test files are excluded.

.PARAMETER ModuleName
Name used for the top-level NUnit test suite or SARIF automation details. This
parameter is required.

.PARAMETER Recurse
Searches each analysis directory recursively.

.PARAMETER TreatSuppressedAsSkipped
Represents rules whose diagnostics are all suppressed as skipped NUnit tests.

.PARAMETER Output
NUnit XML or SARIF destination file. Relative paths are resolved from the
repository root. Used with -OutputFormat.

.PARAMETER OutputFormat
Output artifact format. Specify Nunit for NUnit XML or SARIF for SARIF 2.1.0
compatible with GitHub code scanning. If omitted, raw PSScriptAnalyzer
diagnostic records are returned.

.PARAMETER Severity
Diagnostic severities to collect. Overrides the global configuration.

.PARAMETER FailOnSeverity
Diagnostic severities that fail the quality gate. Overrides the global
configuration.

.PARAMETER IncludeRule
Runs only the named rules. Overrides the global configuration.

.PARAMETER ExcludeRule
Excludes the named rules. Overrides the global configuration.

.PARAMETER Force
Overwrites the output file if it already exists.

.EXAMPLE
./tests/Invoke-Analyzer.ps1 -Path ./src/monkey365 -Recurse `
    -ModuleName monkey365

.EXAMPLE
./tests/Invoke-Analyzer.ps1 -Path ./src/monkey365 -Recurse `
    -OutputFormat Nunit `
    -ModuleName monkey365 -Output ../logs/PSScriptAnalyzer.xml

.EXAMPLE
./tests/Invoke-Analyzer.ps1 -Path ./src/monkey365 -Recurse `
    -OutputFormat SARIF `
    -ModuleName monkey365 -Output ../logs/PSScriptAnalyzer.sarif

.EXAMPLE
./tests/Invoke-Analyzer.ps1 -Path ./src/monkey365/core/modules -Recurse `
    -ModuleName monkey365 -Severity Error,Warning,Information `
    -FailOnSeverity Error -ExcludeRule PSAvoidUsingWriteHost
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Path')]
    [System.String[]]$Path,

    [Parameter(Mandatory = $true, HelpMessage = 'Module Name')]
    [System.String]$ModuleName,

    [Parameter(Mandatory = $false, HelpMessage = 'Recurse')]
    [switch]$Recurse,

    [Parameter(Mandatory = $false, HelpMessage = 'Treat Suppressed rules as Skipped')]
    [Switch]$TreatSuppressedAsSkipped,

    [Parameter(Mandatory = $false, HelpMessage = 'Output')]
    [System.String]$Output,

    [Parameter(Mandatory = $false, HelpMessage = 'Force')]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = 'Output Format')]
    [ValidateSet('Nunit', 'SARIF')]
    [System.String[]]$OutputFormat,

    [Parameter(Mandatory = $false, HelpMessage = 'Severity')]
    [ValidateSet('Error', 'Warning', 'Information')]
    [System.String[]]$Severity,

    [Parameter(Mandatory = $false, HelpMessage = 'FailOnSeverity')]
    [ValidateSet('Error', 'Warning', 'Information')]
    [System.String[]]$FailOnSeverity,

    [Parameter(Mandatory = $false, HelpMessage = 'Include rule')]
    [System.String[]]$IncludeRule,

    [Parameter(Mandatory = $false, HelpMessage = 'Exclude rule')]
    [System.String[]]$ExcludeRule
)
Begin{
    Function Add-XmlElement {
        param(
            [System.Xml.XmlNode] $Parent,
            [string] $Name,
            [System.Collections.IDictionary] $Attributes
        )

        $element = $document.CreateElement($Name)
        if ($null -ne $Attributes) {
            foreach ($key in $Attributes.Keys) {
                if ($null -ne $Attributes[$key]) {
                    $element.SetAttribute([string] $key, $Attributes[$key])
                }
            }
        }
        [void] $Parent.AppendChild($element)
        return $element
    }

    Function Add-Environment {
        param(
            [System.Xml.XmlNode] $Parent
        )

        Try{
            $environment = $Parent.OwnerDocument.CreateElement('environment', $Parent.OwnerDocument.NamespaceURI)
            $null = $Parent.AppendChild($environment)
            $environment.SetAttribute('framework-version', 3)
            $environment.SetAttribute('user', $env:USERNAME)
            $environment.SetAttribute('machine-name', $env:COMPUTERNAME)
            $environment.SetAttribute('cwd', (Get-Location))
            $environment.SetAttribute('user-domain', $env:USERDOMAIN)
            $environment.SetAttribute('platform', ([System.Environment]::OSVersion.Platform))
            $environment.SetAttribute('os-version', ([System.Environment]::OSVersion.Version.ToString()))
            $environment.SetAttribute('clr-version', $PSVersionTable.CLRVersion)
            $environment.SetAttribute('os-architecture', [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)
            $environment.SetAttribute('uiculture', (Get-UICulture).Name)
            $environment.SetAttribute('culture', (Get-Culture).Name)

            return $environment
        }
        catch{
            throw
        }
    }

    Function Add-CDataElement {
        param(
            [System.Xml.XmlNode] $Parent,
            [string] $Name,
            [AllowNull()] [object] $Value
        )

        $element = Add-XmlElement -Parent $Parent -Name $Name
        [void] $element.AppendChild($document.CreateCDataSection($Value))
        return $element
    }

    Function Add-PropertyContainer {
        param(
            [System.Xml.XmlNode] $Parent,
            [System.Collections.IDictionary] $Values
        )

        $propertiesElement = Add-XmlElement -Parent $Parent -Name 'properties'
        foreach ($key in $Values.Keys) {
            if ($null -ne $Values[$key] -and -not [string]::IsNullOrWhiteSpace([string] $Values[$key])) {
                [void] (Add-XmlElement -Parent $propertiesElement -Name 'property' -Attributes ([ordered]@{
                    name  = [string] $key
                    value = [string] $Values[$key]
                }))
            }
        }
        return $propertiesElement
    }

    Function Get-RepositoryRelativePath {
        param(
            [Parameter(Mandatory)]
            [string]$LiteralPath,

            [Parameter(Mandatory)]
            [string]$RepositoryRoot
        )

        If ([string]::IsNullOrWhiteSpace($LiteralPath)) {
            return ''
        }

        Try {
            return [System.IO.Path]::GetRelativePath($RepositoryRoot, $LiteralPath).
                Replace([System.IO.Path]::DirectorySeparatorChar, '/')
        }
        Catch {
            return $LiteralPath
        }
    }

    Function ConvertTo-SarifLevel {
        param(
            [AllowNull()]
            [Object]$Severity
        )

        switch ([System.String]$Severity) {
            'Error'       { return 'error' }
            'ParseError'  { return 'error' }
            'Warning'     { return 'warning' }
            'Information' { return 'note' }
            default       { return 'none' }
        }
    }

    Function ConvertTo-SarifArtifact {
        param(
            [Parameter(Mandatory)]
            [AllowEmptyCollection()]
            [Object[]]$CaseModels,

            [Parameter(Mandatory)]
            [System.String]$RepositoryRoot,

            [Parameter(Mandatory)]
            [System.String]$ModuleName,

            [Parameter(Mandatory)]
            [System.String]$ToolVersion
        )
        #Get rule descriptors
        $ruleDescriptors = @(
            $CaseModels |
                Where-Object { $_.Records.Count -gt 0 } |
                Sort-Object -Property Rule -Unique |
                ForEach-Object {
                    [ordered]@{
                        id = [System.String]$_.Rule
                        name = [System.String]$_.Rule
                        shortDescription = [ordered]@{
                            text = $_ | Select-Object -ExpandProperty Description
                        }
                        defaultConfiguration = [ordered]@{
                            level = ConvertTo-SarifLevel -Severity $_.Severity
                        }
                        properties = [ordered]@{
                            tags = @('PowerShell', 'PSScriptAnalyzer')
                            severity = [System.String]$_.Severity
                        }
                    }
                }
        )
        #Iterate over case models
        $results = [System.Collections.Generic.List[PsObject]]::new()
        foreach ($caseModel in $CaseModels) {
            foreach ($record in $caseModel.Records) {
                $result = [ordered]@{
                    ruleId = [System.String]$caseModel.Rule
                    level = ConvertTo-SarifLevel -Severity $record.Severity
                    message = [ordered]@{
                        text = [System.String]$record.Message
                    }
                    properties = [ordered]@{
                        severity = [System.String]$record.Severity
                        isBlocking = [System.String]$caseModel.IsBlocking
                        isSuppressed = [bool]$record.IsSuppressed
                    }
                }
                $sourcePath = If ($record.Extent -and $record.Extent.File) { $record.Extent.File } ElseIf ($record.ScriptName){$record.ScriptName} Else {'<script-definition>'}
                $region = [ordered]@{
                    startLine = [math]::Max(1, [int]$record.Line)
                    startColumn = [math]::Max(1, [int]$record.Column)
                }
                If ($record.Extent) {
                    If ([int]$record.Extent.EndLineNumber -ge $region.startLine) {
                        $region.endLine = [int]$record.Extent.EndLineNumber
                    }
                    If ([int]$record.Extent.EndColumnNumber -gt 0) {
                        $region.endColumn = [int]$record.Extent.EndColumnNumber
                    }
                }
                $result.locations = @(
                    [ordered]@{
                        physicalLocation = [ordered]@{
                            artifactLocation = [ordered]@{
                                uri = $sourcePath
                            }
                            region = $region
                        }
                    }
                )
                #Check If suppressed
                If ($record.IsSuppressed) {
                    $suppression = [ordered]@{
                        kind = 'inSource'
                        status = 'accepted'
                    }
                    $suppressionId = $record | Select-Object -ExpandProperty RuleSuppressionID -ErrorAction Ignore
                    if (-not [string]::IsNullOrWhiteSpace([string]$suppressionId)) {
                        $suppression.justification = [string]$suppressionId
                    }
                    $result.suppressions = @($suppression)
                }
                #Add to array
                $results.Add([PsCustomObject]$result)
            }
        }
        #Create sarif
        $sarif = [ordered]@{
            '$schema' = 'https://json.schemastore.org/sarif-2.1.0.json'
            version = '2.1.0'
            runs = @(
                [ordered]@{
                    tool = [ordered]@{
                        driver = [ordered]@{
                            name = 'PSScriptAnalyzer'
                            informationUri = 'https://github.com/PowerShell/PSScriptAnalyzer'
                            semanticVersion = $ToolVersion
                            rules = $ruleDescriptors
                        }
                    }
                    automationDetails = [ordered]@{
                        id = $ModuleName
                    }
                    results = @($results)
                }
            )
        }

        return ($sarif | ConvertTo-Json -Depth 20)
    }
    #I need to add isBlocking
    #$blockingDiagnostics = @($diagnostics | Where-Object IsBlocking)
    Function Get-ResultSummary {
        [CmdletBinding()]
	    Param (
            [Parameter(Mandatory=$True, HelpMessage="Cases")]
            [Object[]]$Cases
        )
        Begin{
            $summary = [PsCustomObject]@{
                Total        = 0;
                Passed       = 0;
                Failed       = 0;
                Inconclusive = 0;
                Skipped      = 0;
                Asserts      = 0;
                Result       = $null;
            }
        }
        Process{
            $summary.Total = $Cases.Count
            $summary.Passed = @($Cases).Where({$_.Result -eq "Passed"}).Count
            @($Cases).Where({$_.Result -eq "Failed"}).ForEach({
                If($_.Asserts -gt 1){
                    $summary.Failed+= ($_.Records | Sort-Object -Property ScriptName -Unique).count
                }
                Else{
                    $summary.Failed+=1
                }
            });
            $summary.Inconclusive = @($Cases).Where({$_.Result -eq "Inconclusive"}).Count
            $summary.Skipped = @($Cases).Where({$_.Result -eq "Skipped"}).Count
            $summary.Asserts = ($Cases | Measure-Object -Property Asserts -Sum).Sum
            If ($null -eq $asserts) { $summary.Asserts = 0 }

            $summary.Result = If ($failed -gt 0) {
                'Failed'
            }
            ElseIf ($inconclusive -gt 0) {
                'Inconclusive'
            }
            ElseIf ($Cases.Count -gt 0 -and $skipped -eq $Cases.Count) {
                'Skipped'
            }
            Else {
                'Passed'
            }
            #return object
            return $summary
        }
    }
    Function ConvertTo-NUnitArtifact {
        param(
            [Parameter(Mandatory)]
            [AllowEmptyCollection()]
            [Object[]]$CaseModels,

            [Parameter(Mandatory = $false, HelpMessage = 'Treat Suppressed rules as Skipped')]
            [Switch]$TreatSuppressedAsSkipped,

            [Parameter(Mandatory = $false)]
            [Nullable[datetime]]$StartTime,

            [Parameter(Mandatory)]
            [Nullable[datetime]]$EndTime
        )
        Begin{
            If($EndTime.HasValue){
                $finishTime = $EndTime.Value.ToUniversalTime()
            }
            Else{
                $finishTime = [datetime]::UtcNow                
            }
            If($StartTime.HasValue){
                $beginTime = $StartTime.Value.ToUniversalTime()
            }
            Else{
                $beginTime = [datetime]::UtcNow                
            }
            $duration = [math]::Max(0, ($finishTime - $beginTime).TotalSeconds)
            $durationText = $duration.ToString('0.000000', [Globalization.CultureInfo]::InvariantCulture)
            $startText = $beginTime.ToString('yyyy-MM-dd HH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
            $endText = $finishTime.ToString('yyyy-MM-dd HH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
            $summary = Get-ResultSummary -Cases $CaseModels
            $document = [System.Xml.XmlDocument]::new()
            [void] $document.AppendChild($document.CreateXmlDeclaration('1.0', 'utf-8', $null))
            $run = Add-XmlElement -Parent $document -Name 'test-run' -Attributes ([ordered]@{
                        id              = '0'
                        testcasecount   = $summary.Total
                        result          = $summary.Result
                        total           = $summary.Total
                        passed          = $summary.Passed
                        failed          = $summary.Failed
                        inconclusive    = $summary.Inconclusive
                        skipped         = $summary.Skipped
                        asserts         = $summary.Asserts
                        'engine-version'= 'PSScriptAnalyzer-NUnit3-Converter/1.0'
                        'clr-version'   = [Environment]::Version.ToString()
                        'start-time'    = $startText
                        'end-time'      = $endText
                        duration        = $durationText
                    })

            #[void] (Add-CDataElement -Parent $run -Name 'command-line' -Value $CommandLine)
            $suiteAttributes = [ordered]@{
                id              = '0-1000'
                name            = $ModuleName
                fullname        = if ($repoRoot) { $repoRoot } else { $ModuleName }
                testcasecount   = $summary.Total
                runstate        = 'Runnable'
                result          = $summary.Result
                'start-time'    = $startText
                'end-time'      = $endText
                duration        = $durationText
                total           = $summary.Total
                passed          = $summary.Passed
                failed          = $summary.Failed
                inconclusive    = $summary.Inconclusive
                skipped         = $summary.Skipped
                asserts         = $summary.Asserts
            }
            $projectAttributes = [ordered]@{ type = 'Project' }
            foreach ($entry in $suiteAttributes.GetEnumerator()) { $projectAttributes[$entry.Key] = $entry.Value }
            $projectSuite = Add-XmlElement -Parent $run -Name 'test-suite' -Attributes $projectAttributes
            [void] (Add-PropertyContainer -Parent $projectSuite -Values ([ordered]@{
                Module     = $ModuleName
                ModulePath = $repoRoot
                Generator  = 'ConvertTo-PSScriptAnalyzerNUnit3'
            }))
            $assemblyAttributes = [ordered]@{ type = 'Assembly' }
            foreach ($entry in $suiteAttributes.GetEnumerator()) { $assemblyAttributes[$entry.Key] = $entry.Value }
            $assemblyAttributes.id = '0-1001'
            $assemblyAttributes.name = 'PSScriptAnalyzer'
            $assemblySuite = Add-XmlElement -Parent $projectSuite -Name 'test-suite' -Attributes $assemblyAttributes
            #Add environment element
            [void] (Add-XmlElement -Parent $assemblySuite -Name 'environment' -Attributes ([ordered]@{
                'framework-version' = 3
                'clr-version'       = [Environment]::Version.ToString()
                'os-version'        = [Environment]::OSVersion.VersionString
                platform            = [Environment]::OSVersion.Platform.ToString()
                cwd                 = [Environment]::CurrentDirectory
                'machine-name'      = [Environment]::MachineName
                user                = [Environment]::UserName
                'user-domain'       = [Environment]::UserDomainName
                culture             = [Globalization.CultureInfo]::CurrentCulture.Name
                uiculture           = [Globalization.CultureInfo]::CurrentUICulture.Name
                'os-architecture'   = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture;
            }))
        }
        Process{
            $nextId = 1002
            ForEach($case in $caseModels.GetEnumerator()){
                $caseSummary = Get-ResultSummary -Cases $case
                $fixtureId = '0-{0}' -f $nextId
                $nextId++
                $className = ('PsScriptAnalyzer.{0}' -f $case.Rule);
                $fullName = ('{0}.PsScriptAnalyzer.{1}' -f $ModuleName, $case.Rule);
                $fixture = Add-XmlElement -Parent $assemblySuite -Name 'test-suite' -Attributes ([ordered]@{
                    type            = 'TestFixture';
                    id              = $fixtureId;
                    name            = $case.Rule;
                    fullname        = $fullName;
                    classname       = $className;
                    testcasecount   = $caseSummary.Total;
                    runstate        = 'Runnable';
                    result          = $caseSummary.Result;
                    'start-time'    = $startText;
                    'end-time'      = $endText;
                    duration        = $durationText;
                    total           = $caseSummary.Total;
                    passed          = $caseSummary.Passed;
                    failed          = $caseSummary.Failed;
                    inconclusive    = $caseSummary.Inconclusive;
                    skipped         = $caseSummary.Skipped;
                    asserts         = $caseSummary.Asserts;
                });
                [void] (Add-PropertyContainer -Parent $fixture -Values ([ordered]@{
                    Module     = $ModuleName
                    ModulePath = $repoRoot
                    Language   = 'PowerShell'
                }));
                #Check if result pass/failed
                If($case.Result.ToLower() -eq 'passed' -and $case.Records.Count -eq 0){
                    $caseId = '0-{0}' -f $nextId
                    $nextId++
                    $caseAttributes = [ordered]@{
                        id           = $caseId
                        name         = $case.Rule
                        fullname     = $className;
                        methodname   = $case.Rule;
                        classname    = $className;
                        runstate     = 'Runnable';
                        result       = $case.Result;
                        'start-time' = $startText;
                        'end-time'   = $endText;
                        duration     = '0.000000';
                        asserts      = $case.Asserts;
                        label        = [System.String]::Empty;
                    }
                    $testCase = Add-XmlElement -Parent $fixture -Name 'test-case' -Attributes $caseAttributes
                    #Add property container
                    [void] (Add-PropertyContainer -Parent $testCase -Values ([ordered]@{
                        Module            = $ModuleName;
                        ModulePath        = $repoRoot;
                        RuleName          = $case.Rule;
                        Description       = $case.Description;
                        Severity          = $case.Severity;
                        ScriptName        = $null;
                        ScriptPath        = $null;
                        DiagnosticCount   = $case.Records.Count;
                        RuleSuppressionID = $null;
                    }));
                    [void] (Add-CDataElement -Parent $testCase -Name 'output' -Value ("All files pass PsScriptAnalyzer rule [{0}]" -f $case.Rule))
                    continue
                }
                ElseIf($case.Result.ToLower() -eq 'skipped'){
                    $caseId = '0-{0}' -f $nextId
                    $nextId++
                    $caseAttributes = [ordered]@{
                        id           = $caseId
                        name         = $case.Rule
                        fullname     = $className;
                        methodname   = $case.Rule;
                        classname    = $className;
                        runstate     = 'Runnable';
                        result       = $case.Result;
                        'start-time' = $startText;
                        'end-time'   = $endText;
                        duration     = '0.000000';
                        asserts      = $case.Asserts;
                        label        = 'Ignored';
                    }
                    $testCase = Add-XmlElement -Parent $fixture -Name 'test-case' -Attributes $caseAttributes
                    #Add property container
                    [void] (Add-PropertyContainer -Parent $testCase -Values ([ordered]@{
                        Module            = $ModuleName;
                        ModulePath        = $repoRoot;
                        RuleName          = $case.Rule;
                        Description       = $case.Description;
                        Severity          = $case.Severity;
                        ScriptName        = $null;
                        ScriptPath        = $null;
                        DiagnosticCount   = $case.Records.Count;
                        RuleSuppressionID = $null;
                    }));
                    $reason = Add-XmlElement -Parent $testCase -Name 'reason'
                    [void] (Add-CDataElement -Parent $reason -Name 'message' -Value ('Diagnostic for {0} rule was suppressed by PSScriptAnalyzer configuration or SuppressMessageAttribute.' -f $case.Rule));
                    continue
                }
                Else{
                    ForEach($record in $case.Records.GetEnumerator()){
                        $caseId = '0-{0}' -f $nextId
                        $nextId++
                        $sourcePath = If ($record.Extent -and $record.Extent.File) { $record.Extent.File } ElseIf ($record.ScriptName){$record.ScriptName} Else {'<script-definition>'}
                        $fileName = If ($sourcePath -eq '<script-definition>') { $filePath } Else { [System.IO.Path]::GetFileName($sourcePath) }
                        $className = '{0}.{1}' -f $ModuleName, ([System.IO.Path]::GetFileNameWithoutExtension($fileName))
                        #Set case attributes
                        $caseAttributes = [ordered]@{
                            id           = $caseId;
                            name         = $case.Rule;
                            fullname     = '{0}.{1}' -f $className, $case.Rule;
                            methodname   = $case.Rule;
                            classname    = $className;
                            runstate     = If ($record.IsSuppressed) { 'Ignored' } Else { 'Runnable' };
                            result       = $case.Result;
                            'start-time' = $startText;
                            'end-time'   = $endText;
                            duration     = '0.000000';
                            asserts      = 1;
                        }
                        $testCase = Add-XmlElement -Parent $fixture -Name 'test-case' -Attributes $caseAttributes
                        #Add property container
                        [void] (Add-PropertyContainer -Parent $testCase -Values ([ordered]@{
                            Module            = $ModuleName;
                            ModulePath        = $repoRoot;
                            RuleName          = $case.Rule;
                            Description       = $case.Description;
                            Severity          = $case.Severity;
                            ScriptName        = $fileName;
                            ScriptPath        = $sourcePath;
                            DiagnosticCount   = $case.Records.Count;
                            RuleSuppressionID = ($record | Select-Object -ExpandProperty RuleSuppressionID -ErrorAction Ignore);
                        }));
                        #Add failure
                        $failure = Add-XmlElement -Parent $testCase -Name 'failure'
                        #Add message
                        [void] (Add-CDataElement -Parent $failure -Name 'message' -Value ($record.Message))
                        $stackTrace_ = ("at line: {0}, column: {1} in {2} {3} {4}" -f $record.Line, $record.Column, $record.ScriptPath, $record.Extent.Text, $record.Severity);
                        [void] (Add-CDataElement -Parent $failure -Name 'stack-trace' -Value $stackTrace_)
                    }
                }
            }
        }
        End{
            $writerSettings = [System.Xml.XmlWriterSettings]::new()
            $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false)
            $writerSettings.Indent = $true
            $writerSettings.IndentChars = '  '
            $writerSettings.NewLineChars = [Environment]::NewLine
            $writerSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace

            $memoryStream = [System.IO.MemoryStream]::new()
            try {
                $writer = [System.Xml.XmlWriter]::Create($memoryStream, $writerSettings)
                try {
                    $document.Save($writer)
                }
                finally {
                    $writer.Dispose()
                }
                $xmlText = [System.Text.Encoding]::UTF8.GetString($memoryStream.ToArray())
                #return text
                return $xmlText
            }
            finally {
                $memoryStream.Dispose()
            }
        }
    }
    $rules = Get-ScriptAnalyzerRule
    $caseModels = [System.Collections.Generic.List[object]]::new()
}
Process{
    Try{
        $StartTime = [datetime]::UtcNow
        If($null -ne (Get-Command -Name git -ErrorAction Ignore)){
            $repoRoot = git rev-parse --show-toplevel 2>$null
        }
        IF($null -eq $repoRoot){
            $repoRoot = Split-Path $PSScriptRoot -Parent
        }
        $pssaConfig = [System.IO.Path]::Combine($repoRoot, "tests", "monkey365pssa.config.ps1")
        $monkey365pssa = Get-Command -Name $pssaConfig -CommandType ExternalScript -ErrorAction Ignore
        If($null -ne $monkey365pssa){
            #Set parameters
            $newPsboundParams = [ordered]@{}
            $param = $monkey365pssa.Parameters.Keys
            ForEach($p in $param.GetEnumerator()){
                If($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        Else{
            Write-Error ("Function monkey365pssa.config.ps1 was not found")
            return
        }
        $configuration = & $pssaConfig @newPsboundParams
        $loadedAnalyzer = Get-Module -Name PSScriptAnalyzer -ErrorAction Ignore
        If($null -eq $loadedAnalyzer){
            throw "PSScriptAnalyzer is not present"
        }
        $rawDiagnostics = @(
            $files = @()
            ForEach ($analysisPath in $configuration.Run.Path.GetEnumerator()) {
                If (-not (Test-Path -LiteralPath $analysisPath)) {
                    throw "Analysis path does not exist: $analysisPath"
                }
                If($configuration.Run.Recurse){
                    $files+= [System.IO.Directory]::EnumerateFiles(
                        (Resolve-Path $analysisPath),
                        '*',
                        [System.IO.SearchOption]::AllDirectories
                    )
                }
                Else{
                    $files+= [System.IO.Directory]::EnumerateFiles(
                        (Resolve-Path $analysisPath),
                        '*',
                        [System.IO.SearchOption]::TopDirectoryOnly
                    )
                }
            }
            $files = @($files | Sort-Object -Unique).Where({$_ -match '\.(ps1|psm1|psd1)$' -and $_ -notlike '*Tests.ps1'})
            If($files.Count -gt 0){
                $options = @{
                    IncludeDefaultRules = $configuration.Run.DefaultRules;
                    Settings = $configuration.AnalyzerSettings;
                }
                $files | Invoke-ScriptAnalyzer @options
            }
        )
        $blockingSeverities = @($configuration.QualityGate.FailOnSeverity)
        ForEach($rule in $rules){
            $ismatch = $rawDiagnostics.Where({$_.RuleName -eq $rule.RuleName});
            If($ismatch.Count -gt 0){
                $_records = [System.Collections.Generic.List[object]]::new();
                #Check all suppressed
                $allSuppressed = $ismatch.Where({$_.IsSuppressed}).Count -eq $ismatch.Count
                If ($TreatSuppressedAsSkipped -and $allSuppressed) {
                    $result = 'Skipped';
                }
                Else {
                    $result = 'Failed';
                }
                If ($ismatch -is [System.Collections.IEnumerable] -and $ismatch -isnot [string]) {
			        [void]$_records.AddRange($ismatch);
		        }
		        ElseIf ($ismatch.GetType() -eq [System.Management.Automation.PSCustomObject] -or $ismatch.GetType() -eq [System.Management.Automation.PSObject]) {
			        [void]$_records.Add($ismatch);
		        }
                Else{
                    Write-Warning "Unable to add records";
                }
                #Add case model
                $caseModels.Add([PSCustomObject]@{
                    Rule    = $rule.RuleName;
                    Description = $rule.Description;
                    Severity = $rule.Severity;
                    Records = $_records;
                    Result  = $result;
                    Asserts = $ismatch.Count;
                    IsBlocking = ($rule.Severity -in $blockingSeverities);
                });
            }
            Else{
                $caseModels.Add([PSCustomObject]@{
                    Rule    = $rule.RuleName;
                    Description = $rule.Description;
                    Severity = $rule.Severity;
                    Records = [System.Collections.Generic.List[object]]::new();
                    Result  = 'Passed';
                    Asserts = 0;
                    IsBlocking = $false;
                });
            }
        }
        $EndTime = [datetime]::UtcNow
        #$elapsedTime =  [math]::round(($EndTime - $StartTime).TotalMinutes , 2)
        If ($configuration.Output.Format.Enabled) {
            $fileType = $configuration.Output.Format.Type
            If($fileType.ToLower() -eq 'sarif'){
                $options = @{
                    CaseModels = $caseModels
                    RepositoryRoot = $configuration.RepositoryRoot
                    ModuleName = $configuration.ModuleName
                    ToolVersion = $loadedAnalyzer.Version.ToString()
                }
                $_rawOutput = ConvertTo-SarifArtifact @options
            }
            ElseIf($fileType.ToLower() -eq 'nunit'){
                $options = @{
                    CaseModels = $caseModels;
                    StartTime = $StartTime;
                    EndTime = $EndTime;
                    TreatSuppressedAsSkipped = $TreatSuppressedAsSkipped;
                }
                $_rawOutput = ConvertTo-NUnitArtifact @options
            }
            Else{
                throw ("Unrecognized output type: {0}" -f $fileType)                
            }
            If($null -ne $_rawOutput -and $null -ne $configuration.Output.Format.Path){
                If ((Test-Path -Path $configuration.Output.Format.Path -PathType Leaf) -and (-not $Force)){
                    throw ("{0} already exists and -Force was not specified. Exiting without replacing it." -f $configuration.Output.Format.Path)
                }
                [System.IO.File]::WriteAllText($configuration.Output.Format.Path, $_rawOutput, [System.Text.UTF8Encoding]::new($false))
                Write-Information "PSScriptAnalyzer $($fileType.ToUpper()) results: $($configuration.Output.Format.Path)" -InformationAction Continue
            }
            Else{
                return $_rawOutput
            }
        }
        Else{
            return $rawDiagnostics
        }
        $blockingDiagnostics = @(
            $rawDiagnostics | Where-Object {
                $diagnosticSeverity = [System.String]$_.Severity
                $diagnosticSeverity -in $blockingSeverities -or
                    ($diagnosticSeverity -eq 'ParseError' -and 'Error' -in $blockingSeverities)
            }
        )
        If($blockingDiagnostics.Count -gt 0) {
            $msgObject = [System.Management.Automation.HostInformationMessage]@{
                Message = ("{0} blocking check(s) failed." -f $blockingDiagnostics.Count)
                ForegroundColor = [System.ConsoleColor]::Red
            }
            Write-Information -MessageData $msgObject -InformationAction Continue
            exit 1
        }
        Else{
            $msgObject = [System.Management.Automation.HostInformationMessage]@{
                Message = ("No blocking checks failed. {0} diagnostic(s) reported." -f $rawDiagnostics.Count)
                ForegroundColor = [System.ConsoleColor]::Green
            }
            Write-Information -MessageData $msgObject -InformationAction Continue
            exit 0
        }
    }
    Catch{
        throw
    }
}
