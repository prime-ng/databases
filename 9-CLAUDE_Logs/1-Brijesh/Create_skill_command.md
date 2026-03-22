# How to create Custom Skills
=============================

## Question:
Can I create a config file for me which I can use as Claude Command. Which will my life bit easy. I can create user freindly command as per my choice and Claude will understand those  
command from that config file. First only asnwer my query and if Yes I can then provide me the complete how can you do that for me and How will I use it?

## Answer:

>> Yes, absolutely. Claude Code has a built-in feature for exactly this — they're called Skills (slash commands).

  You already have some: /test, /review, /schema, /lint, /module-status — these are all custom commands defined in your AI_Brain.

  >> How it works :
  You create a simple markdown file with instructions. When you type /command-name in Claude, it loads that file and follows those instructions.

  >> What you can create:
  Any command you want. Examples:

  ┌────────────────────────┬──────────────────────────────────────────┐
  │      Your Command      │               What It Does               │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /gap-analysis Hpc      │ Run a full gap analysis on a module      │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /update-brain          │ Update AI_Brain files from a source doc  │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /fix-paths             │ Propagate config/paths.md to all files   │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /status                │ Show overall project status              │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /new-prompt ModuleName │ Generate a prompt template for a module  │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /check-links           │ Scan AI_Brain for broken file references │
  ├────────────────────────┼──────────────────────────────────────────┤
  │ /sprint-plan Hpc       │ Create a sprint plan for a module        │
  └────────────────────────┴──────────────────────────────────────────┘

  >> Where they live :
  ~/.claude/skills/
  ├── gap-analysis/SKILL.md      ← /gap-analysis
  ├── update-brain/SKILL.md      ← /update-brain
  ├── fix-paths/SKILL.md         ← /fix-paths
  └── ...

  >> Each SKILL.md is just a markdown file with:
  - A name and description (frontmatter)
  - Step-by-step instructions Claude follows when you invoke it

  >> How easy is it?
  - Creating: Write a markdown file describing what you want Claude to do
  - Using: Just type /command-name with optional arguments
  - Editing: Change the markdown file, next invocation uses the new version — no restart needed

  Want me to create some commands for you? If yes, tell me what commands would make your daily work easier and I'll build them.

❯ I want to create Skills but right now I have some other priority work to work on.                                                                                                       

⏺ Got it. Whenever you're ready, just say "create skills" or point me to your requirements and I'll build them.

