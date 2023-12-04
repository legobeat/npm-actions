FROM node:18-alpine

RUN apk add --no-cache bash coreutils curl envsubst findutils git grep jq openssl wget && \
    npm install -g verdaccio && \
    npm install -g verdaccio-auth-memory && \
    npm install -g verdaccio-memory && \
    npm install -g npm-auth-to-token@1.0.0

RUN apk add --no-cache ncurses python3 make gcc g++ libgcc linux-headers util-linux binutils

COPY verdaccio-config.yaml.tmpl /

COPY entrypoint.sh /

USER node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
ARG NODE_VERSIONS="16.20 18.19 20.10"
RUN bash -c ". ~/.nvm/nvm.sh && for nv in ${NODE_VERSIONS}; do  nvm install \$nv ; done"

ENTRYPOINT ["/entrypoint.sh"]
