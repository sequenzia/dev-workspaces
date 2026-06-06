# =============================================================================
# dev-workspaces workspace image -- PLACEHOLDER (not the MVP focus)
# =============================================================================
# The Helm chart is the MVP. This Dockerfile is a minimal, valid skeleton that
# establishes the OpenShift arbitrary-UID contract the chart relies on; the full
# developer toolchain is intentionally deferred (see image/README.md and the PRD
# Non-Goals). Until a real image is published, the chart's image.repository/tag
# point at a placeholder and pods report ImagePullBackOff -- expected per spec.
#
# Build (when ready):  podman build -t <registry>/dev-workspaces/workspace:0.1.0 image/
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:latest

# Fixed UID/GID contract the chart's securityContext expects:
#   runAsUser: 1001, runAsGroup: 0, fsGroup: 1001
# OpenShift may also run arbitrary UIDs, so $HOME is owned by GID 0 and made
# group-writable -- the standard OpenShift "arbitrary user ID" support pattern.
ARG USER_UID=1001
ARG USER_HOME=/home/dev
ENV HOME=${USER_HOME}

RUN useradd -u ${USER_UID} -g 0 -d ${USER_HOME} -m -s /bin/bash dev \
 && chgrp -R 0 ${USER_HOME} \
 && chmod -R g=u ${USER_HOME}

# The developer toolchain is added in later layers (deferred to image work):
#   Python 3.12 + uv, Node.js 18 + npm, Git, code-server, Jupyter Lab,
#   OpenSSH server, and common build tooling (curl, wget, build-essential).
# code-server must listen on 8080 with --auth none (the chart fronts it with
# oauth-proxy). Jupyter Lab must start with --ServerApp.base_url=/jupyter/ to
# match workspace.jupyter.basePath. Managed dotfiles are mounted by the chart's
# ConfigMap at /etc/dev-workspace.

EXPOSE 8080 8888 2222
USER ${USER_UID}
WORKDIR ${USER_HOME}

# No ENTRYPOINT yet: the process supervisor (code-server + Jupyter + optional
# sshd) ships with the real image. This placeholder is not meant to run.
