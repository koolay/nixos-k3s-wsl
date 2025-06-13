{
  config,
  pkgs,
  lib,
  k3sImagesTarball,
  ...
}:

let
  local-storage-yaml = pkgs.writeText "local-storage.yaml" ''
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: local-path-provisioner-service-account
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: local-path-provisioner-role
    rules:
    - apiGroups: [""]
      resources: ["nodes", "persistentvolumeclaims", "configmaps", "pods/log"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["endpoints", "persistentvolumes", "pods"]
      verbs: ["*"]
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["create", "patch"]
    - apiGroups: ["storage.k8s.io"]
      resources: ["storageclasses"]
      verbs: ["get", "list", "watch"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: local-path-provisioner-bind
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: local-path-provisioner-role
    subjects:
    - kind: ServiceAccount
      name: local-path-provisioner-service-account
      namespace: kube-system
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: local-path-provisioner
      namespace: kube-system
    spec:
      revisionHistoryLimit: 0
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 1
      selector:
        matchLabels:
          app: local-path-provisioner
      template:
        metadata:
          labels:
            app: local-path-provisioner
        spec:
          priorityClassName: "system-node-critical"
          serviceAccountName: local-path-provisioner-service-account
          tolerations:
              - key: "CriticalAddonsOnly"
                operator: "Exists"
              - key: "node-role.kubernetes.io/control-plane"
                operator: "Exists"
                effect: "NoSchedule"
              - key: "node-role.kubernetes.io/master"
                operator: "Exists"
                effect: "NoSchedule"
          nodeSelector:
            kubernetes.io/os: linux
          containers:
          - name: local-path-provisioner
            image: "rancher/local-path-provisioner:v0.0.31"
            imagePullPolicy: IfNotPresent
            command:
            - local-path-provisioner
            - start
            - --config
            - /etc/config/config.json
            volumeMounts:
            - name: config-volume
              mountPath: /etc/config/
            env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          volumes:
            - name: config-volume
              configMap:
                name: local-path-config
    ---
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: local
      annotations:
        defaultVolumeType: "local"
        storageclass.kubernetes.io/is-default-class: "true"
    provisioner: rancher.io/local-path
    volumeBindingMode: WaitForFirstConsumer
    reclaimPolicy: Delete
    ---
    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: local-path-config
      namespace: kube-system
    data:
      config.json: |-
        {
          "nodePathMap":[
          {
            "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
            "paths":["/var/localpv"]
          }
          ]
        }
      setup: |-
        #!/bin/sh
        set -eu
        mkdir -m 0777 -p "''${VOL_DIR}"
        chmod 700 "''${VOL_DIR}/.."
      teardown: |-
        #!/bin/sh
        set -eu
        rm -rf "''${VOL_DIR}"
      helperPod.yaml: |-
        apiVersion: v1
        kind: Pod
        metadata:
          name: helper-pod
        spec:
          containers:
          - name: helper-pod
            image: "rancher/mirrored-library-busybox:1.36.1"
            imagePullPolicy: IfNotPresent
  '';
in
{

    # 用户配置
    users.users.pieter = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = ["wheel"];
    };

    # Home Manager 配置 (新添加的部分)
    home-manager.users.pieter = {
      # home-manager 会自动创建 ~/.zshrc
      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;    # 使用 home-manager 的正确选项
        enableSyntaxHighlighting = true; # 使用 home-manager 的正确选项
        # 将别名移动到这里，更符合用户配置的逻辑
        shellAliases = {
          k = "kubectl";
          kgp = "kubectl get pods";
          kgs = "kubectl get services";
        };
      };

      # 将用户工具包移动到这里
      home.packages = with pkgs; [
        fzf
        ripgrep
      ];

      # 将用户环境变量移动到这里
      home.sessionVariables = {
        KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
      };

      # 关键：这确保 home-manager 知道如何管理你的家目录
      home.stateVersion = "24.05";
    };

    # WSL 配置
    wsl = {
      enable = true;
      defaultUser = "pieter";
      wslConf.automount.root = "/mnt";
      wslConf.interop.appendWindowsPath = false;
      wslConf.network.generateHosts = false;
      startMenuLaunchers = true;
    };

    # 基础配置
    networking.hostName = "k3s-wsl";
    time.timeZone = "Asia/Shanghai";

    # 系统软件包
    environment.systemPackages = with pkgs; [
      vim git curl wget jq
      kubectl kubernetes-helm
      zsh fzf ripgrep
    ];

    # Shell 配置
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };

    # K3s 服务配置
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = [
        "--https-listen-port=7443"
        "--flannel-iface=eth0"
        "--disable=traefik"
        "--disable=servicelb"
        "--disable=local-storage"
        "--write-kubeconfig-mode=644"
      ];
    };

    # 容器镜像配置
    environment.etc."rancher/k3s/agent/images/k3s-airgap-images-amd64.tar.gz" = {
      source = k3sImagesTarball; # k3sImagesTarball 现在是下载的 .tar.zst 文件
      mode = "0644";
    };

    environment.etc."k3s/custom/local-storage.yaml" = {
      source = local-storage-yaml;
      mode = "0644";
    };

    systemd.tmpfiles.rules = [
      # 格式: 类型 路径       模式  用户  组  年龄  目标
      # L+ 表示如果路径不存在，就递归创建父目录并建立符号链接
      "L+ /var/lib/rancher/k3s/agent/images - - - - /etc/rancher/k3s/agent/images"
      "L /var/lib/rancher/k3s/server/manifests/00-local-storage.yaml - - - - /etc/k3s/custom/local-storage.yaml"
    ];

    # 网络配置
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 6443 7443 10250 8080 ];
      allowedUDPPorts = [ 8472 ];
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # Nix 配置
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        trusted-users = ["root" "pieter"];
        substituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://nix-community.cachix.org"
          "https://cache.nixos.org/"
        ];
      };
    };

    # 环境变量
    environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

    # 别名
    environment.shellAliases = {
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
    };

    system.stateVersion = "24.05";

}
