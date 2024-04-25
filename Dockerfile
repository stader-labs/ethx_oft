FROM ghcr.io/collectivexyz/foundry:latest

RUN python3 -m pip install slither-analyzer --break-system-packages

ARG PROJECT=layer_zero
WORKDIR /workspaces/${PROJECT}
ENV USER=foundry
USER foundry
ENV PATH=${PATH}:~/.cargo/bin:/usr/local/go/bin

RUN chown -R foundry:foundry .

COPY --chown=foundry:foundry package.json .
COPY --chown=foundry:foundry package-lock.json .
COPY --chown=foundry:foundry tsconfig.json .

RUN npm ci --frozen-lockfile

COPY --chown=foundry:foundry . .

RUN yamlfmt -lint .github/workflows/*.yml

RUN forge install
RUN forge fmt --check
#RUN python3 -m slither . --exclude-dependencies --exclude-info --exclude-low --exclude-medium
RUN npm run lint:sol
RUN forge test -v
