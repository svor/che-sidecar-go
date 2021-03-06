# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM node:13.13.0-alpine

ENV HOME=/home/theia

RUN mkdir /projects ${HOME} && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/projects"; do \
      echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
      chmod -R g+rwX ${f}; \
    done

RUN set -e \
    && \
    apk add --update --no-cache git \
    && \
    apk add --update --no-cache  --virtual .build-deps \
        bash \
        gcc g++ \
        musl-dev \
        openssl \
        go \
    && \
    export \
        GOROOT_BOOTSTRAP="$(go env GOROOT)" \
        GOOS="$(go env GOOS)" \
        GOARCH="$(go env GOARCH)" \
        GOHOSTOS="$(go env GOHOSTOS)" \
        GOHOSTARCH="$(go env GOHOSTARCH)" \
    && \
    apkArch="$(apk --print-arch)" \
    && \
    case "$apkArch" in \
        armhf) export GOARM='6' ;; \
        x86) export GO386='387' ;; \
    esac

RUN wget -qO- https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz | tar xvz -C /usr/local && \
    cd /usr/local/go/src && ./make.bash && \
    rm -rf /usr/local/go/pkg/bootstrap /usr/local/go/pkg/obj

RUN export GOPATH="/go" && \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg" && \
    export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"

RUN go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols &&  \
    go get -u -v github.com/stamblerre/gocode &&  \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v golang.org/x/tools/cmd/godoc && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/lint/golint && \
    go get -u -v github.com/fatih/gomodifytags &&  \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v sourcegraph.com/sqs/goreturns && \
    go get -u -v golang.org/x/tools/cmd/goimports && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct && \
    go get -u -v github.com/go-delve/delve/cmd/dlv && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v golang.org/x/tools/cmd/gotype && \
    GO111MODULE=on go get -v golang.org/x/tools/gopls@latest && \
    go build -o /go/bin/gocode-gomod github.com/stamblerre/gocode && \
    chmod -R 777 /go && \
    apk del .build-deps && \
    mkdir /.cache && chmod -R 777 /.cache && \
    cd /usr/local/go && wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.22.2

ENV GOPATH /go
ENV GOCACHE /.cache
ENV GOROOT /usr/local/go
ENV GO111MODULE on
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH

ADD etc/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ${PLUGIN_REMOTE_ENDPOINT_EXECUTABLE}