from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parent.parent
META_TEST = ROOT / "data" / "meta_test.csv"
OUTPUT = ROOT / "prediction" / "prediction.csv"
LABEL = "MERFISH_cell_type_annotation"


def main() -> None:
    meta = pd.read_csv(META_TEST, index_col=0)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame({"Cell_ID": meta.index.astype(str), LABEL: ""}).to_csv(
        OUTPUT, index=False
    )
    print(f"submission template: rows={len(meta)} path={OUTPUT}")


if __name__ == "__main__":
    main()

