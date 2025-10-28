from argparse import ArgumentParser
from datetime import date
import itertools as it
import os
import re
import subprocess as sp
import sys


IMAGE = "tutteinstitute/vector-toolkit"


def confirm(prompt: str, code_abort: int | None = 1) -> bool:
    if not re.match(r"y(es)?", input(f"{prompt} [yN] ")):
        if code_abort is None:
            return False
        print("Abort!", file=sys.stderr)
        sys.exit(code_abort)
    return True


def main():
    parser = ArgumentParser(
        description="""
            Builds, tags and publishes the Vector Toolkit Docker image.
        """
    )
    parser.add_argument(
        "job",
        choices=["build", "publish", "test", "clean"],
        help="""
            Either builds the Docker image, publishes current tags, tests it as
            a base image, or destroys all build artifacts.
        """
    )
    parser.add_argument(
        "-v",
        "--version",
        help="""
            Version number to use for build artifacts.
            Default value is today's date, without any punctuation.
        """,
        default=date.today().strftime("%Y%m%d"),
    )
    parser.add_argument(
        "-t",
        "--incremental",
        help="""
            When building the image, the build makes use of cached build
            stages, as well as uses the current base image in local storage.
            This is useful for testing Dockerfile modifications.
            A full uncached build should be produced before publishing new
            tags.
        """,
        action="store_true",
        default=False,
    )
    args = parser.parse_args()
    match args.job:
        case "build":
            build(version=args.version, incremental=args.incremental)
        case "clean":
            clean()
        case "publish":
            publish()
        case "test":
            test()


def build(version: str, incremental: bool) -> None:
    args = [
        "docker",
        "build",
        *([] if incremental else ["--no-cache", "--pull"]),
        "--tag",
        f"{IMAGE}:{version}",
        "."
    ]
    print(">>> " + " ".join(args), file=sys.stderr)
    sp.run(args).check_returncode()
    if confirm(f"Update latest tag to {version}?", None):
        sp.run(
            ["docker", f"{IMAGE}:{version}", f"{IMAGE}:latest"]
        ).check_returncode()
    else:
        print("Ok, skip updating latest", file=sys.stderr)


def select_images() -> list[str]:
    cp = sp.run(
        ["docker", "images", "--format", "{{.Digest}} {{.Tag}}", IMAGE],
        stdout=sp.PIPE,
        encoding="utf-8",
    )
    cp.check_returncode()
    digest_x_tags = {
        digest: sorted(tag for _, tag in pairs)
        for digest, pairs in it.groupby(
            sorted([line.split() for line in cp.stdout.split("\n") if line.strip()]),
            lambda p: p[0]
        )
    }
    selected = set(sum(digest_x_tags.values(), []))
    while True:
        num_x_image = {}
        print("=" * int(os.environ.get("COLUMNS", 78)))
        for digest, tags in digest_x_tags.items():
            print(f"Image digest {digest}")
            for i, tag in enumerate(tags, start=len(num_x_image) + 1):
                num_x_image[i] = tag
                print(f"  {'x' if tag in selected else ' '} {i:2d}. {tag}")
        print()
        answer = input(
            "<NUM>: toggle | a: select all | n: select none | [g]: go >>> "
        ).lower().strip()
        if m := re.match(r"[0-9]+", answer):
            j = int(m.group(0))
            if j in num_x_image:
                tag = num_x_image[j]
                if tag in selected:
                    selected.remove(tag)
                else:
                    selected.add(tag)
        else:
            match answer:
                case "a":
                    selected = set(sum(digest_x_tags.values(), []))
                case "n":
                    selected = set()
                case "g":
                    break

    return sorted(selected)


def clean() -> None:
    for tag in select_images():
        sp.run(["docker", "image", "rm", f"{IMAGE}:{tag}"])


def publish() -> None:
    for tag in select_images():
        sp.run(["docker", "push", f"{IMAGE}:{tag}"])


def test() -> None:
    raise NotImplementedError()


if __name__ == "__main__":
    main()
