ARG V_BASE=-3.0.4
ARG py_env_path=/env

FROM opendatacube/geobase:wheels${V_BASE} as env_builder
ARG py_env_path

RUN mkdir -p /conf

# Some libs assume presence of Cython and numpy in the environment, so build
# minimal env with those first, then extend further
COPY requirements0.txt /conf/
RUN echo "Building python environment: stage 1" \
  && env-build-tool new /conf/requirements0.txt ${py_env_path}

COPY requirements.txt /conf/
RUN echo "Building python environment: stage 2" \
  && env-build-tool extend /conf/requirements.txt ${py_env_path}

ENV PATH=${py_env_path}/bin:$PATH

# Install extra libs for labextensions without a full rebuild
RUN pip install --no-cache-dir jupyterlab_iframe==0.2.1

RUN echo "Adding jupyter lab extensions" \
  && jupyter labextension install --no-build @jupyter-widgets/jupyterlab-manager@v1.0.2 \
  && jupyter labextension install --no-build @jupyterlab/geojson-extension@v1.0.0 \
  && jupyter labextension install --no-build @jupyterlab/hub-extension@v1.1.0 \
  && jupyter labextension install --no-build jupyter-leaflet@v0.11.1 \
  && jupyter labextension install --no-build dask-labextension@v1.0.1 \
  && jupyter labextension install --no-build jupyter-matplotlib@v0.4.2 \
  && jupyter labextension install --no-build @bokeh/jupyter_bokeh@1.1.1 \
  && jupyter labextension install --no-build nbdime-jupyterlab@v1.0.0 \
  && jupyter labextension install --no-build @ryantam626/jupyterlab_code_formatter@v0.5.0 \
  && jupyter labextension install --no-build @jupyter-widgets/jupyterlab-sidecar@v0.4.0 \
  && jupyter labextension install --no-build ipyevents@v1.7.0 \
  && jupyter labextension install --no-build ipycanvas@v0.3.4 \
  && jupyter labextension install --no-build jupyterlab_iframe@0.2.1 \
  && jupyter lab build \
  && jupyter serverextension enable --py jupyterlab_code_formatter \
  && jupyter serverextension enable --py --system jupyterlab_iframe \
  && jupyter labextension list \
  && echo "...done"

COPY requirements-odc.txt /conf/
RUN echo "Adding odc-dependencies" \
  && env-build-tool extend /conf/requirements-odc.txt ${py_env_path}

FROM opendatacube/geobase:runner${V_BASE}

RUN apt-get update -y \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
  # developer convenience
  postgresql-client-10 \
  postgresql-10 \
  less \
  wget \
  curl \
  vim \
  tmux \
  htop \
  fish \
  tig \
  git \
  xz-utils \
  openssh-client \
  graphviz \
  sudo \
  iproute2 \
  iputils-ping \
  net-tools \
  simpleproxy \
  rsync \
# rgsislib dependencies
  libcgal13 \
  libmuparser2v5 \
  libgsl23 \
  libboost-system1.65.1 \
  libboost-filesystem1.65.1 \
  libboost-date-time1.65.1 \
# for cython to work need compilers
  build-essential \
# for pyRAT install or something
  libfftw3-dev \
  liblapack-dev \
&& rm -rf /var/lib/apt/lists/*

#Install ffmpeg static binary
RUN curl -s -L https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.1.4-amd64-static.tar.xz > ffmpeg.tar.xz \
  && echo "546b9eb4517f4f5278356dfa125e08f95829b00282331d23f0c60241955b99c2" ffmpeg.tar.xz | sha256sum -c - \
  && tar xvJ --strip-components=1 -C /tmp < ffmpeg.tar.xz \
  && mv /tmp/ffmpeg /usr/local/bin/ffmpeg \
  && rm -rf /tmp/* ffmpeg.tar.xz

# Install Tini
COPY --from=env_builder /bin/tini /bin/tini

ARG nb_user=jovyan
ARG nb_uid=1000
ARG nb_gid=100

RUN useradd -m -s /bin/bash -N -g $nb_gid -u $nb_uid $nb_user

# Copy python env
ARG py_env_path
COPY --chown=1000:100 --from=env_builder $py_env_path $py_env_path

ENV LC_ALL=C.UTF-8
ENV SHELL=bash
ENV PATH=${py_env_path}/bin:$PATH

# TODO: remove this once we have working NFS with tidal data in it
RUN mkdir -p /var/share/TPX08_atlas_compact/ \
    && (cd /var/share/TPX08_atlas_compact/ && otps_fetch_data .)

# Patch env when needed here
RUN pip install --no-cache-dir nbresuse \
  && jupyter serverextension enable --py --system nbresuse \
  && pip install --no-cache-dir \
  --extra-index-url="https://packages.dea.ga.gov.au" \
  --no-deps --upgrade odc-algo odc-ui 'datacube[performance]'

COPY --chown=1000:100  jupyter_notebook_config.py /etc/jupyter/

COPY sync_repo with_bootstrap /usr/local/bin/
COPY with_bootstrap /usr/local/bin/
ENTRYPOINT ["/bin/tini", "-s", "--", "with_bootstrap"]

VOLUME ["/home/$nb_user", "/run/postgresql"]

WORKDIR "/home/$nb_user"

EXPOSE 9988

CMD ["jupyter", "lab", \
"--ip=0.0.0.0", \
"--port=9988", \
"--no-browser"]

ARG WITH_SUDO=0
RUN if [ "$WITH_SUDO" = "yes" ]; then \
  adduser ${nb_user} sudo \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
;fi

USER $nb_user
