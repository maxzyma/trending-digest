# 通过工作负载身份联合（Workload Identity Federation）安全访问 Claude 平台

> Secure access to the Claude Platform with Workload Identity Federation

工作负载身份联合（Workload Identity Federation，WIF）现已在 Claude 平台正式发布（generally available）。WIF 兼容任何符合 OIDC 规范的身份提供方（identity provider），并覆盖所有 Claude API 端点，包括通过我们的第一方 SDK 和 Claude Code 访问这些端点的场景。

> Workload Identity Federation (WIF) is now generally available on the Claude Platform. WIF is compatible with any OIDC-compliant identity provider and covers all Claude API endpoints, including when accessing the endpoints through our first-party SDKs and Claude Code.

通过面向工作负载的 WIF 以及面向交互式会话的 ant auth login，开发者在使用 Claude 平台构建应用时，无需再处理静态 API 密钥。

> With WIF for workloads and [ant auth login](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/quickstart#authentication) for interactive sessions, developers never have to handle a static API key when building with the Claude Platform.

### 工作负载身份联合（Workload Identity Federation）的工作原理

> How Workload Identity Federation works

WIF 用请求时签发的短期、限定范围凭证取代静态 API 密钥。无论你是运行 GitHub Actions 的两人初创团队，还是拥有详细凭证策略的企业，现在都能以与认证技术栈其余部分相同的方式认证 Claude 平台。

> WIF replaces static API keys with short-lived, scoped credentials issued at request time. Whether you're a two-person startup running GitHub Actions or an enterprise with detailed credential policies, you can now authenticate with the Claude Platform the same way you authenticate with the rest of your stack.

使用 WIF，无需创建、轮换或担心泄露任何静态的 Anthropic 凭证。工作负载使用其已有的身份进行认证：AWS IAM 角色、GCP 或 Kubernetes 服务账户、Azure 托管身份、GitHub Actions 令牌、Okta 或其他符合 OIDC 标准的提供方。

> With WIF, there are no static Anthropic credentials to create, rotate, or leak. Workloads authenticate with the identity they already have: an AWS IAM role, a GCP or Kubernetes service account, an Azure managed identity, a GitHub Actions token, Okta, or other OIDC-compliant providers.

我们还在 Claude 平台中引入了服务账户（service accounts），使每个工作负载都能拥有自己的身份、角色和审计记录，而不再共用一个 API 密钥。首先，由联合规则（federation rule）将外部身份绑定到某个服务账户。随后，当工作负载请求访问时，Claude 平台会验证该工作负载签名的 OIDC 令牌，将其声明（claims）与你的联合规则进行匹配，并签发一个受该服务账户角色限定的短期访问令牌。每一次令牌交换和请求都会以该服务账户的名义记录在你的审计日志中。

> We're also introducing service accounts to the Claude Platform, so each workload can have its own identity, roles, and audit trail instead of a shared API key. First, a federation rule binds an external identity to a service account. Then, when a workload requests access, the Claude Platform verifies the workload's signed OIDC token, matches its claims against your federation rules, and issues a short-lived access token bounded by the service account's roles. Every exchange and request is recorded against that service account in your audit logs.

### 几分钟内配置你的第一个工作负载

> Set up your first workload in minutes

Claude Console 提供了引导式配置流程，用于设置工作负载身份（workload identity）。该流程会逐步验证每一步，并在最后提供一条测试命令，确认你的工作负载能够完成身份验证。

> The [Claude Console](https://platform.claude.com/) has a guided setup flow for configuring workload identities. The setup validates each step and finishes with a test command that confirms your workload can authenticate.

![](https://cdn.prod.website-files.com/68a44d4040f98a4adf2207b6/6a2f08711ad72d3a0d542c25_Screenshot%202026-06-13%20at%209.20.12%E2%80%AFAM.png)

### 无需静态密钥即可运行整个组织

> Run your whole organization without static keys

WIF 与用于组织管理的管理 API（Admin API）兼容。可以通过细粒度作用域（scope）配置联合（federation）规则，实现最小权限访问。

> WIF is compatible with the [Admin API](https://platform.claude.com/docs/en/build-with-claude/administration-api) for organization management. Federation rules can be configured for least-privilege access through fine-grained scopes. 

对于大规模运营的组织，联合配置也完全支持编程方式实现。新增的管理 API 端点让你能够创建和更新签发者（issuer）、服务账户和联合规则。

> Federation configuration is also fully programmatic for organizations operating at scale. New Admin API endpoints let you create and update issuers, service accounts, and federation rules.
