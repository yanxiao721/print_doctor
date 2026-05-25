# Print Doctor 部署说明

## 推荐方式

前期验证阶段建议部署到 Vercel：

- 不需要自购域名，Vercel 会提供 `*.vercel.app` 链接。
- Flutter Web 静态文件放在 `build/web`。
- `/api/diagnosis` 由 Vercel Serverless Function 代理到 unifyapi，避免 token 暴露在前端。

## Vercel 环境变量

在 Vercel Project Settings -> Environment Variables 添加：

```env
OPENAI_API_KEY=你的 unifyapi token
AI_DIAGNOSIS_ENDPOINT=https://unifyapi.xyz/v1/responses
AI_DIAGNOSIS_MODEL=gpt-5.5
```

## 本地开发

本地临时调试可以继续使用：

```bash
./tool/run_ai.sh
```

## 线上构建

Vercel 会执行：

```bash
./tool/build_web.sh
```

这个脚本会把前端 AI 地址写成同源代理：

```text
/api/diagnosis
```

因此线上 Flutter Web 包里不会包含 `OPENAI_API_KEY`。
