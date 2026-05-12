{pkgs, ...}: {
  # Base packages for every machine in my inventory.
  environment.systemPackages = with pkgs; [
    efibootmgr # Linux user-space application to modify the Intel Extensible Firmware Interface (EFI) Boot Manager

    gptfdisk # Set of text-mode partitioning tools for Globally Unique Identifier (GUID) Partition Table (GPT) disks
    parted # Create, destroy, resize, check, and copy partitions
    tparted # Text-based user interface (TUI) frontend for parted

    git # Distributed version control system

    vim # Most popular clone of the VI editor

    wget # Tool for retrieving files using HTTP, HTTPS, and FTP
    curl # Command line tool for transferring files with URL syntax
  ];
}
