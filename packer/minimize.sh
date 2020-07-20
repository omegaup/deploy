#!/bin/bash

# This is to fill all unused space with 0s, in order to
# optimize compression after the image is created

# dd will fail when the disk fills up, we will ignore that error
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY
