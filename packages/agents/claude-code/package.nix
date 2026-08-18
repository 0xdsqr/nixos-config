{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.234";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-CNhwAxNpfL5zCiVCDJCKKZzlLVbw6yz0+slMq1EJvFc=";
    darwin-x64 = "sha256-GnsuiUhgnx9zKmSYzRe4BbXFGH10qZrcYeuqWinvw0w=";
    linux-arm64 = "sha256-JK3aZzWRzYNFsD7IJFkVuxUaJZoevD7yNkm1e6lEqqI=";
    linux-x64 = "sha256-NHNgHqaV1b92nFsgKETUy0+/cjrplUUPy2lzIEd1yEo=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
