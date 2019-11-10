#!/bin/sh
# OpenTaiko install script for Unix-like OSes.
# Change the environment variables to your desired values before executing this
# script, else the default values will apply.
# $OPENTAIKO_BINARY_INSTALLDIR - where binaries should be installed.
# $OPENTAIKO_RESOURCE_INSTALLDIR - where resources should be installed.

resource_install_dir=/usr/local/share/OpenTaiko
binary_install_dir=/usr/local/games
real_binary_name=OpenTaiko-real
launch_script_name=OpenTaiko

if [[ $real_binary_name == $launch_script_name ]] ; then
	echo "\$real_binary_name and \$launch_script_name cannot be equal; "\
		 "refusing to make fork bomb."
	exit 1;
fi
if [[ -v OPENTAIKO_BINARY_INSTALLDIR ]] ; then
	binary_install_dir=$OPENTAIKO_BINARY_INSTALLDIR;
fi
if [[ -v OPENTAIKO_RESOURCE_INSTALLDIR ]] ; then
	resource_install_dir=$OPENTAIKO_RESOURCE_INSTALLDIR;
fi

# If game binary can be found, copy it to $binary_install_dir as
# $real_binary_name, and create a start script based on the current environment
# in the same directory as $launch_script_name, and copy assets/ and locale/ to
# $resource_install_dir, creating it if necessary.
function install_game {
	if ! [[ -f "OpenTaiko" ]] ; then
		echo "You must compile the game before it can be installed. See"\
		     "README.md for instructions."
		exit 1;
	fi
	if ! [[ -a $resource_install_dir ]] ; then
		mkdir $resource_install_dir || exit 1;
	fi
	cp -r assets/ $resource_install_dir || exit 1
	cp -r locale/ $resource_install_dir || exit 1
	cp OpenTaiko $binary_install_dir/$real_binary_name || exit 1
	echo "#!"$(which sh) > $binary_install_dir/$launch_script_name || exit 1
	echo "export OPENTAIKO_INSTALLDIR="$resource_install_dir >> $binary_install_dir/$launch_script_name || exit 1
	echo $real_binary_name \"\$\@\" >> $binary_install_dir/$launch_script_name || exit 1
	echo "Installation complete."
	printf "If \"%s\" is on your PATH, you can run the game as \"%s\".\n"\
	       $binary_install_dir $launch_script_name
}

# Delete the start script and real binary from the binary install directory, and
# delete the asset and locale directories from the resource install directory.
# Deliberately does not delete the $resource_install_dir itself.
function uninstall_game {
	rm $binary_install_dir/$real_binary_name || exit 1
	rm $binary_install_dir/$launch_script_name || exit 1
	rm -r $resource_install_dir/assets || exit 1
	rm -r $resource_install_dir/locale || exit 1
	echo "Uninstallation complete."
}

case $1 in
	"--install")   install_game;;
	"--uninstall") uninstall_game;;
	"")            install_game;;
	*)             echo "Usage: "$0" [--install | --uninstall]" && exit 1;;
esac
