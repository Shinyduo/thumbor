FROM python:3.11

LABEL maintainer="MinimalCompact"

# Step 1: Update the package lists
RUN apt-get update

# Step 2: Install the required packages
RUN apt-get install -y -q \
    git \
    curl \
    libjpeg-turbo-progs \
    graphicsmagick \
    libgraphicsmagick++3 \
    libgraphicsmagick++1-dev \
    libgraphicsmagick-q16-3 \
    libmagickwand-dev \
    zlib1g-dev \
    libboost-python-dev \
    libmemcached-dev \
    gifsicle \
    ffmpeg

# Step 3: Upgrade remaining packages and clean up
RUN apt-get -y upgrade && \
    apt-get -y autoremove && \
    apt-get clean

ENV HOME /app
ENV SHELL bash
ENV WORKON_HOME /app
WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY conf/thumbor.conf.tpl /app/thumbor.conf.tpl

ARG SIMD_LEVEL
# This block for Pillow-SIMD optimization is kept as it's a performance feature
RUN PILLOW_VERSION=$(python -c 'import PIL; print(PIL.__version__)') ; \
    if [ "$SIMD_LEVEL" ]; then \
      pip uninstall -y pillow || true && \
      CC="cc -m$SIMD_LEVEL" pip install --no-cache-dir -U --force-reinstall --no-binary=:all: "pillow-SIMD<=${PILLOW_VERSION}.post99" \
      --global-option="build_ext" --global-option="--enable-lcms" \
      --global-option="build_ext" --global-option="--enable-zlib" \
      --global-option="build_ext" --global-option="--enable-jpeg" \
      --global-option="build_ext" --global-option="--enable-tiff" ; \
    fi ;

# Copy the entrypoint script and make it executable
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

# The CMD is simplified. The entrypoint script will handle passing config.
CMD ["thumbor"]
