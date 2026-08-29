{
  claude-code,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "2.1.251";

  platformKey = "${stdenvNoCC.hostPlatform.node.platform}-${stdenvNoCC.hostPlatform.node.arch}";
  checksums = {
    darwin-arm64 = "sha256-YlhpsB4AUPJgspgPrCSP2c755GJhK97U7J09Sf+JaaU=";
    darwin-x64 = "sha256-RCIdcqPzV3L6qFrZo2pngISlFvcg5ktF4m65AVMVUAs=";
    linux-arm64 = "sha256-ZURb1N0EIHnMP6Q3kbVhNwoFyFmejsR1gOJagQUKu90=";
    linux-x64 = "sha256-/V8Q/w61ja7ASQBGaxQ+qYqrUKvyCKQivACOrsE/Yfc=";
  };
in
claude-code.overrideAttrs (_: {
  inherit version;
  src = fetchurl {
    url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platformKey}/claude";
    sha256 = checksums.${platformKey};
  };
})
