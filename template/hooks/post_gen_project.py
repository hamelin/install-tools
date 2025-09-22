from textwrap import dedent, wrap


print()
print(
    "\n".join(wrap(dedent(
        """\
        Configuration {{cookiecutter.installer_name}} is ready! You may now
        build the installer with command
        """
    )))
)
print()
print("    make out/{{cookiecutter.installer_name}}.sh")
print()
print(
    "\n".join(wrap(
        dedent(
            """\
            Note that you do not have to regenerate your installer
            configuration merely for the sake of changing the target Python
            version. Instead, edit file
            {{cookiecutter.installer_name}}/python_version,
            and the base Python installer and bootstrap environments will be
            regenerated to match.
            """.rstrip(),
        ),
        break_on_hyphens=False,
    ))
)
