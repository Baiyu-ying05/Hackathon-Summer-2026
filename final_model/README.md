# Frozen backup scorer

This directory is the frozen, end-to-end backup scorer for the final validation round.
It uses only the four official CSV files under `data/` and writes the required file
to `prediction/prediction.csv`.

The currently submitted V12 CSV is not changed merely by adding this directory.
Run the scorer only after the organizers replace `data/counts_test.csv` and
`data/meta_test.csv` with the validation data.

## Run

From the repository root in PowerShell:

```powershell
python -m pip install -r final_model/requirements.txt
powershell -ExecutionPolicy Bypass -File final_model/run_pipeline.ps1 -Python python
```

The frozen pipeline trains a four-fold ensemble containing multinomial logistic
regression and three LightGBM configurations, then applies a conservative metadata
prior correction. It rebuilds the submission template from the current
`meta_test.csv`, so a replacement test set may have a different set of Cell IDs.

The archived local OOF diagnostic for this deliberately conservative fallback was
0.7708 accuracy. This is not the hidden-test score and it is not the V12 score.
The V12 historical-version router and its audit report are stored under `audit/`;
that router depends on previously generated model probability artifacts and is
included for provenance, not as the standalone validation entrypoint.

