SHELL := /bin/bash

########################################################################################
# Environment Checks
########################################################################################

CHECK_ENV:=$(shell ./scripts/check-environment.sh)
ifneq ($(CHECK_ENV),)
$(error Check environment dependencies.)
endif


########################################################################################
# Targets
########################################################################################

help: ## Help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

helm: ## Install Helm 3 dependency
	@./scripts/install-helm.sh

helm-plugins: ## Install Helm plugins
	@helm plugin install https://github.com/databus23/helm-diff

repos: ## Add Helm repositories for dependencies
	@echo "=> Installing Helm repos"
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo update
	@echo

tools: install-prometheus install-loki install-metrics install-dashboard ## Intall/Update Prometheus/Grafana, Loki, Metrics Server, Kubernetes dashboard

pull: ## Git pull helm-charts repository
	@git clean -idf
	@git pull origin $(shell git rev-parse --abbrev-ref HEAD)

## NEEDS WORK ***
## Error: directory unchained/infra/unchained/chart/arbitrum not found
update-dependencies:
	@echo "=> Updating Helm chart dependencies"
	@helm dependencies update ./relayer
	#@helm dependencies update ./unchained
	#@helm dependencies update ./blockchain-daemons
	@echo

## NEEDS WORK
## Error from server (NotFound): namespaces "arkeo" not found
mnemonic: ## Retrieve and display current mnemonic for backup from your arkeonode
	@./scripts/mnemonic.sh

## NEEDS WORK
## Error from server (NotFound): namespaces "arkeo" not found
password: ## Retrieve and display current password for backup from your arkeonode
	@./scripts/password.sh

## NEEDS WORK
## No resources found in arkeo namespace.
pods: ## Get arkeonode Kubernetes pods
	@./scripts/pods.sh

## NEEDS WORK ***
## Error: directory unchained/infra/unchained/chart/arbitrum not found
pre-install: update-dependencies ## Pre deploy steps for a arkeonode (secret creation)
	@./scripts/pre-install.sh

## NEEDS WORK
## Error: directory unchained/infra/unchained/chart/arbitrum not found
install: update-dependencies ## Deploy a THORNode
	@./scripts/install.sh

## NEEDS WORK
## Error: directory unchained/infra/unchained/chart/arbitrum not found
recycle: update-dependencies ## Destroy and recreate a THORNode recycling existing daemons to avoid re-sync
	@./scripts/recycle.sh

## NEEDS WORK
## Error: directory unchained/infra/unchained/chart/arbitrum not found
update: pull update-dependencies ## Update a THORNode to latest version
	@./scripts/update.sh

# NEEDS UPDATE -> ARKEO
status: ## Display current status of your THORNode
	@./scripts/status.sh

# NEEDS UPDATES -> ARKEO
reset: ## Reset and resync a service from scratch on your THORNode. This command can take a while to sync back to 100%.
	@./scripts/reset.sh

# NEEDS UPDATES -> ARKEO
hard-reset-thornode: ## Hard reset and resync thornode service from scratch on your THORNode, leaving no bak/* files.
	@./scripts/hard-reset-thornode.sh

# NEEDS UPDATES -> ARKEO
backup: ## Backup specific files from either thornode of bifrost service of a THORNode.
	@./scripts/backup.sh

# NEEDS UPDATES -> ARKEO
full-backup: ## Create volume snapshots and backups for both thornode and bifrost services.
	@./scripts/full-backup.sh

# NEEDS UPDATES -> ARKEO
restore-backup: ## Restore backup specific files from either thornode of bifrost service of a THORNode.
	@./scripts/restore-backup.sh

# NEEDS UPDATES -> ARKEO
snapshot: ## Snapshot a volume for a specific THORNode service.
	@./scripts/snapshot.sh

# NEEDS UPDATES -> ARKEO
restore-snapshot: ## Restore a volume for a specific THORNode service from a snapshot.
	@./scripts/restore-snapshot.sh

# NEEDS UPDATES -> ARKEO
wait-ready: ## Wait for all pods to be in Ready state
	@./scripts/wait-ready.sh

# NEEDS UPDATES
destroy: ## Uninstall current THORNode
	@./scripts/destroy.sh

# NEEDS UPDATES -> ARKEO
export-state: ## Export chain state
	@./scripts/export-state.sh

# NEEDS UPDATES -> ARKEO
shell: ## Open a shell for a selected THORNode service
	@./scripts/shell.sh

# NEEDS UPDATES -> ARKEO
debug: ## Open a shell for THORNode service mounting volume to debug
	@./scripts/debug.sh

# NEEDS UPDATES -> ARKEO
restore-external-snapshot: ## Restore THORNode from external snapshot.
	@./scripts/restore-external-snapshot.sh

# NEEDS UPDATES -> ARKEO
watch: ## Watch the THORNode pods in real time
	@./scripts/watch.sh

# NEEDS UPDATES -> ARKEO
logs: ## Display logs for a selected THORNode service
	@./scripts/logs.sh

# NEEDS UPDATES -> ARKEO
restart: ## Restart a selected THORNode service
	@./scripts/restart.sh

# NEEDS UPDATES -> ARKEO
halt: ## Halt a selected THORNode service
	@./scripts/halt.sh

# NEEDS UPDATES -> ARKEO
set-node-keys: ## Send a set-node-keys transaction to your THORNode
	@./scripts/set-node-keys.sh

# NEEDS UPDATES -> ARKEO
set-version: ## Send a set-version transaction to your THORNode
	@./scripts/set-version.sh

# NEEDS UPDATES -> ARKEO
set-ip-address: ## Send a set-ip-address transaction to your THORNode
	@./scripts/set-ip-address.sh

# NEEDS UPDATES -> ARKEO
set-monitoring: ## Enable PagerDuty or Deadmans Snitch monitoring via Prometheus/Grafana re-deploy
	@./scripts/set-monitoring.sh

destroy-tools: destroy-prometheus destroy-loki destroy-dashboard ## Uninstall Prometheus/Grafana, Loki, Kubernetes dashboard

install-loki: repos ## Install/Update Loki logs management stack
	@./scripts/install-loki.sh

destroy-loki: ## Uninstall Loki logs management stack
	@./scripts/destroy-loki.sh

install-prometheus: repos ## Install/Update Prometheus/Grafana stack
	@./scripts/install-prometheus.sh

destroy-prometheus: ## Uninstall Prometheus/Grafana stack
	@./scripts/destroy-prometheus.sh

install-metrics: repos ## Install/Update Metrics Server
	@echo "=> Installing Metrics"
	@kubectl get svc -A | grep -q metrics-server || kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	@echo

destroy-metrics: ## Uninstall Metrics Server
	@echo "=> Deleting Metrics"
	@kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	@echo

install-dashboard: repos ## Install/Update Kubernetes dashboard
	@echo "=> Installing Kubernetes Dashboard"
	@helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard -n kube-system --wait -f ./kubernetes-dashboard/values.yaml
	@kubectl apply -f ./kubernetes-dashboard/dashboard-admin.yaml
	@echo

destroy-dashboard: ## Uninstall Kubernetes dashboard
	@echo "=> Deleting Kubernetes Dashboard"
	@helm delete kubernetes-dashboard -n kube-system
	@echo

install-provider: ## Install Thorchain provider
	@scripts/install-provider.sh

destroy-provider: ## Uninstall Thorchain provider
	@scripts/destroy-provider.sh

grafana: ## Access Grafana UI through port-forward locally
	@echo User: admin
	@echo Password: thorchain
	@echo Open your browser at http://localhost:3000
	@kubectl -n prometheus-system port-forward service/prometheus-grafana 3000:80

prometheus: ## Access Prometheus UI through port-forward locally
	@echo Open your browser at http://localhost:9090
	@kubectl -n prometheus-system port-forward service/prometheus-kube-prometheus-prometheus 9090

alert-manager: ## Access Alert-Manager UI through port-forward locally
	@echo Open your browser at http://localhost:9093
	@kubectl -n prometheus-system port-forward service/prometheus-kube-prometheus-alertmanager 9093

dashboard: ## Access Kubernetes Dashboard UI through port-forward locally
	@echo Open your browser at http://localhost:8000
	@kubectl -n kube-system port-forward service/kubernetes-dashboard 8000:443

lint: ## Run linters (development)
	./scripts/lint.sh

verify-ethereum: ## Verify Ethereum finalized slot state root
	@./scripts/verify-ethereum.sh

.PHONY: help helm repo pull tools install-loki install-prometheus install-metrics install-dashboard export-state hard-fork destroy-tools destroy-loki destroy-prometheus destroy-metrics prometheus grafana dashboard alert-manager mnemonic update-dependencies reset restart pods deploy update destroy status shell watch logs set-node-keys set-ip-address set-version pause resume lint verify-ethereum

.EXPORT_ALL_VARIABLES:
