ARG V_BASE=3.3.0
ARG py_env_path=/env

FROM opendatacube/geobase-builder:${V_BASE} as env_builder
ARG py_env_path

# Some libs assume presence of Cython and numpy in the environment, so build
# minimal env with those first, then extend further
COPY requirements0.txt constraints0.txt nobinary0.txt /conf/
RUN echo "Building python environment: stage 1" \
  && cat /conf/requirements0.txt \
  && NOBINARY=/conf/nobinary0.txt env-build-tool new /conf/requirements0.txt /conf/constraints0.txt ${py_env_path}

COPY requirements.txt constraints.txt nobinary.txt /conf/
RUN echo "Building python environment: stage 2" \
  && cat /conf/requirements.txt \
  && NOBINARY=/conf/nobinary.txt env-build-tool extend /conf/requirements.txt /conf/constraints.txt ${py_env_path}

ENV PATH=${py_env_path}/bin:$PATH

COPY requirements-jupyter.txt constraints-jupyter.txt /conf/
RUN echo "Building python environment: stage Jupyter" \
  && cat /conf/requirements-jupyter.txt \
  && env-build-tool extend /conf/requirements-jupyter.txt /conf/constraints-jupyter.txt ${py_env_path}

COPY jupyter-extensions.txt /conf/
# TAB_NAME -- name to appear in the browser tab
ARG TAB_NAME="DEA Sandbox"
RUN echo "Adding jupyter lab extensions" \
  && while read ext; do \
      if [ -n "${ext}" ]; then \
        echo "Installing ${ext}"; \
        jupyter labextension install --no-build "${ext}"; \
      fi; \
     done < /conf/jupyter-extensions.txt \
  && jupyter lab build --name="${TAB_NAME}" \
  && jupyter lab clean \
  && jupyter labextension list \
  && echo "...done"

RUN echo "Enable server extensions" \
  && jupyter serverextension enable --py --sys-prefix nbresuse \
  && jupyter serverextension enable --py --sys-prefix jupyterlab_code_formatter \
  && jupyter serverextension enable --py --sys-prefix jupyterlab_iframe \
  && echo done

COPY requirements-odc-static.txt /conf/
RUN echo "Adding odc-dependencies (static)" \
  && env-build-tool extend /conf/requirements-odc-static.txt ${py_env_path}
#
#FROM opendatacube/geobase-runner:${V_BASE}
#
#ENV DEBIAN_FRONTEND=noninteractive
#
#RUN apt-get update -y \
#&& apt-get install -y --fix-missing --no-install-recommends \
#  # developer convenience
#  postgresql-client-10 \
#  postgresql-10 \
#  less \
#  wget \
#  curl \
#  vim \
#  tmux \
#  htop \
#  fish \
#  tig \
#  git \
#  jq \
#  xz-utils \
#  zip \
#  unzip \
#  file \
#  time \
#  openssh-client \
#  graphviz \
#  sudo \
#  iproute2 \
#  iputils-ping \
#  net-tools \
#  simpleproxy \
#  rsync \
#  libtiff-tools \
## rgsislib dependencies
#  libcgal13 \
#  libmuparser2v5 \
#  libgsl23 \
#  libboost-system1.65.1 \
#  libboost-filesystem1.65.1 \
#  libboost-date-time1.65.1 \
## for cython to work need compilers
#  build-essential \
## for pyRAT install or something
#  libfftw3-dev \
#  liblapack-dev \
## install ffmpeg the normal way
#  ffmpeg \
#&& rm -rf /var/lib/apt/lists/*
#
## Install Tini
#COPY --from=env_builder /bin/tini /bin/tini
#
#ARG nb_user=jovyan
#ARG nb_uid=1000
#ARG nb_gid=100
#
#RUN useradd -m -s /bin/bash -N -g $nb_gid -u $nb_uid $nb_user
#
## Copy python env
#ARG py_env_path
#COPY --chown=1000:100 --from=env_builder $py_env_path $py_env_path
#
#ENV LC_ALL=C.UTF-8
#ENV SHELL=bash
## Put `/usr/local/bin` before env to allow overrides in there
#ENV PATH=/usr/local/bin:${py_env_path}/bin:$PATH
#
## Use `--build-arg PURGE_CACHE_ODC=$(date)` to force re-installation of ODC dependencies
## without the need to "edit" requirements-odc.txt
#ARG PURGE_CACHE_ODC=N
#COPY requirements-odc.txt /conf/
#USER $nb_user
#RUN echo "Adding odc-dependencies" \
#  && if [ "${PURGE_CACHE_ODC}" != "N" ]; then echo "Forced docker to purge cache for this step!"; fi \
#  && ${py_env_path}/bin/pip install \
#  --no-cache-dir \
#  --requirement=/conf/requirements-odc.txt
#
#USER root
## Patch env when needed here
## RUN echo "Patching python env" \
##   && pip install --no-cache-dir \
##   --extra-index-url="https://packages.dea.ga.gov.au" \
##   --no-deps --upgrade odc-algo odc-ui 'datacube[performance,s3]'
#
#COPY assets/sync_repo assets/with_bootstrap assets/jupyterhub-singleuser /usr/local/bin/
#COPY assets/overrides.json $py_env_path/share/jupyter/lab/settings/
#
#WORKDIR "/home/$nb_user"
#
#ARG WITH_SUDO="no"
#RUN if [ "$WITH_SUDO" = "yes" ]; then \
#  echo "${nb_user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
#;fi
#
#ARG BUILD_INFO=""
#RUN if [ -z "${BUILD_INFO}" ]; then \
#  BUILD_INFO="$(date)" \
#;fi \
#  && echo "${BUILD_INFO}" > /build.info
#
#USER $nb_user
#
#ENTRYPOINT ["/bin/tini", "-s", "--", "with_bootstrap"]
#CMD ["jupyter", "lab", \
#"--ip=0.0.0.0", \
#"--port=9988", \
#"--no-browser"]
