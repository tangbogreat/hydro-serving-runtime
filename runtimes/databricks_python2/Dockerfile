FROM frolvlad/alpine-python2 AS py2sklearn
ARG SIDECAR_VERSION=0.0.1

RUN apk update && \
    apk add --no-cache curl libstdc++ lapack-dev && \
    apk add --no-cache gcc g++ linux-headers gfortran musl-dev python-dev && \
    ln -s locale.h /usr/include/xlocale.h

RUN pip install numpy scipy==0.18 scikit_learn==0.18 pandas==0.20.1


FROM py2sklearn

ARG SIDECAR_VERSION

ENV SIDECAR_HTTP_PORT=8080
ENV APP_HTTP_PORT=9090
ENV APP_START_SCRIPT=/app/start.sh

ADD . /app/
ADD http://repo.hydrosphere.io/hydrosphere/static/hydro-serving-sidecar-install-$SIDECAR_VERSION.sh /app/sidecar.sh

WORKDIR /app

RUN apk update && \
    chmod +x /app/sidecar.sh && sync && \
    chmod +x /app/start.sh && sync && \
    ./sidecar.sh --target /hydro-serving/sidecar -- alpine && \
    rm -rf sidecar.sh && rm -rf /var/cache/apk/*

RUN pip install -r requirements.txt

WORKDIR /app/src

HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost:$APP_HTTP_PORT/health || exit 1
CMD ["/hydro-serving/sidecar/start.sh"]
