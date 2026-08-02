# Policy Exceptions

This document records known policy violations in upstream Helm charts that cannot
be remediated directly. Each exception is explicitly accepted with justification.

## mattermost-operator Deployment

| Field | Detail |
|-------|--------|
| **Violation** | `runAsNonRoot` not set, no CPU/memory resource limits |
| **Chart** | mattermost/mattermost-operator v1.0.5 |
| **Reason** | Upstream chart does not expose securityContext or resource limit configuration in its values.yaml. This is a constraint of the Operator Helm chart, not our deployment configuration. |
| **Risk** | Medium — the Operator pod runs with elevated privileges but only manages CRDs, not user data |
| **Mitigation** | Falco runtime monitoring will alert on any unexpected syscalls from this pod |
| **Accepted by** | Amal Sboui |
| **Review date** | July 2026 |

## minio Deployment

| Field | Detail |
|-------|--------|
| **Violation** | `runAsNonRoot` not set, no CPU limit defined |
| **Chart** | minio/minio v5.4.0 |
| **Reason** | Upstream MinIO chart runs as root by default. CPU limit not set in base chart values. |
| **Risk** | Medium — MinIO handles file storage; root access is a concern but mitigated by network isolation via NetworkPolicy |
| **Mitigation** | Falco will alert on unexpected file system writes or network connections from the MinIO pod |
| **Accepted by** | Amal Sboui |
| **Review date** | July 2026 |