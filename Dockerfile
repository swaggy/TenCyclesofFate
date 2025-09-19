# 浮生十梦 - TenCyclesofFate Docker配置
# 多阶段构建，优化最终镜像大小

# 第一阶段：构建依赖环境
FROM python:3.11-slim AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY backend/requirements.txt .

# 安装Python依赖到本地目录
RUN pip install --no-cache-dir --user -r requirements.txt

# 第二阶段：运行时环境
FROM python:3.11-slim

# 创建非root用户
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -m appuser

# 设置工作目录
WORKDIR /app

# 安装运行时系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 从builder阶段复制Python包
COPY --from=builder /root/.local /home/appuser/.local

# 复制应用代码
COPY backend/ ./backend/
COPY frontend/ ./frontend/
# 复制游戏数据文件（如果存在）
COPY game_data.json* ./

# 创建必要的目录并设置权限
RUN mkdir -p /app/logs && \
    chown -R appuser:appgroup /app

# 切换到非root用户
USER appuser

# 将用户本地bin添加到PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# 暴露端口
EXPOSE 8000

# 设置环境变量
ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=8000
ENV UVICORN_RELOAD=false

# 默认环境变量（敏感信息必须通过环境变量或.env文件提供）
ENV OPENAI_BASE_URL="https://api.openai.com/v1"
ENV OPENAI_MODEL="gpt-3.5-turbo"
ENV OPENAI_MODEL_CHEAT_CHECK="gpt-3.5-turbo"
ENV ALGORITHM="HS256"
ENV DATABASE_URL="sqlite:///veloera.db"

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/live/players || exit 1

# 启动命令
CMD ["python", "-m", "uvicorn", "backend.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
