godot --headless --path game --export-debug server built/server

dest_dir="infra/build/server/src/server"
if [ -d $dest_dir ]; then
    rm -rf $dest_dir
fi
mkdir -p $dest_dir
cp game/built/* $dest_dir
