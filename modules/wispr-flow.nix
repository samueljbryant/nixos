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

  wispr-flow = pkgs.callPackage "${inputs.wispr-flow-linux}/nix/wispr-flow.nix" {
    installerExe = installer;
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
