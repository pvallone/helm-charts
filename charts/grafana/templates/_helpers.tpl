{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "grafana.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grafana.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "grafana.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account
*/}}
{{- define "grafana.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "grafana.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "grafana.serviceAccountNameTest" -}}
{{- if .Values.serviceAccount.create }}
{{- default (print (include "grafana.fullname" .) "-test") .Values.serviceAccount.nameTest }}
{{- else }}
{{- default "default" .Values.serviceAccount.nameTest }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "grafana.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grafana.labels" -}}
helm.sh/chart: {{ include "grafana.chart" . }}
{{ include "grafana.selectorLabels" . }}
{{- if or .Chart.AppVersion .Values.image.tag }}
app.kubernetes.io/version: {{ mustRegexReplaceAllLiteral "@sha.*" .Values.image.tag "" | default .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "grafana.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grafana.imageRenderer.labels" -}}
helm.sh/chart: {{ include "grafana.chart" . }}
{{ include "grafana.imageRenderer.selectorLabels" . }}
{{- if or .Chart.AppVersion .Values.image.tag }}
app.kubernetes.io/version: {{ mustRegexReplaceAllLiteral "@sha.*" .Values.image.tag "" | default .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels ImageRenderer
*/}}
{{- define "grafana.imageRenderer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana.name" . }}-image-renderer
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "grafana.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "grafana.namespace" .) (include "grafana.fullname" .) ) }}
{{- if $secret }}
{{- index $secret "data" "admin-password" }}
{{- else }}
{{- (randAlphaNum 40) | b64enc | quote }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "grafana.rbac.apiVersion" -}}
{{- if $.Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" }}
{{- else }}
{{- print "rbac.authorization.k8s.io/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "grafana.ingress.apiVersion" -}}
{{- if and ($.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) }}
{{- print "networking.k8s.io/v1" }}
{{- else if $.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for Horizontal Pod Autoscaler.
*/}}
{{- define "grafana.hpa.apiVersion" -}}
{{- if $.Capabilities.APIVersions.Has "autoscaling/v2/HorizontalPodAutoscaler" }}
{{- print "autoscaling/v2" }}
{{- else if $.Capabilities.APIVersions.Has "autoscaling/v2beta2/HorizontalPodAutoscaler" }}
{{- print "autoscaling/v2beta2" }}
{{- else }}
{{- print "autoscaling/v2beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for podDisruptionBudget.
*/}}
{{- define "grafana.podDisruptionBudget.apiVersion" -}}
{{- if $.Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" }}
{{- print "policy/v1" }}
{{- else }}
{{- print "policy/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return if ingress is stable.
*/}}
{{- define "grafana.ingress.isStable" -}}
{{- eq (include "grafana.ingress.apiVersion" .) "networking.k8s.io/v1" }}
{{- end }}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "grafana.ingress.supportsIngressClassName" -}}
{{- or (eq (include "grafana.ingress.isStable" .) "true") (and (eq (include "grafana.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "grafana.ingress.supportsPathType" -}}
{{- or (eq (include "grafana.ingress.isStable" .) "true") (and (eq (include "grafana.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Formats imagePullSecrets.

Parameters:
   .root
   .imagePullSecrets (can be an array or map)
*/}}
{{- define "grafana.imagePullSecrets" -}}
{{- $root := .root }}
{{- range (concat .root.Values.global.imagePullSecrets .imagePullSecrets) }}
{{- if eq (typeOf .) "map[string]interface {}" }}
- {{ toYaml (dict "name" (tpl .name $root)) | trim }}
{{- else }}
- name: {{ tpl . $root }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the fully formed container image name, taking the global image registry into account if it's been set.

Parameters:
   .root
   .image with expected values:
      registry
      repository
      tag (optional)
      sha (optional)
   .defaultTag
*/}}
{{- define "grafana.image" -}}
{{- $registryName := "" -}}
{{- if .root.Values.global.imageRegistry }}
{{- $registryName = .root.Values.global.imageRegistry | toString -}}
{{- else if .image.registry }}
{{- $registryName = .image.registry | toString -}}
{{- end }}
{{- $repositoryName := .image.repository | toString -}}
{{- $tag := .image.tag | default .defaultTag | toString -}}
{{- if .image.sha }}
{{- $tag = printf "%s@sha256:%s" $tag .image.sha -}}
{{- end }}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return the fully formed container testFramework image name, taking the global image registry into account if it's been set.
Note: The testFramework's image config is defined inconsistently, in that it doesn't have an "image" dictionary. Instead,
all of the image configuration is defined under the "testFramework" node, and "testFramework.image" only refers to the image repository.

Parameters:
   .root
   .testFramework with expected values:
      registry
      image
      tag (optional)
*/}}
{{- define "grafana.testFramework.image" -}}
{{- $registryName := "" -}}
{{- if .root.Values.global.imageRegistry }}
{{- $registryName = .root.Values.global.imageRegistry | toString -}}
{{- else if .testFramework.registry }}
{{- $registryName = .testFramework.registry | toString -}}
{{- end }}
{{- $repositoryName := .testFramework.image -}}
{{- $tag := .testFramework.tag -}}
{{- if .sha }}
{{- $tag = printf "%s@sha256:%s" $tag .sha -}}
{{- end }}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return the fully formed extra container image name, taking the global image registry into account if it's been set. Input is (dict "root" . "registry" {registry} "repository" {repository} "tag" {tag})
The registry, repository, and tag are defined in a flat structure so that this function can be called directly from the values file.
For example: image: {{ include "grafana.extra.containers.image" (dict "root" . "registry" "sample-registry.io" "repository" "grafana-auth-proxy" "tag" "1.1") }}

Parameters:
   .root
   .registry
   .repository
   .tag
*/}}
{{- define "grafana.extra.containers.image" -}}
{{- $registryName := .root.Values.global.imageRegistry | default .registry | toString -}}
{{- $repositoryName := .repository -}}
{{- $tag := .tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag | quote -}}
{{- end -}}