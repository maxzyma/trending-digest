---
source: claude-blog
source_url: https://claude.com/blog/workload-identity-federation
published_at: 2026-06-17
category: Product announcements
title_en: Secure access to the Claude Platform with Workload Identity Federation
title_zh: 通过工作负载身份联合（Workload Identity Federation）安全访问 Claude 平台
source_intro_paragraphs: 2
source_image_count: 1
ding_doc_url: "https://alidocs.dingtalk.com/i/nodes/20eMKjyp81RNa19eUeDqMNAyWxAZB1Gv"
---

# 通过工作负载身份联合（Workload Identity Federation）安全访问 Claude 平台

> 来源：Claude Blog，2026-06-17
> 原文链接：https://claude.com/blog/workload-identity-federation
> 分类：Product announcements

## 导语

工作负载身份联合（Workload Identity Federation，WIF）现已在 Claude 平台正式发布（generally available）。WIF 兼容任何符合 OIDC 规范的身份提供方（identity provider），并覆盖所有 Claude API 端点，包括通过我们的第一方 SDK 和 Claude Code 访问这些端点的场景。

## 核心要点

- 工作负载身份联合（WIF）现已在 Claude 平台正式发布，兼容任何符合 OIDC 规范的身份提供方。
- WIF 用请求时签发的短期、限定范围凭证（short-lived, scoped credentials）取代静态 API 密钥，无需创建、轮换或担心密钥泄露。
- 工作负载可使用其已有身份进行认证，如 AWS IAM 角色、GCP 或 Kubernetes 服务账户、Azure 托管身份、GitHub Actions 令牌、Okta 等。
- 平台新增服务账户（service accounts），每个工作负载可拥有独立的身份、角色和审计记录，而非共享 API 密钥。
- Claude Console 提供引导式配置流程，可在数分钟内完成工作负载身份的设置与验证。
- WIF 兼容用于组织管理的 Admin API，并提供全程可编程的联合配置能力。

## 中文译文

工作负载身份联合（Workload Identity Federation，WIF）现已在 Claude 平台正式发布（generally available）。WIF 兼容任何符合 OIDC 规范的身份提供方（identity provider），并覆盖所有 Claude API 端点，包括通过我们的第一方 SDK 和 Claude Code 访问这些端点的场景。

借助面向工作负载的 WIF 以及用于交互式会话的 `ant auth login`，开发者在使用 Claude 平台进行构建时，无需再处理任何静态 API 密钥。

### 工作负载身份联合的工作原理

WIF 用请求时签发的短期、限定范围凭证（short-lived, scoped credentials）取代静态 API 密钥。无论你是运行 GitHub Actions 的两人初创团队，还是拥有详尽凭证策略的企业，现在都可以用与认证其余技术栈相同的方式来认证 Claude 平台。

使用 WIF 后，不再有需要创建、轮换或可能泄露的静态 Anthropic 凭证。工作负载使用其已有的身份进行认证：AWS IAM 角色、GCP 或 Kubernetes 服务账户、Azure 托管身份（managed identity）、GitHub Actions 令牌、Okta，或其他符合 OIDC 规范的提供方。

我们还为 Claude 平台引入了服务账户（service accounts），这样每个工作负载都可以拥有自己的身份、角色和审计记录，而非共享同一个 API 密钥。首先，联合规则（federation rule）会将一个外部身份绑定到某个服务账户。随后，当某个工作负载请求访问时，Claude 平台会验证该工作负载已签名的 OIDC 令牌，将其声明（claims）与你的联合规则进行匹配，并签发一个受该服务账户角色限定的短期访问令牌（access token）。每一次令牌交换和请求都会在你的审计日志中以该服务账户的名义被记录下来。

### 几分钟内完成首个工作负载的设置

Claude Console 提供了用于配置工作负载身份的引导式设置流程。该设置会对每一步进行校验，并以一条测试命令收尾，用于确认你的工作负载能够成功认证。

![Image 1](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a2f08711ad72d3a0d542c25_Screenshot%202026-06-13%20at%209.20.12%E2%80%AFAM.png)

### 在没有静态密钥的情况下运行整个组织

WIF 兼容用于组织管理的 Admin API。可以通过细粒度范围（fine-grained scopes）配置联合规则，以实现最小权限访问（least-privilege access）。

对于大规模运行的组织，联合配置也完全可编程。新的 Admin API 端点允许你创建和更新签发方（issuers）、服务账户和联合规则。

## 术语对照

| English | 中文 |
|---|---|
| Workload Identity Federation (WIF) | 工作负载身份联合 |
| OIDC-compliant identity provider | 符合 OIDC 规范的身份提供方 |
| static API key | 静态 API 密钥 |
| short-lived, scoped credentials | 短期、限定范围凭证 |
| service account | 服务账户 |
| federation rule | 联合规则 |
| claims | 声明 |
| access token | 访问令牌 |
| managed identity | 托管身份 |
| fine-grained scopes | 细粒度范围 |
| least-privilege access | 最小权限访问 |
| issuer | 签发方 |
| generally available | 正式发布 |
