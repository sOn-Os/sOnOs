<p align="center">
  <img src=".github/banner.png" alt="sOnOs" width="100%">
</p>

<p align="center">
  <b>Plain Arch Linux. Nine questions to install.</b><br>
  An operating system for developers and gamers.
</p>

<p align="center">
  <a href="https://son-os.github.io/#indir"><img src="https://img.shields.io/badge/download-ISO-E53935?style=for-the-badge" alt="Download the ISO"></a>
  <a href="https://github.com/sOn-Os/sOnOs/releases/latest"><img src="https://img.shields.io/github/v/release/sOn-Os/sOnOs?style=for-the-badge&label=release&color=0B0909" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/base-Arch%20Linux-0B0909?style=for-the-badge" alt="Base: Arch Linux">
  <img src="https://img.shields.io/badge/license-GPL--2.0-0B0909?style=for-the-badge" alt="License: GPL-2.0">
</p>

---

sOnOs installs a desktop with gaming support, the NVIDIA driver and, if you want them, complete development toolchains, on a plain Arch Linux that stays compatible with the official repositories and the AUR.

This repository is the [archiso](https://gitlab.archlinux.org/archlinux/archiso) profile that builds the sOnOs live ISO. The installer, **soninstall**, lives in [sOnInstall](https://github.com/sOn-Os/sOnInstall).

## Contents

- [Installing sOnOs](#installing-sonos)
- [Verifying the download](#verifying-the-download)
- [Nine questions](#nine-questions)
- [What you get](#what-you-get)
- [The live ISO](#the-live-iso)
- [Building the ISO](#building-the-iso)
- [Releasing](#releasing)
- [Contributing](#contributing)

## Installing sOnOs

| Step | |
|:---:|---|
| **1** | Download the ISO, see below. |
| **2** | Write it to a USB drive with Ventoy, balenaEtcher or `dd`. |
| **3** | Boot from the USB drive. soninstall starts by itself. |
| **4** | Answer nine questions, check the summary and confirm. |

The ISO is one file of about 3.1 GiB:

| | |
|---|---|
| **SourceForge** | <https://sourceforge.net/projects/sonos/files/latest/download> |
| **Google Drive** (mirror) | <https://drive.google.com/file/d/1EBfFsHg2rxhtojXgOF9z-vgoghwFCJsb/view> |
| **Checksum and signature** | [the latest release](https://github.com/sOn-Os/sOnOs/releases/latest) |

<!-- TODO(sOnOs): the SourceForge address above is a placeholder. Replace it with the real project address once the project exists. -->
> [!NOTE]
> **TODO:** the SourceForge project is not set up yet, so that link does not work for now. Use the Google Drive mirror.

GitHub limits release files to 2 GiB, so the ISO itself is not on the release page; the release has its checksum and signature. The same links are on [son-os.github.io](https://son-os.github.io/#indir).

<details>
<summary>Writing the USB drive with dd</summary>

```shell
sudo dd bs=4M if=sOnOs-x86_64.iso of=/dev/sdX status=progress oflag=sync
```

`dd` erases everything on the target disk. Replace `sdX` with your USB drive and check it with `lsblk` first.

</details>

> [!TIP]
> No network cable? The installer offers to connect to Wi-Fi before it starts. You can also quit it, connect with `iwctl`, and run `soninstall` again.

## Verifying the download

Download `sOnOs-<version>-x86_64.iso.sha256` from [the latest release](https://github.com/sOn-Os/sOnOs/releases/latest) into the folder of the ISO and run:

```shell
sha256sum -c sOnOs-<version>-x86_64.iso.sha256
```

It prints `OK` when the download is intact. On Windows, `Get-FileHash sOnOs-<version>-x86_64.iso` in PowerShell prints the checksum to compare with the one in that file.

The checksum catches a broken download. The signature also shows that the ISO comes from sOnOs:

```shell
curl -LO https://raw.githubusercontent.com/sOn-Os/sOnOs/master/packages/sonos-keyring/sonos.gpg
gpg --import sonos.gpg
gpg --verify sOnOs-<version>-x86_64.iso.sig sOnOs-<version>-x86_64.iso
```

`gpg` should say `Good signature` and print this fingerprint:

```
50DC 9400 E338 5CAB FF14  C9FF 7588 C65A 3E0D 5A36
```

## Nine questions

| | | | |
|:---:|---|:---:|---|
| **1** | Language | **6** | Desktop environment |
| **2** | Keyboard layout | **7** | NVIDIA driver |
| **3** | Username | **8** | Development tools |
| **4** | Password, also used for root | **9** | Disk |
| **5** | Time zone | | |

The installer continues in the chosen language, and the installed system gets it too. Everything else uses sensible defaults: NetworkManager, PipeWire, Bluetooth, zram swap and systemd-boot. A summary is shown before anything is written to the disk.

> [!NOTE]
> `nvidia-open` supports NVIDIA GPUs from the GTX 16 and RTX 20 series onward. With an older card, answer "no" to question 7; the open-source drivers are installed instead.

## What you get

| | |
|---|---|
| **Gaming** | Steam, GameMode, and Vulkan drivers (64- and 32-bit) for the GPU in the machine |
| **Performance** | Tuning in the style of CachyOS: ananicy-cpp with CachyOS's rules for about 360 programs, the `scx_lavd` sched_ext CPU scheduler, an I/O scheduler per disk type, and memory settings for zram swap ([sonos-settings](packages/sonos-settings)) |
| **Desktop** | The environment you picked with its everyday apps, Firefox in your language, VLC, Blueman and pavucontrol |
| **Tools** | zsh, Neovim, Vim, micro, Git, fastfetch, btop and 7-Zip, plus the hardware, disk and network tools of the live ISO |
| **sOnOs** | The logo, wallpaper, `os-release` and fastfetch theme, kept across updates |
| **Development** *(optional, ~10 GB)* | C/C++ build tools, Visual Studio Code, Docker, embedded tools (Arduino, AVR, STM32), and compilers or runtimes for over 30 languages |

An installation takes about **7 GB**, or about **17 GB** with the development tools.

<details>
<summary>Changing or turning off the performance tuning</summary>

- Another CPU scheduler: `scxctl switch --sched bpfland` (list them with `scxctl list`), or for good: `default_sched` in `/etc/scx_loader/config.toml`. Back to the kernel's scheduler: `sudo systemctl disable --now scx_loader`.
- Process priorities: `sudo systemctl disable --now ananicy-cpp`. Your own rules go in `/etc/ananicy.d/`.
- Memory settings: override any value in `/etc/sysctl.d/99-local.conf`.

</details>

<details>
<summary>All development languages</summary>

Rust, Go, Python, Java, JavaScript/TypeScript, Ruby, PHP, Lua, Perl, Haskell, R, Elixir, OCaml, Fortran, Zig, D, C#/F# (.NET), Kotlin, Dart, Julia, Erlang, Clojure, Common Lisp, Scheme, Prolog, Nim, Crystal, Vala, Groovy and Assembly.

</details>

## The live ISO

Before you install anything, the same USB drive is a full rescue system:

| | |
|---|---|
| **Graphics** | NVIDIA open kernel driver (`nvidia-open`) |
| **Disks & recovery** | Clonezilla, partclone, TestDisk, ddrescue, fsarchiver, smartmontools, and tools for btrfs, bcachefs, ext4, XFS, F2FS, NTFS, exFAT, LVM, RAID and LUKS |
| **Networking** | iwd, ModemManager, NetworkManager, OpenSSH, OpenVPN, WireGuard, nmap, tcpdump |
| **Virtualization** | Docker, QEMU, and guest tools for QEMU, VMware, VirtualBox and Hyper-V |
| **Development** | GCC, Clang, CMake, GDB, Valgrind, Rust, Go, Python, Node.js, Deno, OpenJDK, Lua, Git |
| **Embedded** | Arduino CLI, AVR toolchain, avrdude, OpenOCD, st-link, dfu-util, minicom |
| **Command line** | zsh, Neovim, nano, tmux, btop, fastfetch, ripgrep, fd, jq, 7-Zip |

## Building the ISO

You need Arch Linux, or an Arch-based system, with `archiso` and `base-devel` installed, and [sOnInstall](https://github.com/sOn-Os/sOnInstall) checked out next to this repository.

1. Build the local package repository the ISO installs `soninstall` from. It goes to `/var/tmp/sonos-repo`, the path in [pacman.build.conf](pacman.build.conf):

   ```shell
   scripts/build-local-repo.sh
   ```

   With the sOnInstall checkout somewhere else: `scripts/build-local-repo.sh -s <sOnInstall checkout>`.

2. Build the ISO from this folder:

   ```shell
   sudo mkarchiso -v -r -w /var/tmp/sonos-work -o out .
   ```

   It is written to `out/`. The build needs about 20 GB of free disk space in `/var/tmp`; `/tmp` is too small, it is kept in memory.

`pacman.build.conf` is used only while building: it trusts that local folder without signatures. It is not the `pacman.conf` of the live ISO or of installed systems.

The same build runs in GitHub Actions, see [build-iso.yml](.github/workflows/build-iso.yml): on a `v*` tag, or by hand from the Actions tab.

## Releasing

- [docs/RELEASE.md](docs/RELEASE.md): the release checklist.
- [docs/signing.md](docs/signing.md): the signing key, the signed `[sonos]` package repository and the secrets the workflow can use.

## Contributing

Bug reports, feedback and pull requests are welcome; open an [issue](https://github.com/sOn-Os/sOnOs/issues) or a pull request, and ask questions in [Discussions](https://github.com/sOn-Os/sOnOs/discussions). The installer is translated into more than 40 languages, and new translations are welcome in [sOnInstall](https://github.com/sOn-Os/sOnInstall).

<p align="center">
  <sub>sOnOs is distributed under the GPL-2.0 license. It is an independent distribution, not affiliated with the Arch Linux project.</sub>
</p>
