param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$failures = New-Object System.Collections.Generic.List[string]
$readmePath = Join-Path $RepoRoot 'README.md'
$expectedSkillName = 'dotnet-vertical-slice-best-practices'
$skillPath = Join-Path $RepoRoot $expectedSkillName
$skillFile = Join-Path $skillPath 'SKILL.md'
$referenceRoot = Join-Path $skillPath 'references'
$expectedReferences = @(
    'dotnet-migrations-project.md'
    'dotnet-platform-baseline.md'
    'dotnet-validation-and-errors.md'
    'dotnet-vertical-slice.md'
)
$expectedReferenceTokens = @(
    'dotnet-migrations-project'
    'dotnet-platform-baseline'
    'dotnet-validation-and-errors'
    'dotnet-vertical-slice'
)

if (-not (Test-Path -LiteralPath $skillPath)) {
    $failures.Add("Missing skill directory: $skillPath")
}

$rootDirectories = @(
    Get-ChildItem -LiteralPath $RepoRoot -Directory -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name
)

if ($expectedSkillName -notin $rootDirectories) {
    $failures.Add("Expected root skill folder '$expectedSkillName' under $RepoRoot")
}

if (-not (Test-Path -LiteralPath $skillFile)) {
    $failures.Add("Missing SKILL.md: $skillFile")
}

$skillNames = @($expectedSkillName)

if (Test-Path -LiteralPath $skillFile) {
    $content = Get-Content -LiteralPath $skillFile -Raw
    $frontmatterOk = $content -match '(?s)^---\r?\nname:\s*[^\r\n]+\r?\ndescription:\s*[^\r\n]+(?:\r?\n[^\r\n]+)*?\r?\n---'
    if (-not $frontmatterOk) {
        $failures.Add("Invalid frontmatter in $skillFile")
    }

    if ($content -notmatch '(?m)^compatibility:\s*[^\r\n]+$') {
        $failures.Add("Missing compatibility field in $skillFile")
    }

    if ($content -notmatch '(?m)^#\s+') {
        $failures.Add("Missing top-level heading in $skillFile")
    }
}

$referenceScanTargets = @(
    (Join-Path $RepoRoot 'README.md')
)

foreach ($scanTarget in $referenceScanTargets) {
    if (-not (Test-Path -LiteralPath $scanTarget)) {
        $failures.Add("Missing referenced repository asset: $scanTarget")
        continue
    }

    $content = Get-Content -LiteralPath $scanTarget -Raw
    $matches = [regex]::Matches($content, '`([a-z0-9-]+)`')
    foreach ($match in $matches) {
        $candidate = $match.Groups[1].Value
        if ($candidate.StartsWith('--')) {
            continue
        }
        if ($candidate -like '*-*' -and $candidate -notin $skillNames) {
            $knownNonSkill = @(
                'backend-only'
                'frontend-only'
                'full-stack'
                'architecture/spec-only'
                'verification-only'
            )
            if ($candidate -notin $knownNonSkill -and $candidate -notin $expectedReferenceTokens) {
                $failures.Add("Unknown referenced skill or token '$candidate' in $scanTarget")
            }
        }
    }
}

$requiredFiles = @($readmePath)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile)) {
        $failures.Add("Missing required file: $requiredFile")
    }
}

if (-not (Test-Path -LiteralPath $referenceRoot)) {
    $failures.Add("Missing references directory: $referenceRoot")
} else {
    $actualReferences = @(
        Get-ChildItem -LiteralPath $referenceRoot -File -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name
    )

    foreach ($expectedReference in $expectedReferences) {
        if ($expectedReference -notin $actualReferences) {
            $failures.Add("Missing expected reference file: $(Join-Path $referenceRoot $expectedReference)")
        }
    }
}

$englishFirstTargets = @(
    $readmePath
)

$spanishMarkers = @(
    'Resolver un issue',
    'Objetivo',
    'Clasificacion',
    'Alcance',
    'Riesgos',
    'Pega el enlace',
    'Issue o requerimiento',
    'Eres el',
    'Debes:',
    'No inventes'
)

foreach ($target in $englishFirstTargets) {
    if (-not (Test-Path -LiteralPath $target)) {
        continue
    }

    $content = Get-Content -LiteralPath $target -Raw
    foreach ($marker in $spanishMarkers) {
        if ($content -match [regex]::Escape($marker)) {
            $failures.Add("Spanish marker '$marker' still present in $target")
        }
    }
}

$forbiddenPaths = @(
    (Join-Path $RepoRoot '.agents')
    (Join-Path $RepoRoot '.github\agents')
    (Join-Path $RepoRoot '.github\prompts')
    (Join-Path $RepoRoot '.opencode')
    (Join-Path $RepoRoot 'workflows')
    (Join-Path $RepoRoot 'references')
)

foreach ($forbiddenPath in $forbiddenPaths) {
    if (Test-Path -LiteralPath $forbiddenPath) {
        $failures.Add("Non-skill adapter or shared-support path should not exist: $forbiddenPath")
    }
}

if ($failures.Count -gt 0) {
    Write-Error ($failures -join [Environment]::NewLine)
}

Write-Output "Agentic asset validation passed."
