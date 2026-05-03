# Primary Workflow: Planning Mode

Whenever I request a new feature, a bug fix, a refactor, or any significant change to the codebase, you MUST follow this Cursor-inspired planning workflow:

1. **Create a Plan:** Do not implement changes immediately. Instead, write a detailed step-by-step implementation plan.
2. **Save the Plan:** Use the appropriate file writing tool to autonomously save this plan as a markdown file in the `.plans/` directory (e.g., `/home/miro/flake/.plans/add-new-feature.md`). **Execute the tool immediately without asking for my permission.**
3. **Display the Plan:** After saving, print the full plan content inline in the chat as a fenced markdown block so I can read it without opening the file in another editor.
4. **Ask for Approval:** Stop and prompt the user to ask if I approve the plan. Use the user interaction tool to present multiple-choice options.
    **CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "Plan Apprvl"`).
    Present the following options:
    - **Approve**: Go ahead and implement the plan.
    - **Wait**: I will manually edit the plan file, wait for my next message before proceeding.
    - **Cancel**: Abort the planning phase.
5. **Implementation:** Only after I explicitly select "Approve" (or provide my edits and give the go-ahead), read the plan file (to ensure you have any manual edits) and implement the changes exactly as described in the plan.

---

# NixOS Configuration Workflow

Whenever you implement a NixOS configuration change that I have requested, you MUST stop and use the user interaction tool to ask me how to proceed.
**CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "NixOS Action"`).

Present the following options:

1. **Apply the change (switch)**: This will stage the changes, prompt for a commit message, commit, push, and apply the configuration.
2. **Verify the configuration (test)**: This will stage the changes and test the configuration without applying it permanently.
3. **Do nothing**

* If I select "Apply the change (switch)", immediately ask me for the commit message using a text input prompt. **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Git Commit"`. Once provided, run:
  `git add . && git commit -m "<commit_message>" && git push && nh os switch -- --override-input last-commit-message "path:./last-commit-message"`
  This option remains user-driven (run it yourself in the terminal where I can see output) because it pushes to git and applies system-wide.
* If I select "Verify the configuration (test)", run the command yourself via the Bash tool — passwordless sudo for `nixos-rebuild` is configured for user `miro`, so this works non-interactively. Stream the output back to me. Command:
  `git add . && sudo nh os test -- --override-input last-commit-message "path:./last-commit-message"`
  The asymmetry with `switch` is intentional: `test` is local and reversible, `switch` is not.
