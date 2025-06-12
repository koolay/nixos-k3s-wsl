{ pkgs }:

let
  # 使用 'let' 来定义局部变量
  k3sVersion = "v1.33.1%2Bk3s1";
in
  # 'in' 后面是 let 块的主体
  pkgs.fetchurl {
    # 现在我们可以在这里引用上面定义的 k3sVersion 变量
    url = "https://github.com/k3s-io/k3s/releases/download/${k3sVersion}/k3s-airgap-images-amd64.tar.gz";

    # 这是下载文件的 sha256 哈希值
    sha256 = "0b1078c30b3528fa4e8d97c414bcacadcfccbb49594314952da43b37043a1f20";
  }
