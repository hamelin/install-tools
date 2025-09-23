import re
import sys
from textwrap import wrap


if not re.match(r"^[-_.=+@,%^0-9a-zA-Z]+$", "{{cookiecutter.installer_name}}"):
    print(
        "\n".join(wrap(
            "Given installer name `{{cookiecutter.installer_name}}' is "
            "invalid. Use only characters that go naturally in program name, "
            "and avoid any blank or whitespace.",
            break_on_hyphens=False,
        ))
    )
    sys.exit(1)
