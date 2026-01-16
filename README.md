# DEA Sandbox

![Sandbox build and push latest](https://github.com/GeoscienceAustralia/dea-sandbox/workflows/Sandbox%20build%20and%20push%20latest/badge.svg)

The DEA Sandbox is a hosted JupyterLab environment preloaded with the DEA Python environment and example notebooks from [DEA Notebooks](https://github.com/GeoscienceAustralia/dea-notebooks/). This repository contains the Docker build configuration used to create the environment for both internal testing and the public DEA Sandbox.

## Approving pull requests
Anyone with 'maintain' role access to the dea-sandbox repository can approve 'pull requests'.

## Automated builds

Docker images are built automatically from this repository and pushed to the `dea-sandbox` AWS Elastic Container Registry (ECR) repository.
Two main server types use these images:

- **Unstable Sandbox servers**: used internally for testing changes and updating DEA Notebooks for upcoming environments.
- **Default Sandbox servers**: public-facing stable servers for general use.

### Updating unstable Sandbox servers

1. Create a branch and implement your changes, then submit a pull request.
3. On PR creation, a Docker image is built and a simple integration test is run against a subset of DEA Notebooks. (Failures are expected if breaking changes occur upstream,  and resolution by updating DEA Notebooks can be deferred until the image is made available on unstable Sandbox servers.)
5. Once the PR is merged, a build will run and the resultant Docker image will be pushed to ECR and tagged `latest`. (It is also tagged with a git reference.)
6. The `latest` image is automatically deployed to the unstable Sandbox servers.
7. Review or run the [DEA Notebooks scheduled integration tests](https://github.com/GeoscienceAustralia/dea-notebooks/actions/workflows/test_notebooks_scheduled.yml) to check the full DEA Notebooks repository against the new image.
8. Work with the DEA Notebooks Community of Practice to resolve any issues before promoting to stable.

> [!TIP]  
> The integration tests in this repository test only a small subset of DEA Notebooks, and are intended to identify major issues only. Refer to the [DEA Notebooks scheduled integration tests](https://github.com/GeoscienceAustralia/dea-notebooks/actions/workflows/test_notebooks_scheduled.yml) for the comprehensive test suite.

### Updating default Sandbox servers

1. Confirm that all issues found in the [DEA Notebooks scheduled integration tests](https://github.com/GeoscienceAustralia/dea-notebooks/actions/workflows/test_notebooks_scheduled.yml) for the `latest` image have been resolved or discussed with the DEA Notebooks Community of Practice.
2. When ready for a stable release, [create a new release](https://github.com/GeoscienceAustralia/dea-sandbox/releases) using the format `major.minor.patch` (e.g., `2.0.1`).
3. The presence of this new git tag triggers pushing a build that will have an image tag exactly matching the git tag. (It will also be tagged `stable`.)
4. JupyterHub deployments can be updated to pin the new version number (e.g. `2.0.1`) as their singleuser image tag. (Directly referencing `stable` is currently discouraged, for greater assurance of stability.)

## Packages' version maintenance and upgrade

The base environment uses Conda, and the Docker image is built in the following stages:

1. Conda install: Create the Conda environment and install as many packages as possible from `conda-forge`.
2. Pip install: Install remaining packages (e.g., most `odc-` packages) via pip.
3. Copy the completed environment into a new Ubuntu base image.

To speed up the build, the workflow pulls images from a cache stored on ECR. However, with every build the cache layers starting from `pip install` will be discarded, so that the newest versions of `odc-` packages will be installed. Thus, to perform version upgrades on these packages, creating a release is sufficient.

The old Conda env cache is used for all builds unless `env.yml` is changed. In addition to speeding up builds, this cached environment allows us to maintain a working `odc-` codebase and defer resolving conflicts on geospatial base packages such as `GDAL` and `GEOS`, until we have a good opportunity to manually review them.

The steps for package version upgrades are as follows:

- For `odc-` packages, create a new release.
- For packages listed in `env.yml`, be specific with the version required, for example, `Shapely>=2.0`.

**Note**: Avoid using `==` or `<=`, unless there is a hard requirement or a very good reason. Ensure you specify this reason clearly in your PR; what is it required for, your justification, and any supporting PRs (if applicable).

## Local environment

### Simple test environment

A simple local environment that can be used to test the JupyterHub system in can be started using Docker Compose
with the command `docker-compose up`

if the container started up successfully, it will show console log similar to the following

```
dea-sandbox-sandbox-1   | [C 2022-12-08 03:02:47.100 ServerApp]
dea-sandbox-sandbox-1   |
dea-sandbox-sandbox-1   |     To access the server, open this file in a browser:
dea-sandbox-sandbox-1   |         file:///home/jovyan/.local/share/jupyter/runtime/jpserver-7-open.html
dea-sandbox-sandbox-1   |     Or copy and paste one of these URLs:
dea-sandbox-sandbox-1   |         http://5cf0ca7d3dd0:9988/lab?token=bedea39c6e6ef14f633a99968cf47ec891588b6e14ec0862
dea-sandbox-sandbox-1   |      or http://127.0.0.1:9988/lab?token=bedea39c6e6ef14f633a99968cf47ec891588b6e14ec0862
```

browsing to http://localhost:9988 and adding the token that is displayed
on your terminal, i.e. `http://localhost:9988/lab?token=bedea39c6e6ef14f633a99968cf47ec891588b6e14ec0862`

#### Tip for hosting behind reverse proxy

```
location / {
        proxy_set_header   Host $http_host;
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;

        # forward to port 9988
        proxy_pass         "http://localhost:9988";

        # for terminal and notebook websockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
```


### With DEA database
To run `docker-compose` with a DEA indexed database, you'll need to start a Kubernetes port forwading process
with a command like `port-forward -n service deployment/pg-proxy 5432:5432`.

And then set up a file in the root of this folder `.env` with connection details in it. Use the
`.env.example` as a template for this file. You then want to run the Docker Compose environment without a
postgres database, so use the command `docker-compose -f docker-compose.yml up` to start it. This will ignore
the `docker-compose.override.yml` file, which provides a postgres container.

Any files in the `./notebooks` folder will be mounted in the user's home folder. That is to say that `./notebooks`
will be mounted at `/home/jovyan`/

## CI and Security
- Vulnerability scan on image build
    - Trivy runs on push if there was any change to docker
    - Critical vulnerabilities will block merge
    - If the critical vulnerability is difficult to remediate, reach out to DaS
- Leaks on Commit
    - GitLeaks will alert you if your commit diff contains secrets
    - Secrets in commit will block merge
- Static Leak Alerts
    - EDD conducts intermittent secret scans across the GA codebase
- Python linting and security suggestions
    - Any change pushed to a .py file will trigger the Python Lint workflow