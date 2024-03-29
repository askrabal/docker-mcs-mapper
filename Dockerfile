FROM alpine AS install-stage

RUN apk add --no-cache \
  build-base \
  curl \
  git \
  python3 \
  python3-dev \
  py3-numpy \
  py3-numpy-dev \
  py3-pillow


RUN git clone https://github.com/overviewer/Minecraft-Overviewer.git /opt/overviewer

ENV PIL_INCLUDE_DIR=/opt/overviewer/Pillow
RUN export PIL_VER="$(python3 -c 'import PIL;print(PIL.__version__)')" \
  ; mkdir /opt/overviewer/Pillow \
  && curl -L https://github.com/python-pillow/Pillow/archive/${PIL_VER}.tar.gz \
  | tar -xz -C $PIL_INCLUDE_DIR --strip-components=3 \
  Pillow-${PIL_VER}/src/libImaging/Imaging.h \
  Pillow-${PIL_VER}/src/libImaging/ImagingUtils.h \
  Pillow-${PIL_VER}/src/libImaging/ImPlatform.h


RUN /opt/overviewer/setup.py build

FROM nginx:stable-alpine as final-stage

RUN apk add --no-cache \
  bash \
  busybox-suid \
  py3-numpy \
  py3-pillow \
  python3 \
  util-linux \
  vim

COPY --from=install-stage /opt/overviewer/build/lib.linux-x86_64-3.*/overviewer_core /usr/local/lib/python3/site-packages/overviewer_core
COPY --from=install-stage /opt/overviewer/build/scripts-3.*/overviewer.py /usr/local/bin/
ARG MC_TEX_VER=1.19
RUN curl -L https://overviewer.org/textures/${MC_TEX_VER} --create-dirs -o ~/.minecraft/versions/${MC_TEX_VER}/${MC_TEX_VER}.jar
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

ARG MINER_UID=25565

RUN adduser -Du ${MINER_UID} miner
RUN addgroup miner www-data
RUN addgroup nginx miner
RUN mv ~/.minecraft /home/miner/
COPY renderAllMaps.py /home/miner/
RUN mkdir -p /home/miner/logs
RUN chown -R miner:miner /home/miner
RUN echo "export EDITOR=vim" >> /home/miner/.bashrc
RUN echo "export PYTHONPATH=/usr/local/lib/python3/site-packages" >> /home/miner/.bashrc

RUN sed -i -e 15,23d /usr/share/nginx/html/index.html
COPY miner_crontab /etc/crontabs/miner

CMD ["/bin/sh","-c","crond && nginx -g 'daemon off;'"]

