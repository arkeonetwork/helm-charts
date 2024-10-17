{{/* vim: set filetype=mustache: */}}
{{/*

Expand the name of the chart.
*/}}
{{- define "osmosis-daemon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "osmosis-daemon.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "osmosis-daemon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "osmosis-daemon.labels" -}}
helm.sh/chart: {{ include "osmosis-daemon.chart" . }}
{{ include "osmosis-daemon.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "osmosis-daemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "osmosis-daemon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "osmosis-daemon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "osmosis-daemon.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Net
*/}}
{{- define "osmosis-daemon.net" -}}
{{- default .Values.net .Values.global.net -}}
{{- end -}}

{{/*
Snapshot
*/}}
{{- define "osmosis-daemon.snapshot" -}}
{{- if eq (include "osmosis-daemon.net" .) "testnet" -}}
    {{ .Values.snapshot.testnet }}
{{- else if eq (include "osmosis-daemon.net" .) "stagenet" -}}
    {{ .Values.snapshot.stagenet }}
{{- else if eq (include "osmosis-daemon.net" .) "mainnet" -}}
    {{ .Values.snapshot.mainnet }}
{{- end -}}
{{- end -}}


{{/*
RPC Port
*/}}
{{- define "osmosis-daemon.rpc" -}}
{{- if eq (include "osmosis-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.rpc }}
{{- else if eq (include "osmosis-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.rpc }}
{{- else -}}
    {{ .Values.service.port.testnet.rpc }}
{{- end -}}
{{- end -}}

{{/*
P2P Port
*/}}
{{- define "osmosis-daemon.p2p" -}}
{{- if eq (include "osmosis-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.p2p }}
{{- else if eq (include "osmosis-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.p2p }}
{{- else -}}
    {{ .Values.service.port.testnet.p2p }}
{{- end -}}
{{- end -}}

{{/*
GRPC Port
*/}}
{{- define "osmosis-daemon.grpc" -}}
{{- if eq (include "osmosis-daemon.net" .) "mainnet" -}}
    {{ .Values.service.port.mainnet.grpc }}
{{- else if eq (include "osmosis-daemon.net" .) "stagenet" -}}
    {{ .Values.service.port.stagenet.grpc }}
{{- else -}}
    {{ .Values.service.port.testnet.grpc }}
{{- end -}}
{{- end -}}
