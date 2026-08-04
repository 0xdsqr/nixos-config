{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.221";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ehgfNu0PxPusbO5OzythXv+T2LQ0Ih//XXyHjcXr84A=";
    darwin-x64 = "sha256-9Ai59+RkOfbjSjaH/2dDP8a8GJ9AIgzk8KHoKeWPClI=";
    linux-arm64 = "sha256-08Wda8xK3PTNhavKO8E/oRMaNMsy+YK98DDYOjsR5wA=";
    linux-x64 = "sha256-YNuOiNQsJLUZnJLP1W7Ig3DFEMN4nG82SvdINU8Ieto=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
