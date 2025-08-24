for name in $(kubectl get configmap -n qc -o jsonpath="{.items[*].metadata.name}"); do
  kubectl get configmap $name -n qc -o yaml > "${name}.yaml"
done