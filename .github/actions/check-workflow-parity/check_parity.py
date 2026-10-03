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


def load_workflow(path: Path) -> dict[str, object]:
    """Load and parse a GitHub Actions workflow YAML file."""
    return yaml.safe_load(path.read_text())  # type: ignore[return-value]


def normalize_job(job: dict[str, object], allowed_diffs: set[str]) -> dict[str, object]:
    """Strip allowed-diff keys from publish-image ``with:`` blocks."""
    raw_steps = job.get("steps") or []
    if not isinstance(raw_steps, list):
        raw_steps = []
    steps: list[dict[str, object]] = []
    for step in raw_steps:
        if not isinstance(step, dict):
            continue
        step_dict = dict(step)
        with_block = step_dict.get("with")
        if isinstance(with_block, dict):
            step_dict["with"] = {
                k: v for k, v in with_block.items() if k not in allowed_diffs
            }
        steps.append(step_dict)
    return {
        "runs-on": job.get("runs-on"),
        "permissions": job.get("permissions"),
        "steps": steps,
    }


def main() -> int:
    """Compare two workflow jobs and exit 1 on drift."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workflow-a", default=".github/workflows/pull_request.yml")
    parser.add_argument("--workflow-b", default=".github/workflows/push_to_main.yml")
    parser.add_argument(
        "--job", default="build_and_publish", help="Job name to compare"
    )
    parser.add_argument(
        "--allowed-diffs",
        default="",
        help="Comma-separated 'with' keys that may differ",
    )
    args = parser.parse_args()
    workflow_a: str = args.workflow_a
    workflow_b: str = args.workflow_b
    job_name: str = args.job

    allowed: set[str] = {k.strip() for k in args.allowed_diffs.split(",") if k.strip()}

    wf_a = load_workflow(Path(workflow_a))
    wf_b = load_workflow(Path(workflow_b))

    raw_jobs_a = wf_a.get("jobs") or {}
    raw_jobs_b = wf_b.get("jobs") or {}
    if not isinstance(raw_jobs_a, dict):
        raw_jobs_a = {}
    if not isinstance(raw_jobs_b, dict):
        raw_jobs_b = {}

    raw_job_a = raw_jobs_a.get(job_name)
    raw_job_b = raw_jobs_b.get(job_name)
    if not isinstance(raw_job_a, dict):
        raw_job_a = None
    if not isinstance(raw_job_b, dict):
        raw_job_b = None

    if raw_job_a is None:
        print(f"ERROR: job '{job_name}' not found in {workflow_a}")
        return 1
    if raw_job_b is None:
        print(f"ERROR: job '{job_name}' not found in {workflow_b}")
        return 1

    norm_a = normalize_job(raw_job_a, allowed)
    norm_b = normalize_job(raw_job_b, allowed)

    if json.dumps(norm_a, sort_keys=True) != json.dumps(norm_b, sort_keys=True):
        print(f"FAIL: job '{job_name}' differs between:")
        print(f"  {workflow_a}")
        print(f"  {workflow_b}")
        print(f"Update {workflow_b} to match {workflow_a}.")
        return 1

    print(f"OK: job '{job_name}' matches in both workflows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
