# GNU Guix --- Functional package management for GNU
# Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
#
# This file is part of GNU Guix.
#
# GNU Guix is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GNU Guix is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

#
# Test the `guix-package' command-line utility.
#

guix-package --version

profile="t-profile-$$"
rm -f "$profile"

trap 'rm "$profile" "$profile-"[0-9]* ; rm -rf t-home-'"$$" EXIT

boot_guile="`guix-build -e '(@ (distro packages bootstrap) %bootstrap-guile)'`"

guix-package --bootstrap -p "$profile" -i "$boot_guile"
test -L "$profile" && test -L "$profile-1-link"
test -f "$profile/bin/guile"

# Installing the same package a second time does nothing.
guix-package --bootstrap -p "$profile"						\
    -i `guix-build -e '(@@ (distro packages base) %bootstrap-guile)'`
test -L "$profile" && test -L "$profile-1-link"
! test -f "$profile-2-link"
test -f "$profile/bin/guile"

# Check whether we have network access.
if guile -c '(getaddrinfo "www.gnu.org" "80" AI_NUMERICSERV)' 2> /dev/null
then
    guix-package --bootstrap -p "$profile"						\
	-i `guix-build -e '(@@ (distro packages base) gnu-make-boot0)'`
    test -L "$profile-2-link"
    test -f "$profile/bin/make" && test -f "$profile/bin/guile"


    # Check whether `--list-installed' works.
    # XXX: Change the tests when `--install' properly extracts the package
    # name and version string.
    installed="`guix-package -p "$profile" --list-installed | cut -f1 | xargs echo | sort`"
    case "x$installed" in
	"guile-bootstrap make-boot0")
	    true;;
	"make-boot0 guile-bootstrap")
	    true;;
	"*")
            false;;
    esac

    test "`guix-package -p "$profile" -I 'g.*e' | cut -f1`" = "guile-bootstrap"

    # Remove a package.
    guix-package --bootstrap -p "$profile" -r "guile-bootstrap"
    test -L "$profile-3-link"
    test -f "$profile/bin/make" && ! test -f "$profile/bin/guile"
fi

# Make sure the `:' syntax works.
guix-package --bootstrap -i "binutils:lib" -p "$profile" -n

# Check whether `--list-available' returns something sensible.
guix-package -A 'gui.*e' | grep guile

# Try with the default profile.

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CACHE_HOME
HOME="t-home-$$"
export HOME

mkdir -p "$HOME"

guix-package --bootstrap -i "$boot_guile"
test -L "$HOME/.guix-profile"
test -f "$HOME/.guix-profile/bin/guile"
