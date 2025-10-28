# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "beautifulsoup4",
#   "requests",
# ]
# ///


from argparse import ArgumentParser
from bs4 import BeautifulSoup
from collections.abc import Callable
import os
from pathlib import Path
import re
import requests
import subprocess as sp
import shutil
import sys
from urllib.parse import urlparse


def main():
    for job in parse_args():
        job()


def confirm(prompt: str, code_abort: int = 1) -> None:
    if not re.match(r"y(es)?", input(f"{prompt} [yN] ")):
        print("Abort!", file=sys.stderr)
        sys.exit(code_abort)


def parse_args() -> list[Callable[[], None]]:
    parser = ArgumentParser(
        description="Builds and publishes the timc-vector-toolkit package."
    )
    parser.add_argument(
        "job",
        choices=["build", "publish", "clean"],
        help="""
            Determines what to do: either just build, build and publish,
            or delete package artifacts.
        """,
    )
    args = parser.parse_args()
    match args.job:
        case "build":
            return [build]
        case "publish":
            return [build, publish]
        case "clean":
            return [clean]


def build():
    sp.run(["uv", "build"]).check_returncode()


def files_to_publish():
    files_local = {
        path.name
        for path in Path("dist").iterdir()
        if path.name != ".gitignore"
    }
    files_remote = {
        urlparse(link["href"]).path.split("/")[-1]
        for link in BeautifulSoup(
            requests.get("https://pypi.org/simple/timc-vector-toolkit/").text,
            "html.parser",
        ).find_all("a")
    }
    return list(files_local - files_remote)


def publish():
    files = files_to_publish()
    if not files:
        print("All built files are already published on PyPI.")
        sys.exit(0)
    cp = sp.run(
        ["openssl", "aes-256-cbc", "-d", "-pbkdf2", "-in", ".token"],
        stdout=sp.PIPE,
        encoding="utf-8",
    )
    cp.check_returncode()
    env = dict(os.environ)
    env["UV_PUBLISH_TOKEN"] = cp.stdout

    print("About to publish the following files:")
    for file in files:
        print(f"    {file}")
    confirm("Proceed?")
    sp.run(
        ["uv", "publish", *files],
        env=env,
    ).check_returncode()


def clean():
    confirm("Destroy subdirectory dist/?")
    shutil.rmtree("dist", ignore_errors=True)


if __name__ == "__main__":
    main()
