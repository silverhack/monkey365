# Security Policy

Monkey365 is a security assessment tool and may process sensitive cloud configuration data. Please report vulnerabilities privately and do not include credentials, access tokens, tenant data, or unredacted Monkey365 reports in a public issue.

## Supported versions

Security fixes are provided for the latest published Monkey365 release.

| Version | Supported |
| --- | --- |
| Latest GitHub and PowerShell Gallery release | Yes |
| Older releases | No |
| Development builds from `main` | Best effort |

Please privately share a minimal reproducible example that demonstrates the potential vulnerability. Include clear instructions on how to set up (using the latest release before reporting it), run and reproduce the issue.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting form:

<https://github.com/silverhack/monkey365/security/advisories/new>

If the private form is unavailable, open a minimal issue asking the maintainer to establish a private contact channel. Do not disclose vulnerability details in that issue.

Include, when applicable:

- The affected Monkey365 version and installation method.
- PowerShell version, operating system, and cloud environment.
- A clear description of the impact and affected component.
- Reproduction steps or a minimal proof of concept.
- Any known mitigations or workarounds.
- Whether the issue is already public or has been reported elsewhere.

Remove secrets and identifying tenant information from all supporting material. Never submit live credentials, refresh tokens, access tokens, certificates, private keys, or complete assessment reports.

## What to expect

Monkey365 is maintained by a solo developer. Reports are reviewed on a best-effort basis and no fixed response or remediation SLA is offered. The maintainer will aim to:

1. Confirm receipt and establish a private discussion.
2. Validate the report and assess severity and affected versions.
3. Coordinate remediation and a release when the report is accepted.
4. Publish a GitHub security advisory when public disclosure is appropriate.

Please allow reasonable time for investigation and remediation before public disclosure. Credit will be given when requested and when it is safe to do so.

## Scope

Examples of in-scope reports include:

- Code execution, command injection, or unsafe file handling in Monkey365.
- Exposure of credentials, access tokens, or sensitive assessment data.
- Authentication or authorization flaws introduced by Monkey365.
- Vulnerable bundled dependencies with a demonstrable Monkey365 impact.
- Compromise risks in release, packaging, or GitHub Actions workflows.

Configuration weaknesses discovered by a normal Monkey365 execution, support requests, false positives, and feature requests are not vulnerabilities in Monkey365. Use the channels described in [SUPPORT.md](SUPPORT.md) for those.