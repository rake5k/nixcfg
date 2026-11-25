// Loads Claude Code's per-project memory (L1) into every opencode session.
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { Plugin } from "@opencode/plugin";

// Claude Code loads the first 200 lines of MEMORY.md.
const MAX_INDEX_LINES = 200;

const readOrEmpty = (path) => readFile(path, "utf8").catch(() => "");

export default Plugin.define({
  id: "claude-memory",
  async setup(ctx) {
    const directory = ctx.location?.directory ?? process.cwd();
    const configDir =
      process.env.CLAUDE_CONFIG_DIR || join(homedir(), ".claude");
    // Same slug as Claude Code: every non-alphanumeric char of the cwd becomes "-".
    const memoryDir = join(
      configDir,
      "projects",
      directory.replace(/[^a-zA-Z0-9]/g, "-"),
      "memory",
    );
    const rules = (
      await readFile(new URL("./claude-memory.md", import.meta.url), "utf8")
    ).replaceAll("{{MEMORY_DIR}}", memoryDir);

    // Read once per session like Claude Code: a changing system prompt would defeat prompt caching.
    const textBySession = new Map();
    const load = async () => {
      const index = (await readOrEmpty(join(memoryDir, "MEMORY.md")))
        .split("\n")
        .slice(0, MAX_INDEX_LINES)
        .join("\n")
        .trim();
      return index ? `${rules}\n## Current MEMORY.md\n\n${index}\n` : rules;
    };

    await ctx.session.hook("context", async (event) => {
      if (!textBySession.has(event.sessionID))
        textBySession.set(event.sessionID, await load());
      event.system.push({
        type: "text",
        text: textBySession.get(event.sessionID),
      });
    });
  },
});
