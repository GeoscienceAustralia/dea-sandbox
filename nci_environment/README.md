# Introduction

These scripts are used to update and deploy DEA modules on NCI.

There are two modules, with date-based version numbers:

 1. The Python Environment module *dea-env*

    * This contains third party dependencies of all of the DEA code, installed via
      a `conda` environment.

 2. A *dea* module, which depends on the _environment module_:

    * [Open Data Cube Core](https://github.com/opendatacube/datacube-core/)

    * [EO Datasets](https://github.com/GeoscienceAustralia/eo-datasets/)

    * [Digital Earth AU](https://github.com/GeoscienceAustralia/digitalearthau/)

    * [Data Cube Stats](https://github.com/GeoscienceAustralia/datacube-stats/)

    * [Fractional Cover](https://github.com/GeoscienceAustralia/fc/)

    * Creates users accounts in the Production Database the first time it is
      loaded by a user.

    * A configuration file including environments for the available _Indexes_


# User instructions

    module load dea
    datacube system check

This will load the latest version of `dea/<build_date>` module.

It will also load `dea-env/<build_date>` which contains all of the software
dependencies for using DEA.

## Notes

Loading these module might conflict with other python modules you have loaded.

The `dea-env` module will prevent conflicts with locally installed python packages by
changing `PYTHONUSERBASE` for each release;

    pip install --user <package_name>

will store packages under `~/.digitalearthau`.


It includes a config file, which it specifies by setting the
`DATACUBE_CONFIG_PATH` environment variable.

# Maintainer Instructions

Only run these scripts from Raijin. We've seen filesystem sync issues when
run from VDI.

    module load python3/3.8.5
    pip3 install --user pyyaml jinja2

## Building a new _Environment Module_

It requires python 3.8+ and pyyaml. Run the following on raijin at the NCI:

      $ module use /g/data/v10/public/modules/modulefiles/
      $ module load python3/3.8.5
      $ ./build_environment_module.py dea-env/modulespec.yaml

This will build a new environment module for today.

The module version number is the current date in format YYYYMMDD, as it is a snapshot
of all of our pip/conda dependencies on that date.

## Building a new _DEA Module_

A DEA module will specify one exact environment module.

    $ module use /g/data/v10/public/modules/modulefiles/
    $ module load python3/3.8.5
    $ ./build_environment_module.py dea/modulespec.yaml

## Updating the Default Version

Once a module has been tested and approved, it can be made the default.

Edit the `.version` file in the modulefiles directory.

Eg. For `dea` this is: `/g/data/v10/public/modules/modulefiles/dea/.version`


## Re-Building _dea-unstable_

    module load python3/3.6.2
    rm -rf /g/data/v10/public/modules/dea/unstable
    python3 build_environment_module.py dea_unstable/modulespec.yaml


## Archiving an old module

[TO DO]...



## How to run the tests on nci/gadi

## Setup

    Copy the 3 lines below and modify the VERSION value
    to the dea and dea-env module version you would
    like the tests to be run on. Paste them in a brand
    new shell session/terminal

        VERSION="20230710"
        module use /g/data/v10/public/modules/modulefiles
        module load dea/$VERSION
        module load dea-env/$VERSION

## Execution
On gadi, just run the tests with in this fashion:

    python3 -m pytest <directory of tests>;

Examples are:

    python3 -m pytest --nbval-lax Beginners_guide/;

    python3 -m pytest --nbval-lax DEA_products/;

    python3 -m pytest --nbval-lax How_to_guides/ --ignore How_to_guides/Land_cover_pixel_drill.ipynb --ignore How_to_guides/External_data_ERA5_Climate.ipynb --ignore How_to_guides/Imagery_on_web_map.ipynb;