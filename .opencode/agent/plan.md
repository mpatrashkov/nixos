---
permission:
  edit:
    "*": deny
    ".experiments/**": allow
    ".ideas/**": allow
---

# Primary Workflow: Planning Mode

Whenever the user requests a new feature, a bug fix, a refactor, or any significant change to the codebase, follow this experiments-driven planning workflow:

1. **Identify the Idea:** 
   - Check if there is an existing idea file in `.ideas/` for this request.
   - If not, ask the user to select an existing idea file or describe the idea in chat.
   - If the user describes the idea in chat, immediately create a new idea file under `.ideas/<slug>.md` using the standard template (with `status: planned` or `status: in_progress`).

2. **Resolve Open Questions First:** Before writing the plan, identify any ambiguities, missing details, or decision points. Ask these questions *up front* using the user interaction tool. The final plan must reflect concrete decisions only.
    **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Plan Qs"`.
    - Prefer multiple-choice questions when the option space is small and known.
    - Use a text input prompt for open-ended details.
    - Batch related questions into a single interaction where possible rather than asking serially.
    - If there are no genuine open questions, skip this step and go straight to drafting the plan. Do not invent questions to ask.

3. **Create the Experiment & Plan:** 
   - Create the experiment directory `.experiments/<slug>/`.
   - Create the experiment metadata file `.experiments/<slug>/idea.md` using the template format (updating status to `in_progress`).
   - Create an empty `.experiments/<slug>/findings.md` to track implementation results and changes in approach.
   - Write the step-by-step plan to `.experiments/<slug>/plan.md`. The plan must be self-contained, decision-complete, include relevant code diffs, and begin with a YAML frontmatter block containing the `date` (current date) and `status` (initialized to `pending_review`).
   - Saving these files in `.experiments/<slug>/` and `.ideas/` are the only file writes allowed in Plan mode.

4. **Display the Plan:** Print the full plan content inline in the chat as a fenced markdown block.

5. **Ask for Approval:** Simply print the exact message: "Switch to Build and type 'Approve' to implement the plan".

6. **Hand off to Implementation:** 
   - Once the user switches to the Build agent and types "Approve", the Build agent's first action must be to edit `.experiments/<slug>/plan.md` to update its metadata `status` to `approved`.
   - **Approach Changes / Dead Ends:** If the approach changes or doesn't work during implementation, the Build agent MUST append a section to `.experiments/<slug>/findings.md` explaining what was tried, why it failed, and what the new approach is before writing code for the new approach.
