{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "imagePullSecret" }}
{{- if .Values.imageCredentials.create -}}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" (required "A valid .Values.imageCredentials.registry entry required" .Values.imageCredentials.registry) (printf "%s:%s" (required "A valid .Values.imageCredentials.username entry required" .Values.imageCredentials.username) (required "A valid .Values.imageCredentials.password entry required" .Values.imageCredentials.password) | b64enc) | b64enc }}
{{- end }}
{{- end -}}

{{- define "platform" }}
{{- printf "%s" (required "A valid .Values.global.platform entry required" .Values.global.platform ) | replace "\n" "" }}
{{- end }}

{{/*
Define a server serviceAccount name
If Values.serviceAccount.create defined as false
*/}}
{{- define "server.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
  {{- if .Values.serviceAccount.name -}}
  {{- printf "%s" .Values.serviceAccount.name -}}
  {{- else -}}
  {{- printf "%s-sa" .Release.Namespace -}}
  {{- end -}}
{{- end -}}
{{- if not .Values.serviceAccount.create -}}
  {{- if .Values.serviceAccount.name -}}
  {{- printf "%s" .Values.serviceAccount.name -}}
  {{- else -}}
  {{- printf "%s" (required "A valid .Values.serviceAccount.name is required as you're selected not create serviceaccount by default" .Values.serviceAccount.name) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Inject extra environment vars in the format key:value, if populated
*/}}
{{- define "server.extraEnvironmentVars" -}}
{{- if .extraEnvironmentVars -}}
{{- range $key, $value := .extraEnvironmentVars }}
- name: {{ printf "%s" $key | replace "." "_" | upper | quote }}
  value: {{ $value | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Inject extra environment populated by secrets, if populated
*/}}
{{- define "server.extraSecretEnvironmentVars" -}}
{{- if .extraSecretEnvironmentVars -}}
{{- range .extraSecretEnvironmentVars }}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ .secretName }}
      key: {{ .secretKey }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aqua.labels" -}}
helm.sh/chart: '{{ include "aqua.chart" . }}'
{{ include "aqua.template-labels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{/*
Common template labels
*/}}
{{- define "aqua.template-labels" -}}
app.kubernetes.io/name: "{{ template "fullname" . }}"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aqua.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Inject additional certificates as volumes if populated
*/}}
{{- define "server.additionalCertVolumes" -}}
{{- if .web.additionalCerts -}}
{{- range $i, $cert := .web.additionalCerts }}
- name: {{ $cert.secretName | quote }}
  secret:
    defaultMode: 420
    secretName: {{ $cert.secretName | quote }}
    items:
    {{- if $cert.createSecret }}
      - key: cert.pem
    {{- else }}
      - key: {{ $cert.certFile | quote }}
    {{- end }}
        path: {{ $cert.secretName }}.pem
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Inject additional certificates as volumemounts if populated
*/}}
{{- define "server.additionalCertVolumeMounts" -}}
{{- if .web.additionalCerts -}}
{{- range $i, $cert := .web.additionalCerts }}
- name: {{ $cert.secretName | quote }}
  subPath: {{ $cert.secretName }}.pem
  mountPath: /etc/ssl/certs/{{ $cert.secretName }}.pem
{{- end }}
{{- end -}}
{{- end -}}
