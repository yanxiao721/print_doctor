# Print Doctor 部署说明

## Cloudflare 推荐方案

前期验证阶段建议部署到 Cloudflare Pages：

- 适合静态 Flutter Web 站点。
- 国内访问通常比 `vercel.app` 更稳。
- AI 请求通过 Cloudflare Worker 代理到 unifyapi，避免 token 暴露在前端。

## Cloudflare 环境变量

在 Pages / Worker 的环境变量里添加：

```env
OPENAI_API_KEY=你的 unifyapi token
AI_DIAGNOSIS_ENDPOINT=https://unifyapi.xyz/v1/responses
AI_DIAGNOSIS_MODEL=gpt-5.4
```

## 本地开发

本地临时调试继续使用：

```bash
./tool/run_ai.sh
```

## 线上构建

Cloudflare Pages 会先执行：

```bash
./tool/build_web.sh
```

前端会把 AI 地址写成同源代理：

```text
/api/diagnosis
```

## 代理接口

Cloudflare Worker 需要暴露一个 `/api/diagnosis`，职责是：

1. 接收前端请求。
2. 从服务端环境变量读取 `OPENAI_API_KEY`。
3. 转发到 unifyapi。
4. 原样返回响应给 Flutter Web。
