package main

# Deny containers running as root
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.securityContext.runAsNonRoot
  msg := sprintf("Container '%s' in Deployment '%s' must set runAsNonRoot: true", [container.name, input.metadata.name])
}

# Deny containers without CPU limits
deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container '%s' in Deployment '%s' is missing CPU limit", [container.name, input.metadata.name])
}

# Deny containers without memory limits
deny[msg] {
  input.kind == "Deployment"
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