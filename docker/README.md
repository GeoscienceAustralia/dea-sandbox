Sandbox Docker
==============

- Uses `opendatacube/geobase` images as base
- Username is `jovyan` to match "typical python notebook dockers"
- `/env/..` contains python environment, writable by `jovyan` user
- Two stage build
  - Stage 1 contains all needed dev packages to build python environment including compilation of packages that need that.
  - Stage 2 installs run-time dependencies only (no headers or static libs) and copies pre-built python environment from stage 1.


### Extending

For large changes add new libraries to `requirements.txt` or
`requirements-jupyter.txt`. There are several "logical clusters" of packages in
there, try to attach new package to a correct group or create new category if
needed.

To add a new jupyter lab extension edit `jupyter-extensions.txt`. Always pin
extensions and Python libraries that use them.

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

### Gotchas

As of right now there are some limitations in the way `env-build-tool` works.
`opendatacube/geobase:wheels` docker pre-compiles following libraries:

- GDAL
- rasterio
- fiona
- shapely
- cartopy
- pyproj
- h5py
- netcdf4

Binary wheels are stored in `/wheels` folder. These wheels are then installed
into a python environment when it is constructed (only if module was requested
via `requirements.txt`). This is done by `env-build-tool` using pip
`constraints` mechanism, as a result you can not constraint any of these
libraries versions in `requirements.txt`, nor can you mark them as
`--no-binary`, even they really are, and must be, "compiled from source".

Ideally `env-build-tool` will be smarter and only use pre-compiled wheels when
needed and allow re-building of newer versions of those libraries. To achieve
this effect one has to delete the wheel file for a library you want to upgrade.
But make sure to mark this library as "compile only" via `--no-binary=libname`.

For example to use a specific version of `rasterio` one has to:

1. Add line like this `rasterio==1.2.3 --no-binary=rasterio` to `requirements.txt`
2. Run `rm /wheels/rasterio*` before creating python environment using `env-build-tool`

Keep in mind that `GDAL` module is special and has to match version of the C
library, so don't touch that one.
