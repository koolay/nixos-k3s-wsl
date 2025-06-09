{
  description = "NixOS-WSL k3s flake for building and distribution";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }@inputs:
    # 使用 nixpkgs.lib.eachDefaultSystem 迭代支持的系统架构
    # 这使得你的 flake 可以轻松地在 x86_64 和 aarch64 (如 M1/M2 Mac 上的 aarch64-linux VM) 上构建
    nixpkgs.lib.eachDefaultSystem (system:
      let
        # 为当前系统架构创建 pkgs 实例
        pkgs = import nixpkgs {
          inherit system;
          # 如果你有 overlays, 可以在这里添加
          # overlays = [ ... ];
        };

        # 【新增】在这里导入我们创建的镜像打包文件
        k3sImagesTarball = import ./k3s-images.nix { inherit pkgs; };

        # 将 NixOS 配置提取出来，以便在多个地方使用
        nixosConfig = nixpkgs.lib.nixosSystem {
          inherit system;
          # 通过 specialArgs 将镜像包传递给 configuration.nix
          specialArgs = {
            inherit inputs pkgs;
            # 将打包好的镜像 tarball 作为一个特殊参数传递下去
            k3sImagesTarball = k3sImagesTarball;
          };

          modules = [
            ./configuration.nix
            nixos-wsl.nixosModules.default
          ];
        };
      in
      {
        # 输出 1: 用于 `nixos-rebuild switch` 的常规系统配置
        nixosConfigurations.nixos = nixosConfig;

        # 输出 2: 用于构建 WSL 压缩包的 package
        packages.wsl-distro = nixos-wsl.lib.buildWSLDistro {
          name = "nixos-wsl-distro";
          configuration = nixosConfig;
        };

        # (可选) 提供一个默认的 package，这样可以直接运行 `nix build`
        defaultPackage = self.packages.${system}.wsl-distro;
      });
}
