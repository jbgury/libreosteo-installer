#!/bin/bash

myuser=${SUDO_USER:-$USER}


function migrate_db() {
  /Applications/LibreosteoService.app/Contents/MacOS/manage migrate --noinput
  chown -R ${myuser} "/Users/${myuser}/Library/Application Support/Libreosteo"
  chmod -R 777 /Applications/LibreosteoService.app/Contents/Resources/static/CACHE
}

function install_service() {
  agents_dir="/Users/${myuser}/Library/LaunchAgents"
  mkdir -p ${agents_dir}
  (
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  echo "<plist version=\"1.0\">"
  echo "<dict>"
  echo "	<key>KeepAlive</key>"
  echo "	<true/>"
  echo "	<key>Label</key>"
  echo "	<string>org.libreosteo.macos.LibreosteoService</string>"
  echo "	<key>ProgramArguments</key>"
  echo "	<array>"
  echo "		<string>/Applications/LibreosteoService.app/Contents/MacOS/LibreosteoService</string>"
  echo "	</array>"
  echo "	<key>RunAtLoad</key>"
  echo "	<true/>"
  echo "	<key>ProcessType</key>"
  echo "	<string>Background</string>"
  echo "</dict>"
  echo "</plist>"
  ) > ${agents_dir}/org.libreosteo.macos.LibreosteoService.plist
  chmod +x "${agents_dir}/org.libreosteo.macos.LibreosteoService.plist"
  chown -R ${myuser} "${agents_dir}/org.libreosteo.macos.LibreosteoService.plist"
  sudo -u ${myuser} launchctl load -w "${agents_dir}/org.libreosteo.macos.LibreosteoService.plist"
  sudo -u ${myuser} launchctl start org.libreosteo.macos.LibreosteoService
}

function remove_oldservice() {
  agents_dir="/Users/${myuser}/Library/LaunchAgents"
  sudo -u ${myuser} launchctl remove "${agents_dir}/org.libreosteo.macos.Libreosteo.plist"
  rm "${agents_dir}/org.libreosteo.macos.Libreosteo.plist"
}

function install_uninstaller() {
  script_dir=$DSTROOT/LibreosteoService.app/Contents/MacOS
  echo "Add uninstall script to $script_dir"
  cp -v uninstall.sh $script_dir/.
  chmod +x $script_dir/uninstall.sh
}

function update_reindex() {
   /Applications/LibreosteoService.app/Contents/MacOS/manage rebuild_index --noinput
   chown -R ${myuser} "/Users/${myuser}/Library/Application Support/Libreosteo/whoosh_index"
}

#####

migrate_db
update_reindex
remove_oldservice
install_service
install_uninstaller
