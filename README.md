```
                  ::::::::              ::::::::
                :+:    :+:            :+:    :+:
     +:++:++:+ +:+    +:+ +:++:++:+  +:+    +:+  +:++:++:+
   +#+        +#+    +:+ +#+    +#+ +#+    +:+ +#+
  +#++:++#++ +#+    +#+ +#+    +#+ +#+    +#+ +#++:++#++
        #+# #+#    #+# #+#    #+# #+#    #+#        #+#
#########   ########  ###    ###  ########  #########
```

sOnOs is an Arch Linux-based operating system for developers and gamers. It installs a desktop with gaming support, NVIDIA drivers and, if you want them, complete development toolchains, on a plain Arch Linux base that stays compatible with the official repositories and the AUR.

This repository is the [archiso](https://gitlab.archlinux.org/archlinux/archiso) profile that builds the sOnOs live ISO. The installer, **soninstall**, lives in [sOnInstall](https://github.com/aOnurTheDev/sOnInstall).

> **Note:** sOnOs is in **beta** and under active development.

## The live ISO

The ISO boots into a console and starts soninstall on the first console automatically. It is also a full rescue system:

| Category | Included |
| :--- | :--- |
| **Graphics** | NVIDIA open kernel driver (`nvidia-open`) |
| **Disks & recovery** | Clonezilla, partclone, TestDisk, ddrescue, fsarchiver, smartmontools, and tools for btrfs, bcachefs, ext4, XFS, F2FS, NTFS, exFAT, LVM, RAID and LUKS |
| **Networking** | iwd (Wi-Fi), ModemManager (mobile broadband), NetworkManager, OpenSSH, OpenVPN, WireGuard, nmap, tcpdump |
| **Virtualization** | Docker, QEMU, and guest tools for QEMU, VMware, VirtualBox and Hyper-V |
| **Development** | GCC, Clang, CMake, GDB, Valgrind, Rust, Go, Python, Node.js, Deno, OpenJDK, Lua, Git |
| **Embedded** | Arduino CLI, AVR toolchain, avrdude, OpenOCD, st-link, dfu-util, minicom |
| **Command line** | zsh, Neovim, nano, tmux, btop, fastfetch, ripgrep, fd, jq, 7-Zip |

## The installed system

soninstall asks only for:

1. Language
2. Keyboard layout
3. Username
4. Password (also used for root)
5. Time zone
6. Desktop environment
7. Whether to install the NVIDIA driver
8. Whether to install the development tools (about 10 GB)
9. Disk

Every installation includes:

- **Gaming:** Steam, GameMode, and Vulkan drivers (64- and 32-bit) for the GPU it finds.
- **Desktop apps:** Firefox (in your language when a translation exists), VLC, Blueman and pavucontrol.
- **Tools:** zsh, Neovim, Vim, micro, Git, fastfetch, btop and 7-Zip, plus the hardware, disk and network tools from the live ISO.
- **sOnOs branding:** logo, `os-release` and fastfetch theme, kept across updates.

The development tools add C/C++ build tools, Visual Studio Code, Docker, embedded tools (Arduino, AVR, STM32), and compilers or runtimes for Rust, Go, Python, Java, JavaScript/TypeScript, Ruby, PHP, Lua, Perl, Haskell, R, Elixir, OCaml, Fortran, Zig, D, C#/F# (.NET), Kotlin, Dart, Julia, Erlang, Clojure, Common Lisp, Scheme, Prolog, Nim, Crystal, Vala, Groovy and Assembly.

> **Note:** `nvidia-open` supports NVIDIA GPUs from the GTX 16 and RTX 20 series onward. Older cards should skip the NVIDIA driver; the open-source drivers are installed instead.

## Installation

1. Download the latest ISO from the Releases section.

   GitHub limits release files to 2 GiB, so a larger ISO is split into parts named `sOnOs.iso.7z.001`, `sOnOs.iso.7z.002` and so on. Download every part into the same folder, then extract the first one:

   ```bash
   7z x sOnOs.iso.7z.001
   ```

   On Windows, right-click `sOnOs.iso.7z.001` and extract it with [7-Zip](https://www.7-zip.org). Either way you get the `.iso` file. A ZIP does not make the ISO smaller, because it is already compressed.

2. Write the ISO to a USB drive with Ventoy, balenaEtcher or `dd`:

   ```bash
   sudo dd bs=4M if=sOnOs-x86_64.iso of=/dev/sdX status=progress oflag=sync
   ```

3. Boot from the USB drive. soninstall starts on its own.

4. If you need Wi-Fi first, quit soninstall, connect with `iwctl`, then run `soninstall` again.

## Building the ISO

Building needs an Arch Linux system (or an Arch-based one) with `archiso` installed.

1. Build the soninstall package repository with `packaging/local/build-repo.sh` from [sOnInstall](https://github.com/aOnurTheDev/sOnInstall).

2. Point the `[sonos]` repository in [pacman.conf](pacman.conf) at that folder:

   ```ini
   [sonos]
   SigLevel = Optional TrustAll
   Server = file:///path/to/repo
   ```

3. Build:

   ```bash
   sudo mkarchiso -v -w /tmp/sonos-work -o out .
   ```

   The ISO is written to `out/`.

## Contributing

Bug reports, feedback and pull requests are welcome. Open an issue or a pull request on GitHub.

## License

Distributed under the GPL-2.0 License.
