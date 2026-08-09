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
2. **Create a Plan:** Once all questions are resolved, write a detailed step-by-step implementation plan that incorporates the user's answers. The plan must be self-contained and decision-complete. The plan file must begin with a YAML frontmatter block containing the `date` (current date) and `status` (initialized to `pending_review`).
3. **Save the Plan:** Use the Write tool to autonomously save this plan as a markdown file in the `.plans/` directory (e.g., `.plans/add-new-feature.md`). Create the directory if it does not already exist. **Do this immediately without asking for permission** — this is the one file-write allowed in Plan mode.
4. **Display the Plan:** After saving, print the full plan content inline in the chat as a fenced markdown block so the user can read it without opening the file in another editor.
5. **Ask for Approval:** Do NOT use the user interaction tool. Instead, simply print the exact message: "Switch to Build and type 'Approve' to implement the plan".
6. **Hand off to Implementation:** Plan mode itself stays read-only outside of `.plans/`. Once the user manually switches to the Build agent (e.g. by pressing Tab) and types "Approve", the Build agent will read the plan file first (to pick up any manual edits). The Build agent's first action must be to edit the plan file to update its metadata `status` from `pending_review` to `approved`. Then, it will implement the changes exactly as described.
