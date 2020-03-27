# This script is sourced by every step.
#
# It defines how git branch maps to docker tag and provides some bash functions

BUILDER_TAG0=_build_cache
branch="${CODEBUILD_WEBHOOK_TRIGGER/branch\/}"
release="${CODEBUILD_WEBHOOK_TRIGGER/tag\/}"

echo "CODEBUILD_WEBHOOK_TRIGGER is $CODEBUILD_WEBHOOK_TRIGGER"

echo "Branch is $branch"
echo "Release is $release"

if [ "${branch}" = "master" ]; then
    echo "Tagging as latest"
    MAIN_TAG="latest"
    BUILDER_TAG="${BUILDER_TAG0}"
elif [[ "${CODEBUILD_WEBHOOK_TRIGGER}" == *"tag/"* ]]; then
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
