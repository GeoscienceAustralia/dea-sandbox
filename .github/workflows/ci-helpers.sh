# This script is sourced by every step.
#
# It defines how git branch maps to docker tag and provides some bash functions

BUILDER_TAG0=_build_cache
branch="${GITHUB_REF/refs\/heads\//}"

if [ "${branch}" = "master" ]; then
    MAIN_TAG="latest"
    BUILDER_TAG="${BUILDER_TAG0}"
else
    MAIN_TAG="${branch}"
    BUILDER_TAG="${BUILDER_TAG0}_${branch}"
fi

SUDO_TAG=${MAIN_TAG}-sudo

pull_docker_cache () {
    local image=${1}
    local fallback=${2}

    if docker pull $image ; then
        echo "Pulled ${image}"
    else
        echo "Pulling fallback ${fallback}"
        if docker pull $fallback ; then
            echo "Using fallback: ${fallback}"
            docker tag $fallback $image
        fi
    fi
}
