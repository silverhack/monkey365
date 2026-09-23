# Contributing to Monkey365

Thank you for considering a contribution to Monkey365. Contributions can include bug fixes, tests, documentation, collectors, security checks, and focused improvements to the developer experience.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Use [support](https://silverhack.github.io/monkey365/support/support/) for usage questions and [SECURITY.md](../SECURITY.md) for suspected vulnerabilities.

## Before starting

- Search existing [issues](https://github.com/silverhack/monkey365/issues), pull requests, and [discussions](https://github.com/silverhack/monkey365/discussions).
- Open an issue or discussion before investing in a large feature, architecture change, new dependency, or broad refactor.
- Never commit credentials, access tokens, tenant identifiers, private keys, or unredacted assessment output.

Small documentation corrections and narrowly scoped fixes can go directly to a pull request.

## Development setup

Prerequisites for the standard test workflow:

- Git.
- PowerShell 7.4 or newer.
- Pester 6.x. The CI-tested version is 6.0.1.
- PSScriptAnalyzer 1.24.0.

```powershell
Install-Module Pester -RequiredVersion 6.0.1 -Scope CurrentUser -Force
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser -Force
```

Fork the repository, create a branch from `main`, and clone your fork:

```text
git switch -c fix/short-description
```

Important repository paths:

| Path | Purpose |
| --- | --- |
| `src/monkey365/` | PowerShell module, collectors, rules, and bundled runtime content |
| `tests/` | Module, unit, smoke, and integration tests |
| `docs/` | MkDocs site, configuration, and Python documentation dependencies |
| `docker/` | Container definitions and build scripts |
| `.github/` | Repository automation and contribution templates |

## Coding guidelines

- Follow the repository `.editorconfig` and `.gitattributes` settings.
- Use four spaces for PowerShell indentation and two spaces for YAML and JSON.
- Prefer approved PowerShell verbs and descriptive command names.
- Preserve cross-platform behavior unless a command is explicitly
  platform-specific.
- Keep public behavior backward compatible or document and justify the break.
- Add comments only where intent is not clear from the code.
- Avoid new runtime dependencies unless they provide a clear, reviewed benefit.
- Add or update tests for behavior changes and regressions.

Do not perform broad formatting or line-ending rewrites in a functional pull
request. Submit mechanical cleanup separately.

## Testing

Run a focused test while developing:

```powershell
./tests/Invoke-Tests.ps1 -TestPath ./tests/unit/path/Subject.Tests.ps1
```

Run the complete credential-free suite before opening a pull request:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/module,./tests/unit,./tests/smoke `
    -Summary
```

Run the CI-equivalent suite with coverage:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/module,./tests/unit,./tests/smoke `
    -Summary -CI -CodeCoverage `
    -CodeCoveragePath ./src/monkey365/core/modules
```

Run repository-wide PowerShell static analysis:

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365 -Recurse `
    -ModuleName monkey365
```

Generate the NUnit analyzer artifact used by CI with:

```powershell
./tests/Invoke-Analyzer.ps1 `
    -Path ./src/monkey365 -Recurse -OutputFormat Nunit `
    -ModuleName monkey365 -Output ./psaResultsFile
```

Run network integration tests only against systems you are authorized to
assess:

```powershell
./tests/Invoke-Tests.ps1 `
    -TestPath ./tests/integration/network `
    -Tag Network
```

See [tests/README.md](../tests/README.md) for the complete runner parameters,
artifacts, coverage configuration, and CI examples.

## Documentation

Documentation changes require Python and the packages in
`docs/requirements-docs.txt`:

```text
python -m pip install -r docs/requirements-docs.txt
mkdocs serve --config-file docs/mkdocs.yml
```

Check that internal links, examples, and navigation render correctly before
submitting the change.

## Pull requests

A pull request should:

- Explain the problem and the chosen solution.
- Link the relevant issue when one exists.
- Describe user-visible or compatibility effects.
- Include tests or explain why tests are not applicable.
- Update documentation for changed behavior.
- Pass the repository's automated checks.
- Avoid generated reports, logs, build output, and unrelated changes.

Maintainer review and merge timing are best effort. A contribution may be
declined when it conflicts with project scope, creates excessive maintenance
cost, lacks sufficient validation, or can be solved more simply.

## Licensing

Monkey365 is licensed under the Apache License 2.0. By submitting a
contribution, you agree that it may be distributed under the repository's
[license](../LICENSE). Only submit material that you have the right to contribute.
