{ pkgs }:

let
  # 定义 k3s 需要的核心镜像
  images = {
    pause = {
      name = "registry.k8s.io/pause";
      tag = "3.9";
      sha256 = "0jphbq8qwfr5cl7mfqwsb2g23j4rrxxcz9sj98kcn3j66qswjkj6";
    };
    coredns = {
      name = "docker.io/rancher/mirrored-coredns-coredns";
      tag = "1.10.1";
      sha256 = "0w7w9w8z3h5x0p4m5k7v5xf1pz6j8y7z4k2q3n2h8s1w6x2f7g9j";
    };
    local-path-provisioner = {
      name = "docker.io/rancher/local-path-provisioner";
      tag = "v0.0.26";
      sha256 = "126m0f9y3f1406y697f4v6x4k9qaj6j28v6l30r8y7q1s50f68d6";
    };
    metrics-server = {
      name = "docker.io/rancher/mirrored-metrics-server-metrics-server";
      tag = "v0.6.4";
      sha256 = "1z4j2y7x8v8d8j7s9d8x5z1w6q4e8r7t3y2u1i0o9p8l7k6j5h4g";
    };
  };

  # 拉取所有镜像
  pulledImages = pkgs.lib.mapAttrs (name: config: 
    pkgs.dockerTools.pullImage {
      imageName = config.name;
      imageTag = config.tag;
      sha256 = config.sha256;
    }
  ) images;

in
pkgs.dockerTools.save {
  name = "k3s-airgap-images";
  images = builtins.attrValues pulledImages;
  compress = true;
}
