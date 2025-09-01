{ self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    with pkgs;
    {
      _module.args.pkgs = import self.inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.inputs.nur-packages.overlays.default ] ++ builtins.attrValues self.overlays;
      };
      devShells.default = mkShell {
        buildInputs = [
          self.checks.${system}.pre-commit-check.enabledPackages
        ];

        shellHook = '''' + self.checks.${system}.pre-commit-check.shellHook;
      };

    };
}
