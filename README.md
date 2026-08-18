# MERFISH Cell-Type Prediction — Rochester BDS Hackathon 2026

This repository is our working submission for the University of Rochester Biomedical Data Science Hackathon Summer 2026. The task is to predict one of 60 cell types for 5,000 held-out MERFISH cells using sparse expression counts, spatial coordinates, and tissue metadata.

The official evaluation metric is multiclass accuracy:

```text
accuracy = number of correct cell-type predictions / 5,000 test cells
```

See [Data.Description.md](Data.Description.md) for the organizer-provided data dictionary and submission rules.

## Current status

| Item | Status |
|---|---|
| Training cells | 5,000 |
| Test cells | 5,000 |
| Genes | 200 |
| Target classes | 60 |
| Best reproducible local OOF accuracy | **0.8068** |
| Best reproducible local OOF macro-F1 | **0.7864** |
| OOF correct predictions | **4,034 / 5,000** |
| Official submission path | [`prediction/prediction.csv`](prediction/prediction.csv) |

The 0.8068 result is a local out-of-fold estimate, not a public or hidden leaderboard score. The current GitHub `prediction.csv` remains the previously submitted version until the newer candidate is explicitly promoted and validated.

## Validation protocol

All reported model-selection results use four-fold out-of-fold predictions. Broad family stages use a stability gate that limits fold-level regressions; the later pairwise residual stages use a stricter gate requiring no fold to lose correct predictions and at least two folds to improve. The complete pipeline is retained only when its aggregate gain is positive in every fold.

For the current best pipeline, the gain over the 0.7932 baseline is positive in every fold:

```text
fold gains in correct predictions: +13 / +15 / +22 / +18
total gain: +68 correct predictions
```

This protocol is useful for iteration, but it is not yet a strict leave-one-sample or leave-one-section-out evaluation. A grouped validation audit by `Section_ID`, `Mouse_ID`, or sample is the next robustness check.

## Model pipeline

The final system is a conservative hierarchy rather than one monolithic classifier.

### 1. Global expression and metadata models

- `log1p` raw expression for all 200 genes.
- Library-size-normalized expression.
- Total transcript count and number of detected genes.
- Cell volume, spatial coordinates, tissue region, segment, mouse, dataset, sex, AP position, and section metadata.
- LightGBM for nonlinear interactions.
- Standardized multinomial logistic regression for a smoother complementary decision boundary.

### 2. Spatial information

Section-constrained spatial k-nearest-neighbour probabilities are used as a low-weight correction. The selected configuration uses cosine similarity, 20 neighbours, and conservative confidence gating. This stage is only retained because it adds correct predictions across folds.

### 3. Hierarchical biological specialists

Separate experts refine predictions within biologically related families:

- Oligodendrocyte lineage.
- Astrocytes.
- Vascular and meningeal cells.
- Dorsal-horn excitatory and inhibitory neurons.
- Motor neurons.
- Mid-ventral inhibitory neurons.

The specialists redistribute probability only inside the relevant family; they do not freely replace the global 60-class prediction.

### 4. Residual pair experts

Binary experts target repeatedly confused pairs. The strongest accepted residual corrections include:

- `DH_in_Klhl14` vs `DH_in_Cdh3`.
- `DH_ex_Grp` vs `DH_ex_Prkcg/Rxfp1`.
- `DH_ex_Prkcg/Cck` vs `DH_ex_Prkcg/Nts`.
- `DH_ex_Gpr83` vs `DH_ex_Grpr`.
- `DH_ex_Tac2` vs `DH_ex_Prkcg/Nts`.
- `meninges_1` vs `meninges_2`.
- `peripheral_glia` vs `Schwann_cell`.

Experts that do not pass the fold-stability gate are skipped automatically.

## OOF progress

| Stage | OOF accuracy | Correct | Net gain |
|---|---:|---:|---:|
| External hierarchical baseline | 0.7910 | 3,955 | — |
| Oligodendrocyte pair + section spatial kNN | 0.7932 | 3,966 | +11 |
| DH-ex, DH-in, and motor-neuron family experts | 0.7972 | 3,986 | +20 |
| Meningeal and peripheral-glia pair experts | 0.7990 | 3,995 | +9 |
| Mid-ventral inhibitory expert | 0.7996 | 3,998 | +3 |
| Strict residual neural pair experts | **0.8068** | **4,034** | **+36** |

Relative to the 0.7932 version, the final OOF labels changed for 141 cells: 101 errors were corrected and 33 previously correct labels were broken, for a net gain of 68.

## Leakage and submission safeguards

- Validation rows are never used as labelled training rows for their own fold.
- All expert thresholds and probability updates are evaluated on OOF predictions.
- Competition train and test Cell IDs are removed from external-reference experiments.
- Expression-fingerprint duplicates are also removed from the reference pool.
- Prediction files must contain exactly 5,000 rows in `meta_test.csv` order.
- Cell IDs must be unique and every prediction must be one of the 60 training labels.
- Only the captain's repository path is treated as the official submission.

## External-reference note

Some local specialist experiments use cells from the public MERFISH spinal-cord reference associated with [Zenodo record 18039571](https://doi.org/10.5281/zenodo.18039571). The reference is restricted to the 200 competition genes after removing all competition Cell IDs and expression-fingerprint matches.

The external-data candidate should only be promoted to the official submission after confirming that the competition rules permit this source. The code and provenance record will be supplied to the organizers if required.

## Repository layout

```text
Hackathon-Summer-2026/
├── Data.Description.md
├── README.md
├── v1/                  # reproducible 80.68% OOF pipeline archive
├── data/
│   ├── counts_train.csv
│   ├── counts_test.csv
│   ├── meta_train.csv
│   └── meta_test.csv
└── prediction/
    └── prediction.csv
```

Raw organizer data should remain unchanged. The only file scored from this fork is `prediction/prediction.csv`.

## Before promoting a new prediction

1. Run the complete OOF pipeline from a clean environment.
2. Confirm the expected OOF accuracy and per-fold deltas.
3. Audit performance with grouped validation by sample or section.
4. Confirm external-data eligibility with the organizers.
5. Check the CSV schema, row order, Cell IDs, null values, duplicates, and label vocabulary.
6. Commit only the intended README or prediction changes.

## Reproducibility status

The current best pipeline has been rerun end to end with fixed folds, seeds, reference filtering, and expert gates, reproducing 0.8068 OOF accuracy. The code, reports, provenance, and archived candidate are available in [`v1/`](v1/README.md).
