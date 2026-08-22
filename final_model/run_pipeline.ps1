param(
    [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$ModelRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceRoot = Join-Path $ModelRoot "src"
$ArtifactRoot = Join-Path $ModelRoot "artifacts"
$RepoRoot = Split-Path -Parent $ModelRoot

New-Item -ItemType Directory -Force -Path $ArtifactRoot | Out-Null

$ExistingPythonPath = $env:PYTHONPATH
$env:PYTHONPATH = if ($ExistingPythonPath) {
    "$SourceRoot;$ExistingPythonPath"
} else {
    $SourceRoot
}

& $Python (Join-Path $ModelRoot "make_submission_template.py")
if ($LASTEXITCODE -ne 0) { throw "make_submission_template.py failed" }

& $Python (Join-Path $SourceRoot "train_model.py")
if ($LASTEXITCODE -ne 0) { throw "train_model.py failed" }

& $Python (Join-Path $SourceRoot "multiseed_ensemble.py")
if ($LASTEXITCODE -ne 0) { throw "multiseed_ensemble.py failed" }

& $Python (Join-Path $SourceRoot "prior_postprocess.py")
if ($LASTEXITCODE -ne 0) { throw "prior_postprocess.py failed" }

$Candidate = Join-Path $ArtifactRoot "prediction_prior_corrected.csv"
$Submission = Join-Path $RepoRoot "prediction\prediction.csv"
Copy-Item -LiteralPath $Candidate -Destination $Submission -Force

& $Python (Join-Path $SourceRoot "validate_submission.py") $Submission
if ($LASTEXITCODE -ne 0) { throw "validate_submission.py failed" }

Write-Host "frozen backup pipeline complete: $Submission"

