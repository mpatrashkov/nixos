import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { promisify } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const exec = promisify(execFile);

// Invoke subprocesses directly, without a shell.
async function run(file: string, args: string[]): Promise<string> {
	const { stdout } = await exec(file, args, {
		timeout: 3000,
		maxBuffer: 64 * 1024,
	});
	return stdout.trim();
}

export default function (pi: ExtensionAPI) {
	if (process.platform !== "darwin") return;

	const owner = randomUUID();
	const pane = process.env.TMUX && /^%\d+$/.test(process.env.TMUX_PANE ?? "")
		? process.env.TMUX_PANE : undefined;
	const warned = new Set<string>();
	const interactive = (ctx: ExtensionContext) => ctx.mode === "tui";

	async function attempt(ctx: ExtensionContext, backend: string, action: () => Promise<unknown>) {
		try {
			await action();
		} catch {
			if (!warned.has(backend)) {
				warned.add(backend);
				ctx.ui.notify(`Pi notifications: ${backend} unavailable; other signals remain enabled.`, "warning");
			}
		}
	}

	async function refresh() {
		const clients = await run("tmux", ["list-clients", "-F", "#{client_name}"]);
		await Promise.all(clients.split("\n").filter(Boolean).map(client =>
			run("tmux", ["refresh-client", "-S", "-t", client])));
	}

	async function clear(ctx: ExtensionContext, claim = false) {
		if (!interactive(ctx) || !pane) return;
		await attempt(ctx, "tmux", async () => {
			const current = await run("tmux", ["show-options", "-pqv", "-t", pane, "@pi_ready_owner"]);
			if (!claim && current !== owner) return;
			await run("tmux", ["set-option", "-p", "-t", pane, "@pi_ready_owner", owner,
				";", "set-option", "-p", "-t", pane, "@pi_ready", "0"]);
			await refresh();
		});
	}

	// session_start also covers reload, new, resume, and fork. Claim this pane
	// once; subsequent cleanup may only clear state still owned by this runtime.
	pi.on("session_start", async (_event, ctx) => clear(ctx, true));
	pi.on("agent_start", async (_event, ctx) => clear(ctx));
	pi.on("session_shutdown", async (_event, ctx) => clear(ctx));
	pi.registerCommand("notify-clear", {
		description: "Acknowledge this Pi pane's ready indicator",
		handler: async (_args, ctx) => clear(ctx),
	});

	// Unlike agent_end, settlement excludes intermediate retries/continuations.
	pi.on("agent_settled", async (event, ctx) => {
		if (!interactive(ctx) || event.aborted) return;
		await Promise.all([
			attempt(ctx, "sound", () => run("/usr/bin/afplay", ["/System/Library/Sounds/Glass.aiff"])),
			pane ? attempt(ctx, "tmux", async () => {
				const current = await run("tmux", ["show-options", "-pqv", "-t", pane, "@pi_ready_owner"]);
				if (current !== owner) return;
				await run("tmux", ["set-option", "-p", "-t", pane, "@pi_ready", "1"]);
				await refresh();
			}) : Promise.resolve(),
		]);
	});
}
