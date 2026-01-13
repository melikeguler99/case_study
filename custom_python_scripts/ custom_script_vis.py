#!/usr/bin/env python
# coding: utf-8

# In[ ]:


from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

csv_path = Path("barcode77_read_stats.csv") 
df = pd.read_csv(csv_path)

# Validate + numeric
for col in ["GC", "ReadLength", "QualityScore"]:
    if col not in df.columns:
        raise ValueError(f"Missing column '{col}'. Found: {list(df.columns)}")
    df[col] = pd.to_numeric(df[col], errors="coerce")

sample_id = df["SampleID"].iloc[0] if "SampleID" in df.columns and len(df) else csv_path.stem

# convert bases -> kb for plotting/summarizing
df["ReadLength_kb"] = df["ReadLength"] / 1000.0

def freedman_diaconis_bins(x: np.ndarray, min_bins=15, max_bins=80) -> int:
    x = x[np.isfinite(x)]
    n = x.size
    if n < 2:
        return min_bins
    q25, q75 = np.percentile(x, [25, 75])
    iqr = q75 - q25
    if iqr <= 0:
        return min_bins
    bw = 2 * iqr * (n ** (-1/3))
    if bw <= 0:
        return min_bins
    bins = int(np.ceil((x.max() - x.min()) / bw))
    return int(np.clip(bins, min_bins, max_bins))

def summarize(series: pd.Series, name: str) -> pd.Series:
    s = series.dropna().astype(float)
    if s.empty:
        return pd.Series({"n": 0}, name=name)
    vals = s.to_numpy()
    q5, q25, q75, q95 = np.percentile(vals, [5, 25, 75, 95])
    return pd.Series({
        "n": len(vals),
        "mean": np.mean(vals),
        "median": np.median(vals),
        "std": np.std(vals, ddof=1) if len(vals) > 1 else np.nan,
        "min": np.min(vals),
        "max": np.max(vals),
        "p5": q5,
        "p25": q25,
        "p75": q75,
        "p95": q95,
    }, name=name)

def plot_hist(ax, data: pd.Series, title: str, xlabel: str, x_max=None):
    x = data.dropna().astype(float).to_numpy()
    x = x[np.isfinite(x)]
    if x.size == 0:
        ax.text(0.5, 0.5, "No data", ha="center", va="center")
        ax.set_axis_off()
        return

    # OPTIONAL: cap extreme outliers for better visibility
    if x_max is not None:
        x = x[x <= x_max]

    bins = freedman_diaconis_bins(x)

    ax.hist(x, bins=bins, edgecolor="white", linewidth=0.6)
    mean = np.mean(x)
    med = np.median(x)

    ax.axvline(mean, linewidth=2, linestyle="--", label=f"mean = {mean:.2f}")
    ax.axvline(med, linewidth=2, linestyle="-",  label=f"median = {med:.2f}")

    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel("count")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False)

stats = pd.concat([
    summarize(df["GC"], "GC Content (%)"),
    summarize(df["ReadLength_kb"], "Read Length (kb)"),          
    summarize(df["QualityScore"], "Mean Read Quality (Phred)"),
], axis=1).T

display(stats.round(4))


fig, axes = plt.subplots(1, 3, figsize=(18, 4.8))

plot_hist(axes[0], df["GC"], "GC content distribution", "GC (%)")
plot_hist(axes[1], df["QualityScore"], "Mean read quality distribution", "Mean Phred score")

# OPTIONAL but recommended: cap to 99th percentile to avoid one massive read wrecking the plot
rl_kb_p99 = np.nanpercentile(df["ReadLength_kb"], 99)
plot_hist(axes[2], df["ReadLength_kb"], "Read length distribution", "Read length (kb)", x_max=rl_kb_p99)

fig.suptitle(f"{sample_id} — distributions from CSV", y=1.02, fontsize=14)
plt.show()
out_png = Path("barcode77_read_stats_histograms.png")
fig.savefig(out_png, dpi=100, bbox_inches="tight")
print("Saved:", out_png.resolve())

