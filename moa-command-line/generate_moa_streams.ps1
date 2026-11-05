# Run complete MOA WriteStreamToARFFFile task commands sequentially.
# Edit $MoaHome if your MOA installation is elsewhere.
$ErrorActionPreference = 'Stop'
$MoaHome = 'C:\Users\Training\Documents\salmanf\moa-software'
$OutputRoot = 'C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams'
$Java = 'java'
$JavaHeap = '-Xmx4g'

if (-not (Test-Path (Join-Path $MoaHome 'lib\moa.jar'))) {
    throw "Cannot find MOA at $MoaHome. Update `$MoaHome."
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

# Paste complete MOA commands here, one quoted string per job.
# Use the same output folder for simplicity. Avoid spaces in output paths.
$Jobs = @(
    'WriteStreamToARFFFile -s (ConceptDriftStream -s (generators.ImbalancedGenerator -a 5 -s 0.4 -b 0.6 -u) -d (generators.ImbalancedGenerator -r 2 -i 2 -a 5 -s 0.4 -b 0.6 -u) -p 25000 -w 1) -f (C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams\50K_static10_1dAbr_border6.arff) -m 50000'
    'WriteStreamToARFFFile -s (ConceptDriftStream -s (generators.ImbalancedGenerator -a 5 -s 0.4 -p 0.6 -u) -d (generators.ImbalancedDriftGenerator -r 2 -i 2 -a 5 -s 0.4 -p 0.6 -u) -p 25000 -w 1) -f (C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams\50K_static10_1dAbr_rare6.arff) -m 50000'
    'WriteStreamToARFFFile -s (ConceptDriftStream -s (generators.ImbalancedGenerator -a 5 -u) -d (generators.ImbalancedDriftGenerator -r 2 -i 2 -a 5 -n 5 -u) -p 25000 -w 1) -f (C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams\50K_static10_1dAbr_split1-5.arff) -m 50000'
    'WriteStreamToARFFFile -s (ConceptDriftStream -s (generators.ImbalancedGenerator -a 5 -n 5 -u) -d (generators.ImbalancedDriftGenerator -r 2 -i 2 -a 5 -u) -p 25000 -w 1) -f (C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams\50K_static10_1dAbr_merge5-1.arff) -m 50000'
    'WriteStreamToARFFFile -s (ConceptDriftStream -s (generators.ImbalancedGenerator -a 5 -u) -d (generators.ImbalancedDriftGenerator -r 2 -i 2 -a 5 -u) -p 25000 -w 1) -f (C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams\50K_static10_1dAbr_move.arff) -m 50000'
)

Push-Location $MoaHome
try {
    $index = 0
    foreach ($Command in $Jobs) {
        $index++
        Write-Host "Running stream $index of $($Jobs.Count)..." -ForegroundColor Cyan
        # Pass the entire MOA task as ONE command-line argument.
        & $Java $JavaHeap -cp 'lib/*' '-javaagent:lib/sizeofag-1.1.0.jar' 'moa.DoTask' $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Stream $index failed (Java exit code $LASTEXITCODE)."
        }
        Write-Host "Stream $index finished." -ForegroundColor Green
    }
    Write-Host "All $($Jobs.Count) stream commands completed. Output: $OutputRoot" -ForegroundColor Green
}
finally {
    Pop-Location
}
