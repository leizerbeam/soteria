# soteria

## What is Soteria?
  
Soteria is a set of Cloud Native Data Protection Policies using open-source CNCF projects such as OPA Gatekeeper and Kyverno.  In Greek mythology, Soteria is the goddess of safety and salvation, deliverance, and preservation from harm. Translated to an IT context, Soteria aims to enforce the protection of IT infrastructure and data from IT risks such as security incidents (ransomware), disasters (both natural and accidental), human error, and other incidents that would impact the availability of cloud native applications and services.  
  
Soteria implements the [WG-Policy Management Whitepaper](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) in a data protection context.
  
## Concept
Initial concept, Soteria v1 implements [Policy Enforcement Point](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) at various stages of the DevOps lifecycle: 
1. Upon check-in and deployment of a development application (checks for a label "purpose: development")
2. Upon final deployment into production (checks for a label "purpose: production")
3. During Day 2 runtime (_Implementation TBD_)

## Kyverno Admission Implementation with Kasten K10
**Prerequisites:** 
- Install Kyverno
  - helm repo add kyverno https://kyverno.github.io/kyverno/
  - helm repo update
  - helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
  - helm install kyverno-policies kyverno/kyverno-policies --namespace kyverno
- Install Data Protection Solution of Choice (ie. [Kasten K10 Install](https://docs.kasten.io/latest/install/install.html))

**Explanation of YAML Files:**  
- kyvernorbac.yaml - allows Kyverno access rights to perform create, update, delete, list, get operations on Kasten K10 _Policy_ resources
- prod-backup-enforce-policy.yaml - Creates a Kyverno _ClusterPolicy_ to **enforce** on _Deployments, StatefulSets_ a valid K10 Data Protection Policy with Immutable Backups Enabled
- dev-backup-audit-policy.yaml - Creates a Kyverno _ClusterPolicy_ to **audit** on _Deployments, StatefulSets_ if developers are testing their applications with K10 Data Protection Policies.
- generate-gold-backup-policy - Creates a Kyverno _ClusterPolicy_ to **generate** a K10 App-Namespace Scoped _Policy_ called "gold-backup-policy using 24H RPO w/ snapshot retention of 7 dailies, 4 weeklies, 12 monthlies, 7 yearlys and enables snapshot export to an immutable backup target called "immutable-location-profile")
- nginx-deployment-invalid.yaml - An example nginx _Deployment_ with an invalid data protection policy (fails Kyverno enforcement)
- nginx-deployment.yaml - A valid nginx _Deployment_ with a "dataprotection: k10-goldpolicy" and "immutable: enabled" labels.  

**Demonstration and Expected Output**
1. Apply _kyvernorbac.yaml_
2. Apply _prod-backup-enforce-policy.yaml_
3. Apply _generate-gold-backup-policy.yaml_

```
clusterrole.rbac.authorization.k8s.io/kyverno:generatecontroller updated
clusterpolicy.kyverno.io/prod-backup-enforce-policy created
clusterpolicy.kyverno.io/generate-gold-backup-policy created
```
4. Apply nginx-deployment-invalid.yaml

```
% kubectl apply -f nginx-deployment-invalid.yaml 
namespace/nginx created
Error from server: error when creating "nginx-deployment-invalid.yaml": 
admission webhook "validate.kyverno.svc-fail" denied the request: 
resource Deployment/nginx/nginx-deployment was blocked due to the 
following policies prod-backup-enforce-policy: cd-prod-backup-policy: 
'validation error: Production Deployments and StatefulSets must have 
Data Protection Policies with Immutability Enabled (use labels: dataprotection:
k10-<policyname> and immutable: enabled). Rule cd-prod-backup-policy 
failed at path /metadata/labels/immutable/'
```

5. Apply nginx-deployment.yaml

```
namespace/nginx configured
deployment.apps/nginx-deployment created
```

6. Open K10 Policy UI

## Open Policy Agent Gatekeeper Admission Implementation
TBD 
