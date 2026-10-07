# Disko skeleton for onix — mirrors current btrfs layout
# Not active until you import it in hosts/onix/default.nix and set disko.enable
# To apply: nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko/onix.nix
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-diskseq/1"; # TODO: replace with actual disk e.g. /dev/nvme0n1
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}
