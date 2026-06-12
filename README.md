# Platform GitOps Lab — Crossplane + ArgoCD on Kind

A hands-on lab for building a **self-service infrastructure platform** on Kubernetes. You define cloud resources in Git, sync them with ArgoCD, and let Crossplane provision real infrastructure in the cloud — using the same workflow teams already use for applications.

## Project goal

Most teams manage apps and infrastructure in separate worlds: Helm charts in Git, cloud resources in consoles or separate IaC pipelines. This project shows how to **close that gap**.

The goal is a **platform-as-a-service style layer** on Kubernetes:

- **Platform engineers** publish reusable infrastructure APIs (what to provision, with guardrails).
- **Application teams** request what they need with simple Kubernetes manifests — not raw provider APIs or cloud consoles.
- **GitOps** keeps everything auditable: change a file, merge, and the cluster reconciles to match Git.

The manifests in this repo are **working examples** of that pattern. The product is the **platform model**: Git-driven, Kubernetes-native infrastructure delivery. What you provision — storage, messaging, databases, networking — is up to you; the workflow stays the same.

```
Developers commit YAML  →  ArgoCD syncs  →  Crossplane provisions  →  Cloud resources
```

## Tools used

| Tool | Role |
|------|------|
| [Kind](https://kind.sigs.k8s.io/) | Runs a full Kubernetes cluster locally in Docker — no cloud cluster required for the lab |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | CLI to interact with the cluster |
| [Helm](https://helm.sh/) | Installs ArgoCD (and can install Crossplane directly if you skip GitOps for that piece) |
| [ArgoCD](https://argo-cd.readthedocs.io/) | GitOps controller — watches this repo and keeps the cluster in sync with Git |
| [Crossplane](https://www.crossplane.io/) | Extends Kubernetes to manage external infrastructure as native resources |
| [Upbound providers](https://marketplace.upbound.io/) | Provider packages that teach Crossplane how to talk to AWS (and other clouds) |

You also need **cloud credentials** (e.g. AWS access keys) if you want Crossplane to provision real resources outside the cluster.

## Run it locally

### Prerequisites

Install Kind, kubectl, and Helm. Have cloud credentials ready if you plan to provision real infrastructure.

### 1. Create the Kind cluster

```bash
kind create cluster --name platform-lab --config kind-k8s-cluster/kind-config.yaml
```

### 2. Install ArgoCD

```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace
```

Wait until ArgoCD is ready:

```bash
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 3. Register GitOps applications

Application manifests live under `applications/`. They tell ArgoCD what to install from this repo (Crossplane, providers, platform definitions, infra claims).

If you forked the project, update `repoURL` in those files to point at your fork. Then apply:

```bash
kubectl apply -f applications/
```

ArgoCD will reconcile everything automatically (`automated` sync with prune and self-heal).

### 4. Add cloud credentials for Crossplane

Crossplane needs credentials to reach your cloud account. Create a credentials file locally (do not commit it — `aws-creds.conf` is gitignored):

```ini
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
```

Once the `crossplane-system` namespace exists:

```bash
kubectl create secret generic aws-secret \
  -n crossplane-system \
  --from-file=creds=aws-creds.conf
```

The provider config in this repo references this secret. Adjust if you use a different auth method or cloud.

### 5. Verify the platform is up

```bash
# ArgoCD applications and sync status
kubectl get applications -n argocd

# Crossplane core and installed providers
kubectl get pods -n crossplane-system
kubectl get providers -n crossplane-system

# Custom platform APIs and claims (once XRDs/compositions are synced)
kubectl get compositeresourcedefinitions
kubectl get managed
```

When ArgoCD apps are `Synced` and `Healthy`, and providers report `Healthy`, the platform loop is working. Add or change manifests under `crossplane/` and `infra/` to exercise provisioning.

### 6. Clean up

```bash
kind delete cluster --name platform-lab
```

### ArgoCD UI (optional)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

Open https://localhost:8080 and log in as `admin`.

## What you can do with it

Once the loop works locally, the same ideas scale to real platform work:

- **Add any infrastructure type** your providers support — expose it behind a simple claim API via XRDs and compositions.
- **Standardize how teams consume infra** — one consistent YAML shape per capability instead of ad-hoc cloud configs.
- **Enforce policy at the platform layer** — regions, naming, tagging, and defaults baked into compositions.
- **Practice GitOps end-to-end** — platform config and workload infra both live in Git with automated reconciliation.
- **Bridge to production** — swap Kind for EKS, GKE, or AKS; keep ArgoCD + Crossplane; the workflow stays the same.

This repo is a **sandbox for learning and prototyping** a Kubernetes-native platform. The end goal is learning how to **operate infrastructure like software**, and having a template you can extend in whatever direction your organization needs.
