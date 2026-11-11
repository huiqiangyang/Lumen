# Maintainer: Lumen
# Written by mygo build next to the app's archive: makepkg -si packages
# the app for Arch Linux and installs it.
pkgname='lumen'
pkgver='0.1.1'
pkgrel=1
pkgdesc='An Agent-first, IDEA-aligned lightweight IDE'
arch=('x86_64')
license=('LicenseRef-custom')
depends=('gtk3' 'webkit2gtk-4.1')
options=('!strip' '!debug')
source=('lumen-0.1.1-linux-amd64.tar.gz' 'lumen-256x256.png' 'lumen-512x512.png')
sha256sums=('be67e109c3b73ebc0fec3b9eef3fdc70579c987667c36becd9d1df3be1071de2' 'abc0acb5fe51c6be0355a8ba3c73f8aafe8deefed2fa0a8728d5937cc556f289' 'a390fbb25292c58da61925b2ed7f3ed69586162d0dbd9737aa9ef92b3ebfc4ba')

package() {
	cd "$srcdir"
	install -d "$pkgdir"/opt/lumen
	cp -dR -- icon.png libghostty-vt.so lumen .mygo-files "$pkgdir"/opt/lumen/
	# The modes of the Debian package: 755 for directories and programs, 644
	# for the other files.
	find "$pkgdir"/opt/lumen -type d -exec chmod 755 {} +
	find "$pkgdir"/opt/lumen -type f -perm /111 -exec chmod 755 {} +
	find "$pkgdir"/opt/lumen -type f ! -perm /111 -exec chmod 644 {} +
	install -d "$pkgdir"/usr/bin
	ln -s ../../opt/lumen/lumen "$pkgdir"/usr/bin/lumen
	printf '%s' '[Desktop Entry]
Type=Application
Name=Lumen
Comment=An Agent-first, IDEA-aligned lightweight IDE
Exec=/opt/lumen/lumen
Icon=lumen
Categories=Development;TextEditor;
Terminal=false
StartupWMClass=lumen
' |
		install -Dm644 /dev/stdin "$pkgdir"/usr/share/applications/lumen.desktop
	install -Dm644 lumen-256x256.png "$pkgdir"/usr/share/icons/hicolor/256x256/apps/lumen.png
	install -Dm644 lumen-512x512.png "$pkgdir"/usr/share/icons/hicolor/512x512/apps/lumen.png
}
