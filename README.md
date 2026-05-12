# Agentic Skills

This repository publishes a single Agent Skill built around the open `SKILL.md` standard.

The published skill is:

- `dotnet-vertical-slice-best-practices`

It intentionally contains **skills only**:

- no custom agents;
- no runtime-specific prompt adapters;
- no command wrappers.

The canonical published source in this repository is:
- `./dotnet-vertical-slice-best-practices/`

## Structure

```text
dotnet-vertical-slice-best-practices/
  SKILL.md
  references/
    dotnet-migrations-project.md
    dotnet-platform-baseline.md
    dotnet-validation-and-errors.md
    dotnet-vertical-slice.md
```

## Standard Layout

Agent Skills define each skill as a folder that contains a required `SKILL.md` file plus optional
`scripts/`, `references/`, or `assets/` directories. This repository follows that structure with a
single publishable skill folder at the repository root.

## Compatible AI Tools

This skill is designed for Agent Skills-compatible coding assistants. The standard is open and is
used across compatible tools such as:

- OpenAI Codex
- GitHub Copilot environments that support Agent Skills
- Claude Code and other compatible clients

The skill includes a `compatibility` field so the intended client family is visible in the skill metadata.

## Installation

Agent Skills are installed by placing skill folders in a client-discoverable skills directory.
The repository source can live at the root, while the installer places the skill into the right
agent-specific skills directory.

For project-level sharing, the common interoperable destination is:

```text
.agents/skills/
```

### Install From `skills.sh`

For a published repository on `skills.sh`, the install pattern for one skill is:

```text
npx skills add https://github.com/<owner>/<repo> --skill dotnet-vertical-slice-best-practices
```

This is the form that works with the standard interactive installer. If the user does not pass
`--agent` or `--yes`, the CLI can ask which agent to install into and which installation method to use.

Example:

```text
npx skills add https://github.com/<owner>/<repo> --skill dotnet-vertical-slice-best-practices
```

### Install From A Local Clone

1. Open the target repository.
2. Create the standard skills directory if it does not exist:

```powershell
New-Item -ItemType Directory -Force .agents\skills | Out-Null
```

3. Copy the skill folder from this repository into the target repository:

```powershell
Copy-Item -Recurse "PATH_TO_THIS_REPO\dotnet-vertical-slice-best-practices" ".agents\skills\"
```

4. Confirm the target repository now contains:

```text
.agents/skills/
  dotnet-vertical-slice-best-practices/
```

PowerShell example:

```powershell
New-Item -ItemType Directory -Force .agents\skills | Out-Null
Copy-Item -Recurse "PATH_TO_THIS_REPO\dotnet-vertical-slice-best-practices" ".agents\skills\"
```

### Verify The Installation

You can validate an individual installed skill with the standard validator:

```text
skills-ref validate ./path/to/skill
```

Example:

```text
skills-ref validate ./.agents/skills/dotnet-vertical-slice-best-practices
```

This repository also ships a local PowerShell validator for the package itself:

```powershell
.\scripts\validate-agentic-assets.ps1
```

### How Compatible AI Tools Discover Them

Once the installer places the folder under the chosen agent's skills directory, Agent Skills-compatible
clients can discover the available skill from its `SKILL.md` metadata and activate it when the task matches.

The standard does not require a single package-manager command. The portable install model is:

1. place the skill folder in a supported skills directory;
2. keep the folder name and `SKILL.md` intact;
3. let the compatible client discover and activate it.

## Included Skill

- `dotnet-vertical-slice-best-practices`
  - implements and evolves .NET backends using vertical slices, explicit validation and error handling, PostgreSQL persistence, and dedicated EF Core migrations.
  - includes internal references for `dotnet-migrations-project`, `dotnet-platform-baseline`, `dotnet-validation-and-errors`, and `dotnet-vertical-slice`.

## Validation

- `scripts/validate-agentic-assets.ps1`
  - validates the single-skill package structure, required metadata, companion reference layout, and the absence of the old multi-skill and adapter layout.
- `.github/workflows/validate-agentic-assets.yml`
  - runs the same validation in CI on pushes and pull requests.

## Scope Boundary

- This repository packages one skill only.
- Consuming repositories remain free to define their own project instructions, local conventions, and runtime-specific tooling outside this package.

The idea is simple: publish the skill as a clean root-level package, let `npx skills add` install it into the
selected agent's standard directory, and keep the package portable instead of tying it to one assistant runtime.
