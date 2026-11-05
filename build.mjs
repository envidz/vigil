// Builds the published vigil.lua from src/vigil.lua.
// Xeno refuses scripts larger than about 100 KB, so the published copy drops the
// header comment, whole-line comments, indentation and blank lines. Nothing
// inside a line is touched, so behaviour is unchanged.
import { readFileSync, writeFileSync } from "node:fs";

const LIMIT = 95_000; // keep clear of Xeno's ~100 KB ceiling

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
writeFileSync(new URL("./vigil.lua", import.meta.url), result);

const bytes = Buffer.byteLength(result);
console.log(`vigil.lua: ${bytes} bytes (source ${Buffer.byteLength(source)})`);
if (bytes > LIMIT) {
	console.error(`over the ${LIMIT} byte budget for Xeno`);
	process.exit(1);
}
