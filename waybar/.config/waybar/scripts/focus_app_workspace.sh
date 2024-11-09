#!/bin/bash

# Parâmetro: nome da aplicação
app_name=$1

# Encontrar o workspace da aplicação usando hyprctl
workspace=$(hyprctl clients -j | jq -r ".[] | select(.title == \"$app_name\") | .workspace")

# Verificar se o workspace foi encontrado
if [ -n "$workspace" ]; then
	# Focar no workspace
	hyprctl dispatch workspace "$workspace"
else
	echo "Aplicação não encontrada ou não está aberta."
fi
