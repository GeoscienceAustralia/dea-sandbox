#!/usr/bin/env bash


# Module to test
if [[-z $1 ]]; then
    echo "ERROR: no module provided"
    exit 1
fi
module_to_test="$1"

echo Testing module: "$module_to_test"

# Reset modules directory
export MODULEPATH=/apps/.mf:/opt/Modules/modulefiles:/apps/Modules/modulefiles:

# Ensure that all files are world readable
if [[ $(find /g/data/v10/public/modules/modulefiles/"$module_to_test" ! -perm /004) ]]; then
    echo "ERROR: Some files in $module_to_test are not world readable."
    exit 1
fi


# Prepare to load the DEA module
module use /g/data/v10/public/modules/modulefiles

# Load the DEA modules
module load "$module_to_test"


# TODO Check the output from:
datacube system check

echo Testing notebooks
cd ../..
export DEA_TOOLS_TIDE_MODELS=/g/data/v10/tide_models
if [[ ! -d dea-notebooks ]]; then
    git clone --depth 1 https://github.com/GeoscienceAustralia/dea-notebooks.git
fi
./dea-notebooks/Tests/test_notebooks.sh

# Run the initialise Test Database Script

# Index some test datasets

# Run a test ingest in PBS

# Run a test FC using PBS (after ingest)

# Run a test Stats using PBS (after ingest)

# Run a test nbconvert using PBS


# Check that all was run
