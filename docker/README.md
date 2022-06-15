Sandbox Docker
==============

- Username is `jovyan` to match "typical python notebook dockers"
- `/env/..` contains python environment, writable by `jovyan` user

### Extending

For large changes add new libraries to `requirements.txt` or
`requirements-jupyter.txt`. There are several "logical clusters" of packages in
there, try to attach new package to a correct group or create new category if
needed.

Modifying `requirements.txt` will trigger a complete rebuild of the python
environment and docker image. This is not always desirable. If you just need to
add a handful of extra modules that do not require compilation, add them
directly in `Dockerfile`, search for `# Patch env when needed here`. That way
docker re-build will be much quicker, there is less risk of breakage due to
changes on pypi, and pulling updated image into deployment will be much quicker
too as most docker layers will be re-used. You should also use this approach
when you need to update some packages to a newer version or to downgrade a
package.

When time comes to make a bigger change or update some binary packages, remember
to move packages listed in `Dockerfile` into `requirements.txt`.

At the end of compiling solve any incompatibility output from `pip check` by adding the version
in `constraints-odc.txt`.
