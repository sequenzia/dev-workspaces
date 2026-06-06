# Dev Workspaces

A Helm chart (and a placeholder custom image) to deploy isolated, browser-based
**per-developer development environments** to an OpenShift cluster — code-server
(VS Code in the browser) and Jupyter Lab today, backed by persistent storage,
fronted by cluster single sign-on, with an explicit suspend/resume lifecycle to
keep idle cost at zero.

One Helm release maps to one developer, so 10–50 workspaces run as independent,
name-prefixed releases (`dev-workspace-<user>`) in a shared namespace.

## Layout

| Path | What |
|---|---|
| [`charts/dev-workspaces`](charts/dev-workspaces) | The Helm chart (the MVP). See its [README](charts/dev-workspaces/README.md). |
| [`examples`](examples) | Ready-to-copy per-developer values files (developer, suspended, ssh, scc, idle reaper). |
| [`image`](image) | **Placeholder** for the workspace container image (deferred; see its [README](image/README.md)). |
| [`specs`](specs) | The product spec / PRD this implementation follows. |

## Quick start

```bash
# 1. Pre-create the Secrets (Ops, once per developer)
NS=dev-workspaces
oc create secret tls alice-workspace-tls -n $NS --cert=alice.crt --key=alice.key
oc create secret generic alice-oauth-cookie -n $NS \
    --from-literal=cookie-secret=$(openssl rand -base64 32)

# 2. Install one developer's workspace
helm install alice charts/dev-workspaces -n $NS -f examples/values-developer.yaml
```

Full install/operate guide, prerequisites, suspend/resume, security (fixed-UID +
SCC), and troubleshooting are in the
[**chart README**](charts/dev-workspaces/README.md).

## Status

- **Helm chart** — implemented (Deployment + oauth-proxy sidecar, Service, edge-TLS
  Route with cert-from-Secret, retained RWO PVC, ConfigMap, ServiceAccount OAuth
  client, suspend/resume, optional gated idle CronJob, optional gated SCC, optional
  gated SSH, `values.schema.json` fail-fast validation). Validated with `helm lint`,
  `helm template`, and `kubeconform`.
- **Container image** — placeholder only; the real image (code-server, Jupyter,
  Python/UV, Node, OpenSSH, dotfiles) is future work.

## Requirements

OpenShift 4.x (4.19+ for native `Route` `externalCertificate`), an RWO
StorageClass, and cluster-admin to grant the SCC for the fixed workspace UID. See
the chart README for the full prerequisite list.
