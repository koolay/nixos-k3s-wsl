{
  description = "NixOS-WSL k3s flake for building and distribution";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-wsl, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # 导入镜像打包文件
      # k3sImagesTarball = import ./k3s-images.nix { inherit pkgs; };
      # Fix the pkgs specialArgs warning by using nixpkgs.pkgs instead
      nixosConfig = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          # inherit inputs k3sImagesTarball;
        };
        modules = [
          ./configuration.nix
          nixos-wsl.nixosModules.default
          {
            # Set nixpkgs.pkgs to avoid the specialArgs warning
            nixpkgs.pkgs = pkgs;
            # Override any nixpkgs.config settings from configuration.nix
            # nixpkgs.config = {
            #   allowUnfree = true;
            # };
          }
        ];
      };
    in
    {
      # 构建包
      packages.${system} = {
        # Use the tarballBuilder for WSL distribution
        wsl-distro = nixosConfig.config.system.build.tarballBuilder;
        
        # k3s-images = k3sImagesTarball;
        default = self.packages.${system}.wsl-distro;
      };
      # NixOS 配置
      nixosConfigurations.nixos = nixosConfig;
      # 开发环境
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ kubectl kubernetes-helm k3s ];
        shellHook = ''
          echo "NixOS-WSL k3s development shell"
          echo "Commands: nix build .#wsl-distro | nix build .#k3s-images"
        '';
      };
    };
}
