# UNTESTED: written 2026-10-12 while the Docker daemon was not running. Build and report back before relying on it.
#   docker build -t cpu-inference-lab .
#   docker run --rm -v lab-models:/models -v "$PWD/benchmarks/results.csv:/lab/benchmarks/results.csv" \
#              cpu-inference-lab --stages "env llamacpp baselines"
#   # the cgroup / read_ahead stage needs --privileged and a Linux filesystem volume (not a Windows bind mount):
#   docker run --rm --privileged -v lab-models:/models cpu-inference-lab --stages "moe"
# On Docker Desktop for Windows the container shares the WSL2 kernel: disk behaviour is WSL2's, not native Linux.
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake clang lld git ca-certificates curl python3 python3-venv python3-pip util-linux procps \
    && rm -rf /var/lib/apt/lists/*
ENV ENGINES_DIR=/opt/engines MODELS_DIR=/models VENV_DIR=/opt/venv VENV_BITNET=/opt/venv-bitnet
WORKDIR /lab
COPY . /lab
# Engines are built into the image (pinned commits); models are downloaded at run time into the /models volume.
RUN bash benchmarks/setup/20_build_llamacpp.sh \
 && bash benchmarks/setup/21_build_routing_tool.sh \
 && bash benchmarks/setup/40_build_powerinfer.sh
VOLUME /models
ENTRYPOINT ["bash", "benchmarks/setup/run_all.sh"]
CMD ["--stages", "env llamacpp baselines"]
