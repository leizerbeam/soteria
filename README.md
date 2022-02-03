# soteria

## What is Soteria?
  
Soteria is a set of K8s Native Data Protection Policies using open source CNCF projects such as OPA Gatekeeper and Kyverno.  In Greek mythology, Soteria is the goddess of safety and salvation, deliverance, and preservation from harm. Translated to an IT context, Soteria aims to enforce the protection of IT infrastructure and data from IT risks such as security incidents (ransomware), disasters (both natural and accidental), human error, and other incidents that would impact the availability of cloud native applications and services.  
  
Soteria implements the [WG-Policy Management Whitepaper](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) in a data protection context.
  
## Concept
Initial concept, Soteria v1 implements [Policy Enforcement Point](https://github.com/kubernetes/community/blob/c61508a8651fcb49036188410becc36a3750217b/sig-security/policy/kubernetes-policy-management.md) at various stages of the DevOps lifecycle: 
1. Upon check-in and deployment of a development application (checks for a label "purpose: development")
2. Upon final deployment into production (checks for a label "purpose: production")
3. During Day 2 runtime (_Implementation TBD_)

## Why Soteria?
Achieving data protection appears easy.  Let's “whip up” a daily cron job backup script and call it “production-ready.” 

However, battle-hardened IT experts will know that there are many additional risks to consider:
- The CIO's balance of cost and resources to implement a solution that reduces the acceptable data loss to minutes or hours.
- The GM's desire to limit financial impact due to downtime of a revenue generating app
- The CISO's requirement to have immutablity, a defense against ransomware operators who target destruction of backups.

Data protection policies are in fact time-consuming to prepare and resource-intensive to execute. Fortunately, attendees of this talk can have their cake and eat it too. CIO’s will learn to implement a low code, K8s native means of authoring data protection "guardrails" that can be easily consumed by app developers. For maximum effect, this approach can be implemented at scale with IaC/GitOps approaches, for example with Argo or Flux.

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

1. Add Kyverno access rights to perform the demonstration. These policies enforceand generate Kasten K10 K8s CRDs. The enforcement policy looks for the a 'dataprotection' label name of a policy pre-vetted by Senior IT Leadership.  Since these label names are already pre-vetted, we'll go ahead and auto generate them whenever a matching resource is deployed correctly.  The gold backup policy RPO/Retention objectives are just an example, but can be freely modified for your purposes.

```console
kubectl apply -f kyvernorbac.yaml
kubectl apply -f prod-backup-enforce-policy.yaml
kubectl apply -f generate-gold-backup-policy.yaml
```
```console
clusterrole.rbac.authorization.k8s.io/kyverno:generatecontroller updated
clusterpolicy.kyverno.io/prod-backup-enforce-policy created
clusterpolicy.kyverno.io/generate-gold-backup-policy created
```

2. The second step demonstrates a typical bad behavior, to deploy an application into production without consideration of the data protection compliance policy and let it be someone elses accountability.  This is also a common pattern in monolithic VM protection where a "handoff" to the data protection operations team follows deployment into production. While not technically incorrectly, highly scalable cloud native operaitons that ship frequently, would become severely bottlenecked.  Feedback is given back to the developer or system integrator to correct the application YAML when they try to deploy nginx. In a GitOps context, this would also fail to deploy after check-in, though we would probably want to implement some form of test at code integration as well (example forthcoming).

```console
kubectl apply -f nginx-deployment-invalid.yaml 
```
```console
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
3. The third step illustrates a correctly defined application YAML that uses the pre-vetted policy label name "k10-goldpolicy" and also correctly uses the "immutable: enabled" label as per Senior IT Leadership's approved data protection policy.

```console
kubectl apply -f nginx-deployment.yaml
```
```console
namespace/nginx configured
deployment.apps/nginx-deployment created
```
4. Lastly (GUI not show) - open up the K10 GUI and review the auto-generated backup policy.

5. (Optional) Review the entire compliance history on your policies. If there are any enforcement errors to review, they will be listed withthe describe command.

```console
kubectl get policyreport -A                                       
```
```console
NAMESPACE   NAME                PASS   FAIL   WARN   ERROR   SKIP   AGE
default     polr-ns-default     16     3      0      0       0      5d2h
kasten-io   polr-ns-kasten-io   144    16     0      0       0      5d2h
nginx       polr-ns-nginx       10     0      0      0       0      103m
olm         polr-ns-olm         54     3      0      0       0      5d2h
```
```console
describe polr polr-ns-nginx | grep "Result: \+fail" -B10
```

This concept can be applied to any data protection solution that uses native K8s Resources or CRD's (ie. Velero).

Send any and all feedback to **joey.lei@veeam.com**!

## Open Policy Agent Gatekeeper Admission Implementation

**Prerequisites:** 
- Install Gatekeeper (https://open-policy-agent.github.io/gatekeeper/website/docs/install

**Explanation of YAML Files:**  
- requireLabelsConstraintTemplate.yaml - a simple ConstraintTemplate example to require the existence of labels (to be defined in the Constraint itself)
- policyConstraintSimpleLabelOnly.yaml - A custom Constraint resource to require all "Deployment" and "StatefulSet" resources contain _dataprotection_ and _immutable_ labels
- requireDPPolicyConstraintTemplate.yaml - an advanced ConstraintTemplate requiring validation of the values inside _dataprotection_ and _immutable_ labels
- policyConstraintDataProtection.yaml - a custom Constraint resource that enforces _dataprotection_ starts with "k10" and an immutable is "enabled"
- nginx-deployment-invalid-missing-labels.yaml - An example nginx _Deployment_ with an invalid data protection policy (fails simple label enforcement)
- nginx-deployment-improper-definition.yaml - An example nginx _Deployment_ with invalid policy definitions for the policy name and immutability status
- nginx-deployment.yaml - A valid nginx _Deployment_ with a "dataprotection: k10-goldpolicy" and "immutable: enabled" labels.  

**Demonstration and Expected Output**  

1. Apply the _ConstraintTemplate_ and custom reosurce _DataProtectionRequiredLabels_

```console
kubectl apply -f requiredLabelsConstraintTemplate.yaml
kubectl apply -f policyConstraintSimpleLabelOnly.yaml
```
```console
constrainttemplate.templates.gatekeeper.sh/dataprotectionrequiredlabels created
dataprotectionrequiredlabels.constraints.gatekeeper.sh/prod-must-have-dp-labels created
```
2. The second step demonstrates a typical bad behavior, to deploy an application into production without consideration of the data protection compliance policy and let it be someone elses accountability.  This is also a common pattern in monolithic VM protection where a "handoff" to the data protection operations team follows deployment into production. While not technically incorrectly, highly scalable cloud native operaitons that ship frequently, would become severely bottlenecked.  Feedback is given back to the developer or system integrator to correct the application YAML when they try to deploy nginx. In a GitOps context, this would also fail to deploy after check-in, though we would probably want to implement some form of test at code integration as well (example forthcoming).

```console
kubectl apply -f nginx-deployment-invalid-missing-labels.yaml 
```
```console
namespace/nginx created
Error from server ([prod-must-have-dp-labels] you must provide labels: {"dataprotection", "immutable"}): error when creating "nginx-deployment-invalid.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [prod-must-have-dp-labels] you must provide labels: {"dataprotection", "immutable"}
```

3. We can a more restrictive example and require specific dataprotection label and immutability label to match for example our gold backup policy. With Gatekeeper, the enforcement policy is more customizable due to the fact one needs to code in REGO.  While it makes it longer to get started for a beginner, more complex data protection policies can be enabled vs Kyverno.

```console
kubectl apply -f requireDPPolicyConstraintTemplate.yaml
kubectl apply -f policyConstraintDataProtection.yaml   
```
```console
constrainttemplate.templates.gatekeeper.sh/requireddataprotectionpolicy created
requireddataprotectionpolicy.constraints.gatekeeper.sh/dp-policy-must-be-defined created
```

4. Next, we'll attempt to deploy the nginx with invalid values for dataprotection and immutable

```console 
kubectl apply -f nginx-deployment-invalid-improper-definition.yaml
```
```console
namespace/nginx created
Error from server ([dp-policy-must-be-defined] Forbidden immutability policy: notenabled
[dp-policy-must-be-defined] Forbidden dataprotection policy: notreal): error when creating "nginx-deployment-invalid-bad-values.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [dp-policy-must-be-defined] Forbidden immutability policy: notenabled
[dp-policy-must-be-defined] Forbidden dataprotection policy: notreal
```

5. Lastly, we'll a correctly defined application YAML that uses the pre-vetted policy label name "k10-goldpolicy" and also correctly uses the "immutable: enabled" label as per Senior IT Leadership's approved data protection policy.  Unlike Kyverno, Gatekeeper does not yet have an ability to generate other custom resources, so other means need to enable the generation of for example Kasten K10 Policy resources.

```console
kubectl apply -f nginx-deployment.yaml 
```
```console
namespace/nginx configured
deployment.apps/nginx-deployment created
```
