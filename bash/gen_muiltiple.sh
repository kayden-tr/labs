#!/bin/bash
read -p "Enter your envs (separated by space, e.g., 'qc dev uat demo asia-prod'): " -a envs              
for env in "${envs[@]}"; do
  echo "Update config for ${env}"
done
