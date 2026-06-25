#!/bin/bash

# Ensure Walker service is started automatically on boot
mkdir -p ~/.config/autostart/
cp $MAITRI_PATH/default/walker/walker.desktop ~/.config/autostart/

# And is restarted if it crashes or is killed
mkdir -p ~/.config/systemd/user/app-walker@autostart.service.d/
cp $MAITRI_PATH/default/walker/restart.conf ~/.config/systemd/user/app-walker@autostart.service.d/restart.conf

# Create pacman hook to restart walker after updates
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/walker-restart.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = walker
Target = walker-debug
Target = elephant*

[Action]
Description = Restarting Walker services after system update
When = PostTransaction
Exec = $MAITRI_PATH/bin/maitri-restart-walker
EOF

# Link the visual theme menu config
mkdir -p ~/.config/elephant/menus
ln -snf $MAITRI_PATH/default/elephant/maitri_themes.lua ~/.config/elephant/menus/maitri_themes.lua
ln -snf $MAITRI_PATH/default/elephant/maitri_background_selector.lua ~/.config/elephant/menus/maitri_background_selector.lua
ln -snf $MAITRI_PATH/default/elephant/maitri_unlocks.lua ~/.config/elephant/menus/maitri_unlocks.lua
