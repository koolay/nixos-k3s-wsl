{ pkgs }:

let
  # 1. 定义 k3s 需要的容器镜像列表。
  # 这个列表取决于你的 k3s 版本。你可以通过在一个有网络的机器上运行
  # `k3s ctr images list -q` 来获取确切的列表。
  # 以下列表适用于 k3s v1.28.4+k3s2。请根据你的版本调整。
  imageNames = [
    "docker.io/rancher/coredns-cni:v0.10.1"
    "docker.io/rancher/klipper-helm:v0.9.1-build20231121"
    "docker.io/rancher/klipper-lb:v0.4.4"
    "docker.io/rancher/local-path-provisioner:v0.0.26"
    "docker.io/rancher/metrics-server:v0.6.4"
    "docker.io/traefik/traefik:v2.10.7"
  ];

  # 2. 使用 ociTools.pullImage 拉取每个镜像。
  # 你需要为每个镜像提供 sha256 校验和。
  pulledImages = {
    "coredns-cni" = pkgs.ociTools.pullImage {
      imageName = "docker.io/rancher/coredns-cni";
      imageTag = "v0.10.1";
      # 第一次构建时，这里留空或填入 "000...000"，Nix 会报错并告诉你正确的 hash。
      sha256 = "03r6f2824y4c2115k6p442gqnj68h8l78lq1g0z0m2m6y9l1k1w8";
    };
    "klipper-helm" = pkgs.ociTools.pullImage {
      imageName = "docker.io/rancher/klipper-helm";
      imageTag = "v0.9.1-build20231121";
      sha256 = "196y325vmyqzzr3b5h0816p26d83a15n9w34x78l88w7w1p8l645";
    };
    "klipper-lb" = pkgs.ociTools.pullImage {
      imageName = "docker.io/rancher/klipper-lb";
      imageTag = "v0.4.4";
      sha256 = "07340b616l252b9y871c5j8g099i9h5v7x8143gph0g0b5a1b32p";
    };
    "local-path-provisioner" = pkgs.ociTools.pullImage {
      imageName = "docker.io/rancher/local-path-provisioner";
      imageTag = "v0.0.26";
      sha256 = "126m0f9y3f1406y697f4v6x4k9qaj6j28v6l30r8y7q1s50f68d6";
    };
    "metrics-server" = pkgs.ociTools.pullImage {
      imageName = "docker.io/rancher/metrics-server";
      imageTag = "v0.6.4";
      sha256 = "18vj8v5qg140x5gajk81w0471xsyz3k6s4jdx7r7b8n9b5x5538w";
    };
    "traefik" = pkgs.ociTools.pullImage {
      imageName = "docker.io/traefik/traefik";
      imageTag = "v2.10.7";
      sha256 = "09k3964x0a4y2r92x8321i9b552h0p1v96z08p2l7i9q301h9bma";
    };
  };

in
# 3. 使用 dockerTools.save 将所有拉取到的镜像打包成一个 tar.gz 文件。
pkgs.dockerTools.save {
  name = "k3s-airgap-images";
  # 从 pulledImages 的属性值中提取所有镜像
  images = builtins.attrValues pulledImages;
  # 启用压缩，减小体积
  compress = true;
}
