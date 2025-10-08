#!/bin/bash
set -e

# Instala a versão específica do Flutter
git clone https://github.com/flutter/flutter.git --depth 1 --branch 3.22.2 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verifica a instalação
flutter doctor

# Baixa as dependências do projeto
flutter pub get

# Compila o projeto para a web
flutter build web --release