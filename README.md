# DEA Sandbox

![Sandbox build and push latest](https://github.com/GeoscienceAustralia/dea-sandbox/workflows/Sandbox%20build%20and%20push%20latest/badge.svg)
![Vulnerability Scan](https://github.com/GeoscienceAustralia/dea-sandbox/workflows/Vulnerability%20Scan/badge.svg)

Digital Earth Australia Sandbox Docker build, configuration and planning.

Please ensure all tasks have a description that includes a clear definition of when the task is complete.

[Kanban](https://github.com/GeoscienceAustralia/dea-sandbox/projects/1)

[Issues](https://github.com/GeoscienceAustralia/dea-sandbox/issues)

## Automated builds

Builds are run automatically out of this repository. Basic workflow is:

- Create a branch and implement your changes.
- The Docker image is built on the branch and as part of the pull request.
- The integration test will be run on PR, merge and release events.
- Once the PR is merged, a build will run. The resultant image will be tagged with git `head` and `latest` and pushed to ECR.
- When you'd like to release a new stable image, create a release with a version number in the format `major.minor.patch`, e.g., `2.0.1`. This will trigger a build and the resultant image will be tagged with `2.0.1` (in this example) and `stable`, and pushed to ECR.

## Packages' version maintenance and upgrade

The base environment uses Conda, and the Docker image is built in two stages:

1. Create conda env and install as many as possible packages from `conda-forge`. Then `pip install` the rest, e.g., most `odc-` packages.
2. Copies the Conda env to a new Ubuntu image.

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
