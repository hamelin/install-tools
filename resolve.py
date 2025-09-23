from pathlib import Path
import sys


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <target>")
    target = sys.argv[1]
    python_version = (
        (Path(target) / "python_version").read_text(encoding="utf-8")
    ).strip()
    dir_artifacts = f"{target}-artifacts"
    print(
        sys.stdin.read().format(
            python_version=python_version,
            dir_artifacts=dir_artifacts,
        ).strip()
    )
