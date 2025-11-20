# 🚀 Talos K8s sur Proxmox : Full Stack Automation (Terraform + Ansible)

Ce dépôt contient l'Infrastructure as Code (IaC) pour provisionner un cluster Kubernetes immuable, géré par API (Talos Linux), sur un hyperviseur Proxmox VE. L'objectif est de valider une chaîne DevOps complète : du provisionnement de la VM à la gestion des secrets.

---

## 1. 🎯 Architecture & Outils

| Composant | Rôle | Outil / Version |
| :--- | :--- | :--- |
| **Infra as Code (IaC)** | Provisionnement des 3 VMs (CP + 2 Workers) | **Terraform** (bpg/proxmox) |
| **OS / K8s** | Système d'exploitation immuable, API-driven. | **Talos Linux** (v1.10.8) |
| **Sécurité** | Gestion et stockage des secrets. | **HashiCorp Vault** (via Helm) |
| **Automatisation** | Configuration de Vault via API. | **Ansible** (Playbook personnalisé) |

---

## 2. ✅ Pré-requis & Configuration

### A. Préparation du Serveur Proxmox (SSH)

1.  **ISO Talos :** Le fichier `talos-amd64.iso` (300 Mo, v1.10.8) doit être présent dans le stockage local : `/var/lib/vz/template/iso/`.
2.  **Comptes :** Un utilisateur API Proxmox (ex: `terraform-prov@pve`) doit être créé avec les privilèges nécessaires (SDN, VM.Allocate, etc.).

### B. Configuration Locale (Fichiers)

Modifiez les adresses IP dans **`infra/terraform.tfvars`** pour correspondre à votre réseau.

* **IP Control Plane (Master) :** `10.202.69.100` (fixe).
* **Passerelle :** `10.202.255.254` (nécessaire pour la configuration).

---

## 3. 🚀 Déploiement Complet (Modus Operandi)

Exécutez toutes ces commandes depuis la racine du dépôt.

### A. Phase Terraform (Infrastructure)

Cette étape crée les 3 VMs avec l'ordre de boot corrigé (`ide2` en premier).

1.  **Exportez le Token Proxmox** (à faire à chaque nouvelle session) :
    ```bash
    export PROXMOX_VE_API_TOKEN='terraform-prov@pve!terraform=VOTRE_UUID_SECRET'
    ```
2.  **Déploiement des 3 VMs :**
    ```bash
    cd infra/proxmox-k8s
    terraform init
    terraform apply -auto-approve
    ```

### B. Phase Talosctl (Installation & Bootstrap)

Une fois les VMs démarrées, récupérez l'IP du Control Plane (`10.202.69.100`).

1.  **Générer la configuration & Installer Talos sur disque :**
    ```bash
    export CP_IP="10.202.69.100"
    talosctl gen config "mon-cluster" https://${CP_IP}:6443

    # Appliquer la config au Master (Installation OS)
    talosctl apply-config --insecure --nodes $CP_IP --file ../config/talos-yaml/controlplane.yaml
    ```
2.  **Faire rejoindre les Workers :**
    *(Répétez pour 10.202.69.101 et 10.202.69.102)*
    ```bash
    talosctl apply-config --insecure --nodes 10.202.69.101 --file ../config/talos-yaml/worker.yaml
    ```

3.  **Démarrer le Cluster (Bootstrap) :**
    *(Une fois le Master redémarré sur disque, patientez)*
    ```bash
    talosctl bootstrap
    ```

### C. Validation & Automatisation de Vault

1.  **Vérification K8s :** Vérifiez que les 3 nœuds sont `Ready`.
    ```bash
    talosctl kubeconfig .
    kubectl --kubeconfig=./kubeconfig get nodes
    ```

2.  **Automatisation de Vault (Ansible) :**
    ```bash
    ANSIBLE_COLLECTIONS_PATH=./collections ansible-playbook -i "localhost," automation/ansible-vault/vault_setup.yml
    ```
    *Ce playbook teste l'automatisation en créant le moteur de secrets `projet-web`.*

---

## 4. 🧹 Nettoyage

Pour supprimer toute l'infrastructure d'un coup (VMs et disques) :

```bash
terraform destroy -auto-approve
