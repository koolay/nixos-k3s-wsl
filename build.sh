#!/usr/bin/env bash

set -euo pipefail

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 清理旧构建
clean() {
    log "清理旧构建结果..."
    rm -rf result*
    success "清理完成"
}

# 构建 WSL 发行版
build() {
    log "构建 NixOS-WSL K3s 发行版..."
    
    if nix build .#wsl-distro --print-build-logs; then
        local size=$(du -h result | cut -f1)
        success "构建完成！大小: $size"
        log "文件位置: $(readlink -f result)"
    else
        error "构建失败"
        exit 1
    fi
}

# 构建镜像
build_images() {
    log "构建 K3s 镜像..."
    
    if nix build .#k3s-images --print-build-logs; then
        success "镜像构建完成"
        log "镜像位置: $(readlink -f result)"
    else
        error "镜像构建失败"
        exit 1
    fi
}

# 显示帮助
help() {
    echo "NixOS-WSL K3s 构建脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  build        构建 WSL 发行版 (默认)"
    echo "  images       仅构建 K3s 镜像"
    echo "  clean        清理构建结果"
    echo "  help         显示帮助"
    echo ""
    echo "示例:"
    echo "  $0           # 构建 WSL 发行版"
    echo "  $0 images    # 仅构建镜像"
    echo "  $0 clean     # 清理"
}

# 主函数
main() {
    case "${1:-build}" in
        build)
            clean
            build
            ;;
        images)
            clean
            build_images
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            help
            ;;
        *)
            error "未知命令: $1"
            help
            exit 1
            ;;
    esac
}

main "$@"
