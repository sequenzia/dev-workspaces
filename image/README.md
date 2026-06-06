# Workspace image (placeholder)

> **Status: deferred.** The Helm chart under [`charts/dev-workspaces`](../charts/dev-workspaces)
> is the MVP. This directory is a placeholder skeleton for the container image
> the chart deploys. Building the real image is explicitly **out of scope** for
> the current spec (see the PRD Non-Goals and Section 8.2).

## How the chart and image relate

The chart references the image purely by coordinates:

```yaml
image:
  repository: registry.example.com/dev-workspaces/workspace
  tag: ""        # defaults to Chart.appVersion when empty
```

Until a real image is published at those coordinates, workspace pods report
`ImagePullBackOff` — this is the documented, expected state for the MVP.

## Contract the real image must honor

The chart is built against these expectations, so the future image must satisfy
them for the deployment to work unchanged:

| Concern | Contract |
|---|---|
| **code-server** | Listens on `:8080` with `--auth none` (oauth-proxy provides auth). Named container port `code-server`. |
| **Jupyter Lab** | Listens on `:8888` started with `--ServerApp.base_url=/jupyter/` to match `workspace.jupyter.basePath`. Named port `jupyter`. |
| **SSH (optional)** | `sshd` on `:2222` reading authorized keys mounted from `ssh.existingSecret`. Named port `ssh`. Gated by `ssh.enabled`. |
| **UID/GID** | Runs as `runAsUser: 1001`, `runAsGroup: 0`; `$HOME` owned by GID `0` and group-writable (OpenShift arbitrary-UID pattern). |
| **Persistent `$HOME`** | The RWO PVC mounts at `persistence.mountPath` (default `/home/dev`); installed packages and config must live under it to survive restarts. |
| **Managed config** | The chart's ConfigMap mounts dotfiles (bashrc/vimrc/code-server settings) at `configMap.mountPath` (default `/etc/dev-workspace`); the image entrypoint should link/source them into `$HOME`. |

## Intended contents (future work)

Python 3.12 + `uv`, Node.js 18 + npm, Git, code-server, Jupyter Lab, OpenSSH
server, and common build tooling (curl, wget, build-essential), plus a process
supervisor to run code-server, Jupyter, and (optionally) sshd together.
