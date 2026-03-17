# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyulog",
#     "pyyaml",
#     "matplotlib",
#     "numpy",
# ]
# ///

import argparse
from pathlib import Path

import numpy as np
import yaml
from matplotlib import pyplot as plt
import pyulog


def load_config(config_path: str) -> dict:
    with open(config_path, "r") as f:
        return yaml.safe_load(f)


def parse_args():
    parser = argparse.ArgumentParser(description="ULog reader and plotter")
    parser.add_argument(
        "--config",
        type=str,
        default="config.yaml",
        help="Path to config YAML file (default: config.yaml)",
    )
    parser.add_argument(
        "--ulg",
        type=str,
        default=None,
        help="Path to ULog file (overrides config.yaml)",
    )
    return parser.parse_args()


def validate_topics(
    ulog: pyulog.ULog, config_topics: dict
) -> list[tuple[str, list[str]]]:
    ulog_topic_data = {d.name: d for d in ulog.data_list}
    ulog_topic_names = set(ulog_topic_data.keys())

    missing_topics = [t for t in config_topics if t not in ulog_topic_names]
    if missing_topics:
        raise ValueError(f"Topics not found in ULog: {missing_topics}")

    result = []
    all_missing_fields = []

    for topic_name, topic_config in config_topics.items():
        ulog_fields = set(ulog_topic_data[topic_name].data.keys())
        config_fields = topic_config["fields"]

        missing_fields = [f for f in config_fields if f not in ulog_fields]
        if missing_fields:
            all_missing_fields.extend([f"{topic_name}.{f}" for f in missing_fields])
        else:
            result.append((topic_name, config_fields))

    if all_missing_fields:
        raise ValueError(f"Fields not found in ULog: {all_missing_fields}")

    return result


def compute_avg_hz(timestamps: np.ndarray, sample_window: int) -> float:
    if len(timestamps) < sample_window + 1:
        return 0.0

    timestamps_us = timestamps.astype(np.float64)
    hz_values = []
    for i in range(len(timestamps_us) - sample_window):
        dt_us = timestamps_us[i + sample_window] - timestamps_us[i]
        if dt_us > 0:
            hz = sample_window * 1_000_000.0 / dt_us
            hz_values.append(hz)

    return np.mean(hz_values) if hz_values else 0.0


def get_topic_data(ulog: pyulog.ULog, topic_name: str):
    for d in ulog.data_list:
        if d.name == topic_name:
            return d
    return None


def plot_topics(
    ulog: pyulog.ULog, topics: list[tuple[str, list[str]]], sample_window: int
):
    n_topics = len(topics)
    n_cols = 2
    n_rows = (n_topics + n_cols - 1) // n_cols
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(14, 4 * n_rows), squeeze=False)
    axes = axes.flatten()

    for idx, (topic_name, fields) in enumerate(topics):
        ax = axes[idx]
        data = get_topic_data(ulog, topic_name)

        if data is None:
            ax.text(0.5, 0.5, f"No data for {topic_name}", ha="center", va="center")
            ax.set_title(f"{topic_name} (N/A)")
            continue

        timestamps = data.data["timestamp"]
        avg_hz = compute_avg_hz(timestamps, sample_window)

        time_s = timestamps.astype(np.float64) / 1_000_000.0

        for field in fields:
            values = data.data[field]
            ax.plot(time_s, values, label=field, linewidth=0.8)

        ax.set_xlabel("Time (s)")
        ax.set_ylabel("Value")
        ax.set_title(f"{topic_name} ({avg_hz:.1f} Hz)")
        ax.legend(loc="upper right", fontsize="small")
        ax.grid(True, alpha=0.3)

    for idx in range(n_topics, len(axes)):
        axes[idx].set_visible(False)

    plt.tight_layout()
    plt.show()


def main():
    args = parse_args()

    script_dir = Path(__file__).parent
    config_path = script_dir / args.config
    config = load_config(config_path)

    ulg_path = args.ulg if args.ulg else config["ulg_file"]
    ulg_path = Path(ulg_path)
    if not ulg_path.is_absolute():
        ulg_path = script_dir / ulg_path

    print(f"Loading ULog: {ulg_path}")
    ulog = pyulog.ULog(str(ulg_path))

    topics = config["topics"]
    sample_window = config.get("sample_window", 5)

    print(f"Validating topics and fields...")
    valid_topics = validate_topics(ulog, topics)
    print(f"Valid topics: {[t[0] for t in valid_topics]}")

    plot_topics(ulog, valid_topics, sample_window)


if __name__ == "__main__":
    main()
