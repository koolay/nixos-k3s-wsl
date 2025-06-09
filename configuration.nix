{
  config,
  pkgs,
  k3sImagesTarball, # 从 specialArgs 传入的镜像包
  ...
}: {
  # ==================================
  # 用户和基础环境配置
  # ==================================
  users.users.pieter = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel", "networkmanager"];
  };

  wsl.defaultUser = "pieter";
  nix.settings.trusted-users = ["root" "pieter"];

  # 主机名
  networking.hostName = "wsl-dev";
  time.timeZone = "Asia/Shanghai";
  programs.zsh.enable = true;

  # ==================================
  # 系统软件包 (增加了 kubectl)
  # ==================================
  environment.systemPackages = with pkgs; [
    # 开发和日常工具
    zsh vim fzf ripgrep git jq curl wget unzip zip

    # Kubernetes 管理工具
    kubectl 
    kubernetes-helm
  ];

  # ==================================
  # Kubernetes (k3s) 自动启动配置
  # ==================================
  services.k3s = {
    enable = true;
    # 对于单节点集群，角色必须是 "server"
    role = "server";
    # 额外的启动参数，对 WSL 环境至关重要
    extraFlags = [
      # 明确告诉 k3s 的网络插件使用 WSL 的 'eth0' 接口。这是在 WSL 中成功运行 k3s 的关键！
      "--flannel-iface=eth0"
      "--disable=traefik"
      "--disable=servicelb"
    ];
  };

  # 将构建时打包的镜像 tarball 放置到 k3s 的自动导入目录
  environment.etc."rancher/k3s/agent/images/k3s-airgap-images.tar.gz" = {
    # source 指向我们在构建时创建的 tarball 文件 (它位于 /nix/store 中)
    source = k3sImagesTarball;
    # 确保文件权限正确
    mode = "0644";
  };

  # 关键：让普通用户可以访问 kubeconfig 文件
  # k3s 服务会创建 /etc/rancher/k3s/k3s.yaml，但默认只有 root 可读。
  # 此配置会将其权限设置为 644 (owner-rw, group-r, other-r)，以便 kubectl 可以读取它。
  environment.etc."rancher/k3s/k3s.yaml".mode = "0644";

  # ==================================
  # Nix & WSL 特定配置
  # ==================================
  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      substituters = [
        "https://hyprland.cachix.org"
        "https://cache.nixos.org"
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    startMenuLaunchers = true;
    nativeSystemd = true;
  };

  system.stateVersion = "24.05";
}
