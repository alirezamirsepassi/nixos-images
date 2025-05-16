{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = ["${toString modulesPath}/profiles/qemu-guest.nix"];

  boot = {
    growPartition = true;
    kernelParams = ["console=ttyS0"];
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    loader = {
      timeout = 0;
      grub = {
        enable = true;
        device = "/dev/vda";
      };
    };
  };

  # Basic packages
  environment.systemPackages = with pkgs; [curl dnsutils htop jq tmux];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;

    # Delegate the hostname setting to cloud-init by default
    hostName = lib.mkOverride 1337 ""; # lower prio than lib.mkDefault
  };

  programs.git.enable = true;

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;

      # Never flush the host's SSH keys. See #148. Since we build the images
      # using NixOS, that kind of issue shouldn't happen to us.
      settings.ssh_deletekeys = false;

      ## Enable the EXT4 filesystem
      ext4.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        X11Forwarding = false;
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        UseDns = false;
        # unbind gnupg sockets if they exists
        StreamLocalBindUnlink = true;

        # Use key exchange algorithms recommended by `nixpkgs#ssh-audit`
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
      };
    };
  };

  system.build.qcow = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = "auto";
    format = "qcow2";
    partitionTableType = "hybrid";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
