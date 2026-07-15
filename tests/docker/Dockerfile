FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& yes | unminimize \
	&& apt-get install --yes --no-install-recommends \
		bash \
		ca-certificates \
		coreutils \
		diffutils \
		expect \
		findutils \
		git \
		grep \
		man-db \
		procps \
		sed \
		tar \
		tmux \
		vim \
	&& rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 tester \
	&& useradd --uid 10001 --gid 10001 --create-home tester

COPY --chown=tester:tester . /opt/tmux-resurrect-source

USER tester:tester
WORKDIR /opt/tmux-resurrect-source

ENV HOME=/home/tester
ENV SHELL=/bin/bash
ENV TERM=xterm-256color

ENTRYPOINT ["/opt/tmux-resurrect-source/tests/docker/entrypoint"]
