#!/usr/bin/env python3
"""Compare two GitHub Actions workflow jobs and fail on drift.

Catches CI drift like runner mismatches or missing steps between PR
and main workflows. Allows specific keys to differ (e.g. extra-tag).
"""

import argparse
import json
import sys
from pathlib import Path

import yaml


def load_workflow(path: Path) -> dict:
    return yaml.safe_load(path.read_text())


def normalize_job(job: dict, allowed_diffs: set[str]) -> dict:
    """Strip allowed-diff keys from publish-image `with:` blocks."""
    steps = []
    for step in job.get("steps", []):
        normalized = dict(step)
        if "with" in normalized:
            normalized["with"] = {
                k: v for k, v in normalized["with"].items() if k not in allowed_diffs
            }
        steps.append(normalized)
    return {
        "runs-on": job.get("runs-on"),
        "permissions": job.get("permissions"),
        "steps": steps,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workflow-a", default=".github/workflows/pull_request.yml")
    parser.add_argument("--workflow-b", default=".github/workflows/push_to_main.yml")
    parser.add_argument("--job", default="build_and_publish", help="Job name to compare")
    parser.add_argument(
        "--allowed-diffs",
        default="",
        help="Comma-separated 'with' keys that may differ",
    )
    args = parser.parse_args()

    allowed = {k.strip() for k in args.allowed_diffs.split(",") if k.strip()}

    wf_a = load_workflow(Path(args.workflow_a))
    wf_b = load_workflow(Path(args.workflow_b))

    job_a = wf_a.get("jobs", {}).get(args.job)
    job_b = wf_b.get("jobs", {}).get(args.job)

    if job_a is None:
        print(f"ERROR: job '{args.job}' not found in {args.workflow_a}")
        return 1
    if job_b is None:
        print(f"ERROR: job '{args.job}' not found in {args.workflow_b}")
        return 1

    norm_a = normalize_job(job_a, allowed)
    norm_b = normalize_job(job_b, allowed)

    if json.dumps(norm_a, sort_keys=True) != json.dumps(norm_b, sort_keys=True):
        print(f"FAIL: job '{args.job}' differs between:")
        print(f"  {args.workflow_a}")
        print(f"  {args.workflow_b}")
        print(f"Update {args.workflow_b} to match {args.workflow_a}.")
        return 1

    print(f"OK: job '{args.job}' matches in both workflows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
