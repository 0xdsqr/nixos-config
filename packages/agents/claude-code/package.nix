{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.270";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-pQa22XCkz0T2q9tTqB3c1dOwzgQqlcUC/p0flGvbiAc=";
    darwin-x64 = "sha256-s+4yN6AZuKWrswCPHH3dRilaDm5lq5RUWnnJuZfciSg=";
    linux-arm64 = "sha256-e/nzOswSTfmrzPbyNmOXqCp0A3jVNfoS1Cb6d/28mUY=";
    linux-x64 = "sha256-OmJKWnzXm7rU0yvX2zbxGX7PRYvFvx4q7YGDSgGtPvA=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
