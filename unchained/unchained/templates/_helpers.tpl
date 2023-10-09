{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "unchained.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "unchained.fullname" -}}
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
{{- define "unchained.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
StatefulSet labels
*/}}
{{- define "unchained.statefulsetLabels" }}
appName: {{ .Release.Name }}
assetName: {{ .Values.name }}
tier: statefulset
{{- end }}

{{/*
API labels
*/}}
{{- define "unchained.apiLabels" }}
appName: {{ .Release.Name }}
assetName: {{ .Values.name }}
tier: api
coinstack: {{ .Values.name }}
{{- end }}

{{/*
Default Template for API Service. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.apiservice" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}-api-svc
  namespace: {{ .Release.Name }}
  labels:
    {{- include "unchained.apiLabels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "unchained.apiLabels" . | nindent 4 }}
{{- end }}

{{/*
Default Template for API HorizontalPodAutoscaler. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.apihpa" }}
{{- if eq .Values.api.autoscaling true }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Chart.Name }}-hpa
  namespace: {{ .Release.Name }}
spec:
  minReplicas: 2
  maxReplicas: 6
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Chart.Name }}-{{ .Values.api.tier }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
{{- end }}
{{- end }}

{{/*
Default Template for StatefulSet Service. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.statefulsetsvc" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}-svc
  namespace: {{ .Release.Name }}
  labels:
    {{- include "unchained.statefulsetLabels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    {{- range .Values.statefulset.containers }}
    {{- range $portIndex, $port := .ports }}
    - port: {{ $port.containerPort }}
      targetPort: {{ $port.name }}
      protocol: TCP
      name: {{ $port.name }}
    {{- end }}
    {{- end }}
  selector:
    {{- include "unchained.statefulsetLabels" . | nindent 4 }}
{{- end }}

{{/*
Default Template for ConfigMaps. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.configmap" }}
---
apiVersion: v1
kind: ConfigMap
metadata: 
  name: {{ .Chart.Name }}-scripts
  namespace: {{ .Release.Name }}
data: {{ (.Files.Glob "files/*").AsConfig | nindent 2 }}
{{- end }}

{{/*
Default Template for VolumeReaperRole. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.volumereaperrole" }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: {{ .Release.Name }}
  name: {{ .Chart.Name }}-volume-reaper-role
rules:
- apiGroups: ["apps"] 
  resources: ["*"]
  verbs: ["get", "watch", "list", "update"]
- apiGroups: ["snapshot.storage.k8s.io"] 
  resources: ["volumesnapshots"]
  verbs: ["get", "watch", "list", "update", "create", "delete"]
{{- end }}

{{/*
Default Template for VolumeReaperJob. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.volumereaperjob" }}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ .Chart.Name }}-volume-reaper-job
  namespace: {{ .Release.Name }}
spec:
  schedule: {{ .Values.global.backupSchedule }}
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  concurrencyPolicy: 'Forbid'
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: {{ .Chart.Name }}-sa
          containers:
          - name: {{ .Chart.Name }}-volume-reaper
            image: 'shapeshiftdao/unchained-volume-reaper:latest'
            args:
            - -n
            - "{{ .Release.Name }}"
            - -s
            - "{{ .Chart.Name }}-svc"
            - -a
            - "{{ .Chart.Name }}"
            - -c
            - "{{ .Values.global.backupCount }}"
          restartPolicy: Never
{{- end }}

{{/*
Default Template for VolumeReaperRoleBinding. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.volumereaperrolebinding" }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ .Chart.Name }}-volume-reaper-role-binding
  namespace: {{ .Release.Name }}
subjects:
- kind: "ServiceAccount"
  name: {{ .Chart.Name }}-sa
  apiGroup: ''
roleRef:
  kind: Role
  name: {{ .Chart.Name }}-volume-reaper-role
  apiGroup: ''
{{- end }}

{{/*
Default Template for ServiceAccount. All Sub-Charts under this Chart can include the below template.
*/}}
{{- define "unchained.serviceaccount" }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Chart.Name }}-sa
  namespace: {{ .Release.Name }}
{{- end }}