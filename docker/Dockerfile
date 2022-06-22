FROM osgeo/gdal:ubuntu-small-latest

RUN curl -fsSL https://deb.nodesource.com/setup_18.x |  bash - \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
    # Build tools\ 
    build-essential \ 
    python3-pip \ 
    python3-dev \ 
    # For Psycopg2 
    libpq-dev\ 
    # Yaml parsing speedup 
    libyaml-dev \ 
    lsb-release \ 
    # tini
    tini \
    # developer convenience
    postgresql-client-12 \
    less \
    wget \
    vim \
    tmux \
    htop \
    fish \
    tig \
    git \
    jq \
    xz-utils \
    zip \
    unzip \
    file \
    time \
    openssh-client \
    graphviz \
    iproute2 \
    iputils-ping \
    net-tools \
    simpleproxy \
    rsync \
    libtiff-tools \
    # rgsislib dependencies
    libgsl-dev \
    libcgal-dev \
    libboost-dev \
    libmuparser2v5 \
    libboost-system1.71.0 \
    libboost-filesystem1.71.0 \
    libboost-date-time1.71.0 \
    # for all no-binary build
    libhdf5-dev \
    libhdf5-103 \
    libhdf5-cpp-103 \
    libwbxml2-dev \
    libxslt1-dev \
    libgeos-dev \
    libffi-dev \
    libproj-dev \
    # for jupyter extension
    nodejs \
    # for pyRAT install or something
    libfftw3-dev \
    liblapack-dev \
    # install ffmpeg the normal way
    ffmpeg \
    # Cleanup 
    && apt-get autoremove -y \ 
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log

ARG py_env_path=/env
ARG nb_user=jovyan
ARG nb_uid=1000
ARG nb_gid=100

RUN mkdir -p ${py_env_path}/bin \
  && useradd -m -s /bin/bash -N -g $nb_gid -u $nb_uid $nb_user \
  && ln -s  /usr/bin/python ${py_env_path}/bin/python \
  && chown -R $nb_uid:$nb_gid ${py_env_path}

COPY pyvenv.cfg ${py_env_path}/

ENV LC_ALL=C.UTF-8 \
    SHELL=bash \
    PATH=/usr/local/bin:${py_env_path}/bin:$PATH

USER $nb_user

RUN echo "Building python environment: " \
  # this is a workaround w.r.t. unable to uninstall pip from dist-package
  && pip install -I --no-cache-dir pip --target ${py_env_path}/lib/python3.8/site-packages/ \ 
  && python -m pip install --upgrade --no-cache-dir --force-reinstall pip

COPY requirements-setup.txt requirements.txt constraints.txt /conf/
RUN echo "install packages" \
  && echo $(/env/bin/pip --version) \
  && echo $(python -m site)  $(which pip) $(pip --version) \
  && pip install --no-cache-dir -r /conf/requirements-setup.txt \
     --prefix ${py_env_path} \
  && pip install --no-cache-dir -r /conf/requirements.txt \
     -c /conf/constraints.txt \
     --prefix ${py_env_path} \
  && pip freeze

COPY requirements-jupyter.txt constraints-jupyter.txt /conf/
RUN echo "Building python environment: stage Jupyter" \
  && pip install --no-cache-dir -r /conf/requirements-jupyter.txt -c /conf/constraints-jupyter.txt --prefix ${py_env_path} \
  && pip freeze -r /conf/requirements-jupyter.txt \
  && echo $(which jupyter) $(jupyter --paths)

# NOTE - JupyterLab extensions can now be distributed as prebuilt extensions and available to PyPI
RUN echo "Enable jupyter lab extensions" \
  && jupyter labextension install jupyterlab-theme-toggle \
  && jupyter labextension list \
  && echo "...done"

RUN echo "Enable server extensions" \
  && jupyter server extension enable --py jupyterlab_iframe --sys-prefix \
  && jupyter server extension enable --py jupyter_resource_usage  --sys-prefix \
  && jupyter server extension list \
  && echo "...done"

COPY requirements-odc.txt  constraints-odc.txt /conf/
RUN echo "Adding odc-dependencies" \
  && pip install \
    --no-cache-dir \
    -r /conf/requirements-odc.txt \
    -c /conf/constraints-odc.txt --prefix ${py_env_path}

USER root
COPY assets/sync_repo assets/with_bootstrap assets/jupyterhub-singleuser /usr/local/bin/
COPY assets/overrides.json $py_env_path/share/jupyter/lab/settings/


WORKDIR "/home/$nb_user"
ARG WITH_SUDO="no"
RUN if [ "$WITH_SUDO" = "yes" ]; then \
  echo "${nb_user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
;fi

ARG BUILD_INFO=""
RUN if [ -z "${BUILD_INFO}" ]; then \
  BUILD_INFO="$(date)" \
;fi \
  && echo "${BUILD_INFO}" > /build.info \
  && pip check

USER $nb_user
ENTRYPOINT ["/bin/tini", "-s", "--", "with_bootstrap"]
CMD ["jupyter", "lab", \
"--ip=0.0.0.0", \
"--port=9988", \
"--no-browser"]
