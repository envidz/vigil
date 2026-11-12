// Builds the published vigil.lua (and the Games-tab-only vigil-games.lua) from src/vigil.lua.
// The published copy drops the header comment, whole-line comments, indentation
// and blank lines to keep the download small. Nothing inside a line is touched,
// so behaviour is unchanged. Xeno's real limit is 200 top-level locals (checked
// with luau-compile -O0), not file size.
import { readFileSync, writeFileSync } from "node:fs";

const LIMIT = 250_000; // sanity cap only

const source = readFileSync(new URL("./src/vigil.lua", import.meta.url), "utf8").replace(/\r\n/g, "\n");

// The only long bracket allowed is the header comment; anything else could be a
// multi-line string, which line-based stripping would corrupt.
const body = source.replace(/^--\[\[[\s\S]*?\]\]\n/, "");
if (/\[=*\[/.test(body.replace(/\w\[\w*\[/g, "").replace(/\]\[/g, ""))) {
	const line = body.split("\n").findIndex((l) => /(^|[^\w\]\)])\[=*\[/.test(l));
	if (line >= 0) throw new Error(`long bracket at source line ${line + 1}; build would be unsafe`);
}

const out = body
	.split("\n")
	.map((line) => line.trim())
	.filter((line) => line !== "" && !line.startsWith("--"))
	.join("\n");

const header = "-- Vigil (built from src/vigil.lua)\n";
const result = header + out + "\n";

// vigil-games.lua: the same script with only the Games tab
const FLAG = "local GAMES_ONLY = false";
if (out.split(FLAG).length !== 2) throw new Error(`expected exactly one "${FLAG}" line`);
const games = "-- Vigil Hub (built from src/vigil.lua)\n" + out.replace(FLAG, "local GAMES_ONLY = true") + "\n";

for (const [file, text] of [["vigil.lua", result], ["vigil-games.lua", games]]) {
	writeFileSync(new URL("./" + file, import.meta.url), text);
	const bytes = Buffer.byteLength(text);
	console.log(`${file}: ${bytes} bytes (source ${Buffer.byteLength(source)})`);
	if (bytes > LIMIT) {
		console.error(`over the ${LIMIT} byte sanity cap`);
		process.exit(1);
	}
}
