# Copy over maitri configs
mkdir -p ~/.config
cp -R ~/.local/share/maitri/config/* ~/.config/

# Use default bashrc from maitri
cp ~/.local/share/maitri/default/bashrc ~/.bashrc
