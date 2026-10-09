# Claude Code mods 入门

> Getting started with Claude Code mods

> 来源：Claude Blog / Anthropic，2026-10-01
> 原文链接：https://claude.dev/blog/getting-started-with-claude-code-mods/
> 分类：AI 编程工具 / Claude Code 扩展开发

## 核心要点

- mod 是在 Claude Code 会话中运行的小型 JavaScript 或 TypeScript 文件，底层是随插件发布的 hooks，能实时看到会话中的每个事件，需要 Claude Code 2.1.287 或更高版本且默认启用。
- 用户无需学习 API 即可让 Claude 根据描述编写 mod，允许热重载后 mod 会在本轮对话结束时出现，并可继续通过提示词微调。
- mod 文件夹是带有 plugin.json 清单的普通插件，hooks.json 指定唯一模块，模块导出 register(on, options)，通过 on(event, matcher?, hook) 注册钩子。
- 钩子像中间件一样组成链条，通过 next(e) 把事件传给下一个插件，模块运行在没有 DOM 和 Node 的独立沙箱中，所有外部交互都经由 $ 完成。
- 与每次事件运行一条 shell 命令的 settings hooks 不同，mod 只加载一次并持续整个会话，可以保持状态、绘制随事件更新的 UI，并回调 Claude Code 打开窗格、运行进程或注册命令和工具。
- Token Weather 示例通过 $.session.usage() 读取上下文窗口占用并在 AbovePrompt 区域绘制天气式预报，历史数据须存放在 $.state 中以便在热重载后保留，且状态值需在类型契约中声明。
- 在渲染钩子中读取 $.state 会自动订阅重绘，组件 props 位于 e.props 上，无内容可绘制时应返回 next(e) 让出区域，并使用单宽字符符号而非 emoji。
- claude plugin validate 用于检查清单和模块，claude plugin test 在真实运行时中执行测试，mod 可像普通插件一样通过 marketplace 分享，但因其拥有与 Claude Code 相同的权限，安装前应审阅代码并只信任可靠发布者。
- Blast Radius 拦截高风险 Bash 命令，用 $.process.run 执行试运行生成影响报告并提供 Proceed 与 Cancel 按钮，但它只读取命令文本，是安全网而非权限系统。
- Replay Theater 记录每轮的 Edit 和 Write 调用，通过 /replay 或按键打开窗格逐个 diff 回放编辑，演示了配对事件、注册斜杠命令和读取文件等用法。

## 正文

mod 是一个在 Claude Code 会话中运行的小型 JavaScript 或 TypeScript 文件。它可以观察正在发生的事情、改变 Claude Code 的行为，或者在终端或桌面应用中绘制自己的 UI。试用 mod 并不需要先学习 API。运行 `claude`，然后描述你想要的 mod。在系统询问时允许热重载，mod 就会在本轮对话结束时出现。

> A mod is a small JavaScript or TypeScript file that runs inside your Claude Code session. It can watch what's happening, change what Claude Code does, or draw its own UI, in the terminal or the desktop app. You don't need to learn the API to try one. Run `claude`, then describe the mod you want. Allow hot reload when it asks, and the mod shows up when the turn ends.

Claude Code 已经允许你对其行为进行大量定制：设置、权限规则、斜杠命令、技能以及状态栏。Mods 则更进一步：它们可以改写或替换 Claude Code 的行为，并绘制自定义 UI。在底层，mods 是随插件一同发布的 hooks，每个 mod 都能实时看到你会话中发生的每一个事件。

> Claude Code already lets you change a lot about how it behaves: settings, permission rules, slash commands, skills and a status line. Mods go further: they can rewrite or replace what Claude Code does, and draw custom UI. Under the hood, mods are hooks that ship inside plugins, and each one sees every event in your session as it happens.

这使得 mods 成为让 Claude Code 适配你工作方式的一种途径。你可以添加一个自己时常查看的状态读数，在那些让你不放心的命令前设置一道防护，或者按照你喜欢的阅读变更的方式，构建一个审查视图。

> That makes mods a way to fit Claude Code to how you work. You can add a readout you check all the time, put a guard in front of the commands that make you nervous, or build a review view for how you like to read changes.

本指南将从一个空文件夹开始构建一个 mod：**Token Weather**，它会在提示符上方绘制上下文窗口的实时预报，代码约 80 行。随后，我们会浏览两个更大的 mod：**Blast Radius** 和 **Replay Theater**，以展示该 API 还能做些什么。这三个 mod 的完整代码都在 [anthropics/claude-code-playground](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods) 中。

> This guide builds one mod from an empty folder, **Token Weather**, a live forecast of the context window drawn above the prompt. It's about 80 lines. Then it tours two larger mods, **Blast Radius** and **Replay Theater**, to show what else the API can do. The finished code for all three is in [anthropics/claude-code-playground](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods).

![A one-line terminal band cycling through three forecasts, a yellow sun for Clear, a blue umbrella for Showers and a pink lightning bolt for Storm, each with its token count out of 200k and a small bar chart of recent turns.](https://claude.dev/media/eaee11951bbed827ef89ee535abfbbed7277b67a65044ea277ade9e9acd1d3b5.png)

**Claude Code 2.1.287 或更高版本。**Mods 默认处于启用状态，因此无需手动开启。API 可能会在不同版本之间发生变化。每次 Claude Code 加载 mod 时，都会将适用于你当前构建版本的类型声明写入该 mod 的 `.claude-plugin/types/` 文件夹中，这些声明是你所用版本的权威依据。

> **Claude Code 2.1.287 or later.** Mods are on by default, so there's nothing to turn on. The API can change between releases. Each time Claude Code loads a mod, it writes the type declarations for your build into the mod's `.claude-plugin/types/` folder, and those are the authority for your version.

#### 模组的工作原理

> HOW A MOD WORKS

mod 是一种 Claude Code 插件，其行为由一个 JavaScript 或 TypeScript 模块实现：

> A mod is a Claude Code plugin whose behavior lives in a JavaScript or TypeScript module:

- 该文件夹是一个普通插件，带有 `.claude-plugin/plugin.json` 清单文件。
- `hooks/hooks.json` 指定 `modules` 下的一个模块。
- 该模块导出 `register(on, options)`。在其内部，`on(event, matcher?, hook)` 添加了一个钩子。

> • The folder is a normal plugin, with a `.claude-plugin/plugin.json` manifest.
> • `hooks/hooks.json` names one module under `modules`.
> • The module exports `register(on, options)`. Inside it, `on(event, matcher?, hook)` adds a hook.

每个 hook 的结构都相同：

> Every hook has the same shape:

```
on("tool.call", { tool: "Bash" }, async ($, e, next) => {
  // $    the mods API: ui, session, state, store, fs, process, clock, http, tool, command, model, ...
  // e    this event's input, as plain data
  // next passes e to the other plugins and then to Claude Code's own behavior
  return next(e);
});
```

钩子像中间件一样构成一条链。你的钩子先运行，`next(e)` 将事件交给下一个插件，到了链的最底端，Claude Code 会执行它原本就会执行的操作。一个钩子可以做以下三件事之一：

> Hooks form a chain, like middleware. Yours runs, `next(e)` hands the event to the next plugin, and at the bottom Claude Code does what it would have done anyway. A hook can do one of three things:

| 移动 | 如何 | 示例 |
| --- | --- | --- |
| 观察 | const r = await next(e); /* 查看 */ return r | 记录每一次文件编辑。每轮结束后读取一次状态。 |
| 重写 | return next({ ...e, command: safer }) | 改变链中后续环节所看到的内容。 |
| 答案 | 返回 { deny: "…" }，且不调用 next | 拒绝某次工具调用。自行处理某个命令或工具。 |

> 英文原表 / English original

| Move | How | Example |
| --- | --- | --- |
| Observe | const r = await next(e); /* look */ return r | Record every file edit. Take a reading after each turn. |
| Rewrite | return next({ ...e, command: safer }) | Change what the rest of the chain sees. |
| Answer | return { deny: "…" } without calling next | Refuse a tool call. Serve a command or a tool yourself. |

这些事件涵盖工具调用、提交时的提示词、轮次的开始与结束、会话的开始与结束、斜杠命令，以及 `ui.render`：即界面绘制出来的每一个部分。该模块运行在自己独立的沙箱中，没有 DOM，也没有 Node，因此与外部的一切交互都要通过 `$` 进行。

> The events cover tool calls, the prompt as submitted, turns starting and finishing, the session starting and ending, slash commands, and `ui.render`: every piece of the interface as it's drawn. The module runs in a sandbox of its own, with no DOM and no Node, so everything outside it goes through `$`.

**这与 settings hooks 有何不同。**settings hook 会针对每个事件运行一条 shell 命令，并通过 stdin 和 stdout 传递 JSON。mod 则只加载一次，并在整个会话中持续存在。它可以保持状态，绘制随事件发生而更新的 UI，还能回调 Claude Code：打开一个窗格、运行一个进程、注册一个斜杠命令，或者注册一个可供模型调用的工具。

> **How this differs from settings hooks.** A settings hook runs a shell command for each event and passes JSON over stdin and stdout. A mod is loaded once and stays in the session. It can keep state, draw UI that updates as events happen, and call back into Claude Code: open a pane, run a process, register a slash command, or register a tool the model can call.

**Claude Code 自身也在使用它们。**Claude Code 自己的一些功能就是以 mod 的形式构建的，包括 AGENTS.md 支持以及对话旁边的 `/diff` 窗格。它们的源代码连同测试都位于公开的 [anthropics/claude-code](https://github.com/anthropics/claude-code) 仓库的 `mods/` 下，你可以借此了解团队是如何构建它们的。

> **Claude Code uses them itself.** Some of Claude Code's own features are built as mods, including AGENTS.md support and the `/diff` pane beside the conversation. Their source, with tests, is in the public [anthropics/claude-code](https://github.com/anthropics/claude-code) repository under `mods/`, so you can read how the team builds them.

#### 构建你的第一个模组：TOKEN WEATHER

> BUILD YOUR FIRST MOD: TOKEN WEATHER

Token Weather 会在每轮对话结束后读取上下文窗口的占用情况，并在提示符上方绘制一行信息：一个天气图标、占用百分比、已用 token 数与窗口总量之比、最近几轮的小型图表，以及上一轮新增了多少 token。

> Token Weather reads how full the context window is after each turn and draws one line above the prompt: a weather icon, the percentage, the tokens used out of the window, a small chart of recent turns, and how much the last turn added.

| 已使用 | 预测 |
| --- | --- |
| 低于 25% | ☀ 晴 |
| 25–49% | ☁ 多云 |
| 50–74% | ☂ 阵雨 |
| 75–89% | ☇ 风暴 |
| 90% 及以上 | ↯ 即将压缩 |

> 英文原表 / English original

| Used | Forecast |
| --- | --- |
| under 25% | ☀ Clear |
| 25–49% | ☁ Cloudy |
| 50–74% | ☂ Showers |
| 75–89% | ☇ Storm |
| 90% and up | ↯ Compact soon |

下面是它在真实会话中的样子。每一轮都会读取更多文件，色带随之从 ☀ 晴朗变为 ☂ 阵雨，再变为 ☇ 风暴：

> Here it is in a real session. Each turn reads more files, and the band fills from ☀ Clear to ☂ Showers to ☇ Storm:

##### 捷径：让 Claude 来构建

> The shortcut: let Claude build it

你可以跳过这六个步骤。Claude Code 知道如何编写 mod，所以你只需描述你想要的 mod，让它来完成工作。用 `claude` 启动一个会话，然后粘贴下面的提示词：

> You can skip the six steps. Claude Code knows how to write mods, so you can describe the one you want and let it do the work. Start a session with `claude` and paste the prompt below:

```
Make me a Claude Code mod called token-weather: a live forecast of my context window, shown in the band above the prompt.

What it should show, on one line:
- A weather icon and word for how full the context window is: under 25% ☀ Clear (yellow), 25–49% ☁ Cloudy (cyan), 50–74% ☂ Showers (blue), 75–89% ☇ Storm (magenta), 90% and up ↯ Compact soon (red).
- The percentage used, then the tokens used out of the window, like "134.4k / 200k".
- A small chart of the last 12 turns, drawn with ▁▂▃▄▅▆▇█.
- How much the last turn added, like "▲ +98.3k last turn".

It should update after every turn.
```

Claude 会询问一次是否为本次会话开启热重载。允许后，当 Claude 的回合结束时，状态条会出现在提示符上方。从那以后，每次改动都会就地重新加载，因此你可以继续提出微调要求（“让 Storm 从 70% 开始”“在末尾加上美元花费”），并看着状态条随之变化。该 mod 只在本次会话中加载，其文件夹稍后会被清理；如果想保留它，请把文件夹复制出来，然后像安装任何插件一样安装它（[第 6 步](https://claude.dev/blog/getting-started-with-claude-code-mods/#step-6-share-it)）。

> Claude asks once whether to turn on hot reloading for the session. Allow it, and the band appears above the prompt when Claude's turn ends. From then on, every change reloads in place, so you can keep asking for tweaks ("make Storm start at 70%", "add the dollar cost at the end") and watch the band change. The mod loads only in this session, and its folder is cleaned up later, so to keep it, copy the folder out and install it like any plugin ([Step 6](https://claude.dev/blog/getting-started-with-claude-code-mods/#step-6-share-it)).

请注意，这个提示词只描述了你希望看到的内容。你不需要了解 API 就能写出它。Claude Code 内置的 mod 编写指南会负责具体做法：把状态保存在哪里才能在重新加载后保留下来，如何用 `claude plugin validate` 检查插件，以及应该挂接哪些事件。修改“What it should show”那几行，它就成了你自己的 mod，而不是我们的。

> Notice that the prompt only describes what you want to see. You don't need to know the API to write one. Claude Code's built-in guide for writing mods covers the how: where to keep state so it survives a reload, how to check the plugin with `claude plugin validate`, and which events to hook. Change the "What it should show" lines and it's your mod, not ours.

如果你想先了解它是如何搭建起来的，或者想检查 Claude 写了什么，请继续阅读。

> If you'd rather see how it's put together first, or want to check what Claude wrote, read on.

##### 第 1 步：创建文件夹

> Step 1: Create the folder

检查你的 Claude Code 版本是否足够新：

> Check that your Claude Code is new enough:

```
claude --version   # 2.1.287 or later
```

创建如下布局：

> Create this layout:

```
token-weather/
├── .claude-plugin/
│   ├── plugin.json
│   └── types/            (written by Claude Code when it loads the mod)
├── hooks/
│   ├── hooks.json
│   └── token-weather.mjs
├── types/
│   └── index.d.ts        (added in step 3)
└── tests/
    └── token-weather.test.ts   (added in step 5)
```

`.claude-plugin/plugin.json` 是一个标准的插件清单：

> `.claude-plugin/plugin.json` is a standard plugin manifest:

```
{
  "name": "token-weather",
  "version": "0.1.0",
  "description": "A live forecast of the context window, drawn above the prompt.",
  "author": { "name": "You" }
}
```

`hooks/hooks.json` 指向该模块。一个 mod 有且仅有一个：

> `hooks/hooks.json` points at the module. A mod has exactly one:

```
{
  "modules": ["./token-weather.mjs"]
}
```

##### 第 2 步：画点东西

> Step 2: Draw something

提示符正上方的那一栏是一个名为 `AbovePrompt` 的组件。Claude Code 自身不会在那里绘制任何内容，因此它很适合作为第一个改造目标。挂钩它的 `ui.render` 事件，并返回一棵元素树：

> The band directly above the prompt is a component called `AbovePrompt`. Claude Code draws nothing there itself, so it's a good first target. Hook its `ui.render` event and return a tree of elements:

```
// hooks/token-weather.mjs
export function register(on) {
  on("ui.render", { component: "AbovePrompt" }, ($, e, next) => {
    const { Box, Text } = $.ui.resolve(e);
    return Box({
      paddingX: 1,
      children: [Text({ color: "yellow", bold: true, children: "☀  Clear skies" })],
    });
  });
}
```

这些元素并不是全局变量。`$.ui.resolve(e)` 会返回当前所绘制界面对应的构造函数，因为 Claude Code 所绘制的每种界面支持的元素集合都略有不同。JSX 同样可用，以 `h` 作为工厂函数。

> The elements aren't globals. `$.ui.resolve(e)` returns the constructors for the surface being drawn, because each surface Claude Code draws on supports a slightly different set. JSX works too, with `h` as the factory.

启动一个加载了该插件的会话：

> Start a session with the plugin loaded:

```
claude --plugin-dir ./token-weather
```

提示符上方会出现“☀ Clear skies”。保持会话开启。该文件夹处于监视状态，因此每次保存都会就地重新加载模块，无需重启。正是这种快速的反馈循环，让编写模组充满乐趣。

> "☀ Clear skies" appears above the prompt. Keep the session open. The folder is watched, so every save reloads the module in place, with no restart. That quick feedback loop is most of what makes mods fun to write.

**提示：**一旦你了解了它的结构，就可以像[该快捷方式](https://claude.dev/blog/getting-started-with-claude-code-mods/#the-shortcut-let-claude-build-it)那样向 Claude 描述下一个模组。它会把插件写入一个可在同一会话中热重载的文件夹。

> **Tip:** Once you know the shape, describe the next mod to Claude the way [the shortcut](https://claude.dev/blog/getting-started-with-claude-code-mods/#the-shortcut-let-claude-build-it) does. It writes the plugin to a folder that hot-reloads in the same session.

##### 第 3 步：读取真实数值，并将其保存在 `$.state` 中

> Step 3: Read real numbers and keep them in `$.state`

`$.session.usage()` 返回的数值与状态栏相同。`context.tokens` 是上一次响应所基于的输入，`context.window` 是模型的上下文窗口，`context.percent` 则是前者与后者之比。该调用不产生费用：只有当你请求 `breakdown` 时，它才会发送一次 token 计数请求。

> `$.session.usage()` returns the same figures as the status line. `context.tokens` is the input the last response was answered over, `context.window` is the model's window, and `context.percent` is one over the other. The call is free: it only sends a token-count request if you ask for a `breakdown`.

在会话开始时以及每一轮之后进行一次读数：

> Take a reading when the session starts and after every turn:

```
on("session.start", async ($, e, next) => {
  const result = await next(e);
  await takeReading($);
  return result;
});

on("turn.complete", async ($, e, next) => {
  const result = await next(e);
  if (!e.agentId) {
    await takeReading($); // main-loop turns only, not subagents
  }
  return result;
});
```

两个钩子都会先调用 `next(e)`，然后再进行观察。它们都不会改变实际发生的事情。

> Both hooks call `next(e)` first and then observe. Neither one changes what happens.

**读数存放在哪里。**模块级的 `let readings = []` 看起来是显而易见的选择，但热重载是一次全新的加载：`register` 会再次运行，`session.start` 会再次触发，模块变量也会从头开始。因此应把历史记录放在 `$.state` 中。它在宿主中为整个会话保存命名值，这些值在重载后依然保留。

> **Where to keep the readings.** A module-level `let readings = []` looks like the obvious choice, but a hot reload is a fresh load: `register` runs again, `session.start` fires again, and module variables start over. Put the history in `$.state` instead. It holds named values in the host for the whole session, and they survive reloads.

```
// Held by the host, so the history survives a hot reload of this file.
const readings = { plugin: "token-weather", key: "readings" };

async function takeReading($) {
  const { context } = await $.session.usage();
  if (!context?.window) return;
  const tokens = context.tokens ?? 0;
  const percent = context.percent ?? Math.round((tokens / context.window) * 100);
  const { value: history = [] } = await $.state.get(readings);
  await $.state.set(readings, [...history, { tokens, window: context.window, percent }].slice(-HISTORY));
}
```

状态值在插件的**类型契约**中声明，类型契约是 manifest 所指向的一个小型 `.d.ts` 文件。添加 `types/index.d.ts`：

> A state value is declared in the plugin's **type contract**, which is a small `.d.ts` file the manifest points to. Add `types/index.d.ts`:

```
export type TokenWeatherReading = { tokens: number; window: number; percent: number };

declare module "claude-code" {
  interface PluginState {
    "token-weather": { readings: TokenWeatherReading[] };
  }
}
```

然后将 `"types": "./types/index.d.ts"` 添加到 `plugin.json` 中。如果跳过这一步，`claude plugin validate` 会报错并中止，错误信息会指明修复方法：`token-weather.readings is not declared: the manifest's types contract must name it in interface PluginState { … }`。

> Then add `"types": "./types/index.d.ts"` to `plugin.json`. If you skip this step, `claude plugin validate` stops you with an error that names the fix: `token-weather.readings is not declared: the manifest's types contract must name it in interface PluginState { … }`.

作为回报，重绘是免费的。在渲染钩子运行期间进行的 `$.state.get` 会让该绘制订阅它，因此之后每一次 `$.state.set` 都会重绘该色带。你永远不需要调用 `$.ui.invalidate`。

> In return, you get redraws for free. A `$.state.get` made while a render hook runs subscribes that drawing, so every later `$.state.set` redraws the band. You never call `$.ui.invalidate`.

##### 第 4 步：绘制预测图

> Step 4: Draw the forecast

以下是完整的模块：

> Here is the whole module:

```
// Token Weather: a live forecast of the context window, above the prompt.

const HISTORY = 12;
const BARS = "▁▂▃▄▅▆▇█";
const FORECAST = [
  { upTo: 25, icon: "☀", word: "Clear", color: "yellow" },
  { upTo: 50, icon: "☁", word: "Cloudy", color: "cyan" },
  { upTo: 75, icon: "☂", word: "Showers", color: "blue" },
  { upTo: 90, icon: "☇", word: "Storm", color: "magenta" },
  { upTo: Infinity, icon: "↯", word: "Compact soon", color: "red" },
];

// Held by the host, so the history survives a hot reload of this file.
const readings = { plugin: "token-weather", key: "readings" };

export function register(on) {
  on("session.start", async ($, e, next) => {
    const result = await next(e);
    await takeReading($);
    return result;
  });

  on("turn.complete", async ($, e, next) => {
    const result = await next(e);
    if (!e.agentId) {
      await takeReading($); // main-loop turns only, not subagents
    }
    return result;
  });

  on("ui.render", { component: "AbovePrompt" }, async ($, e, next) => {
    const { value: history = [] } = await $.state.get(readings);
    if (e.props.hasSurvey || history.length === 0) {
      return next(e);
    }
    const { Box, Text } = $.ui.resolve(e);
    return band(Box, Text, history, e.props.bodyColumns);
  });
}

async function takeReading($) {
  const { context } = await $.session.usage();
  if (!context?.window) return;
  const tokens = context.tokens ?? 0;
  const percent = context.percent ?? Math.round((tokens / context.window) * 100);
  const { value: history = [] } = await $.state.get(readings);
  await $.state.set(readings, [...history, { tokens, window: context.window, percent }].slice(-HISTORY));
}

function band(Box, Text, history, columns) {
  const now = history[history.length - 1];
  const f = FORECAST.find((b) => now.percent < b.upTo);
  const parts = [
    Text({ color: f.color, bold: true, children: `${f.icon}  ${f.word}` }),
    Text({ children: `  ${now.percent}% of context` }),
    Text({ dimColor: true, children: `  ${short(now.tokens)} / ${short(now.window)}` }),
  ];
  if (columns >= 60) {
    parts.push(Text({ dimColor: true, children: "   last turns " }));
    parts.push(Text({ color: f.color, children: sparkline(history) }));
    if (history.length > 1) {
      parts.push(Text({ dimColor: true, children: trend(history) }));
    }
  }
  return Box({ flexDirection: "row", paddingX: 1, children: parts });
}

function sparkline(history) {
  const top = Math.max(...history.map((r) => r.tokens), 1);
  return history.map((r) => BARS[Math.floor((r.tokens / top) * (BARS.length - 1))]).join("");
}

function trend(history) {
  const delta = history[history.length - 1].tokens - history[history.length - 2].tokens;
  if (delta === 0) return "  steady";
  return delta > 0 ? `  ▲ +${short(delta)} last turn` : `  ▼ ${short(-delta)} last turn`;
}

function short(n) {
  if (n >= 1_000_000) return `${+(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${+(n / 1_000).toFixed(1)}k`;
  return String(n);
}
```

有三个细节值得借鉴到你自己的模组中：

> Three details are worth copying into your own mods:

- **组件的 props 位于 `e.props` 上。**`hasSurvey` 会告诉你有调查问卷需要占用该区域，因此 hook 会通过 `next(e)` 将其让出。`bodyColumns` 是该区域的实际宽度；当有面板停靠在对话记录旁边时，它会比终端更窄。请根据它来确定组件树的尺寸。只有 `e.component`、`e.surface`、`e.requestId` 和 `e.viewport` 位于 `e` 的顶层。
- **没有内容要绘制时就放行。**返回 `next(e)` 会把该区域交还给 Claude Code 和其他 mod。
- **使用单宽字符符号，而不是 emoji。** ☀ ☁ ☂ ☇ ↯ 在任何终端字体中都能对齐。

> • **The component's props are on `e.props`.** `hasSurvey` tells you a survey wants the band, so the hook yields to it with `next(e)`. `bodyColumns` is the band's real width, which is narrower than the terminal while a pane is docked beside the transcript. Size the tree to it. Only `e.component`, `e.surface`, `e.requestId` and `e.viewport` sit at the top level of `e`.
> • **Pass when you have nothing to draw.** Returning `next(e)` gives the band back to Claude Code and to other mods.
> • **Use single-width symbols, not emoji.** ☀ ☁ ☂ ☇ ↯ line up in every terminal font.

保存文件后，正在运行的会话就会加载它。经过几轮读取大文件的对话后，状态带会从 Clear 变为 Showers，再变为 Storm，正如本节开头的录屏所示。

> Save the file and the running session picks it up. After a few turns that read large files, the band moves from Clear to Showers to Storm, as in the recording at the start of this section.

##### 第 5 步：验证与测试

> Step 5: Validate and test

`claude plugin validate` 会以与 Claude Code 相同的方式读取清单文件和模块源码，并报告该模块挂载了哪些钩子、调用了哪些内容：

> `claude plugin validate` reads the manifest and the module's source the same way Claude Code will, and reports what the module hooks and calls:

```
$ claude plugin validate ./token-weather
  > types ./types/index.d.ts declares state: token-weather.readings
  > ./token-weather.mjs hooks: session.start, turn.complete, ui.render{component=AbovePrompt}
  > ./token-weather.mjs calls: $.session.usage (via takeReading), $.state.get, $.state.set (via takeReading), $.ui.resolve
  > ./token-weather.mjs state writes: token-weather.readings
  > ./token-weather.mjs state reads: token-weather.readings
√ Validation passed
```

`claude plugin test` 会在真实的 Claude Code 运行时中运行插件的 `*.test.ts` 文件。测试通过 `on` 注册的 hook 会在调用链中排在该 mod *之后*运行，并模拟 Claude Code 本应返回的响应，因此你可以精确控制 `$.session.usage()` 的返回内容：

> `claude plugin test` runs the plugin's `*.test.ts` files against the real Claude Code runtime. Hooks that a test registers with `on` run *after* the mod in the chain and stub what Claude Code would answer, so you control exactly what `$.session.usage()` returns:

```
// tests/token-weather.test.ts
import { describe, expect, test } from "claude-code/testing";

describe("token-weather", () => {
  test("the band follows the context window", async ($, on) => {
    // Hooks registered here run after the mod and stub what Claude Code would answer.
    let tokens = 36_100;
    on("session.start", ($, e) => ({ cwd: e.cwd }));
    on("session.usage", () => ({
      value: { startedAt: 0, rateLimits: [], context: { tokens, window: 200_000, percent: Math.round(tokens / 2_000) } },
    }));
    on("turn.complete", () => ({ text: "" }));

    await $.session.start({ surface: "terminal", isInteractive: true, cwd: "/work" } as any);
    const ui = await $.ui.mount({
      plugin: "token-weather",
      surface: "terminal",
      component: "AbovePrompt",
      props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 120 },
    } as any);
    expect(await ui.find({ type: "Text", text: /Clear/ })).toBeDefined();

    tokens = 134_400;
    await $.turn.complete({ reason: "answer", answer: "ok", durationMs: 1 } as any);
    expect(await ui.find({ type: "Text", text: /Showers/ })).toBeDefined();
    expect(await ui.find({ type: "Text", text: /67% of context/ })).toBeDefined();
    expect(await ui.find({ type: "Text", text: /▲ \+98\.3k last turn/ })).toBeDefined();
    await ui.unmount();
  });
});
```

```
$ claude plugin test ./token-weather
(pass) token-weather > the band follows the context window
 1 pass
 0 fail
```

该测试还会检查第 3 步中的重绘行为。在 `turn.complete` 之后，band 会自动更新，而 mod 无需主动请求重绘。

> The test also checks the redraw behavior from step 3. The band updates after `turn.complete` without the mod ever asking for a redraw.

##### 第 6 步：分享

> Step 6: Share it

mod 本身就是一个插件，因此发布方式也相同。把它放进一个 marketplace 即可，marketplace 可以简单到只是一个包含 `.claude-plugin/marketplace.json` 的文件夹：

> A mod is a plugin, so it ships the same way. Put it in a marketplace, which can be as simple as a folder with a `.claude-plugin/marketplace.json`:

```
{
  "name": "my-mods",
  "owner": { "name": "You" },
  "plugins": [{ "name": "token-weather", "source": "./token-weather" }]
}
```

```
claude plugin marketplace add ./my-mods
claude plugin install token-weather@my-mods --scope user
```

如需将你的版本与完成版进行对比，请参阅 anthropics/claude-code-playground 中[完整的 Token Weather mod](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/token-weather)。

> To compare your version with a finished one, see [the complete Token Weather mod](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/token-weather) in anthropics/claude-code-playground.

#### 分享你的模组

> SHARING YOUR MOD

mod 本质上就是一个 Claude Code 插件，因此分享方式与其他任何插件完全相同，无需学习任何新东西。把 mod 放进一个带有 marketplace 文件的 GitHub 仓库，这个仓库就成了你的 marketplace。任何人都可以从中安装，而你只需正常 push 即可更新它。

> A mod is a Claude Code plugin, so you share it the same way as any other plugin, and there's nothing new to learn. Put the mod in a GitHub repo with a marketplace file and that repo becomes your marketplace. Anyone can install from it, and you can update it with a normal push.

在 Claude Code 中安装只需三条命令：

> Installing takes three commands in Claude Code:

```
/plugin marketplace add your-org/my-mods
/plugin install token-weather@my-mods
/reload-plugins
```

重新加载后，该 mod 即会启动。如果没有出现，请重启 Claude Code。

> The mod starts when you reload. If it doesn't show up, restart Claude Code.

mod 是在你本机的 Claude Code 内部运行的代码，拥有与 Claude Code 相同的访问权限，并且由其发布者而非 Anthropic 编写。因此，安装 mod 时应像安装软件包一样谨慎：先阅读代码仓库，只安装来自你信任之人的 mod。在你运行该命令之前，不会安装任何内容。

> A mod is code that runs inside Claude Code on your machine, with the same access Claude Code has, and it's written by its publisher, not Anthropic. So install mods the way you'd install a package: read the repo first and only install from people you trust. Nothing gets installed until you run the command.

Claude 目录接受包含 mods 的插件，你可以在 [claude.ai/directory/manage](https://claude.ai/directory/manage) 提交你的插件，这样即使没有你提供的链接，人们也能找到它。

> The Claude directory accepts plugins that include mods, and you can submit yours at [claude.ai/directory/manage](https://claude.ai/directory/manage), so people can find it without a link from you.

#### 另外两项改动

> TWO MORE MODS

Token Weather 只负责观察和绘制。接下来的两个 mod 则会介入事件、打开窗格并接收输入。

> Token Weather only watches and draws. The next two mods step into events, open panes, and take input.

两者的完整代码都在 anthropics/claude-code-playground 中：[Blast Radius](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/blast-radius) 和 [Replay Theater](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/replay-theater)，每个都附有一份 README，说明其构建过程。

> The complete code for both is in anthropics/claude-code-playground: [Blast Radius](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/blast-radius) and [Replay Theater](https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/replay-theater), each with a README that explains how it was built.

##### Blast Radius：在高风险命令运行之前，查看它将会改变什么

> Blast Radius: see what a risky command would change before it runs

当 Claude 调用 Bash 执行 `rm -rf`、`git reset --hard`、`git clean`、强制推送或数据库迁移时，Blast Radius 会拦下这次调用。它会推算出该命令将影响哪些内容，并打开一个带有 **Proceed** 和 **Cancel** 的窗格。按下 `2`，Claude 会收到一条附带原因的拒绝；按下 `1`，命令则按原样执行。

> When Claude calls Bash with `rm -rf`, `git reset --hard`, `git clean`, a force push, or a database migration, Blast Radius holds the call. It works out what the command would touch and opens a pane with **Proceed** and **Cancel**. Press `2` and Claude gets a refusal with the reason. Press `1` and the command runs as written.

它使用了三个 hook：`tool.call` on Bash, and `ui.render` on `Pane` and on `AbovePrompt`. The core of it is the "answer" move from the table above:

> It uses three hooks: `tool.call` on Bash, and `ui.render` on `Pane` and on `AbovePrompt`. The core of it is the "answer" move from the table above:

```
on("tool.call", { tool: "Bash" }, async ($, e, next) => {
  const risk = classify(String(e.command ?? ""));
  if (risk === null) return next(e);                 // everything else runs as normal

  const report = await measure($, risk, await $.session.cwd());  // git status, git clean -n, du, ...
  held = { command: e.command, risk, report, decision: null };
  const opened = await $.ui.open({ id: "blast-radius", title: "Blast Radius", focus: true });
  if (!opened.isPlaced) held.where = "band";         // too narrow for a pane: draw above the prompt

  while (held.decision === null && !next.signal.aborted) {
    await $.process.run(["sleep", "0.25"]);          // time inside $ calls doesn't count against the hook's time limit
  }
  if (held.decision === "proceed") return next(e);   // let it run
  return { deny: `Blast Radius held this command: the user pressed Cancel. It would have: ${report.summary}.` };
});
```

它教授的内容：

> What it teaches:

- **`$.process.run` 用于试运行（dry run）。**报告来自各工具自身的命令：`git status --porcelain`、`git clean -n`、`git log HEAD..origin/main`、`showmigrations`。参数以 argv 数组的形式传入，因此路径中的任何内容都不会被当作 shell 代码执行。
- **挂起调用。**每次分派时，hook 自身有 10 秒的运行时间，但在 `$` 调用内部等待所花的时间不计入其中。循环会等待短暂的 `sleep` 进程，直到某个按钮的 `onPress` 设置了决策；当 `next.signal` 中止时（即你按下了 Esc），循环便会放弃等待。
- **带快捷键的按钮。**`Button({ label: "Proceed", hotkey: "1", onPress })` 可以通过点击、Tab 加 Enter 或数字键来触发。
- **退化为横条显示。**当终端足够宽时，会在对话记录旁停靠一个窗格。当 `$.ui.open` 返回 `isPlaced: false` 时，同样的报告会绘制在提示符上方：

> • **`$.process.run` for dry runs.** The report comes from the tools' own commands: `git status --porcelain`, `git clean -n`, `git log HEAD..origin/main`, `showmigrations`. Arguments go in as an argv array, so nothing in a path is run as shell code.
> • **Holding a call.** A hook gets 10 seconds of its own time per dispatch, but time spent waiting inside a `$` call doesn't count. The loop waits on short `sleep` processes until a button's `onPress` sets the decision, and it gives up when `next.signal` aborts (you pressed Esc).
> • **Buttons with hotkeys.** `Button({ label: "Proceed", hotkey: "1", onPress })` works by click, by Tab and Enter, or by the digit.
> • **Degrade to the band.** The terminal docks a pane beside the transcript when it's wide enough. When `$.ui.open` answers `isPlaced: false`, the same report is drawn above the prompt:

![A terminal with no side pane: a yellow-bordered box above the prompt shows the command, the two files with uncommitted changes it would discard, and numbered Proceed and Cancel choices.](https://claude.dev/media/ac53d89fc2dbe36603c30639b12fdc7edcfba5072b9b417e656a65a2d196cc37.png)

它是一张安全网，而不是权限系统。它读取的是命令文本，因此 `$(…)`、别名以及调用 `rm` 的脚本都能绕过它。如需硬性拦截，请使用权限规则。

> It's a safety net, not a permission system. It reads the command text, so `$(…)`, aliases and scripts that call `rm` get past it. Use permission rules for a hard block.

##### 回放剧场：逐步查看上一轮的编辑

> Replay Theater: step through the last turn's edits

在一轮对话运行期间，Replay Theater 会记录每一次 Edit 和 Write 调用：包括文件本身，以及修改前后的文本。当这一轮结束时，提示框上方会出现一条提示。按下 `r`（或输入 `/replay`），就会打开一个窗格，逐个 diff 地带你回顾这些编辑，窗格中有一排带编号的步骤条，以及 **Prev**、**Next** 和 **Close** 按钮。

> While a turn runs, Replay Theater records every Edit and Write call: the file, plus the text before and after. When the turn ends, a hint appears above the prompt. Press `r` (or type `/replay`) and a pane walks through the edits one diff at a time, with a strip of numbered steps and **Prev**, **Next** and **Close** buttons.

它从不阻止或更改任何编辑，只做观察：

> It never blocks or changes an edit. It observes:

```
on("tool.call", async ($, e, next) => {
  if (EDIT_TOOLS.has(e.tool)) state.pending.push(...(await stepsFor($, e)));  // old/new text → diff
  return next(e);                                                              // the edit runs untouched
});

on("turn.start", ($, e, next) => { if (!e.agentId) state.pending = []; return next(e); });

on("turn.complete", async ($, e, next) => {
  const r = await next(e);
  if (!e.agentId && state.pending.length) state.replay = state.pending;       // one replay per turn
  return r;
});

on("session.start", async ($, e, next) => {
  const r = await next(e);
  await $.command.register({ name: "replay", description: "Step through the last turn's file edits" });
  return r;
});
on("command.run", { command: "replay" }, async ($, e) => ({ text: (await openReplay($)) ? "Replaying" : "No edits" }));
```

它教授的内容：

> What it teaches:

- **配对事件。**`turn.start` 和 `turn.complete` 将编辑操作框定为每轮一次重放，而 `e.agentId` 则将子代理的轮次排除在分组之外。
- **注册斜杠命令。**`$.command.register`（位于 `session.start` 中），然后在 `command.run` 上对其作出响应。
- **读取文件。**对于 Write 操作，`$.fs.read` 会在写入生效前一刻获取旧内容，因此 diff 是真实的。
- **放置位置由界面层负责。**在全屏模式下，面板停靠在右侧。在 80 列宽度下，它会以内联方式在提示符上方展开。无论哪种情况，mod 绘制的都是同一棵树。

> • **Pairing events.** `turn.start` and `turn.complete` bracket the edits into one replay per turn, and `e.agentId` keeps subagent turns out of the grouping.
> • **Registering a slash command.** `$.command.register` in `session.start`, then answer it on `command.run`.
> • **Reading files.** For a Write, `$.fs.read` gets the old contents just before the write lands, so the diff is real.
> • **Placement is the surface's job.** In fullscreen the pane docks on the right. At 80 columns it opens inline above the prompt. The mod draws the same tree either way.

![A tall terminal window with a magenta-bordered box above the prompt: a numbered step strip, the file greet.js, a one-line diff, and Prev, Next and Close buttons.](https://claude.dev/media/bb2b908077c752f4e43672b5d5e7b0d262756bf27303d0884634cd142487f996.png)

#### 值得保持的四个习惯

> FOUR HABITS WORTH KEEPING

- **善用 Claude Code 为你生成的类型。**每次加载你的 mod 时，Claude Code 都会把与你的构建相对应的声明写入该 mod 的 `.claude-plugin/types/` 文件夹，因此你的编辑器和 `tsc -p` 无需任何额外步骤即可直接使用。它们是每个事件、`$` 上的每个方法以及每个元素 props 的参考依据。
- **从 `e.props` 读取 props。**`hasSurvey`、`bodyColumns` 等属性都位于其中，而不是直接位于 `e` 本身上。
- **为热重载做好规划。**每次保存都会重新运行 `register` 和 `session.start`，因此要把数据保存在 `$.state` 中，而不是模块变量里。
- **图形没有显示时，请查看日志。**运行 `claude --debug`，查找提示某个 hook 返回的树未通过校验的那一行。

> • **Lean on the types Claude Code writes for you.** Each time it loads your mod, Claude Code writes the declarations for your build into the mod's `.claude-plugin/types/` folder, so your editor and `tsc -p` work with no extra step. They're the reference for every event, every method on `$` and every element's props.
> • **Read props from `e.props`.** `hasSurvey`, `bodyColumns` and the rest live there, not on `e` itself.
> • **Plan for hot reload.** Every save runs `register` and `session.start` again, so keep data in `$.state`, not in module variables.
> • **When a drawing doesn't show, read the log.** Run `claude --debug` and look for a line saying a hook returned a tree that does not validate.

#### 你会改造什么？

> WHAT WILL YOU MOD?

这里的三个改造各自源于一个问题：*我的上下文用了多少？*、*这条命令将要删除什么？*，以及*Claude 刚才改了什么？*你的问题会有所不同，而这正是关键所在。以下是一些可以作为起点的想法：

> The three mods here came from one question each: *how full is my context?*, *what is this command about to delete?*, and *what did Claude just change?* Your questions will be different, and that's the point. Some ideas to start from:

- 来自 `$.session.usage()` 的费用或速率限制计量器，以带有 `$.ui.status` 的状态栏形式呈现
- 一个 `prompt.submit` 钩子，可将团队的约定添加到每个提示词中
- 一个列出 Claude 在本次会话中读取过的文件的面板，以实时地图的形式呈现它已看过的内容
- 一个专注计时器，在长轮次结束时通过 `$.ui.toast` 发送弹窗通知
- 一个针对你的技术栈调校的 `tool.call` 防护，例如生产环境的 kubectl 上下文或 `terraform apply`

> • A cost or rate-limit meter from `$.session.usage()`, as a status line with `$.ui.status`
> • A `prompt.submit` hook that adds your team's conventions to every prompt
> • A pane that lists the files Claude read this session, as a live map of what it has seen
> • A focus timer that sends a toast with `$.ui.toast` when a long turn finishes
> • A `tool.call` guard tuned to your stack, such as production kubectl contexts or `terraform apply`

##### 分享你的作品

> Share what you build

做了一个自己每天都在用的 mod？把它发到 X 或 LinkedIn 上，附上运行效果的 GIF 或截图，让其他开发者看看还能做到什么。把插件放进 marketplace（[分享你的 mod](https://claude.dev/blog/getting-started-with-claude-code-mods/#sharing-your-mod)）并附上链接，这样任何喜欢它的人只需三条命令就能安装。

> Made a mod you now use every day? Post it on X or LinkedIn with a GIF or a screenshot of it running, so other developers can see what's possible. Put the plugin in a marketplace ([Sharing your mod](https://claude.dev/blog/getting-started-with-claude-code-mods/#sharing-your-mod)) and link to it, so anyone who likes it can install it with three commands.

## 术语对照

| 英文 | 中文 | 说明 |
|---|---|---|
| mod | 模组 | 在 Claude Code 会话中运行、可观察事件、改变行为并绘制 UI 的 JS/TS 模块。 |
| hook | 钩子 | 挂接在特定事件上、以中间件链方式执行的处理函数。 |
| plugin | 插件 | 带有 .claude-plugin/plugin.json 清单的 Claude Code 扩展包，mod 即一种插件。 |
| manifest | 清单文件 | 描述插件元信息及其类型契约等配置的 JSON 文件。 |
| middleware | 中间件 | 按顺序串联处理请求或事件、可选择传递给下一环节的组件模式。 |
| hot reload | 热重载 | 保存代码后在不重启会话的情况下就地重新加载模块。 |
| sandbox | 沙箱 | 与外部环境隔离的受限执行环境，mod 在其中运行且无 DOM 与 Node。 |
| context window | 上下文窗口 | 模型单次可处理的最大 token 容量。 |
| type contract | 类型契约 | 清单所指向的 .d.ts 文件，用于声明插件状态等类型。 |
| marketplace | 插件市场 | 包含 marketplace.json、用于发布和安装插件的目录或仓库。 |
| dry run | 试运行 | 在不实际产生变更的情况下预演命令以查看其影响。 |
| slash command | 斜杠命令 | 以 / 开头、在 Claude Code 中触发特定功能的命令。 |
| pane | 窗格 | 停靠在对话记录旁、由 mod 绘制内容的界面区域。 |
| subagent | 子代理 | 由主代理派生、独立执行子任务的代理实例。 |
| permission rules | 权限规则 | Claude Code 中用于硬性允许或拦截操作的配置规则。 |
