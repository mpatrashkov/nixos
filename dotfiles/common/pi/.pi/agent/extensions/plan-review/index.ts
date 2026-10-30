import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { reviewPlan } from "./review.ts";

export default function (pi: ExtensionAPI): void {
  pi.registerTool(defineTool({
    name: "review_plan",
    label: "Review plan in Neovim",
    description: "Offer the user a read-only Neovim review of a saved Markdown plan. " +
      "Call only when the complete plan is ready, as the only tool call in the batch. " +
      "Only an explicit approved decision authorizes implementation. Feedback means read the annotation report, " +
      "revise the plan and request fresh approval; never implement. Pending means stop for user feedback.",
    parameters: Type.Object({
      path: Type.String({ description: "Path to the complete saved .md plan, relative to the working directory or absolute." }),
    }),
    exposure: "model-only",
    executionMode: "sequential",
    async execute(_id, params, signal, _onUpdate, ctx) {
      const decision = await reviewPlan(ctx, params.path, signal);

      return {
        content: [{ type: "text", text: JSON.stringify(decision, null, 2) }],
        details: decision,
        terminate: decision.decision === "pending",
      };
    },
  }));

  pi.registerCommand("review-plan", {
    description: "Review a saved Markdown plan in Neovim: /review-plan path/to/plan.md",
    handler: async (args, ctx) => {
      if (!args.trim()) {
        ctx.ui.notify("Usage: /review-plan path/to/plan.md (no shell quoting needed)", "info");
        return;
      }

      try {
        const decision = await reviewPlan(ctx, args.trim());
        pi.sendMessage({
          customType: "plan-review",
          content: JSON.stringify(decision, null, 2),
          display: true,
        }, { triggerTurn: decision.decision !== "pending" });
      } catch (error) {
        ctx.ui.notify(`Plan review failed: ${String(error)}`, "error");
      }
    },
  });
}
