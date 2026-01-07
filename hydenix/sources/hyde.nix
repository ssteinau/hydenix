{ pkgs, inputs }:
pkgs.stdenv.mkDerivation {
  name = "hyde-modified";
  src = inputs.hyde;

  nativeBuildInputs = with pkgs; [
    gnutar
    unzip
  ];

  buildPhase = ''
    # remove assets folder
    rm -rf Source/assets

    rm -rf Configs/.local/lib/hyde/resetxdgportal.sh
    rm -rf Configs/.local/bin/hydectl
    rm -rf Configs/.local/bin/hyde-ipc
    rm -rf Configs/.local/lib/hyde/hyde-config
    rm -rf Configs/.local/lib/hyde/hyq
    rm -rf Configs/.local/bin/hyq

    # Update waybar killall command in all HyDE files
    find . -type f -print0 | xargs -0 sed -i 's/killall waybar/killall .waybar-wrapped/g'

    # update dunst
    find . -type f -print0 | xargs -0 sed -i 's/killall dunst/killall .dunst-wrapped/g'

    # update kitty
    find . -type f -print0 | xargs -0 sed -i 's/killall kitty/killall .kitty-wrapped/g'
    find . -type f -print0 | xargs -0 sed -i 's/killall -SIGUSR1 kitty/killall -SIGUSR1 .kitty-wrapped/g'

    # fix find commands for symlinks
    find . -type f -executable -print0 | xargs -0 sed -i 's/find "/find -L "/g'
    find . -type f -name "*.sh" -print0 | xargs -0 sed -i 's/find "/find -L "/g'

    # remove lines 187-190 from Configs/.local/lib/hyde/theme.switch.sh
    # fixes gtk4 themes
    sed -i '187,190d' Configs/.local/lib/hyde/theme.switch.sh

    # remove pkill command from rofilaunch.sh
    sed -i '5d' Configs/.local/lib/hyde/rofilaunch.sh

    # Fix windowrules for Hyprland 0.53+ compatibility
    # Fix line 11: floating:1 syntax and < symbols
    sed -i '11s/windowrule = size <85% <95%,floating:1/windowrulev2 = size 85% 95%,floating:1/' Configs/.local/share/hypr/windowrules.conf
    # Fix line 12: windowrule with tag needs windowrulev2
    sed -i '12s/^windowrule = float,tag:/windowrulev2 = float,tag:/' Configs/.local/share/hypr/windowrules.conf
    # Fix line 13: remove < symbols and use windowrulev2 for tag
    sed -i '13s/windowrule = size <60% <90%,tag:/windowrulev2 = size 60% 90%,tag:/' Configs/.local/share/hypr/windowrules.conf
    # Fix line 16: windowrule with tag needs windowrulev2
    sed -i '16s/^windowrule = float,tag:/windowrulev2 = float,tag:/' Configs/.local/share/hypr/windowrules.conf
    # Fix lines 21-22,24-26: multiple criteria need windowrulev2
    sed -i '21s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '22s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '24s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '25s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '26s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    # Fix lines 41-61: tag rules with title/class need windowrulev2
    sed -i '41,61s/^windowrule = tag/windowrulev2 = tag/' Configs/.local/share/hypr/windowrules.conf
    # Fix line 17: windowrule with tag needs windowrulev2
    sed -i '17s/^windowrule = center,tag:/windowrulev2 = center,tag:/' Configs/.local/share/hypr/windowrules.conf
    # Fix lines 20,23,27-38: all remaining float rules need windowrulev2
    sed -i '20s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '23s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf
    sed -i '27,38s/^windowrule = /windowrulev2 = /' Configs/.local/share/hypr/windowrules.conf

    # BUILD FONTS
    mkdir -p $out/share/fonts/truetype
    for fontarchive in ./Source/arcs/Font_*.tar.gz; do
      if [ -f "$fontarchive" ]; then
        tar xzf "$fontarchive" -C $out/share/fonts/truetype/
      fi
    done

    # BUILD VSCODE EXTENSION
    mkdir -p $out/share/vscode/extensions/prasanthrangan.wallbash
    unzip ./Source/arcs/Code_Wallbash.vsix -d $out/share/vscode/extensions/prasanthrangan.wallbash
    # Ensure extension is readable and executable
    chmod -R a+rX $out/share/vscode/extensions/prasanthrangan.wallbash

    # BUILD GRUB THEMES
    mkdir -p $out/share/grub/themes
    tar xzf ./Source/arcs/Grub_Retroboot.tar.gz -C $out/share/grub/themes
    tar xzf ./Source/arcs/Grub_Pochita.tar.gz -C $out/share/grub/themes

    # BUILD ICONS
    mkdir -p $out/share/icons
    tar xzf ./Source/arcs/Icon_Wallbash.tar.gz -C $out/share/icons

    # BUILD GTK THEME
    mkdir -p $out/share/themes
    tar xzf ./Source/arcs/Gtk_Wallbash.tar.gz -C $out/share/themes
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
