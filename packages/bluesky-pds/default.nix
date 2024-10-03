{
  mkYarnPackage,
  nodejs,
  stdenv,
  symlinkJoin,
  writeShellApplication,
  vipsdisp,
  ...
}:
let
  inherit (stdenv) isDarwin;

  sharp = {
    darwin = fetchTarball {
      url = "https://github.com/lovell/sharp/releases/download/v0.33.5/sharp-v0.33.5-napi-v9-darwin-arm64.tar.gz";
      sha256 = "sha256:1bcylmns5bjwknyzc0qqhmvypwqc5kr6arc04q705875rafgj78q";
    };

    linux = fetchTarball {
      url = "https://github.com/lovell/sharp/releases/download/v0.33.5/sharp-v0.33.5-napi-v9-linuxmusl-x64.tar.gz";
      sha256 = "sha256:117kvqrih0nir25fbmpnjv74fg2510b2a4zfjwipw642nbjznf0d";
    };
  };
  sharpFilename = if isDarwin then "sharp-darwin-arm64.node" else "sharp-linuxmusl-x64.node";
  sharpExpected = if isDarwin then sharpFilename else "sharp-linux-x64.node";

  currentSharp = if isDarwin then sharp.darwin else sharp.linux;

  nodePackage = mkYarnPackage {
    name = "bluesky-pds-unwrapped";
    src = ./.;
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;

    postInstall = ''
      ROOT="$out/libexec/bluesky-pds/node_modules/sharp"
      mkdir -p "$ROOT/build/Release"
      cp -rf ${currentSharp}/Release/${sharpFilename} "$ROOT/build/Release/${sharpExpected}"
    '';
  };

  script = writeShellApplication {
    name = "bluesky-pds";

    runtimeInputs = [ nodejs ];

    text = ''
      cd ${nodePackage}/libexec/bluesky-pds/deps/bluesky-pds
      exec node index.js
    '';
  };
in
symlinkJoin {
  name = "bluesky-pds";

  paths = [
    nodePackage
    script
    vipsdisp
  ];
}
