package requiredDataProtectionPolicy
        
        deny[{"msg": msg, "details": {"Policy should have": required}}] {
          input.review.object.kind == "Deployment"
          policy := input.review.object.metadata.labels.dataprotection
          required := input.parameters.policy
          not startswith(policy,required)
          msg := sprintf("Forbidden dataprotection policy: %v", [policy])
        }
        
        deny[{"msg": msg, "details": {"Immutability should have": requiredimmutablity}}] {
          input.review.object.kind == "Deployment"
          immutability := input.review.object.metadata.labels.immutable
          requiredimmutablity := input.parameters.immutable
          not startswith(immutability,requiredimmutablity)
          msg := sprintf("Forbidden immutability policy: %v", [immutability])
        }