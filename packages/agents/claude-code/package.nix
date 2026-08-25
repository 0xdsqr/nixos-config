{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.245";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-n3wiYCUXZaGNCzUZhmnazBkS9ugSmjsB9rWNkzZf8fE=";
    darwin-x64 = "sha256-3gRLtUPoJjUvMVh6dDVuGy2ulNwbnJYKNi2fB9+Wwqc=";
    linux-arm64 = "sha256-0NopkwPXEKfMXN7OlimVj1EozhpyfhVGPGUe1c84XH8=";
    linux-x64 = "sha256-Fq0rlN6veymr7ZZtmByZkaR68EIPW+jtSj+Dvqn2eLw=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
