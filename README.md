# DEA Sandbox

![Sandbox build and push latest](https://github.com/GeoscienceAustralia/dea-sandbox/workflows/Sandbox%20build%20and%20push%20latest/badge.svg)
![Vulnerability Scan](https://github.com/GeoscienceAustralia/dea-sandbox/workflows/Vulnerability%20Scan/badge.svg)

Digital Earth Australia Sandbox Docker build, configuration and planning.

Please ensure all tasks have a description that includes a clear definition of when the task is complete.

[Kanban](https://github.com/GeoscienceAustralia/dea-sandbox/projects/1)

[Issues](https://github.com/GeoscienceAustralia/dea-sandbox/issues)

## Automated builds

Builds are run automatically out of this repository. Basic workflow is:

- Create a branch and implement your changes
- The Docker image is built on the branch and as part of the pull request
- Once the PR is merged, a build will be run and pushed to `latest` and `sudo-latest` from master
- When a new stable image is ready, create a release with a version number like `0.0.6` and
this will be pushed to `0.0.6` and `sudo-0.0.6`.

## Local environment

A simple local environment that can be used to test the JupyterHub system in can be started using Docker Compose
with the command `docker-compose up` and browsing to http://localhost:8888 and adding the token that is displayed
on your terminal after starting the system.

To run connected to a database in one of the DEA systems, you'll need to start a Kubernetes port forwading process
with a command like `port-forward -n service deployment/pg-proxy 5432:5432`.

And then set up a file in the root of this folder `.docker.env` with connection details in it. Use the
`.docker.env.example` as a template for this file. You then want to run the Docker Compose environment without a
postgres database, so use the command `docker-compose -f docker-compose.yml up` to start it. This will ignore
the `docker-compose.override.yml` file, which provides a postgres container.

Any files in the `./notebooks` folder will be mounted in the user's home folder. That is to say that `./notebooks`
will be mounted at `/home/jovyan`/
