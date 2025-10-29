# Maintainer documentation

The scripts in this directory are meant to make the lives of package and image maintainers easier.
This here also documents our resolutions on release conditions and scheduling.

## Distributing `timc-vector-toolkit` on PyPI

### New releases: **on nominal dependency changes**

So far, we have not put bounds on dependencies for the package.
This gives the standing package an _evergreen_ sort of property.
Thus,
we mainly release a new version of the package whenever we add new libraries or sunset obsolete projects.
We will also ensure to release more frequently if we start including bounded dependencies on packages not made by the Tutte Institute.

### Tooling

| Task | Command |
|------|---------|
| Bump version | `uv version <NEW-VERSION>` |
| Rebuild the package | `uv run scripts/pypi.py build` |
| Publish a fresh build | `uv run scripts/pypi.py publish` |
| Clean out the build artifacts | `uv run scripts/pypi.py clean` |
| Tool documentation | `uv run scripts/pypi.py --help` |

The publishing subscript is smart enough to upload only files that are not yet stored on PyPI.

## Distributing the `tutteinstitute/vector-toolkit` Docker image

### New releases: **each month**

In addition to new releases of our own packages,
external dependencies also get new releases and bugfixes.
Rebuilding and publishing the Docker image keeps it fresh in this regard.

Version tags correspond to dates formatted in year-month-day order,
without any punctuation.

### Tooling

| Task | Command |
|------|---------|
| Update the minor Python version our image is based on | Edit `Dockerfile`, change `FROM` statement. |
| Build *fresh* | `uv run scripts/docker.py build` |
| Build incrementally (e.g. for testing `Dockerfile` tweaks) | `uv run scripts/docker.py build -t` |
| Publish local tags to Docker hub | `uv run scripts/docker.py publish` |
| Discard Docker images | `uv run scripts/docker.py clean` |
| Tool documentation | `uv run scripts/docker.py --help` | 

A *fresh* build denotes one produced from the most up-to-date suitable online artifacts and external dependencies.

Let us be careful when discarding previously-built Docker images,
as we do not have the means to reproduce old builds.
We can still `docker pull` these if we discard them by mistake,
but not remake them exactly.
