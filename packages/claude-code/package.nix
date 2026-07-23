{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.218";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-cauv9ZMSyam2odgYNlBItC5OlcxSGoI2YO3tPgiA2bc=";
    darwin-x64 = "sha256-mGK3Sgg+ik7VcvmcvUiVGF4N1aCmAa/7D7jkPY0fQOY=";
    linux-arm64 = "sha256-KV/TBIG9A7OEUP3sKm4lu2RywgdPBLDEpWbNWYjyML8=";
    linux-x64 = "sha256-4SBxdRqTNrivEBLBAzWP8ErBj5qv9Kc4z/e6XN+vY/I=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
