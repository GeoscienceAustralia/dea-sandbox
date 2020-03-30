# This script is sourced by every step.
#
# It defines how git branch maps to docker tag and provides some bash functions

BUILDER_TAG0=_build_cache
branch="${CODEBUILD_RESOLVED_SOURCE_VERSION/refs\/heads\//}"
release="${CODEBUILD_RESOLVED_SOURCE_VERSION/refs\/tags\//}"

echo "GITHUB_REF is $CODEBUILD_RESOLVED_SOURCE_VERSION"
echo "GITHUB_EVENT_NAME is $GITHUB_EVENT_NAME"

echo "Branch is $branch"
echo "Release is $release"

if [ "${branch}" = "master" ]; then
    echo "Tagging as latest"
    MAIN_TAG="latest"
    BUILDER_TAG="${BUILDER_TAG0}"
elif [[ "${CODEBUILD_RESOLVED_SOURCE_VERSION}" == *"/tags/"* ]]; then
    echo "Tagging as release"
    MAIN_TAG="${release}"
    BUILDER_TAG="${BUILDER_TAG0}_${release}"
else
    echo "Tagging as branch"
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