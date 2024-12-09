FROM docker.io/debian:bookworm

ARG RUBY_VERSION=2.6.10
ARG NODEJS_VERSION=20.18.1

SHELL [ "/bin/bash", "-lc" ]

# install version managers
RUN apt update \
  && apt install -y curl git build-essential zlib1g-dev \
  && git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 \
  && echo '. "$HOME/.asdf/asdf.sh"' > ~/.bashrc

RUN asdf plugin add ruby \
  && asdf install ruby ${RUBY_VERSION} \
  && asdf global ruby ${RUBY_VERSION}

RUN asdf plugin add nodejs \
  && asdf install nodejs ${NODEJS_VERSION} \
  && asdf global nodejs ${NODEJS_VERSION}

WORKDIR /src
