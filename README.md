# nixos-k3s-wsl

nixos + k3s + wsl

## Debug

```bash

sudo nixos-rebuild switch --flake .#nixos
systemctl status k3s
kubectl get nodes

```

## Build

```bash

# 构建 WSL 发行版
chmod +x build.sh
./build.sh

# 仅构建镜像
./build.sh images

# 清理
./build.sh clean

# 直接使用 nix
nix build .#wsl-distro
nix build .#k3s-images

```

## Build k3s 工作流程总结

1.  **构建时 (`nix build .#wsl-distro`)**：

    - `flake.nix` 调用 `k3s-images.nix`。
    - `k3s-images.nix` 连接网络，从 Docker Hub 等地上拉取所有指定的容器镜像，并验证其 SHA256 哈希。
    - 所有镜像被打包成一个 `/nix/store/xxxxx-k3s-airgap-images.tar.gz` 文件。
    - `configuration.nix` 创建一个符号链接：`/etc/rancher/k3s/agent/images/k3s-airgap-images.tar.gz` -> `/nix/store/xxxxx-k3s-airgap-images.tar.gz`。
    - 最终的 `nixos-wsl-distro.tar.gz` 被创建，它包含了 k3s 二进制文件和这个镜像包的引用。

2.  **运行时 (首次在 WSL 中启动)**：
    - 您将 `nixos-wsl-distro.tar.gz` 导入到一个**没有网络**的 WSL 实例中。
    - 系统启动，`systemd` 启动 `k3s.service`。
    - k3s 服务进程启动，它会检查 `/var/lib/rancher/k3s/agent/images/` 目录。
    - 它发现了我们放置的 `k3s-airgap-images.tar.gz`。
    - 它**自动**解压并导入这个包里的所有容器镜像到它自己的内部 `containerd` 存储中。
    - k3s 使用这些本地可用的镜像启动所有核心组件（CoreDNS, Traefik 等）。
    - 整个集群成功启动，**全程无需访问外部网络**。
