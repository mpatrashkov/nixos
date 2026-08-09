---
permission:
  edit:
    "*": deny
    ".plans/**": allow
---

# Primary Workflow: Planning Mode

Whenever the user requests a new feature, a bug fix, a refactor, or any significant change to the codebase, follow this Cursor-inspired planning workflow:

1. **Resolve Open Questions First:** Before writing the plan, identify any ambiguities, missing details, or decision points you would otherwise leave open in the plan (e.g. "should X be configurable?", "which module should this live in?", "do you want Y behavior or Z?"). Ask these questions *up front* using the user interaction tool — do not proceed to drafting a plan that contains unresolved questions, TODOs, or "we could do X or Y" sections. The final plan must reflect concrete decisions only.
    **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Plan Qs"`.
    - Prefer multiple-choice questions when the option space is small and known.
    - Use a text input prompt for open-ended details.
    - Batch related questions into a single interaction where possible rather than asking serially.
    - If there are no genuine open questions, skip this step and go straight to drafting the plan. Do not invent questions to ask.
2. **Create a Plan:** Once all questions are resolved, write a detailed step-by-step implementation plan that incorporates the user's answers. The plan must be self-contained and decision-complete.
3. **Save the Plan:** Use the Write tool to autonomously save this plan as a markdown file in the `.plans/` directory (e.g., `.plans/add-new-feature.md`). Create the directory if it does not already exist. **Do this immediately without asking for permission** — this is the one file-write allowed in Plan mode.
4. **Display the Plan:** After saving, print the full plan content inline in the chat as a fenced markdown block so the user can read it without opening the file in another editor.
5. **Ask for Approval:** Stop and use the user interaction tool to ask if the user approves the plan.
    **CRITICAL**: Use a short `header` (max 12 chars, e.g., `header: "Plan Apprvl"`).
    Present the following options:
    - **Approve**: Go ahead and implement the plan.
    - **Wait**: The user will manually edit the plan file; wait for their next message before proceeding.
    - **Cancel**: Abort the planning phase.
6. **Hand off to Implementation:** Plan mode itself stays read-only outside of `.plans/`. Once the user approves, implementation happens after switching to build mode (or an implementing agent) — at that point, re-read the plan file first (to pick up any manual edits) and implement the changes exactly as described.
