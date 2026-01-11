#!/bin/bash

# ZeroNews LazyCat 应用构建和发布脚本
# 支持构建、镜像复制、发布等完整流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用信息（从 manifest 读取）
APP_NAME="ZeroNews"
APP_VERSION="1.0.0"
PACKAGE_NAME="cloud.lazycat.app.zeronews"
ORIGINAL_IMAGE="zeronews/zeronews:latest"

# 打印函数
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 检查必要文件
check_files() {
    print_header "检查必要文件"

    local files=(
        "lzc-manifest.yml"
        "lzc-deploy-params.yml"
        "lzc-build.yml"
        "content/index.html"
    )

    local missing=0
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file 存在"
        else
            print_error "$file 不存在"
            missing=1
        fi
    done

    if [ ! -f "icon.png" ]; then
        print_warning "icon.png 不存在，需要手动提供 512x512 PNG 图标"
    fi

    if [ $missing -eq 1 ]; then
        print_error "缺少必要文件，请检查"
        return 1
    fi

    print_success "所有必要文件检查完成"
    return 0
}

# 验证配置
validate_config() {
    print_header "验证配置文件"

    # 检查 YAML 格式（简单检查）
    if command -v yamllint &> /dev/null; then
        yamllint lzc-manifest.yml && print_success "lzc-manifest.yml 格式正确" || print_warning "yamllint 检查失败"
        yamllint lzc-deploy-params.yml && print_success "lzc-deploy-params.yml 格式正确" || print_warning "yamllint 检查失败"
    else
        print_info "yamllint 未安装，跳过 YAML 格式检查"
    fi

    # 检查是否包含 min_os_version
    if grep -q "min_os_version:" lzc-manifest.yml; then
        print_success "包含 min_os_version 字段"
    else
        print_warning "建议添加 min_os_version: 1.3.8"
    fi
}

# 显示应用信息
show_info() {
    print_header "应用信息"

    echo -e "${BLUE}应用名称:${NC} $APP_NAME"
    echo -e "${BLUE}应用版本:${NC} $APP_VERSION"
    echo -e "${BLUE}包名:${NC} $PACKAGE_NAME"
    echo -e "${BLUE}原始镜像:${NC} $ORIGINAL_IMAGE"
    echo ""

    print_info "配置参数:"
    echo "  - zeronews_token: ZeroNews 认证令牌（必填）"
    echo ""

    print_info "存储路径:"
    echo "  - /lzcapp/var/config: ZeroNews 配置目录"
    echo ""

    print_info "特性:"
    echo "  - background_task: true (后台服务)"
    echo "  - network_mode: host (主机网络模式)"
    echo "  - 包含介绍页面: content/index.html"
}

# 构建应用
build_app() {
    print_header "构建应用"

    if ! check_files; then
        return 1
    fi

    if [ ! -f "icon.png" ]; then
        print_error "请先提供 icon.png 文件（512x512 PNG）"
        return 1
    fi

    local output_file="${PACKAGE_NAME}-${APP_VERSION}.lpk"

    print_info "开始构建: $output_file"

    if lzc-cli project build -o "$output_file"; then
        print_success "构建成功: $output_file"
        ls -lh "$output_file"
        return 0
    else
        print_error "构建失败"
        return 1
    fi
}

# 复制镜像到懒猫仓库
copy_image() {
    print_header "复制镜像到懒猫仓库"

    # 检查登录状态
    if ! lzc-cli appstore my-images &> /dev/null 2>&1; then
        print_warning "未登录懒猫应用商店"
        print_info "请先执行: lzc-cli appstore login"
        return 1
    fi

    print_info "正在复制镜像: $ORIGINAL_IMAGE"
    print_warning "这可能需要几分钟时间，请耐心等待..."

    # 执行镜像复制
    local result
    result=$(lzc-cli appstore copy-image "$ORIGINAL_IMAGE" 2>&1)

    if echo "$result" | grep -q "uploaded:"; then
        local new_image
        new_image=$(echo "$result" | grep "^uploaded:" | awk '{print $2}')

        print_success "镜像复制成功"
        print_info "新镜像: $new_image"

        # 更新 manifest 文件
        print_info "更新 manifest 文件..."
        update_manifest_image "$new_image"

        print_success "manifest 已更新，请重新构建应用"
        return 0
    else
        print_error "镜像复制失败"
        echo "$result"
        return 1
    fi
}

# 更新 manifest 中的镜像
update_manifest_image() {
    local new_image=$1

    # 备份原文件
    cp lzc-manifest.yml lzc-manifest.yml.bak

    # 更新镜像（保留原镜像作为注释）
    sed -i.tmp "/image: zeronews\/zeronews:latest/s|^|    # |" lzc-manifest.yml
    sed -i.tmp "/# image: zeronews\/zeronews:latest/a\\    image: $new_image" lzc-manifest.yml
    rm -f lzc-manifest.yml.tmp

    print_success "lzc-manifest.yml 已更新"
}

# 发布到应用商店
publish_app() {
    print_header "发布到应用商店"

    # 检查登录状态
    if ! lzc-cli appstore my-images &> /dev/null 2>&1; then
        print_warning "未登录懒猫应用商店"
        print_info "请先执行: lzc-cli appstore login"
        return 1
    fi

    local lpk_file="${PACKAGE_NAME}-${APP_VERSION}.lpk"

    if [ ! -f "$lpk_file" ]; then
        print_error "找不到 LPK 文件: $lpk_file"
        print_info "请先构建应用"
        return 1
    fi

    print_info "发布应用: $lpk_file"

    if lzc-cli appstore publish "$lpk_file"; then
        print_success "发布成功"
        print_info "应用已提交审核，请等待 1-3 天审核结果"
        return 0
    else
        print_error "发布失败"
        return 1
    fi
}

# 一键构建+镜像复制+发布
one_click_publish() {
    print_header "一键构建+镜像复制+发布"

    print_info "阶段 1: 初始构建（原始镜像）"
    if ! build_app; then
        print_error "初始构建失败"
        return 1
    fi

    echo ""
    print_info "阶段 2: 镜像复制（自动更新 manifest）"
    if ! copy_image; then
        print_warning "镜像复制失败，使用原始镜像继续"
    fi

    echo ""
    print_info "阶段 3: 重新构建（新镜像）"
    if ! build_app; then
        print_error "重新构建失败"
        return 1
    fi

    echo ""
    print_info "阶段 4: 发布审核"
    if ! publish_app; then
        print_error "发布失败"
        return 1
    fi

    print_success "一键发布完成！"
}

# 主菜单
show_menu() {
    clear
    print_header "$APP_NAME 构建和发布工具"
    echo ""
    echo "1. 📦 构建应用 (Build)"
    echo "2. 🔧 镜像复制到懒猫仓库 (Copy Image)"
    echo "3. 📤 发布到应用商店 (Publish)"
    echo "4. 🚀 一键构建+镜像复制+发布 (One-Click)"
    echo "5. 📋 查看应用信息 (Info)"
    echo "6. ✅ 检查文件 (Check Files)"
    echo "7. 🔍 验证配置 (Validate)"
    echo "8. ❌ 退出"
    echo ""
    echo -n "请选择操作 [1-8]: "
}

# 主循环
main() {
    if [ "$1" == "--build" ]; then
        build_app
        exit $?
    elif [ "$1" == "--copy-image" ]; then
        copy_image
        exit $?
    elif [ "$1" == "--publish" ]; then
        publish_app
        exit $?
    elif [ "$1" == "--one-click" ]; then
        one_click_publish
        exit $?
    elif [ "$1" == "--info" ]; then
        show_info
        exit 0
    fi

    while true; do
        show_menu
        read -r choice

        case $choice in
            1)
                echo ""
                build_app
                ;;
            2)
                echo ""
                copy_image
                ;;
            3)
                echo ""
                publish_app
                ;;
            4)
                echo ""
                one_click_publish
                ;;
            5)
                echo ""
                show_info
                ;;
            6)
                echo ""
                check_files
                ;;
            7)
                echo ""
                validate_config
                ;;
            8)
                print_info "退出"
                exit 0
                ;;
            *)
                print_error "无效选择"
                ;;
        esac

        echo ""
        echo -n "按 Enter 继续..."
        read -r
    done
}

main "$@"
