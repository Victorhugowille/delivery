#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git --depth 1 --branch 3.22.2 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

flutter doctor

flutter pub get

# Constrói o aplicativo para a web, desabilitando a otimização de ícones
flutter build web --release --no-tree-shake-icons