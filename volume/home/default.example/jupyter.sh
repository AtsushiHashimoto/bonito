#!/bin/bash

. /root/.bashrc
cd /root/
/root/.pyenv/shims/jupyter-notebook --ip=$(hostname -I | cut -f1 -d' ') --no-browser --allow-root
