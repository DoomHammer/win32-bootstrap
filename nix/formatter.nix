{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem =
    { config, pkgs, ... }:
    let
      fmt_excludes = [
        "flake.lock"
      ];
    in
    {
      formatter = config.treefmt.build.wrapper;

      treefmt = {
        projectRootFile = "flake.nix";

        settings.global.excludes = fmt_excludes;

        settings.formatter = {
          powershell-beautifier = {
            command = pkgs.writeShellApplication {
              name = "powershell-formatter-wrapper";
              text = ''
                for file in "$@"; do
                  touch -r "$file" "$file.tstp"
                  ${pkgs.powershell-beautifier}/bin/powershell-beautifier "$file"
                  touch -r "$file.tstp" "$file"
                  rm "$file.tstp"
                done
              '';
            };
            includes = [ "*.ps1" ];
          };
        };

        programs = {
          actionlint = {
            enable = true;
          };
          biome = {
            enable = true;
          };
          deadnix = {
            enable = true;
          };
          dos2unix = {
            enable = true;
          };
          mdformat = {
            enable = true;
          };
          nixfmt = {
            enable = true;
          };
          pinact = {
            enable = true;
          };
        };
      };
    };
}
