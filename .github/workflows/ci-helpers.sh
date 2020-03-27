# This script is sourced by every step.
#
# It defines how git branch maps to docker tag and provides some bash functions

BUILDER_TAG0=_build_cache
branch="${GITHUB_REF/refs\/heads\//}"
release="${GITHUB_REF/refs\/tags\//}"

echo "GITHUB_REF is $GITHUB_REF"
echo "GITHUB_EVENT_NAME is $GITHUB_EVENT_NAME"

echo "Branch is $branch"
echo "Release is $release"

if [ "${branch}" = "master" ]; then
    MAIN_TAG="latest"
    BUILDER_TAG="${BUILDER_TAG0}"
elif [ "$GITHUB_EVENT_NAME" = "release" ]; then
    MAIN_TAG="${release}"
    BUILDER_TAG="${BUILDER_TAG0}_${release}"
else
    MAIN_TAG="${branch}"
    BUILDER_TAG="${BUILDER_TAG0}_${branch}"
fi

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
