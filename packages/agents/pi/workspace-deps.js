// Print the workspace package directories pi-coding-agent depends on, in build
// order (dependencies first). Upstream reshuffles its internal packages often,
// so the build derives this from package.json instead of a hand-kept list.
const fs = require("node:fs");
const path = require("node:path");

const scope = "@earendil-works/";
const packages = {};
for (const dir of fs.readdirSync("packages")) {
  const manifest = path.join("packages", dir, "package.json");
  if (!fs.existsSync(manifest)) continue;
  const pkg = JSON.parse(fs.readFileSync(manifest, "utf8"));
  const deps = { ...pkg.dependencies, ...pkg.peerDependencies };
  packages[pkg.name] = {
    dir: path.join("packages", dir),
    deps: Object.keys(deps).filter((name) => name.startsWith(scope)),
  };
}

const order = [];
const seen = new Set();
const visit = (name) => {
  if (seen.has(name) || !packages[name]) return;
  seen.add(name);
  packages[name].deps.forEach(visit);
  order.push(packages[name].dir);
};
packages[`${scope}pi-coding-agent`].deps.forEach(visit);

console.log(order.join("\n"));
