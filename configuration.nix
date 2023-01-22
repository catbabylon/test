# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  nix-software-center = (import (pkgs.fetchFromGitHub { # <-this section is for pulling in the nixos
    owner = "vlinkz";                                   #   software centre from github which is currently in 
    repo = "nix-software-center";                       #   early development so not in the nix store
    rev = "0.1.0";
    sha256 = "d4LAIaiCU91LAXfgPCWOUr2JBkHj6n0JQ25EqRIBtBM=";
  })) {};
in
{
  imports =
    [
      ./hardware-configuration.nix # <- Include the results of the hardware scan  (don't edit that file, this will override it)
      <home-manager/nixos> #  <- this is added to enable the 'home-manager' system
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest; # <- nix-os defaults to the LTS kernel but latest (6.x) has lots of fixes so worth having
  boot.loader.systemd-boot.enable = true; # <- nix-os uses systemd-boot by default which is newer than GRUB2 and generally better for modern systems
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelParams = [ "i915.enable_guc=3" "i915.enable_psr=1" ]; # <- kernel parameters (normally set in grub) first is to enable GuC/HuC GPU offloading, 2nd is panel self-refresh for laptop
  boot.initrd.kernelModules = [ "i915" ]; # <- early loading of the intel i915 gpu drivers sometimes helps stop flickering screen during boot
  services.xserver.videoDrivers = [ "modesetting" ]; # <- forces the modesetting driver. Might not need this as it is probably the default anyway
  boot.extraModprobeConfig = ''
    options i915 enable_guc=3
    '';
  console = { # ^ above is same as kernel paramemters earlier but set in the modprobe options for the init ramdisk
    font = "ter-powerline-v20n"; # <- this  is to set the TTY console font 
    packages = [                 # and this is to tell nixos to install the required font packages
      pkgs.terminus_font
      pkgs.powerline-fonts
    ];
  };
  # services.gpm.enable = true; # ... why not have mouse available in the tty console??
  # services.kmscon = { # ... enable the new KMSCON console rather than the old TTY
  #   enable = true;
  #   fonts = [ { name = "Maple Mono NF"; package = pkgs.maple-mono-NF; } ];
  #   extraConfig = "font-size=16";
  # };
  
  networking.hostName = "nixos-laptop"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.catbabylon = {
    isNormalUser = true;
    description = "catbabylon";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };

  # !!! HOME MANAGER !!! <- home manager set up as a module of the nixos configuration
  
  home-manager.users.catbabylon = { pkgs, ... }: {
    home.packages = [
      # this is where we would stick some packages we want to have installed as part of home manager 
    ];
    programs.zsh = { # zsh however has to be installed as a program because it has options and settings...
      enable = true;
        oh-my-zsh = { # such as the oh-my-zsh framework...
          enable = true;
          plugins = [
                      "git"
                      "battery"
                      "emoji-clock"
                      "history-substring-search"
                      "ruby"
                      "rust"
                      "sudo"
                      "systemd"
                    ]; # ...and all the lovely plugins 
          theme = "half-life"; # ...and the lovely themes
        };
      };
    dconf.settings = { # ... this is how we set dconf settings for gnome in nixos, this one is the equivalent of the 
      "org/gnome/mutter" = { # ... gsettings command that enables fractional scaling for hidpi monitors
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
    };
    home.stateVersion = "22.11"; # ... and lastly we set the version of nixos
  };
  # *** END OF HOME MANAGER ***


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true; # does what it says on the tin

  # Here we list packages installed in system profile...
  environment.systemPackages = with pkgs; [ # ...sometimes we options to include only certain extensions like with vscode here
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        rebornix.ruby
        matklad.rust-analyzer
        oderwat.indent-rainbow
        gitlab.gitlab-workflow
        dracula-theme.theme-dracula
        mads-hartmann.bash-ide-vscode
      ];
    })
    nix-software-center # ... but mostly we just list the package names that we get from the nixos search page
    wget
    curl
    git
    blackbox-terminal
    tdesktop
    micro
    epson-escpr
    epson-escpr2
    tidal-hifi
    gnomecast
    gnome-feeds
    gnome.pomodoro
    gnome.gnome-tweaks
    gnome.gnome-mines
    appimage-run
    abiword
    whatsapp-for-linux
    #tweet-hs
    t
    cawbird
    tg 
    kotatogram-desktop
    endless-sky
    qbittorrent
    alacritty
    sublime3
    gnome-extension-manager
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 22 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "22.11"; # don't change this even when we upgrade to 23.04. I have no idea why but thats the rules!
  
  fonts.fonts = with pkgs; [ # ... although fonts are packages we have to tell nixos to treat them as fonts
    inter # ... so they are listed under this fonts.fonts option
    roboto-slab
    maple-mono-NF
    (nerdfonts.override { fonts = [ "Meslo" "FantasqueSansMono" ]; }) # the nerd-fonts package contains LOADS of fonts, so here we tell it to only download the two we need...
  ];

  # Zsh stuff:
  environment.shells = with pkgs; [ zsh ]; # although we are managing z-shell through home-manager we have to have it installed systemwide too
  users.users.catbabylon.shell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  environment.sessionVariables = { # here are where we put the environment variables you'd normally add to your .profile or .bashrc
    MOZ_ENABLE_WAYLAND = "1"; # ... to make sure firefox loads in wayland natively
    XCURSOR_THEME = "Adwaita"; # ... these two are to make Qt apps like Telegram use GNOME's cursor theme
    XCURSOR_SIZE= "24";
    MICRO_TRUECOLOR="1";       # this is to make the cli editor 'micro' (like nano but much better) use truecolor 
    NIXOS_OZONE_WL = "1";      # ... this one is apparently to make vscode run in wayland natively, but looks like it will effect other apps too
  };
  hardware.opengl.enable = true; # apparently we need this to enable opengl bits of the gpu 

  # services.tlp.enable = true; # - not sure if this is needed as it conflicts with preset power options...

  fonts.fontDir.enable = true; # needed apparently to help flatpaks use system fonts (wasn't working when I tried)
  services.flatpak.enable = true; # and last but not least, enabling flatpak apps...

  nix.settings.auto-optimise-store = true; # optimse files
}
