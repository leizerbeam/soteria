# soteria

## What is Soteria?
  
Soteria is a set of K8s Native Data Protection Policies using open source CNCF Kubernetes Native Security Policies OPA Gatekeeper and Kyverno.  In Greek mythology, Soteria is the goddess of safety and salvation, deliverance, and preservation from harm. Translated to an IT context, Soteria aims to **enforce** the protection of IT infrastructure and data from IT risks such as security incidents (ransomware), disasters (both natural and accidental), human error, and other incidents that would impact the availability of cloud native applications and services.  
  
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

Data protection policies to mitigate these concerns are in fact time-consuming to prepare and resource-intensive to execute at cloud-scale.

Traditional "ITIL" processes require lots of sign off and checks and balances to ensure IT has reviewed risks and has central control over what is deployed. The current competitive environment enabled by cloud demands more decentralized approach: to leverage self service for agility purposes and automated policy checks to mitigate risk. This has been true with autonomous operations like GitOps or Infrastructure as Code now leveraging more and more "Shift Left" security policies and scanning for misconfiguration in code.

Soteria borrows from the Cloud Native Posture Management approach to implement "Shift Left" policy "guardrails" that can be easily consumed by anyone, including app developers. These policies restrict deployment of non-compliant configurations and prevents launching ill-prepared code into production, thereby mitigating risk.

How Soteria works is that CIO/CISOs can define controls as a set of Cloud Native Data Protection Policies, perform audit & enforcement while enabling developers to move rapidly by providing real-time feedback how to comply.

## Kyverno Admission Implementation with Kasten K10

Kyverno approaches cloud native policies designed with Kubernetes in mind.  All policies are familiar Kubernetes Native API and for anyone who has worked with custom resources, will feel like defining policies is second nature.  Kyverno cna also create "generation" policies which help perform automation. This is useful to automate additional deployments conditional on a passing policy audit. Kyverno is the engine of choice for every day practicioners. 

**Prerequisites:** 
- Install Kyverno
  - helm repo add kyverno https://kyverno.github.io/kyverno/
  - helm repo update
  - helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
  - helm install kyverno-policies kyverno/kyverno-policies --namespace kyverno
- Install Data Protection Solution of Choice (ie. [Kasten K10 Install](https://docs.kasten.io/latest/install/install.html))

**Policy as Code Repos**
- /kyverno: all Kyverno policies for data protection guardrails
- /opa-gatekeeper: all Open Policy Agent data protection guardrails

**Demonstration and Expected Output**  

1. Add Kyverno access rights to perform the demonstration. These policies enforce and generate Kasten K10 K8s Policy Resources. The enforcement policy looks for a 'dataprotection' label name of a policy pre-vetted by Senior IT Leadership.  Since these label names are already pre-vetted, we'll go ahead and auto generate them whenever a matching resource is deployed correctly.  The gold backup policy RPO/Retention objectives are just an example, but can be freely modified for your purposes.

```console
kubectl apply -f kyvernorbac.yaml
kubectl apply -f enforce-data-protection-by-label.yaml
kubectl apply -f generate-gold-backup-policy.yaml
```
```console
clusterrole.rbac.authorization.k8s.io/kyverno:generatecontroller updated
clusterpolicy.kyverno.io/enforce-data-protection-by-label created
clusterpolicy.kyverno.io/generate-gold-backup-policy created
```

2. The second step demonstrates a typical bad behavior, to deploy an application into production without consideration of the data protection compliance policy and let it be someone elses accountability.  This is also a common pattern in monolithic VM protection where a "handoff" to the data protection operations team follows deployment into production. While not technically incorrect, highly scalable cloud native operations that ship frequently, would become severely bottlenecked.  Feedback is given back to the developer or system integrator to correct the application YAML when they try to deploy nginx. In a GitOps context, this would also fail to deploy after check-in, though we would probably want to implement some form of test at code integration as well (example forthcoming).

```console
kubectl apply -f nginx-deployment-invalid.yaml 
```
```console
namespace/nginx created

Error from server: error when creating "nginx-deployment-invalid.yaml": 
admission webhook "validate.kyverno.svc-fail" denied the request: 
resource Deployment/nginx/nginx-deployment was blocked due to the 
following policies enforce-data-protection-by-label: cd-prod-backup-policy: 
'validation error: Production Deployments and StatefulSets must have 
Data Protection Policies with Immutability Enabled (use labels: dataprotection:
k10-<policyname> and immutable: enabled). Rule enforce-data-protection-by-label
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

5. (Optional) Review the entire compliance history on your policies. If there are any enforcement errors to review, they will be listed with the describe command.

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

This concept can be applied to any data protection solution that uses native K8s Resources or CRD's.

## Advanced Kyverno Policies
- enforce-3-2-1.yaml - The rule of 3-2-1 recommends that you have at least 3 copies of data, on 2 different storage targets, and 1 being "offsite"
      In K8s/K10, this translates to a StatefulSet (the production PersistentVolumeClaim), a backup (a snapshot of the PVC),
      and an export to cloud object storage (a cloud copy of the PVC snapshot)
- enforce-immutable-backup.yaml - K10 Object Storage Location Profiles store K10 RestorePoints (App Backups) for import and export operations.
      AWS S3 or S3 compatible object storage that supports object lock can store immutable backups. 
      Immutability is typically not enabled by default due to the increased costs of retaining storage. 
      This policy checks that the Profile contains a 'protectionPeriod' which is the main configuration for K10 immutability. 
- enforce-minimum-retentions.yaml - K10 Policy resources can be validated to adhere to common compliance retention standards. This policy demonstrates "mutation" which modifies incoming API requests before being processed by the K8s API Server
- enforce-mission-critical-rpo.yaml - K10 Policy resources can be educated to adhere to common Recovery Point Objective (RPO) best practices. 
      This policy is advising to use an RPO frequency that with hourly granularity if it has the appPriority: Mission Critical
- enforce-namespace-whitelisting.yaml - K10 allows on backup and restore of applications (namespaces) and is designed to be run with full cluster admin permissions.      This policy is designed to prevent exfiltration outside trusted namespaces (ie. whitelisted namespaces)

## Test Manifests
- backup-export-policy.yaml - a compliant K10 Policy with the above advanced policies 
- immutable-location-profile.yaml - a non-compliant K10 Profile (protectionPeriod is commented out)
- nginx-deployment-invalid.yaml - a non-compliant "app" - missing "immutable: enabled"
- nginx-deployment.yaml - a compliant "app" - has k10-goldpolicy (pairs with generate policy)

Send any and all feedback to **joey.lei@veeam.com**!

## Open Policy Agent Gatekeeper Admission Implementation

Open Policy Agent is the dominant enforcement policy for cloud native applications.  It is written using a langauge called REGO. While this increases the complexity of authoring policies, this also enables more fine grained control for complex policies. Gatekeeper is the Kubernetes native implementation of OPA. It is the engine of choice for developers.

**Prerequisites:** 
- Install Gatekeeper (https://open-policy-agent.github.io/gatekeeper/website/docs/install

**Explanation of YAML Files:**  
- dataprotectionpolicy.rego - REGO policy matching the 'requireDPPolicyConstraintTemplate.yaml" for use in CI/CD pipelines
- requireLabelsConstraintTemplate.yaml - a simple ConstraintTemplate example to require the existence of labels (to be defined in the Constraint itself)
- policyConstraintSimpleLabelOnly.yaml - A custom Constraint resource to require all "Deployment" and "StatefulSet" resources contain _dataprotection_ and _immutable_ labels
- requireDPPolicyConstraintTemplate.yaml - an advanced ConstraintTemplate requiring validation of the values inside _dataprotection_ and _immutable_ labels
- policyConstraintDataProtection.yaml - a custom Constraint resource that enforces _dataprotection_ starts with "k10" and an immutable is "enabled"
- nginx-deployment-invalid-missing-labels.yaml - An example nginx _Deployment_ with an invalid data protection policy (fails simple label enforcement)
- nginx-deployment-improper-definition.yaml - An example nginx _Deployment_ with invalid policy definitions for the policy name and immutability status
- nginx-deployment.yaml - A valid nginx _Deployment_ with a "dataprotection: k10-goldpolicy" and "immutable: enabled" labels.  

**Demonstration and Expected Output**  

1. Apply the _ConstraintTemplate_ and custom reosurce _DataProtectionRequiredLabels_ to create the Gatekeeper policies. This uses a simpler approach to look for required labels in an application definition.

```console
kubectl apply -f requiredLabelsConstraintTemplate.yaml
kubectl apply -f policyConstraintSimpleLabelOnly.yaml
```
```console
constrainttemplate.templates.gatekeeper.sh/dataprotectionrequiredlabels created
dataprotectionrequiredlabels.constraints.gatekeeper.sh/prod-must-have-dp-labels created
```
2. The second step is identical to the Kyverno example. It demonstrates a typical bad behavior, to deploy an application into production without consideration of the data protection compliance policy and let it be someone elses accountability.  This is also a common pattern in monolithic VM protection where a "handoff" to the data protection operations team follows deployment into production. While not technically incorrectly, highly scalable cloud native operaitons that ship frequently, would become severely bottlenecked.  Feedback is given back to the developer or system integrator to correct the application YAML when they try to deploy nginx. In a GitOps context, this would also fail to deploy after check-in, though we would probably want to implement some form of test at code integration as well (example forthcoming).

```console
kubectl apply -f nginx-deployment-invalid-missing-labels.yaml 
```
```console
namespace/nginx created
Error from server ([prod-must-have-dp-labels] you must provide labels: {"dataprotection", "immutable"}): error when creating "nginx-deployment-invalid.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [prod-must-have-dp-labels] you must provide labels: {"dataprotection", "immutable"}
```

3. We can a more advanced example and require specific dataprotection label and immutability label to match the name of our K10 backdata protection policy and specifically looks for a policy with immutability enabled.

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

5. Lastly, like in the Kyverno example, we'll a correctly defined application YAML that uses the pre-vetted policy label name "k10-goldpolicy" and also correctly uses the "immutable: enabled" label as per Senior IT Leadership's approved data protection policy.  Unlike Kyverno, Gatekeeper does not yet have an ability to generate other custom resources, so other means need to enable the generation of for example Kasten K10 Policy resources.

```console
kubectl apply -f nginx-deployment.yaml 
```
```console
namespace/nginx configured
deployment.apps/nginx-deployment created
```
