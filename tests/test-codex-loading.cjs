// Read-only acceptance through the installed Codex app-server skill loader.
// No turn is started, no model is called, and no GitHub operation is performed.
const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const readline = require("node:readline");
const assert = require("node:assert/strict");

(async () => {
  const fixture = await fs.mkdtemp(
    path.join(os.tmpdir(), "vapa codex loading "),
  );
  const names = (await fs.readdir(path.resolve(__dirname, "../skills")))
    .filter((name) => name.startsWith("vapa-"));
  const explicit = new Set(["vapa-init", "vapa-proposal", "vapa-design", "vapa-review"]);
  let server;
  try {
    spawnSync("git", ["init", "-q", fixture]);
    for (const name of names)
      await fs.cp(
        path.resolve(__dirname, "../skills", name),
        path.join(fixture, ".agents/skills", name),
        { recursive: true },
      );
    server = spawn(
      process.env.VAPA_CODEX_BINARY || "codex",
      ["app-server", "--stdio"],
      { cwd: fixture, stdio: ["pipe", "pipe", "ignore"] },
    );
    const pending = new Map();
    let id = 0;
    readline.createInterface({ input: server.stdout }).on("line", (line) => {
      let message;
      try {
        message = JSON.parse(line);
      } catch {
        return;
      }
      if (pending.has(message.id)) {
        const { resolve, reject, timer } = pending.get(message.id);
        clearTimeout(timer);
        pending.delete(message.id);
        if (message.error) reject(new Error(JSON.stringify(message.error)));
        else resolve(message.result);
      }
    });
    server.on("error", (error) => {
      for (const item of pending.values()) {
        clearTimeout(item.timer);
        item.reject(error);
      }
    });
    const request = (method, params) =>
      new Promise((resolve, reject) => {
        const requestId = ++id;
        const timer = setTimeout(() => {
          pending.delete(requestId);
          reject(new Error(`Timeout: ${method}`));
        }, 20000);
        pending.set(requestId, { resolve, reject, timer });
        server.stdin.write(
          JSON.stringify({ jsonrpc: "2.0", id: requestId, method, params }) +
            "\n",
        );
      });
    await request("initialize", {
      clientInfo: { name: "vapa-compatibility-check", version: "1.0.0" },
      capabilities: { experimentalApi: true },
    });
    server.stdin.write(
      JSON.stringify({ jsonrpc: "2.0", method: "initialized" }) + "\n",
    );
    const response = await request("skills/list", {
      cwds: [fixture],
      forceReload: true,
    });
    const entry = response.data.find(
      (item) =>
        item.cwd === fixture ||
        path.resolve(item.cwd) === path.resolve(fixture),
    );
    assert(entry, "Fixture skills entry was returned");
    const relevantErrors = entry.errors.filter((error) =>
      error.path.includes(fixture),
    );
    assert.deepEqual(relevantErrors, [], "Codex rejected a fixture Skill");
    for (const name of names) {
      const skill = entry.skills.find(
        (item) => item.name === name && item.path.includes(fixture),
      );
      assert(skill, `Codex discovers ${name}`);
      assert.equal(skill.enabled, true);
      if (explicit.has(name)) {
        assert(skill.interface?.displayName, `${name}: sidecar interface loaded`);
        assert(skill.interface.defaultPrompt.includes(`$${name}`));
      }
      console.log(`Codex loaded ${name}: enabled${explicit.has(name) ? ", interface and explicit invocation prompt" : ""}`);
    }
  } finally {
    if (server) {
      server.stdin.end();
      server.kill("SIGTERM");
    }
    await fs.rm(fixture, { recursive: true, force: true });
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
