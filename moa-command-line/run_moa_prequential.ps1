# Run MOA EvaluatePrequential tasks sequentially; keep one root summary.
# Dataset folders contain learner result CSVs only. Java logs are retained only on failure in OutputRoot.
# Compatible with Windows PowerShell 5.1 / PowerShell 7.
# Edit $MoaHome, $DatasetRoot, and $OutputRoot for your computer.

$ErrorActionPreference = 'Stop'
$MoaHome = 'C:\Users\Training\Documents\salmanf\moa-software'
$DatasetRoot = 'C:\Users\Training\Documents\salmanf\moa\dataset\generated_streams'
$OutputRoot = 'C:\Users\Training\Documents\salmanf\moa\results'
$Java = 'java'
$JavaHeap = '-Xmx4g'

# Each job is ONE complete MOA task command. Paste/edit tasks here only.
# Use __ARFF_FILE__ wherever the current dataset should be used.
# The script substitutes each ARFF file from $DatasetRoot into every job.
$Jobs = @(
    'EvaluatePrequential -l meta.UOB -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l meta.OOB -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l active.CALMID -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (meta.imbalanced.CSMOTE -l (meta.AdaptiveRandomForest -l (ARFHoeffdingTree -e 2000000 -c 0.0) -s 10 -x (ADWINChangeDetector -a 0.001) -p (ADWINChangeDetector -a 0.01))) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (meta.imbalanced.OnlineUnderOverBagging -l trees.HoeffdingTree) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (meta.BASWE -l (trees.HoeffdingTree -e 2000000 -c 0.0) -c 500) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (active.MicFoal -c (trees.HoeffdingTree -c 0.0)) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (meta.KUE -l (trees.HoeffdingTree -e 2000000 -c 0.0) -c 500) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l meta.imbalanced.ROSE -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l meta.imbalanced.RebalanceStream -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l (meta.imbalanced.OnlineSMOTEBagging -l trees.HoeffdingTree) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500 -a 0.009999999999999998'
    'EvaluatePrequential -l (meta.imbalanced.OnlineRUSBoost -l trees.HoeffdingTree -i 1 -a (Fixed sampling rate)) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500 -a 0.009999999999999998'
    'EvaluatePrequential -l (meta.AdaptiveRandomForest -l (ARFHoeffdingTree -k 3 -e 2000000 -c 0.0) -s 10 -x (ADWINChangeDetector -a 0.001) -p (ADWINChangeDetector -a 0.01)) -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500'
    'EvaluatePrequential -l trees.HoeffdingAdaptiveTree -s (ArffFileStream -f (__ARFF_FILE__)) -e (WindowClassificationPerformanceEvaluator -w 500 -o -p -r -f) -i 50000 -f 500 -a 0.009999999999999998'
)

# Read all .arff files directly under the dataset folder (sorted by filename).
if (-not (Test-Path -LiteralPath (Join-Path $MoaHome 'lib\moa.jar') -PathType Leaf)) {
    throw "Cannot find lib\moa.jar under '$MoaHome'. Edit `$MoaHome."
}
if (-not (Test-Path -LiteralPath (Join-Path $MoaHome 'lib\sizeofag-1.1.0.jar') -PathType Leaf)) {
    throw "Cannot find sizeofag-1.1.0.jar under '$MoaHome'. Edit `$MoaHome."
}
if (-not (Test-Path -LiteralPath $DatasetRoot -PathType Container)) {
    throw "Dataset folder not found: '$DatasetRoot'. Edit `$DatasetRoot."
}
$Datasets = @(Get-ChildItem -LiteralPath $DatasetRoot -Filter '*.arff' -File | Sort-Object Name)
if ($Datasets.Count -eq 0) {
    throw "No .arff datasets found in '$DatasetRoot'."
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$SummaryFile = Join-Path $OutputRoot 'run_summary.csv'
$Summary = New-Object System.Collections.Generic.List[object]
$Total = $Datasets.Count * $Jobs.Count
$Done = 0
Write-Host "Found $($Datasets.Count) datasets and $($Jobs.Count) learners: $Total evaluations." -ForegroundColor Cyan

Push-Location $MoaHome
try {
    foreach ($Dataset in $Datasets) {
        $ArffFile = $Dataset.FullName
        $DatasetName = [System.IO.Path]::GetFileNameWithoutExtension($Dataset.Name)
        $DatasetOutput = Join-Path $OutputRoot $DatasetName
        New-Item -ItemType Directory -Path $DatasetOutput -Force | Out-Null
        Write-Host "`nDataset: $($Dataset.Name)" -ForegroundColor Yellow

        $index = 0
        foreach ($Command in $Jobs) {
            $index++
            $Done++
            if ($Command -notmatch '^EvaluatePrequential\s+-l\s+\(?([A-Za-z0-9_.]+)') {
                throw "Job $index does not begin with an expected EvaluatePrequential -l classifier."
            }
            $LearnerName = $Matches[1].Split('.')[-1]
            $Prefix = ('{0:D2}_{1}' -f $index, $LearnerName)
            $CsvFile = Join-Path $DatasetOutput ($Prefix + '.csv')
            # Capture Java output temporarily at the root, not inside dataset result folders.
            $LogFile = Join-Path $OutputRoot ('_java_output_{0}_{1}.tmp.log' -f $DatasetName, $Prefix)
            $FailureLog = Join-Path $OutputRoot ('FAILED_{0}_{1}.log' -f $DatasetName, $Prefix)

            # The output files for this dataset/learner are replaced on rerun.
            if (Test-Path -LiteralPath $CsvFile) { Remove-Item -LiteralPath $CsvFile -Force }
            if (Test-Path -LiteralPath $LogFile) { Remove-Item -LiteralPath $LogFile -Force }
            if (Test-Path -LiteralPath $FailureLog) { Remove-Item -LiteralPath $FailureLog -Force }

            $ResolvedCommand = $Command.Replace('__ARFF_FILE__', $ArffFile)
            $Task = "$ResolvedCommand -d ($CsvFile)"
            Write-Host ("[{0}/{1}] {2} / {3}" -f $Done, $Total, $DatasetName, $LearnerName) -ForegroundColor Cyan
            $Started = Get-Date
            # Windows PowerShell 5.1 may treat native stderr as a terminating
            # NativeCommandError when ErrorActionPreference is 'Stop'. Capture
            # BOTH Java streams without stopping before checking its exit code.
            $PreviousErrorActionPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                & $Java $JavaHeap '-cp' 'lib/*' '-javaagent:lib/sizeofag-1.1.0.jar' 'moa.DoTask' $Task 2>&1 |
                    Out-File -LiteralPath $LogFile -Encoding UTF8
                $ExitCode = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $PreviousErrorActionPreference
            }
            $Seconds = [math]::Round(((Get-Date) - $Started).TotalSeconds, 2)
            $ValidCsv = (Test-Path -LiteralPath $CsvFile) -and ((Get-Item -LiteralPath $CsvFile).Length -gt 0)
            $Status = if (($ExitCode -eq 0) -and $ValidCsv) { 'Success' } else { 'Failed' }
            $Summary.Add([pscustomobject]@{
                Dataset = $Dataset.Name; Job = $index; Learner = $LearnerName
                Status = $Status; ExitCode = $ExitCode; Seconds = $Seconds
                Csv = $CsvFile; ErrorLog = $(if ($Status -eq 'Failed') { $FailureLog } else { '' })
            })
            $Summary | Export-Csv -LiteralPath $SummaryFile -NoTypeInformation -Encoding UTF8

            if ($Status -ne 'Success') {
                Write-Host "Failed: $($Dataset.Name) / $LearnerName. Log: $FailureLog" -ForegroundColor Red
                Write-Host "Last 25 lines of Java output:" -ForegroundColor Yellow
                if (Test-Path -LiteralPath $LogFile) {
                    Get-Content -LiteralPath $LogFile -Tail 25 | ForEach-Object { Write-Host $_ }
                }
                if (Test-Path -LiteralPath $LogFile) {
                    Move-Item -LiteralPath $LogFile -Destination $FailureLog -Force
                }
                throw "Evaluation stopped after $Done of $Total tasks; Java exit code $ExitCode; CSV exists/nonempty: $ValidCsv"
            }
            # Keep only learner CSVs in dataset folders and a single root summary.
            # Successful runs do not retain individual Java console logs.
            if (Test-Path -LiteralPath $LogFile) {
                Remove-Item -LiteralPath $LogFile -Force
            }
            Write-Host ("    Done in {0} seconds." -f $Seconds) -ForegroundColor Green
        }
    }
    Write-Host "All $Total evaluations complete. Results: $OutputRoot" -ForegroundColor Green
}
finally {
    Pop-Location
}
