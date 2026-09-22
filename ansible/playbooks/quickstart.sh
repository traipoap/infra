#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -Eeuo pipefail

INVENTORY="inventory/hosts"
PLAYBOOK_DIR="playbooks"
SLEEP_SECONDS=15
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/bootstrap-$(date '+%Y%m%d-%H%M%S').log"

PLAYBOOKS=(
  "00-prerequisites.yml"
  "01-cluster-setup.yml"
  "02-servicemesh.yml"
  "03-storage-networking.yml"
  "04-garage-deploy.yml"
  "05-gitops-bootstrap.yml"
)

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

trap 'echo "ERROR: Failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

START_TIME=$(date +%s)

echo "=========================================="
echo "Cluster Bootstrap"
echo "Started: $(date)"
echo "=========================================="

LAST_INDEX=$((${#PLAYBOOKS[@]} - 1))

for i in "${!PLAYBOOKS[@]}"; do
  playbook="${PLAYBOOKS[$i]}"
  PLAYBOOK_START=$(date +%s)

  echo
  echo ">>> Running ${playbook}"
  echo ">>> Started: $(date)"

  ansible-playbook \
    -i "${INVENTORY}" \
    "${PLAYBOOK_DIR}/${playbook}"

  PLAYBOOK_END=$(date +%s)
  PLAYBOOK_DURATION=$((PLAYBOOK_END - PLAYBOOK_START))

  printf '>>> %s completed successfully\n' "${playbook}"
  printf '>>> Duration: %02dh %02dm %02ds\n' \
    $((PLAYBOOK_DURATION / 3600)) \
    $(((PLAYBOOK_DURATION % 3600) / 60)) \
    $((PLAYBOOK_DURATION % 60))

  if (( i != LAST_INDEX )); then
    echo ">>> Waiting ${SLEEP_SECONDS}s..."
    sleep "${SLEEP_SECONDS}"
  fi
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo
echo "=========================================="
echo "✓ Cluster Bootstrap Completed"
echo "Finished: $(date)"
printf 'Total Duration: %02dh %02dm %02ds\n' \
  $((TOTAL_DURATION / 3600)) \
  $(((TOTAL_DURATION % 3600) / 60)) \
  $((TOTAL_DURATION % 60))
echo "=========================================="
