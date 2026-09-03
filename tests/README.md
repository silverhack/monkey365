# Monkey365 PowerShell quality infrastructure

Monkey365 uses Pester 6.0.1 for tests and PSScriptAnalyzer for static analysis.
The scripts in this directory provide the same entry points for local runs and
CI pipelines.

## Prerequisites

PowerShell 7.4 or newer is recommended. Install the versions used by the
pipeline before running the scripts:

```powershell
Install-Module Pester -RequiredVersion 6.0.1 -Scope CurrentUser -Force
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser -Force
```

Start a new PowerShell session if another major Pester version is already
loaded.

## Test layout

| Path | Purpose |
| --- | --- |
| `module/` | Module import, manifest, configuration, and public API tests |
| `unit/` | Deterministic function and nested-module tests |
| `smoke/` | Credential-free command smoke tests |
| `integration/` | Tests that can require network access or external services |

Pester discovers files ending in `.Tests.ps1`. `Invoke-Tests.ps1` does not
choose test directories automatically; `-TestPath` is mandatory.

## Invoke-Tests.ps1

Run the credential-free suites from the repository root:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/module,./tests/unit,./tests/smoke `
    -Summary
```

Run one directory or test file:

```powershell
./tests/Invoke-Tests.ps1 -TestPath ./tests/unit/modules/monkeyhtml

./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/unit/modules/monkeyhtml/New-HtmlTag.Tests.ps1 `
    -Verbosity Detailed
```

When the current directory is `tests`, use paths relative to that directory:

```powershell
./Invoke-Tests.ps1 -TestPath ./ -Summary `
    -Output ../pester-results `
    -CI -TestSuiteName monkey365-pester `
    -CodeCoverage -CodeCoveragePath ../src/monkey365/core/modules/
```

### Test parameters

| Parameter | Type | Behavior |
| --- | --- | --- |
| `-TestPath` | `string[]` | Required test files or directories. |
| `-Summary` | `switch` | Writes `pester-summary.json`. |
| `-Output` | `DirectoryInfo` | Artifact directory. Defaults to `pester-results` at the repository root. |
| `-CI` | `switch` | Enables test-result XML output. |
| `-TestSuiteName` | `string` | Suite name in XML and summary output. Defaults to `Monkey365-PowerShell-Tests`. |
| `-TestOutputFormat` | `string` | `NUnitXml`, `NUnit2.5`, `NUnit3`, or `JUnitXml`; defaults to `NUnit2.5`. |
| `-CIFormat` | `string` | `GithubActions`, `AzureDevops`, or `Auto`; defaults to `Auto`. |
| `-Verbosity` | `string` | `Diagnostic`, `Detailed`, or `None`; defaults to `None`. |
| `-CILogLevel` | `string` | `Error` or `Warning`; defaults to `Error`. |
| `-CodeCoverage` | `switch` | Enables coverage collection and `coverage.xml`. |
| `-CodeCoveragePercentTarget` | `int` | Coverage threshold; defaults to 45. |
| `-CodeCoveragePath` | `string[]` | Source directories to instrument. Defaults to `src/monkey365`. |
| `-CodeCoverageOutputFormat` | `string` | `JaCoCo` or `Cobertura`; defaults to `JaCoCo`. |
| `-IncludeTag` | `string[]` | Includes matching Pester tags. `-Tag` is an alias. |
| `-ExcludeTag` | `string[]` | Excludes matching Pester tags. |

No include or exclude tags are applied unless they are passed explicitly.

### Test artifacts and exit codes

The output directory is created when needed. The runner writes:

| Artifact | Condition |
| --- | --- |
| `pester-failures.json` | Every run that reaches Pester result processing |
| `pester-summary.json` | `-Summary` |
| `pester-results.xml` | `-CI` |
| `coverage.xml` | `-CodeCoverage` |

The failure report contains `TestName`, `FilePath`, `ErrorMessage`, and
`StackTrace` for each failed test. The summary includes test counts, duration,
suite name, Pester version, and coverage data when coverage is enabled.

The runner exits with code 1 when one or more tests fail and code 0 when all
tests pass. This exit behavior is independent of `-CI`; `-CI` controls the XML
test-result artifact.

### Coverage example

Measure the MonkeyHtml module and require 80 percent coverage:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/unit/modules/monkeyhtml `
    -Summary `
    -CodeCoverage `
    -CodeCoveragePath ./src/monkey365/core/modules/monkeyhtml `
    -CodeCoveragePercentTarget 80
```

## Invoke-Analyzer.ps1

`-Path` and `-ModuleName` are mandatory. Add `-Recurse` when nested source
directories must be scanned.

Analyze the complete source tree and return PSScriptAnalyzer diagnostic
records:

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365 `
    -Recurse `
    -ModuleName monkey365
```

Generate an NUnit report for CI:

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365 `
    -Recurse `
    -CI `
    -ModuleName monkey365 `
    -Output ./psaResultsFile
```

When the current directory is `tests`, the equivalent pipeline command is:

```powershell
./Invoke-Analyzer.ps1 -Path ../src/monkey365/ -Recurse -CI `
    -ModuleName monkey365 -Output psaResultsFile
```

Relative `-Output` values are resolved from the repository root. If the file
already exists, pass `-Force` to replace it.

### Analyzer parameters

| Parameter | Type | Behavior |
| --- | --- | --- |
| `-Path` | `string[]` | Required source directories. |
| `-ModuleName` | `string` | Required name for the NUnit project suite. |
| `-Recurse` | `switch` | Recursively enumerates each source directory. |
| `-TreatSuppressedAsSkipped` | `switch` | Emits fully suppressed rules as skipped NUnit cases. |
| `-Output` | `string` | NUnit destination file used with `-CI`. |
| `-Force` | `switch` | Replaces an existing output file. |
| `-CI` | `switch` | Converts analyzer results to NUnit XML. |
| `-Severity` | `string[]` | Collects `Error`, `Warning`, and/or `Information` diagnostics. |
| `-FailOnSeverity` | `string[]` | Passes blocking severity selection to the analyzer configuration. |
| `-IncludeRule` | `string[]` | Runs only the named analyzer rules. |
| `-ExcludeRule` | `string[]` | Excludes the named analyzer rules. |

The runner analyzes `.ps1`, `.psm1`, and `.psd1` files and excludes files whose
names end in `Tests.ps1`. Without `-CI`, raw diagnostic records are returned to
the caller. With `-CI`, the runner writes NUnit XML to `-Output`; if `-Output`
is omitted, the XML text is returned instead.

Example with analyzer overrides:

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365/core/modules `
    -Recurse `
    -ModuleName monkey365 `
    -Severity Error,Warning,Information `
    -FailOnSeverity Error `
    -ExcludeRule PSAvoidUsingWriteHost
```

## Azure DevOps examples

The pipeline runs both commands from the `tests` directory and publishes the
generated NUnit and coverage files:

```yaml
- task: PowerShell@2
  displayName: Run Pester tests
  inputs:
    pwsh: true
    targetType: inline
    workingDirectory: '$(Build.SourcesDirectory)/tests'
    script: |
      ./Invoke-Tests.ps1 -TestPath ./ -Summary `
        -Output '$(Build.ArtifactStagingDirectory)' `
        -CI -TestSuiteName monkey365-pester `
        -CodeCoverage -CodeCoveragePath ../src/monkey365/core/modules/

- task: PowerShell@2
  displayName: Run PSScriptAnalyzer
  inputs:
    pwsh: true
    targetType: inline
    workingDirectory: '$(Build.SourcesDirectory)/tests'
    script: |
      ./Invoke-Analyzer.ps1 -Path ../src/monkey365/ -Recurse -CI `
        -ModuleName monkey365 `
        -Output '$(Build.ArtifactStagingDirectory)/PSScriptAnalyzer.xml'
```

## Using the Pester configuration directly

The configuration script returns a Pester 6 `PesterConfiguration` object:

```powershell
$configuration = & ./tests/monkey365pester.config.ps1 `
    -TestPath ./tests/unit
Invoke-Pester -Configuration $configuration
```

Direct configuration invocation bypasses the runner's failure and summary JSON
reports and its explicit exit-code handling.

## Adding tests

1. Place the test in the directory matching its purpose.
2. Name it `<subject>.Tests.ps1`.
3. Keep module, unit, and smoke tests deterministic and credential-free.
4. Place network or service-dependent tests under `integration/` and tag them.
5. Run the narrow test path first, followed by the required suite paths.

New tests should use Pester 6 assertions and `Should-Invoke` for mock call
verification.
