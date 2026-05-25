# arco-papers-api

Python backend for the Arco Papers AI platform. Built as a real-world vehicle for learning and shipping production-grade AI integration — function calling, multi-step agent pipelines, and stateful LangGraph workflows.

## What this is

Arco Papers is a family paper manufacturing business in Islamabad, Pakistan. This backend is being built to automate the parts of the business that currently run on phone calls and manual follow-ups — payment reminders, price queries, quotation generation, and order tracking. It is also a deliberate learning project: each layer of the stack is built to production standard, not demo standard.

## Stack

- **Python** — FastAPI
- **AI** — OpenAI API, LangChain, LangGraph
- **Integrations** — WhatsApp Business API (Meta Cloud API)
- **Storage** — SQLite (dev), PostgreSQL (prod)

## What's built

### AI research agent
A multi-tool agent built in two implementations for direct comparison:

`research_assistant.py` — hand-rolled agent loop with explicit tool dispatch, error handling, and `max_iterations` guard.

`research_assistant_lg.py` — LangGraph implementation using `StateGraph`, `ToolNode`, and `tools_condition`. First trace verified. Streaming via `stream_mode="updates"` in progress.

Tools: `search_web`, `fetch_and_summarise`, `save_note`, `get_saved_notes`.

### Payment reminder system
Automated WhatsApp follow-up for overdue B2B payments. Three-stage reminder sequence (due date, 7 days overdue, 14 days overdue) using approved Meta message templates. Runs as a scheduled script, logs reminder state per customer to avoid duplicate sends.

## What's in progress

- LangGraph streaming and human-in-the-loop checkpoints
- Quotation generator
- WhatsApp price query agent
- Connecting LangGraph agent to Flutter frontend as an API endpoint

## Structure

```
backend/
  research_assistant.py       # hand-rolled agent (Level 4 complete)
  research_assistant_lg.py    # LangGraph agent (Level 5 in progress)
  payment_reminders.py        # WhatsApp payment follow-up
  payments.json               # payment records (dev)
  notes.json                  # agent memory store
  test_research.py
  test_whatsapp.py
  .env.example
```

## Related

- Frontend: [arco-papers-app](https://github.com/Awanjee/arco-papers-app)
