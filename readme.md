# GitBroom 🧹  
智能Git分支清扫工具，精准识别和清理已合并分支，保持仓库整洁如新

## 🌟 核心能力
### 分支管理三剑客
🛡 **安全清理**  
智能识别已合并分支，双重校验保护关键分支

🔍 **深度扫描**  
支持三种扫描模式：  
```bash
# 快速扫描（默认）
./gitbroom.sh <repo-url> 
# 深度分析模式
./gitbroom.sh <repo-url> --scan-mode deep
```

📊 **数据洞察**  
生成多维清理报告：
- 📅 分支时间分布图
- 👥 开发者活跃度统计
- 📏 仓库瘦身指数

## 🚀 快速上手
### 安装方式
```bash
# 一键安装
curl -sSL https://git.io/gitbroom | bash
```

### 日常清理
```bash
# 典型工作流
gitbroom https://github.com/your-team/project.git \
  --protect main,dev \
  --backup \
  --interactive
```

## 📁 文件结构
```text
├── backups/           # 分支备份
├── reports/           # 清理报告
│   └── 2023-08-clean.html
└── gitbroom.log       # 操作日志
```

## 🔧 高级配置
### 环境变量
```bash
# 永久保护分支
export GITBROOM_PROTECTED="main,prod"
# 自动确认模式
export GITBROOM_AUTO_CONFIRM=1
```

### 定时任务
```cron
# 每周日凌晨清理
0 3 * * 0 /path/to/gitbroom.sh <repo-url> --silent
```

## 🤝 开源协作
欢迎通过以下方式参与贡献：
```bash
# 开发模式启动
make dev && ./gitbroom.sh --debug
```

## 📜 协议声明
本项目基于 [MIT License](LICENSE) 开源，使用请遵守：
- 禁止用于商业恶意软件
- 需保留原始版权声明

