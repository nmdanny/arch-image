ARG archlinux_tag=base-devel
FROM archlinux:$archlinux_tag AS arch

RUN pacman -Syu --noconfirm

COPY packages.txt /tmp/packages.txt
RUN cat /tmp/packages.txt | xargs pacman -S --needed --noconfirm

RUN chsh -s /usr/bin/fish && \
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel && \
    # we use different uid/gid, since we want our custom user to have gid 1000 - see https://github.com/microsoft/WSL/issues/9689
    useradd --create-home builder -g 1234 -u 1234 && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

USER builder
RUN rustup default stable && \
    cd /tmp && \
    git clone https://aur.archlinux.org/paru.git && \
    cd paru && \
    makepkg -si --noconfirm && \
    paru -Syu --noconfirm mise go-task-bin flux-bin && \
    sudo rm -rf ~/.cache/* \
    sudo rm -rf /var/cache/pacman/pkg

USER root
COPY --chmod=700 wsl2-setup /usr/local/bin/wsl2-setup

FROM scratch

COPY --from=arch / /

USER root
ENTRYPOINT /usr/bin/fish
