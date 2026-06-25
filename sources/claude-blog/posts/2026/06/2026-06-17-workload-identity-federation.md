---
source: claude-blog
source_url: https://claude.com/blog/workload-identity-federation
published_at: 2026-06-17
category: Product announcements
title_en: Secure access to the Claude Platform with Workload Identity Federation
title_zh: 使用工作负载身份联合（Workload Identity Federation）安全访问 Claude 平台
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/6LeBq413JAzGDpRXC3EKNMxR8DOnGvpb"
---

# 使用工作负载身份联合（Workload Identity Federation）安全访问 Claude 平台

> 来源：Claude Blog，2026-06-17
> 原文链接：https://claude.com/blog/workload-identity-federation
> 分类：Product announcements

## 核心要点

- 工作负载身份联合（Workload Identity Federation，WIF）现已在 Claude 平台正式可用，兼容任何符合 OIDC 标准的身份提供方，并覆盖所有 Claude API 端点（包括通过第一方 SDK 和 Claude Code 访问的端点）。
- WIF 以请求时签发的短时、限定范围凭据取代静态 API 密钥，无需创建、轮换或担心密钥泄露。
- 工作负载可使用其已有的身份进行认证，例如 AWS IAM 角色、GCP 或 Kubernetes 服务账户、Azure 托管身份、GitHub Actions 令牌、Okta 等 OIDC 兼容提供方。
- 平台引入了服务账户（service accounts），使每个工作负载拥有独立的身份、角色和审计记录。
- 通过联合规则将外部身份绑定到服务账户，平台验证签名的 OIDC 令牌并签发受角色边界约束的短时访问令牌。
- Claude 控制台提供引导式配置流程，并支持通过 Admin API 进行完全程序化的联合配置。

## 中文译文

工作负载身份联合（Workload Identity Federation，WIF）现已在 Claude 平台正式可用（generally available）。WIF 兼容任何符合 OIDC 标准的身份提供方，并覆盖所有 Claude API 端点，包括通过我们的第一方 SDK 和 Claude Code 访问这些端点的场景。

借助面向工作负载的 WIF，以及面向交互式会话的 `ant auth login`，开发者在基于 Claude 平台进行构建时，再也无需处理静态 API 密钥。

### 工作负载身份联合的工作原理

WIF 以请求时签发的短时、限定范围（scoped）凭据，取代静态 API 密钥。无论你是运行 GitHub Actions 的两人初创团队，还是拥有详尽凭据策略的企业，现在都可以像认证技术栈中其余部分那样，对 Claude 平台进行认证。

使用 WIF 后，不再有需要创建、轮换或可能泄露的静态 Anthropic 凭据。工作负载使用其已有的身份进行认证：AWS IAM 角色、GCP 或 Kubernetes 服务账户、Azure 托管身份、GitHub Actions 令牌、Okta，或其他符合 OIDC 标准的提供方。

我们还向 Claude 平台引入了服务账户（service accounts），使每个工作负载都能拥有自己的身份、角色和审计记录，而不再共用一个 API 密钥。首先，联合规则（federation rule）将一个外部身份绑定到某个服务账户。随后，当某个工作负载请求访问时，Claude 平台会验证该工作负载签名后的 OIDC 令牌，将其声明（claims）与你的联合规则进行匹配，并签发一个受该服务账户角色边界约束的短时访问令牌。每一次令牌交换和请求都会针对该服务账户记录在你的审计日志中。

### 几分钟内完成你的首个工作负载配置

Claude 控制台（Claude Console）提供了引导式（guided）配置流程，用于设置工作负载身份。该流程会对每一步进行校验，并以一条测试命令结束，用于确认你的工作负载能够成功认证。

### 在不使用静态密钥的情况下运行整个组织

WIF 兼容用于组织管理的 Admin API。可以通过细粒度的范围（fine-grained scopes）配置联合规则，以实现最小权限（least-privilege）访问。

对于大规模运营的组织，联合配置也完全支持程序化操作。新的 Admin API 端点允许你创建和更新签发方（issuers）、服务账户和联合规则。

## 术语对照

| English | 中文 |
|---|---|
| Workload Identity Federation (WIF) | 工作负载身份联合 |
| OIDC-compliant identity provider | 符合 OIDC 标准的身份提供方 |
| static API key | 静态 API 密钥 |
| short-lived, scoped credentials | 短时、限定范围的凭据 |
| service account | 服务账户 |
| federation rule | 联合规则 |
| signed OIDC token | 签名的 OIDC 令牌 |
| claims | 声明 |
| access token | 访问令牌 |
| audit logs | 审计日志 |
| Claude Console | Claude 控制台 |
| Admin API | 管理 API |
| fine-grained scopes | 细粒度范围 |
| least-privilege access | 最小权限访问 |
| issuer | 签发方 |
| generally available | 正式可用 |
| IAM role | IAM 角色 |
| managed identity | 托管身份 |
