{
  config,
  pkgs,
  lib,
  k3sImagesTarball,
  ...
}: {
  # 用户配置
  users.users.pieter = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
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
      "--flannel-iface=eth0"
      "--disable=traefik"
      "--disable=servicelb"
      "--write-kubeconfig-mode=644"
    ];
  };

  # 容器镜像配置
  environment.etc."rancher/k3s/agent/images/k3s-airgap-images.tar.gz" = {
    source = k3sImagesTarball;
    mode = "0644";
  };

  # 网络配置
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 6443 10250 ];
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
