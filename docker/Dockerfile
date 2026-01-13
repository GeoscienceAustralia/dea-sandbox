FROM mambaorg/micromamba:git-df79b72-jammy AS sandbox-conda

USER root
COPY env.yaml /conf/
RUN micromamba create  -y -p /env -f /conf/env.yaml && \
    micromamba clean --all --yes && \
    micromamba env export -p /env --explicit

ARG MAMBA_DOCKERFILE_ACTIVATE=1
ARG UPDATE_VERSION=1
COPY requirements.txt /conf/
# required to build hdmedians
# or any --no-binary
ENV CC=/env/bin/x86_64-conda_cos6-linux-gnu-gcc \
    CXX=/env/bin/x86_64-conda_cos6-linux-gnu-g++ \
    LDSHARED="/env/bin/x86_64-conda_cos6-linux-gnu-gcc -pthread -shared -B /env/compiler_compat -L/env/lib -Wl,-rpath=/env/lib -Wl,--no-as-needed"
RUN micromamba run -p /env pip install --no-cache-dir \
    --no-build-isolation -r /conf/requirements.txt

FROM ubuntu:jammy-20240212

ARG nb_user=jovyan
ARG nb_uid=1000
ARG nb_gid=100

RUN useradd -l -m -s /bin/bash -N -g $nb_gid -u $nb_uid $nb_user

COPY --chown=$nb_uid:$nb_gid --from=sandbox-conda /env /env

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

RUN echo "Enable server extensions" \
   && jupyter server extension enable  --py jupyterlab_iframe --sys-prefix \
   && jupyter server extension enable  --py jupyter_resource_usage --sys-prefix \
   && jupyter server extension list \
   && jupyter lab build \
   && echo "...done"

# Checks common jupyter lab cache dirs and cleans them up to reclaim space.
SHELL ["/bin/bash", "-lc"]
RUN set -euo pipefail; \
  PY_PREFIX=$(python -c "import sys; print(sys.prefix)"); \
  LABDIRS=""; \
  for d in "$PY_PREFIX/share/jupyter/lab" \
           "/opt/conda/share/jupyter/lab" \
           "/usr/local/share/jupyter/lab" \
           "/usr/share/jupyter/lab"; do \
    [ -d "$d" ] && LABDIRS="$LABDIRS $d"; \
  done; \
  [ -z "$LABDIRS" ] && echo "No JupyterLab dirs found" && exit 0; \
  BEFORE=$(du -sm $LABDIRS | awk '{s+=$1} END {print s}'); \
  jupyter lab clean || true; \
  command -v yarn >/dev/null 2>&1 && yarn cache clean --all || true; \
  command -v npm  >/dev/null 2>&1 && npm  cache clean --force || true; \
  rm -rf "${HOME}/.cache/yarn" "${HOME}/.npm" || true; \
  AFTER=$(du -sm $LABDIRS | awk '{s+=$1} END {print s}'); \
  echo "JupyterLab clean freed $((BEFORE - AFTER)) MB"

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
