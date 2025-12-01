# Old Wine Builder

This is a generic wine builder to build Wine for Affinity by Canva.

## Image

Build the Linux container image:

```sh
podman build -t old-wine-builder -f Containerfile

# clear dangling images from local storage
podman system prune
```

## Building

1. Download the Wine src, either official or various forks.
   Choose Wine 10.4 if unsure which version.
2. Extract and navigate to the folder.
3. Apply patches to the Wine src 9.14, 9.22, 10.1, 10.4, or 10.11.
4. Run the docker image in the folder, using bind mount.
5. Move the "wine-install" folder to a final destination.

```sh
cd path-to/wine-source-folder/

# apply patches
/path-to/patches/patchinstall.sh

# you can use `docker` instead of `podman` to build Wine
podman run --rm --init -it \
  -v ./:/wine-builder/wine-src old-wine-builder

# move the "wine-install" folder and append the version
# set your Wine prefix to this path, run "wineboot -u" to update
mv wine-install $HOME/.wine-install-10.4
```

The script defaults to 4 threads. If you wish to use more for faster builds, set the `BUILD_THREADS` env var.

```sh
podman run --rm --init -it -e BUILD_THREADS=8 \
  -v ./:/wine-builder/wine-src old-wine-builder
```

If you wish the build to produce debugging information, set the `BUILD_DEBUG` env var.

```sh
podman run --rm --init -it -e BUILD_THREADS=8 -e BUILD_DEBUG=1 \
  -v ./:/wine-builder/wine-src old-wine-builder
```

Wayland support is enabled by default. To disable, set the `BUILD_WAYLAND` env var.

```sh
podman run --rm --init -it -e BUILD_THREADS=8 -e BUILD_WAYLAND=0 \
  -v ./:/wine-builder/wine-src old-wine-builder
```

Finally, if you are on Fedora or any distro using SELinux, you need to append a `:Z` to the end of the bind mount.

```sh
podman run --rm --init -it \
  -v ./:/wine-builder/wine-src:Z old-wine-builder
```

### Information

_This GitHub repo is not intended for Wine bug fixes. Please refer to upstream support._

The motivation for this project is wanting to run an older Wine release.

[📜 FAQ](/FAQ.md)

[📜 Wine Patches](/patches)

[📜 Patch Origin](https://gitlab.winehq.org/ElementalWarrior/wine/-/commits/affinity-photo3-wine9.13-part3)

[📜 Legacy NTsync patch for Wine v9.22](https://github.com/Frogging-Family/wine-tkg-git/pull/1348/)

[📜 Credits](/Credits.md)

