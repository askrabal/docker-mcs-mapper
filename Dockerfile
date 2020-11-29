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
  python3 \
  py3-numpy \
  py3-pillow \
	vim

COPY --from=install-stage /opt/overviewer/build/lib.linux-x86_64-3.8/overviewer_core /usr/lib/python3.8/site-packages/overviewer_core
COPY --from=install-stage /opt/overviewer/build/scripts-3.8/overviewer.py /usr/local/bin/
RUN curl -L https://overviewer.org/textures/1.16 --create-dirs -o ~/.minecraft/versions/1.16/1.16.jar
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

ARG MINER_UID=1002

RUN adduser -Du ${MINER_UID} miner
RUN addgroup miner www-data
RUN addgroup nginx miner
RUN mv ~/.minecraft ~miner/
RUN mkdir -p /home/miner/logs
RUN chown -R miner:miner /home/miner

RUN sed -i -e 15,23d /usr/share/nginx/html/index.html
COPY miner_crontab /etc/crontabs/miner

CMD ["/bin/sh","-c","crond && nginx -g 'daemon off;'"]

