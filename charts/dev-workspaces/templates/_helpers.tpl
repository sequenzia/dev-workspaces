{{/* vim: set filetype=mustache: */}}

{{/*
==============================================================================
dev-workspaces helpers
One release == one developer. Resource name prefix is dev-workspace-<user>.
==============================================================================
*/}}

{{/*
dev-workspaces.user
Validated, sanitized developer identifier. REQUIRED.
Lowercased, non-DNS chars collapsed to '-', trimmed, truncated to 49 chars so
the "dev-workspace-" prefix (14 chars) keeps the full name within 63.
*/}}
{{- define "dev-workspaces.user" -}}
{{- $user := required "dev-workspaces: .Values.user is required (e.g. --set user=alice)" .Values.user | toString -}}
{{- $lower := lower $user -}}
{{/* Authoritative: REJECT non-conforming users rather than silently rewriting
     them. Silent sanitization could alias two distinct users (a.b and a-b) to
     the same resource name and collide in the shared namespace (AC 5.1). */}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $lower) -}}
{{- fail (printf "dev-workspaces: .Values.user %q is not a valid DNS-1123 label (lowercase alphanumeric and '-' only); choose a conforming identifier" $user) -}}
{{- end -}}
{{- if gt (len $lower) 40 -}}
{{- fail (printf "dev-workspaces: .Values.user %q exceeds 40 chars; the 'dev-workspace-' prefix must keep resource names within 63" $user) -}}
{{- end -}}
{{- $lower -}}
{{- end -}}

{{/*
dev-workspaces.name
Chart-name segment used in labels (NOT the resource name prefix).
Overridable via .Values.nameOverride.
*/}}
{{- define "dev-workspaces.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
dev-workspaces.fullname
Resource name PREFIX for this release: dev-workspace-<user>.
Honors .Values.fullnameOverride for full control.
Truncated to 63 chars (DNS-1123 label) and de-suffixed.
*/}}
{{- define "dev-workspaces.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "dev-workspace-%s" (include "dev-workspaces.user" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
dev-workspaces.chart
Chart name + version for the helm.sh/chart label (sanitized).
*/}}
{{- define "dev-workspaces.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
dev-workspaces.selectorLabels
STABLE across upgrades and UNIQUE per developer in the shared namespace.
A Deployment/Service .spec.selector is IMMUTABLE, so this set must never change
for the life of a release: user, .Release.Name, and nameOverride are all fixed
once installed (documented in values.yaml). The dev-workspaces.io/user label
guarantees per-developer uniqueness so two developers' Deployments/Services
never select each other's pods. Component/version live in .labels (metadata),
NOT here, so adding a sidecar component later cannot perturb the selector.
*/}}
{{- define "dev-workspaces.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dev-workspaces.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
dev-workspaces.io/user: {{ include "dev-workspaces.user" . }}
{{- end -}}

{{/*
dev-workspaces.labels
Full label set for resource metadata. Includes selectorLabels plus
version / managed-by / part-of and any commonLabels.
*/}}
{{- define "dev-workspaces.labels" -}}
helm.sh/chart: {{ include "dev-workspaces.chart" . }}
{{ include "dev-workspaces.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: dev-workspaces
app.kubernetes.io/component: workspace
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
dev-workspaces.annotations
Common annotations applied to all resources.
*/}}
{{- define "dev-workspaces.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
dev-workspaces.serviceAccountName
The ServiceAccount used by the pod. Defaults to the fullname when created,
or "default" when serviceAccount.create=false and no name supplied.
*/}}
{{- define "dev-workspaces.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "dev-workspaces.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
dev-workspaces.imageTag
Workspace image tag; falls back to .Chart.AppVersion when image.tag is empty.
*/}}
{{- define "dev-workspaces.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{/*
dev-workspaces.image
Fully-qualified workspace image reference (repository:tag).
*/}}
{{- define "dev-workspaces.image" -}}
{{- printf "%s:%s" .Values.image.repository (include "dev-workspaces.imageTag" .) -}}
{{- end -}}

{{/*
dev-workspaces.sccName
Name of the custom SCC to create (scc.name override or <fullname>-scc).
*/}}
{{- define "dev-workspaces.sccName" -}}
{{- default (printf "%s-scc" (include "dev-workspaces.fullname" .) | trunc 63 | trimSuffix "-") .Values.scc.name -}}
{{- end -}}

{{/*
dev-workspaces.routeHost
Route host; fails fast when route.enabled and no host provided.
*/}}
{{- define "dev-workspaces.routeHost" -}}
{{- if and .Values.route.enabled (not .Values.route.host) -}}
{{- fail "dev-workspaces: route.host is required when route.enabled=true" -}}
{{- end -}}
{{- .Values.route.host -}}
{{- end -}}

{{/*
dev-workspaces.oauthRedirectReference
Value for the serviceaccounts.openshift.io/oauth-redirectreference.primary
annotation. The inner apiVersion is the OAuth redirect-reference schema "v1"
(NOT route.openshift.io/v1). reference.name MUST equal the Route name.
*/}}
{{- define "dev-workspaces.oauthRedirectReference" -}}
{{- $ref := dict "kind" "OAuthRedirectReference" "apiVersion" "v1" "reference" (dict "kind" "Route" "name" (include "dev-workspaces.fullname" .)) -}}
{{- $ref | toJson -}}
{{- end -}}

{{/*
dev-workspaces.validateSecrets
Fail-fast guard for required existingSecret references. Call from templates
that consume them (Route, oauth-proxy, ssh) for clear install-time errors.
*/}}
{{- define "dev-workspaces.validateSecrets" -}}
{{/* Security invariant: OAuth is enforced AT THE ROUTE, so route.enabled and
     oauthProxy.enabled MUST match. route-on + oauth-off would expose the
     workspace over HTTPS with NO authentication; oauth-on + route-off leaves
     the SA OAuth client with no registered redirect URI. The supported modes
     are both-on (secure default) and both-off (internal-only, no ingress). */}}
{{- if and .Values.route.enabled (not .Values.oauthProxy.enabled) -}}
{{- fail "dev-workspaces: route.enabled=true with oauthProxy.enabled=false would expose the workspace over HTTPS with NO authentication. Enable oauthProxy, disable the route, or front the Service with your own authenticating proxy." -}}
{{- end -}}
{{- if and .Values.oauthProxy.enabled (not .Values.route.enabled) -}}
{{- fail "dev-workspaces: oauthProxy.enabled=true with route.enabled=false: the oauth-proxy OAuth client has no registered redirect URI without a Route. Enable the route or disable oauthProxy." -}}
{{- end -}}
{{- if and .Values.route.enabled (not .Values.route.tls.externalCertificate.name) -}}
{{- fail "dev-workspaces: route.tls.externalCertificate.name is required when route.enabled=true (pre-create a kubernetes.io/tls Secret)" -}}
{{- end -}}
{{- if and .Values.oauthProxy.enabled (not .Values.oauthProxy.cookieSecret.existingSecret) -}}
{{- fail "dev-workspaces: oauthProxy.cookieSecret.existingSecret is required when oauthProxy.enabled=true (pre-create an Opaque Secret with the cookie secret)" -}}
{{- end -}}
{{- if and .Values.ssh.enabled (not .Values.ssh.existingSecret) -}}
{{- fail "dev-workspaces: ssh.existingSecret is required when ssh.enabled=true (pre-create an Opaque Secret with authorized_keys)" -}}
{{- end -}}
{{- end -}}
