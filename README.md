# soteria

## What is Soteria?
  
Soteria is a set of Cloud Native Data Protection Policies using open-source CNCF projects such as OPA Gatekeeper and Kyverno.  In Greek mythology, Soteria is the goddess of safety and salvation, deliverance, and preservation from harm. Translated to an IT context, Soteria aims to enforce the protection of IT infrastructure and data from IT risks such as security incidents (ransomware), disasters (both natural and accidental), human error, and other incidents that would impact the availability of cloud native applications and services.  
  
Soteria implements the [WG-Policy Management Whitepaper](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) in a data protection context.
  
## Concept
Initial concept, Soteria v1 implements [Policy Enforcement Point](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) at various stages of the DevOps lifecycle: 
1. Upon check-in and deployment of a development application (checks for a label "purpose: development")
2. Upon final deployment into production (checks for a label "purpose: production")
3. During Day 2 runtime (_Implementation TBD_)

## Why Soteria?
Many organization’s risk management teams focus on enforcing security policies to help reduce the risk of unauthorized access (breach of confidentiality). However, risk management should take a perspective of all possible impacts on an organization. Data loss for stateful applications – and the resulting opportunity cost of outages and service unavailability – is one risk that’s less commonly discussed with respect to cloud native applications.  

Data protection operations are notoriously manual and heavyweight, but with Cloud Native Policy Engines, there is a brighter future.  As organizations leverage speed and agility as a competitive advantage and ITOps strategies such as GitOps, automated data protection policy enforcement becomes a must for ensuring that autonomous systems can safely deploy to production multiple times a day, week, or month without recourse.

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
First steps involve adding Kyverno access rights to perform the demonstration. These policies enforceand generate Kasten K10 K8s CRDs. The enforcement policy looks for the a 'dataprotection' label name of a policy pre-vetted by Senior IT Leadership.  Since these label names are already pre-vetted, we'll go ahead and auto generate them whenever a matching resource is deployed correctly.  The gold backup policy RPO/Retention objectives are just an example, but can be freely modified for your purposes.
1. Apply _kyvernorbac.yaml_ 
2. Apply _prod-backup-enforce-policy.yaml_
3. Apply _generate-gold-backup-policy.yaml_

```
clusterrole.rbac.authorization.k8s.io/kyverno:generatecontroller updated
clusterpolicy.kyverno.io/prod-backup-enforce-policy created
clusterpolicy.kyverno.io/generate-gold-backup-policy created
```

Second step demonstrates a typical bad behavior, to deploy an application into production without consideration of the data protection compliance policy and let it be someone elses accountability.  This is also a common pattern in monolithic VM protection where a "handoff" to the data protection operations team follows deployment into production. While not technically incorrectly, highly scalable cloud native operaitons that ship frequently, would become severely bottlennecked.  

Feedback is given back to the developer or system integrator to correct the application YAML when they try to deploy nginx. In a GitOps context, this would also fail to deploy after check-in, though we would probably want to implement some form of test at code integration as well (example forthcoming).

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
Third step illustrates a correctly defined application YAML that uses the pre-vetted policy label name "k10-goldpolicy" and also correctly uses the "immutable: enabled" label as per Senior IT Leadership's approved data protection policy.

5. Apply nginx-deployment.yaml

```
namespace/nginx configured
deployment.apps/nginx-deployment created
```
Lastly (GUI not show) - open up the K10 GUI and review the auto-generated backup policy.

6. Open K10 Policy UI

This concept can be applied to any data protection solution that uses native K8s Resources or CRD's (ie. Velero).

Send any and all feedback to **joey.lei@veeam.com**!

## Open Policy Agent Gatekeeper Admission Implementation
TBD 
