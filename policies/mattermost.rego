package main

# ── Exceptions ──────────────────────────────────────────────────────────────
# These are upstream Helm chart violations we cannot fix directly.
# Each exception is documented in EXCEPTIONS.md with accepted risk and mitigation.

# Deployments from upstream charts that violate our security baseline
# but cannot be remediated without forking the chart.
upstream_exceptions := {
  "mattermost-operator",  # See EXCEPTIONS.md - operator chart constraint
  "minio"                 # See EXCEPTIONS.md - upstream chart runs as root
}

# Deny containers running as root
deny[msg] {
  input.kind == "Deployment"
  not upstream_exceptions[input.metadata.name]
  container := input.spec.template.spec.containers[_]
  not container.securityContext.runAsNonRoot
  msg := sprintf("Container '%s' in Deployment '%s' must set runAsNonRoot: true", [container.name, input.metadata.name])
}

# Deny containers without CPU limits
deny[msg] {
  input.kind == "Deployment"
  not upstream_exceptions[input.metadata.name]
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container '%s' in Deployment '%s' is missing CPU limit", [container.name, input.metadata.name])
}

# Deny containers without memory limits
deny[msg] {
  input.kind == "Deployment"
  not upstream_exceptions[input.metadata.name]
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("Container '%s' in Deployment '%s' is missing memory limit", [container.name, input.metadata.name])
}

# Deny privileged containers
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Container '%s' in Deployment '%s' must not be privileged", [container.name, input.metadata.name])
}

# Deny NodePort services
deny[msg] {
  input.kind == "Service"
  input.spec.type == "NodePort"
  msg := sprintf("Service '%s' must not use NodePort - use ClusterIP and route through ingress", [input.metadata.name])
}

# Deny LoadBalancer services
deny[msg] {
  input.kind == "Service"
  input.spec.type == "LoadBalancer"
  msg := sprintf("Service '%s' must not use LoadBalancer - use ClusterIP and route through ingress", [input.metadata.name])
}

# Deny hardcoded sensitive env vars
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  env := container.env[_]
  sensitive_names := {"PASSWORD", "SECRET", "KEY", "TOKEN", "CREDENTIAL"}
  upper_name := upper(env.name)
  contains(upper_name, sensitive_names[_])
  env.value != ""
  not env.valueFrom
  msg := sprintf(
    "SECURITY: Container '%s' has hardcoded sensitive env var '%s' - use SecretKeyRef",
    [container.name, env.name]
  )
}