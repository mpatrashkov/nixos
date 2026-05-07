# Primary Workflow: Planning Mode

Whenever I request a new feature, a bug fix, a refactor, or any significant change to the codebase, you MUST follow this Cursor-inspired planning workflow:

1. **Resolve Open Questions First:** Before writing the plan, identify any ambiguities, missing details, or decision points you would otherwise leave open in the plan (e.g. "should X be configurable?", "which module should this live in?", "do you want Y behavior or Z?"). Ask me these questions *up front* using the user interaction tool — do not proceed to drafting a plan that contains unresolved questions, TODOs, or "we could do X or Y" sections. The final plan must reflect concrete decisions only.
    **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Plan Qs"`.
    - Prefer multiple-choice questions when the option space is small and known.
    - Use a text input prompt for open-ended details.
    - Batch related questions into a single interaction where possible rather than asking serially.
    - If you have no genuine open questions, skip this step and go straight to drafting the plan. Do not invent questions to ask.
2. **Create a Plan:** Once all questions are resolved, write a detailed step-by-step implementation plan that incorporates my answers. The plan must be self-contained and decision-complete.
3. **Save the Plan:** Use the appropriate file writing tool to autonomously save this plan as a markdown file in the `.plans/` directory (e.g., `/home/miro/flake/.plans/add-new-feature.md`). **Execute the tool immediately without asking for my permission.**
4. **Display the Plan:** After saving, print the full plan content inline in the chat as a fenced markdown block so I can read it without opening the file in another editor.
5. **Ask for Approval:** Stop and prompt the user to ask if I approve the plan. Use the user interaction tool to present multiple-choice options.
    **CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "Plan Apprvl"`).
    Present the following options:
    - **Approve**: Go ahead and implement the plan.
    - **Wait**: I will manually edit the plan file, wait for my next message before proceeding.
    - **Cancel**: Abort the planning phase.
6. **Implementation:** Only after I explicitly select "Approve" (or provide my edits and give the go-ahead), read the plan file (to ensure you have any manual edits) and implement the changes exactly as described in the plan.

---

# NixOS Configuration Workflow

Whenever you implement a NixOS configuration change that I have requested, you MUST stop and use the user interaction tool to ask me how to proceed.
**CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "NixOS Action"`).

Present the following options:

1. **Apply the change (switch)**: This will stage the changes, prompt for a commit message, commit, push, and apply the configuration.
2. **Verify the configuration (test)**: This will stage the changes and test the configuration without applying it permanently.
3. **Do nothing**

Both options run autonomously via the Bash tool. Passwordless sudo for `nh` is configured for user `miro` in `nixos-modules/services/users.nix`, and `--bypass-root-check` is required because `nh` otherwise refuses to run as root. Stream output back to me.

**Command reference (do not confuse these):**
- `./scripts/nix-test` — stages changes and tests the config without making it permanent (`nh os test`)
- `./scripts/nix-switch "<msg>"` — stages, commits, pushes, and applies the config permanently (`nh os switch`)

* If I select "Apply the change (switch)", immediately ask me for the commit message using a text input prompt. **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Git Commit"`. Once provided, run:
  `./scripts/nix-switch "<commit_message>"`
  Run the command exactly as shown — no output redirection.
* If I select "Verify the configuration (test)", run:
  `./scripts/nix-test`
  Run the command exactly as shown — no output redirection (no `2>&1 | tail -N` or similar). The raw output must be streamed directly to the Bash tool output so the user can see it in full.
