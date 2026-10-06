{inputs, ...}: final: prev: {
  # Provide unstable as `pkgs.unstable`
  unstable = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  # Optional: add custom packages from pkgs/
  # custom = prev.callPackage ../pkgs/custom { };
}
