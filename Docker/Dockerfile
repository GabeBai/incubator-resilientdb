# 使用官方的 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置时区（可选）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 更新APT包列表并安装常用软件和依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    git \
    vim \
    ca-certificates \
    sudo \
    tzdata \
    && rm -rf /var/lib/apt/lists/*


# 拷贝本地的文件（如果需要）
# COPY ./localfile /home/$USERNAME/localfile

# 添加一个长期运行的命令，防止容器退出
CMD ["tail", "-f", "/dev/null"]