import sys
import subprocess
from pathlib import Path

def run_nanoqc(fastq: Path, outdir: Path):
    try:
        from nanoQC.nanoQC import main as nanoqc_main
        sys.argv = ["nanoQC", "-o", str(outdir), str(fastq)]
        nanoqc_main()
    except Exception as e:
        print("⚠ NanoQC failed:", e)

def run_nanoplot(fastq: Path, outdir: Path):
    cmd = ["NanoPlot", "--fastq", str(fastq), "-o", str(outdir)]
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print("⚠ NanoPlot failed:", e)

if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--fastq", required=True)
    p.add_argument("--nanoqc_dir", required=True)
    p.add_argument("--nanoplot_dir", required=True)
    args = p.parse_args()

    fastq = Path(args.fastq)
    nanoqc_dir = Path(args.nanoqc_dir)
    nanoplot_dir = Path(args.nanoplot_dir)

    nanoqc_dir.mkdir(parents=True, exist_ok=True)
    nanoplot_dir.mkdir(parents=True, exist_ok=True)

    print("🧪 Running NanoQC...")
    run_nanoqc(fastq, nanoqc_dir)
    print("📈 Running NanoPlot...")
    run_nanoplot(fastq, nanoplot_dir)
