{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.250";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-UG1zYqnGJTBgRIeanZHY8zvS7vljaBtWvjKV21/j40s=";
    darwin-x64 = "sha256-wkfpv3j8qKCByKdGgR2WQfTDjnJ8NB0lPzWd2raHD0U=";
    linux-arm64 = "sha256-D0/1QviVUmSZziPYdSxky7LOsFoyz2ocDR4x2CsgZD0=";
    linux-x64 = "sha256-K+JSoArFbnBNf79+Xp7xJDWECTM0qGGUUjigwn6Evaw=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
