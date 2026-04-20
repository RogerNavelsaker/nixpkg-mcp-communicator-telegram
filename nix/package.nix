{ bash, bun, bun2nix, lib, stdenv, symlinkJoin }:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  packageVersion =
    manifest.package.version
    + lib.optionalString (manifest.package ? packageRevision) "-r${toString manifest.package.packageRevision}";
  licenseMap = {
    "MIT" = lib.licenses.mit;
    "Apache-2.0" = lib.licenses.asl20;
    "SEE LICENSE IN README.md" = lib.licenses.unfree;
  };
  resolvedLicense =
    if builtins.hasAttr manifest.meta.licenseSpdx licenseMap
    then licenseMap.${manifest.meta.licenseSpdx}
    else lib.licenses.unfree;
  bunCompileTargetMap = {
    x86_64-linux = "bun-linux-x64";
    aarch64-linux = "bun-linux-arm64";
    x86_64-darwin = "bun-darwin-x64";
    aarch64-darwin = "bun-darwin-arm64";
  };
  bunCompileTarget =
    bunCompileTargetMap.${stdenv.hostPlatform.system}
      or (throw "Unsupported Bun compile target for ${stdenv.hostPlatform.system}");
  aliasSpecs = map (
    alias:
    if builtins.isString alias then
      {
        name = alias;
        args = [ ];
      }
    else
      alias
  ) (manifest.binary.aliases or [ ]);
  renderAliasArgs = args: lib.concatMapStringsSep " " lib.escapeShellArg args;
  aliasOutputLinks = lib.concatMapStrings
    (
      alias:
      ''
        mkdir -p "${"$" + alias.name}/bin"
        cat > "${"$" + alias.name}/bin/${alias.name}" <<EOF
#!${lib.getExe bash}
exec "$out/bin/${manifest.binary.name}" ${renderAliasArgs alias.args} "\$@"
EOF
        chmod +x "${"$" + alias.name}/bin/${alias.name}"
      ''
    )
    aliasSpecs;
  basePackage = bun2nix.writeBunApplication {
    pname = manifest.package.repo;
    version = packageVersion;
    packageJson = ../package.json;
    src = lib.cleanSource ../.;
    dontUseBunBuild = true;
    dontUseBunCheck = true;
    startScript = ''
      bun x ${manifest.binary.upstreamName or manifest.binary.name} "$@"
    '';
    bunDeps = bun2nix.fetchBunDeps {
      bunNix = ../bun.nix;
    };
    meta = with lib; {
      description = manifest.meta.description;
      homepage = manifest.meta.homepage;
      license = resolvedLicense;
      mainProgram = manifest.binary.name;
      platforms = platforms.linux ++ platforms.darwin;
      broken = manifest.stubbed || !(builtins.pathExists ../bun.nix);
    };
  };
in
symlinkJoin {
  pname = manifest.binary.name;
  version = packageVersion;
  name = "${manifest.binary.name}-${packageVersion}";
  outputs = [ "out" ] ++ map (alias: alias.name) aliasSpecs;
  paths = [ basePackage ];
  nativeBuildInputs = [ bun ];
  postBuild = ''
    rm -rf "$out/bin"
    mkdir -p "$out/bin"
    entrypoint="$(find "${basePackage}/share/${manifest.package.repo}/node_modules" -path "*/node_modules/${manifest.package.npmName}/${manifest.binary.entrypoint}" | head -n 1)"
    ${lib.getExe' bun "bun"} build \
      --compile \
      --target ${lib.escapeShellArg bunCompileTarget} \
      --outfile "$out/bin/${manifest.binary.name}" \
      "$entrypoint"
    ${aliasOutputLinks}
  '';
  meta = basePackage.meta;
}
