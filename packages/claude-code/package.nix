{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.205";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-M+KGJMWuhPK9fS2HYeXS53mXupZcsRtkSN5rbixWb5w=";
    darwin-x64 = "sha256-Qpmj9IVR7zZfLQVvJNh+hLgixMELasxGl5RGt7XGDOs=";
    linux-arm64 = "sha256-wYdMhbzTqItwQ5/VD/WRC35qxTccFN1J1MzCh4pZLQk=";
    linux-x64 = "sha256-3Yc0wLalA/4dF0JRhOV7OXwwuwM3oz8UcNmYX+v+Wwk=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
