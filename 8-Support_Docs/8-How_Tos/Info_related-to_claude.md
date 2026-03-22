# Queries
=========

Is there any place where I can see Claude log, whatever conversation I am having with Claude and whatever work claude has done for me?

⏺ Yes, Claude Code stores full conversation transcripts as JSONL files. Here's where to find them:

  Session Transcripts (Full Logs)

  ~/.claude/projects/-Users-bkwork-Herd-laravel/         

  Each conversation gets a .jsonl file named by session ID. For example, your previous session:                                                                                                                        
  /Users/bkwork/.claude/projects/-Users-bkwork-Herd-laravel/4dc0ad42-aceb-421a-af8c-28354087c397.jsonl

  Let me show you what's actually there.

  Here's the summary:

  Where Claude Logs Are Stored                                                                                                    

  ┌───────────────────────┬────────────────────────────────────────────────┐                                                                                                             
  │         What          │                    Location                    │
  ├───────────────────────┼────────────────────────────────────────────────┤                                                                                                             
  │ Session transcripts   │ ~/.claude/projects/{project-path}/*.jsonl      | 
  ├───────────────────────┼────────────────────────────────────────────────┤                                                                                                             
  │ Cross-session memory  │ ~/.claude/projects/{project-path}/memory/      │
  ├───────────────────────┼────────────────────────────────────────────────┤                                                                                                             
  │ Your project sessions │ ~/.claude/projects/-Users-bkwork-Herd-laravel/ │
  └───────────────────────┴────────────────────────────────────────────────┘                                                                                                             

  Your Session History

  ┌────────────────┬──────────────────┬───────┐
  │      Date      │       File       │ Size  │
  ├────────────────┼──────────────────┼───────┤
  │ Mar 13 (today) │ 4dc0ad42...jsonl │ 14 MB │
  ├────────────────┼──────────────────┼───────┤
  │ Mar 12         │ 3c4d39a5...jsonl │ 23 MB │
  ├────────────────┼──────────────────┼───────┤
  │ Mar 11         │ d44af689...jsonl │ 10 KB │
  └────────────────┴──────────────────┴───────┘

  How to Read Them

  The .jsonl files contain every message (yours + Claude's), every tool call, every file read/written. They're JSON-lines format — one JSON object per line. You can:

  # Search for a specific topic across all sessions
  grep "SmartTimetable" ~/.claude/projects/-Users-bkwork-Herd-laravel/*.jsonl

  # Pretty-print a session (large output)
  cat ~/.claude/projects/-Users-bkwork-Herd-laravel/4dc0ad42*.jsonl | python3 -m json.tool --no-ensure-ascii

  Other Useful Locations

  ┌─────────────────┬────────────────────────────────────────────────────────────────┐
  │      What       │                              Path                              │
  ├─────────────────┼────────────────────────────────────────────────────────────────┤
  │ Deployed skills │ ~/.claude/skills/                                              │
  ├─────────────────┼────────────────────────────────────────────────────────────────┤
  │ Deployed agents │ ~/.claude/agents/                                              │
  ├─────────────────┼────────────────────────────────────────────────────────────────┤
  │ Claude settings │ ~/.claude/settings.json                                        │
  ├─────────────────┼────────────────────────────────────────────────────────────────┤
  │ Project memory  │ ~/.claude/projects/-Users-bkwork-Herd-laravel/memory/MEMORY.md │
  └─────────────────┴────────────────────────────────────────────────────────────────┘

  The JSONL files are the complete audit trail of every Claude interaction — nothing is lost, even after context compression during long sessions.

  