# How we built a data agent with Manus to help every team make better decisions

> 来源：Manus Blog / Manus，2026-11-06
> 原文链接：https://manus.im/blog/how-we-built-a-data-agent

*Manus's four-person data team built a data agent that more than 40 people use every week. We sat down with Ben Zhong, whose Slack title is "Data Guy," to hear how it came together, and what other teams can take from it.*

For a long time, if someone at Manus wanted to understand some data, they messaged the data team. Why did usage jump on Tuesday? What are people really building with Manus? There were only four people on the team, and the questions kept coming.

Today, more than 40 people get answers to those questions every week by talking to a data agent built on Manus. Today, we share a bit about how our data team gets it done with Manus.

**At a glance**

- **4** people on the data team
- **40+** people use the data agent every week
- **2–3** questions per person on average, and heavy users ask a dozen or more a day
- **~1 week** to a first working version

### Why it matters: every team needs data, but analysts are limited

The reason for building a data agent was simple: there weren't enough people. Almost every team at Manus makes decisions with data, but people rarely have the access or the time to dig into all the questions they have.

When a team had a question, they had two options: check an existing dashboard, or send a Slack message to one of the four people on the data team.

Besides the sheer volume of questions, data requests often got stuck in two places:

- **New data.** Someone needed a number nobody had pulled before, so there was no dashboard for it.
- **The "why."** A dashboard showed that a number moved, but finding the cause meant digging well past it.

The data team could only answer so many requests, so a lot of good questions never got asked.

### How to build a data agent

A data agent needs two things: a connection to your data, and the business context to make sense of it.

#### Data connection

The data team gave the agent tools to query our data directly, not just the dashboards. With access to the detailed data, the agent can answer questions that no dashboard covers. The team added data in stages, such as summarized business metrics, marketing data, and detailed product data. Once one category of data is well connected and stable, they will connect the next group.

#### Business context

Data alone isn't enough. The AI agent also needs a map of the business, so that when a question comes in, it knows where to go. The data team created a detailed knowledge base that shows the agent how each metric is defined, what each table helps you solve, and how the tables and metrics relate to each other.

With that map, the agent can work through a question the way an analyst would. It picks the right table, uses the right definition, and follows the links from one metric to the next. That works even for metrics that have no dashboard.

### The five steps to building a data agent

#### 1. Automate your own work first

The data team didn't start by building a tool for the company. They started by getting the agent to automate their own work. *"You're really building a copy of yourself,"* says Ben.

The goal is for the data team to stop writing queries by hand and do most of its analysis by talking to the agent.

#### 2. Design it for business users

Making the agent useful for everyone else turned out to be a design question more than a technical one. The two groups want different things from an answer. Ben's data team wants to know how a number was calculated. Business teams want to know what the number means.

So the team designed the agent from the business perspective. For business users, every answer covers three things:

- **What it means:** What the data suggests is behind the change.
- **What to act on:** Which findings are solid enough to drive action, with a suggested next step.
- **What to double-check:** Which findings are still too weak to trust, so the person knows to check with the data team.

#### 3. Set up governance and trust

The hardest problems weren't the technical piece of getting the agent set up. They were about setting the right company policy and guardrails.

##### Split access by topic

Because of user privacy as well as company governance reasons, Ben's team can't grant access to everyone for every data table. They wanted to give everyone enough access to answer the questions they have. What they did was to create a governance layer in the data tables and let the agent know about the access rules. Splitting access by topic protects our users and keeps us compliant.

##### Ask for access when it's needed

Normally, if you can't see a dashboard, you file a ticket and wait. With the data agent, Ben's team automated the process. When a user asks questions using a data table they don't have access to, it triggers an approval request in our internal approval software and gets approved by the right data owner. After that, the data agent resumes working automatically, giving the user the answer they want.

#### 4. Get people to use it

Once Ben's team got the tool to be compliant and ready, they wanted to make sure our team uses it as much as possible. So the team put the agent into the places where questions already come up. Ben's team launched Data Agent in Slack where team members can ask questions directly, collaborate on a thread, and share answers easily in channels.

#### 5. Keep refining and improving

As the business keeps changing, the data team constantly updates the knowledge base about new data tables and definitions that reflect what we care about as a business. The best part is - users of Data Agent don't need to know about any of them because the knowledge base is automatically updated in the Manus project.

Ben's team also reviews our internal usage of the data agent to see if the data agent is answering the questions using the right approach and providing the right insight. Most fixes fall into two types, a missing knowledge base entry, or a fuzzy definition. Ben said while this process is not rocket science, it’s important to keep it running to ensure the quality of the agent.

### Getting the data agent live

Our data agent has been live for months now, and we have seen many cool ways that the team is using this awesome product. Here are some examples.

#### Drill down until it finds the cause

Many of those detailed numbers have no dashboard at all, but with the Manus Data Agent, it's much easier to do deep dive analyses.

***Example: Why did our usage jump?***

*For this question, the agent splits usage by region and by channel. It checks how people reach Manus, whether through the web, the mobile or desktop app or the API. If the jump came from ad traffic, it checks whether a specific ad caused it, or whether there's some change with our ad tracking.*

![How the data agent breaks down a usage spike by region, channel, and ad traffic](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/ebb8cec6831b899f24c5265a3ca5f33c08e0de10127b062cdaaf6bf6b7734cdd.webp)

#### Turns large amounts of unstructured data into insight

Some questions can't be answered by any dashboard, because the answer is buried in a large amount of user data. The agent turns that into insight in real time.

***Example: Who are our users in the Middle East?***

*We have many users in Saudi Arabia and the UAE, and we wanted to know whether they were local residents or expats who had moved there for work. Locals tend to use Manus for everyday life and social uses, while people there for work tend to use it to run a business. The agent looked at which languages people used in their conversations: standard Arabic, local Arabic or English and got us some really interesting insight.*

![The data agent summarizing use cases from user sessions](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/72b27c8b0d86d64a0fd06f49da3f6e8e78355eb1ed92ead4251e5e3ed102e1f9.webp)

#### Builds new tracking as the product evolves

Our product changes every week, and each new feature brings numbers that no existing table or dashboard covers yet. Instead of waiting for someone to set up tracking, the data agent is connected to our release process.

***Example: How is the new feature doing?***

*When engineering ships a feature, the agent automatically starts tracking it. A few days later, the product manager sees how the feature is doing. That loop used to need someone to coordinate it. Now it just happens.*

![The data agent reporting on feature usage in Slack](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/7e618126039184cb8addf290494fbe5566287f6e22d38a7baf188987e9ecfc82.webp)

### Why use Manus for a data agent

Ben's team chose to use Manus because it manages the agent out of the box, so a four-person team could spend its time on the data and the business context.

#### You don't need to maintain your own agent infrastructure

On Manus, there's no server to look after and no agent code to keep up with. Manus automatically picks the best models for your task, uses tools and manages context. With the Manus API, Ben’s team was able to deploy the data agent on Slack without a line of code. "I want to spend my time keeping the knowledge base right, and improving it every week based on real questions and answers. So I spent no time building the agent itself," says Ben.

#### A project keeps the knowledge base in one place

A Manus project holds the agent's instructions, skills and knowledge in one shared place. Ben updates them once, and everyone gets the latest version right away. When the team connects new data, it shows up for everyone the same way.

![The data agent project in Manus, with shared instructions, skills, and knowledge](https://files.manuscdn.com/assets/dashboard/materials/2026/11/06/1c97677bd7e242cde881b5a509ecd6bb855a9d81b7e7698d2094ab323d0d5f25.webp)

#### Automations handle the approvals

Getting access is usually where a data request stalls. On Manus Data Agent, Ben's team leveraged our new Automations feature to submit an approval to the relevant data owner automatically. Once it's approved, the agent picks the task back up and finishes it.

#### Answers can become charts and dashboards

Manus can also build charts, reports and web pages in the same session, making it easy to understand. At Manus, people often share Data Agent's reports with their teams, and other agents read those reports to pick up the next piece of work.

### Some advice from the Manus Data Team

#### Don't wait for clean data to start

While it helped that we had a relatively clear set of definitions in our data table, Ben said that other teams shouldn't treat that as a requirement: "Agents are very capable now. It doesn't matter what your setup looks like, or whether you have a list of definitions. You can sort it out as you go." Over time, the agent builds up its own working system in its instructions and project. From there, you keep improving it and tidying it up.

#### Give the agent as much context as possible

The more an agent can reach, the stronger it gets. If you have lots of different databases, that's fine. Connect them, and let the agent take over the work you'd normally do by hand. In Ben's words, the most important step is to connect with as much context as you can and start automating your manual querying work.

#### Put your most AI-native person in charge

Getting an agent to automate real work is a skill. If someone on your team already excels at automating work with AI, give them this project.

*If your team wants to build something similar, reach out. We'll walk you through how we set it up.*
