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

COPY requirements-jupyter.txt /conf/
RUN echo "Building python environment: stage Jupyter" \
  && env-build-tool extend /conf/requirements-jupyter.txt ${py_env_path}

COPY jupyter-extensions.txt /conf/
RUN echo "Adding jupyter lab extensions" \
  xargs -n1 jupyter labextension install --no-build < /conf/jupyter-extensions.txt \
  && jupyter lab build \
  && jupyter lab clean \
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

RUN echo "Enable server extensions" \
  && jupyter serverextension enable --py --system nbresuse \
  && jupyter serverextension enable --py --system jupyterlab_code_formatter \
  && jupyter serverextension enable --py --system jupyterlab_iframe \
  && echo done

# Patch env when needed here
# RUN echo "Patching python env" \
#   && pip install --no-cache-dir \
#   --extra-index-url="https://packages.dea.ga.gov.au" \
#   --no-deps --upgrade odc-algo odc-ui 'datacube[performance,s3]'

COPY sync_repo with_bootstrap /usr/local/bin/
ENTRYPOINT ["/bin/tini", "-s", "--", "with_bootstrap"]

VOLUME ["/home/$nb_user", "/run/postgresql"]

WORKDIR "/home/$nb_user"

EXPOSE 9988

CMD ["jupyter", "lab", \
"--ip=0.0.0.0", \
"--port=9988", \
"--no-browser"]

ARG WITH_SUDO="no"
RUN if [ "$WITH_SUDO" = "yes" ]; then \
  echo "${nb_user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
;fi

ARG BUILD_INFO=""
RUN if [ -z "${BUILD_INFO}" ]; then \
  BUILD_INFO="$(date)" \
;fi \
  && echo "${BUILD_INFO}" > /build.info

USER $nb_user
