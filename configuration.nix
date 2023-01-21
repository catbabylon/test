# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  nix-software-center = (import (pkgs.fetchFromGitHub {
    owner = "vlinkz";
    repo = "nix-software-center";
    rev = "0.1.0";
    sha256 = "d4LAIaiCU91LAXfgPCWOUr2JBkHj6n0JQ25EqRIBtBM=";
  })) {};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelParams = [ "i915.enable_guc=3" "i915.enable_psr=1" ];
  boot.initrd.kernelModules = [ "i915" ];
  services.xserver.videoDrivers = [ "modesetting" ];
  boot.extraModprobeConfig = ''
    options i915 enable_guc=3
    '';
  console = {
    font = "ter-powerline-v20n";
    packages = [
      pkgs.terminus_font
      pkgs.powerline-fonts
    ];
  };

  networking.hostName = "nixos-laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

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

  # !!! HOME MANAGER !!!
  
  home-manager.users.catbabylon = { pkgs, ... }: {
    home.packages = [
      # stick some home packages here
    ];
    programs.zsh = {
      enable = true;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" "battery" "emoji-clock" "history-substring-search" "ruby" "rust" "sudo" "systemd" ];
          theme = "half-life";
        };
      };
    dconf.settings = {
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
    };
    home.stateVersion = "22.11";
  };
  # *** END OF HOME MANAGER ***


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    nix-software-center
    wget
    curl
    git
    # blackbox-terminal
    tdesktop
    micro
    epson-escpr
    epson-escpr2
    turses
    tidal-hifi
    gnomecast
    gnome-feeds
    gnome.pomodoro
    gnome.gnome-tweaks
    gnome.gnome-mines
    appimage-run
    abiword
    vscode-with-extensions
    vscode-extensions.mkhl.direnv
    whatsapp-for-linux
    gnomeExtensions.ddterm
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

  system.stateVersion = "22.11"; # don't change this

  # services.flatpak.enable = true;
  
  fonts.fonts = with pkgs; [
    inter
    roboto-slab
    maple-mono-NF
    (nerdfonts.override { fonts = [ "Meslo" "FantasqueSansMono" ]; })
  ];

  # Zsh stuff:
  environment.shells = with pkgs; [ zsh ];
  users.users.catbabylon.shell = pkgs.zsh;
  programs.zsh = {
    enable = true;
  };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE= "24";
    MICRO_TRUECOLOR="1";
  };
  hardware.opengl.enable = true;

  # services.tlp.enable = true; # - not sure if this is needed as it conflicts with preset power options...

  fonts.fontDir.enable = true;
  services.flatpak.enable = true;

}