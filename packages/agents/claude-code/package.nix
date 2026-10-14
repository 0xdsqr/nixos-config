{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.299";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-ulq3uMGV+gOrjVvzkVx2FTtXaixA55pcRuJl5+2XRLM=";
    darwin-x64 = "sha256-CZ3MU9q7vvq+2JJtqyWwMYd1wXWnyHu2umxU/en47OI=";
    linux-arm64 = "sha256-TNWrAGtJ3BKiR/7U28QqklrRrqHnEdmqJFh9KF7ofC8=";
    linux-x64 = "sha256-LYlKSxv6qpqrcq7/eAPjxzvCUQ8nmhcfa49Z9y0X0Hc=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
