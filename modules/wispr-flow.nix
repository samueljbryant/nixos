{
  pkgs,
  inputs,
  ...
}:
let
  # Pure install, no --impure: the Nix build never fetches the proprietary
  # app itself, so we fetch the exact Windows installer this checkout's
  # patches target ourselves and hand it in via installerExe. These three
  # values come straight from wispr-flow-linux's own
  # scripts/setup/installer-pin.sh -- bump all three together whenever that
  # repo's pin moves (a "chore: bump Wispr Flow to ..." commit there), or
  # fetchurl's hash check will fail the build with the new expected hash.
  installer = pkgs.fetchurl {
    url = "https://dl.wisprflow.com/wispr-flow/win32/x64/Wispr%20Flow%20Setup-v1.6.1034.exe";
    sha256 = "95fb2884fe6e2a03b22f0484e85143efd1d4bc489c950a64e08fc4aa85b89d22";
  };

  # Likewise pure-fetch the pinned prebuilt Linux better_sqlite3.node +
  # node_sqlite3.node (the shipped app carries Windows PE builds of these --
  # see nix/wispr-flow.nix's NATIVE-MODULE NOTE). Published as release assets
  # in the dedicated github.com/wispr-flow-linux/native-modules repo. Keep
  # nativeModulesVersion + both hashes in sync with wispr-flow-linux's
  # native-modules-version.txt / native-modules/native-modules.lock.
  nativeModulesVersion = "native-v1";
  nativeModulesRepo = "wispr-flow-linux/native-modules";
  betterSqlite3Node = pkgs.fetchurl {
    url = "https://github.com/${nativeModulesRepo}/releases/download/${nativeModulesVersion}/better_sqlite3-x86_64.node";
    sha256 = "a26c6fec70bb6d31c38609491b0391b8eadf3d9c2cc584d54f1601857e090e3f";
  };
  nodeSqlite3Node = pkgs.fetchurl {
    url = "https://github.com/${nativeModulesRepo}/releases/download/${nativeModulesVersion}/node_sqlite3-x86_64.node";
    sha256 = "c9bd0419f77efb3b5d3a691fda04e265f740ad8dc195f0b56003cdeac92e9a34";
  };
  nativeModulesDir = pkgs.runCommand "wispr-flow-native-modules" { } ''
    mkdir -p "$out"
    cp ${betterSqlite3Node} "$out/better_sqlite3.node"
    cp ${nodeSqlite3Node} "$out/node_sqlite3.node"
  '';

  wispr-flow = pkgs.callPackage "${inputs.wispr-flow-linux}/nix/wispr-flow.nix" {
    installerExe = installer;
    inherit nativeModulesDir;
  };
  wispr-flow-fhs = pkgs.callPackage "${inputs.wispr-flow-linux}/nix/fhs.nix" {
    inherit wispr-flow;
  };
in
{
  # No services.udev.packages wiring: the helper's needs (write /dev/uinput,
  # read /dev/input/event*) are already covered on this system by
  # hardware.uinput.enable + the sam user's input/uinput groups
  # (configuration.nix, set up for kanata). If text injection stalls, run
  # `wispr-flow --doctor` before reaching for the package's own udev rule.
  home.packages = [ wispr-flow-fhs ];
}
