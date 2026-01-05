{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hydenix.hm.editors;
in
{
  options.hydenix.hm.editors = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.hydenix.hm.enable;
      description = "Enable text editors module";
    };

    vscode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable vscode";
      };

      wallbash = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable wallbash extension for vscode";
      };

      userSettings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Additional VS Code user settings to override Hyde defaults";
        example = { "workbench.sideBar.location" = "left"; };
      };

      extensions = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "List of VS Code extensions to install";
        example = lib.literalExpression ''
          with pkgs.vscode-extensions; [
            eamodio.gitlens
            ms-dotnettools.csharp
          ]
        '';
      };
    };

    neovim = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable neovim";
    };

    vim = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable vim";
    };

    default = lib.mkOption {
      type = lib.types.str;
      default = "code";
      description = "Default text editor";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (lib.mkIf cfg.vim vim) # terminal text editor
      (lib.mkIf cfg.neovim neovim) # terminal text editor
    ];

    programs.vscode = lib.mkIf cfg.vscode.enable {
      enable = true;
      package = pkgs.vscode.fhs;
      mutableExtensionsDir = true;
    };

    # Override Hyde VS Code settings with user-provided settings
    # This runs AFTER home.file links, so it will persist user settings
    home.activation.applyVsCodeUserSettings = lib.mkIf (cfg.vscode.enable && cfg.vscode.userSettings != {}) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
        if [ -f "$VSCODE_SETTINGS" ]; then
          $DRY_RUN_CMD echo "Applying custom VS Code user settings..."
          $DRY_RUN_CMD ${pkgs.jq}/bin/jq '. + $settings' \
            --argjson settings '${builtins.toJSON cfg.vscode.userSettings}' \
            "$VSCODE_SETTINGS" > "$VSCODE_SETTINGS.tmp"
          $DRY_RUN_CMD mv "$VSCODE_SETTINGS.tmp" "$VSCODE_SETTINGS"
          $DRY_RUN_CMD echo "VS Code user settings applied"
        fi
      ''
    );

    xdg.mimeApps = {
      defaultApplications = {
        "text/plain" = [ "${cfg.default}.desktop" ];
        "application/x-shellscript" = [ "${cfg.default}.desktop" ];
        "text/css" = [ "${cfg.default}.desktop" ];
        "application/javascript" = [ "${cfg.default}.desktop" ];
        "application/json" = [ "${cfg.default}.desktop" ];
        "application/xml" = [ "${cfg.default}.desktop" ];
        "text/x-python" = [ "${cfg.default}.desktop" ];
        "text/x-java-source" = [ "${cfg.default}.desktop" ];
        "text/x-c++src" = [ "${cfg.default}.desktop" ];
        "text/x-csrc" = [ "${cfg.default}.desktop" ];
        "text/x-go" = [ "${cfg.default}.desktop" ];
        "text/x-typescript" = [ "${cfg.default}.desktop" ];
        "text/markdown" = [ "${cfg.default}.desktop" ];
      };
    };

    home.file = lib.mkMerge [
      (lib.mkIf cfg.vscode.enable {
        # Editor flags
        ".config/code-flags.conf".source = "${pkgs.hyde}/Configs/.config/code-flags.conf";
        ".config/codium-flags.conf".source = "${pkgs.hyde}/Configs/.config/codium-flags.conf";

        # VS Code settings
        ".config/Code - OSS/User/settings.json" = {
          source = "${pkgs.hyde}/Configs/.config/Code - OSS/User/settings.json";
          force = true;
          mutable = true;
        };
        ".config/Code/User/settings.json" = {
          source = "${pkgs.hyde}/Configs/.config/Code/User/settings.json";
          force = true;
          mutable = true;
        };
        ".config/VSCodium/User/settings.json" = {
          source = "${pkgs.hyde}/Configs/.config/VSCodium/User/settings.json";
          force = true;
          mutable = true;
        };
      })
      (lib.mkIf cfg.vscode.wallbash {
        # Link the wallbash extension from hyde package
        ".vscode/extensions/prasanthrangan.wallbash" = {
          source = "${pkgs.hyde}/share/vscode/extensions/prasanthrangan.wallbash";
          recursive = true;
          mutable = true;
          force = true;
        };
      })
      # Link user-provided extensions
      (lib.mkMerge (lib.lists.imap0 (i: ext:
        let
          publisher = lib.head (lib.splitString "." ext.vscodeExtPublisher);
          name = lib.last (lib.splitString "." ext.vscodeExtPublisher);
          extDir = ".vscode/extensions/${publisher}.${name}-${ext.vscodeExtUniqueId}";
        in
        {
          "${extDir}" = {
            source = "${ext}/share/vscode/extensions/${publisher}.${name}";
            recursive = true;
          };
        }
      ) cfg.vscode.extensions))

      (lib.mkIf (cfg.vim or cfg.neovim) {
        ".config/vim/colors/wallbash.vim" = {
          source = "${pkgs.hyde}/Configs/.config/vim/colors/wallbash.vim";
          force = true;
          mutable = true;
        };
        ".config/vim/hyde.vim".source = "${pkgs.hyde}/Configs/.config/vim/hyde.vim";
        ".config/vim/vimrc".source = "${pkgs.hyde}/Configs/.config/vim/vimrc";
      })
    ];

    home.sessionVariables = {
      EDITOR = cfg.default;
      VISUAL = cfg.default;
    };
  };
}
