# dea-sandbox
Digital Earth Australia Sandbox config and planning

Please ensure all tasks have a description that includes a clear definition of when the task is complete.

[Kanban](https://github.com/GeoscienceAustralia/dea-sandbox/projects/1)

[Issues](https://github.com/GeoscienceAustralia/dea-sandbox/issues)

## Local environment

A simple local environment that can be used to test the JupyterHub system in can be started using Docker Compose
with the command `docker-compose up` and browsing to http://localhost:8888 and adding the token that is displayed
on your terminal after starting the system.

To run connected to a database in one of the DEA systems, you'll need to start a Kubernetes port forwading process
with a command like `port-forward -n service deployment/pg-proxy 5432:5432`.

And then set up a file in the root of this folder `.docker.env` with connection details in it. Use the 
`.docker.env.example` as a template for this file.

Any files in the `./notebooks` folder will be mounted in the user's home folder. That is to say that `./notebooks`
will be mounted at `/home/jovyan`/
