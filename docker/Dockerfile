FROM mambaorg/micromamba:git-df79b72-jammy AS sandbox-conda

USER root
COPY locks/conda-linux-64.lock /conf/
RUN micromamba create  -y -p /env -f /conf/conda-linux-64.lock && \
    micromamba clean --all --yes && \
    micromamba env export -p /env --explicit > /conf/conda-linux-64.lock.out

ARG MAMBA_DOCKERFILE_ACTIVATE=1
ARG UPDATE_VERSION=1
COPY requirements.txt /conf/
COPY locks/constraints.txt /conf/
# required to build hdmedians
# or any --no-binary
ENV CC=/env/bin/x86_64-conda_cos6-linux-gnu-gcc \
    CXX=/env/bin/x86_64-conda_cos6-linux-gnu-g++ \
    LDSHARED="/env/bin/x86_64-conda_cos6-linux-gnu-gcc -pthread -shared -B /env/compiler_compat -L/env/lib -Wl,-rpath=/env/lib -Wl,--no-as-needed"
RUN micromamba run -p /env pip install --no-cache-dir \
    --no-build-isolation -r /conf/requirements.txt -c /conf/constraints.txt

FROM ubuntu:jammy-20240212

ARG nb_user=jovyan
ARG nb_uid=1000
ARG nb_gid=100

RUN useradd -l -m -s /bin/bash -N -g $nb_gid -u $nb_uid $nb_user

COPY --chown=$nb_uid:$nb_gid --from=sandbox-conda /env /env
# copies the generated conda lock from the build stage for use in github actions workflows post sandbox runtime stage
COPY --from=sandbox-conda /conf/conda-linux-64.lock.out /tmp/conf/conda-linux-64.lock

ENV LC_ALL=C.UTF-8 \
    SHELL=bash \
    GDAL_DRIVER_PATH=/env/lib/gdalplugins \
    PROJ_LIB=/env/share/proj \
    GDAL_DATA=/env/share/gdal \
    SQLALCHEMY_SILENCE_UBER_WARNING=1 \
    USE_PYGEOS=0 \
    PATH=/env/bin:$PATH

USER $nb_user

# NOTE - Install lab extension from pypi NOT here. 
# Leave the layer here for potential disable/enable and non-working check
RUN echo "Enable jupyter lab extensions" \
  && jupyter labextension list \
  && echo "...done"

# Enable server extensions and then clean up jupyter lab staging dir to reclaim
# space in this layer. 
# Ref: https://github.com/jupyterlab/jupyterlab/blob/main/docs/source/user/directories.md#staging-and-static
SHELL ["/bin/bash", "-euo", "pipefail", "-lc"]
RUN set -euo pipefail \
    && echo "Enable server extensions" \
    && jupyter server extension enable  --py jupyterlab_iframe --sys-prefix \
    && jupyter server extension enable  --py jupyter_resource_usage --sys-prefix \
    && jupyter server extension list \
    # enable these flags to diagnose lab build issues --debug --minimize=false
    && jupyter lab build \
    && echo "...done" \
    && APPDIR="$(jupyter lab path | awk -F': ' '/Application directory/ {print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" \
    && echo "JupyterLab APPDIR=${APPDIR}" \
    && [ -n "${APPDIR}" ] || (echo "ERROR: APPDIR is empty"; exit 1) \
    && mkdir -p "${APPDIR}" \
    && BEFORE="$(du -sm "${APPDIR}" | awk '{print $1}')" \
    && STAGING="${APPDIR}/staging" \
    && if [ -d "${STAGING}" ]; then \
        echo "Removing staging caches at ${STAGING}"; \
        rm -rf "${STAGING:?}" || true; \
      else \
        echo "No staging dir at ${STAGING}; skipping staging cleanup"; \
      fi \
    && AFTER="$(du -sm "${APPDIR}" | awk '{print $1}')" \
    && echo "Preserved production assets in ${APPDIR}. Size before: ${BEFORE} MB, after: ${AFTER} MB"

# Install from unzip instead of conda as conda version is not the tool but an "invoker" 
RUN echo "Install AWS CLI v2" \
   && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
   && unzip /tmp/awscliv2.zip -d /tmp > /dev/null \
   && /tmp/aws/install -i /env/bin/aws-cli -b /env/bin \
   && aws --version \
   && rm -f /tmp/awscliv2.zip \
   && rm -fr /tmp/aws \
   && echo "...done"

COPY assets/sync_repo assets/jupyterhub-singleuser /usr/local/bin/
COPY assets/overrides.json /env/share/jupyter/lab/settings/

RUN pip list --format=freeze > /tmp/requirements.txt

WORKDIR "/home/$nb_user"
ENTRYPOINT ["/env/bin/tini", "--"]
CMD ["jupyter", "lab", \
"--ip=0.0.0.0", \
"--port=9988", \
"--no-browser"]
