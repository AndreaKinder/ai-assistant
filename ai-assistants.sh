#!/bin/bash

# Asistente virtual con Gemini - v1.0
# Fecha: 23 de abril de 2025

# Colores del tema Dracula
FUCHSIA='\033[38;5;213m' # Color para respuestas de la IA
GREEN='\033[38;5;84m'    # Color para el usuario
YELLOW='\033[38;5;228m'  # Color para advertencias/información
CYAN='\033[38;5;117m'    # Color para comandos/acciones
PURPLE='\033[38;5;141m'  # Color para títulos
RESET='\033[0m'          # Restablecer color

# Directorios de configuración
CONFIG_DIR="$HOME/.config/ai-assistants"
PLUGINS_DIR="$CONFIG_DIR/mcp-plugins"
CONDITIONS_RESPONSE_DIR="$CONFIG_DIR/conditions-response.json"
MEMORY_DIR="$CONFIG_DIR/conversation_history.json"

# Función para imprimir encabezados
print_header() {
  echo -e "\n${PURPLE}===============================================${RESET}"
  echo -e "${PURPLE}$1${RESET}"
  echo -e "${PURPLE}===============================================${RESET}"
}

# Función para imprimir mensajes de la IA
ai_message() {
  echo -e "${FUCHSIA}AI Assistant: ${1}${RESET}"
}

# Función para imprimir mensajes del usuario
user_message() {
  echo -e "${GREEN}User: ${1}${RESET}"
}

# Función para imprimir información
info_message() {
  echo -e "${YELLOW}[INFO] ${1}${RESET}"
}

# Función para comprobar dependencias
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    info_message "$1 no está instalado. Instalando..."
    return 1
  else
    return 0
  fi
}

# Función para instalar dependencias
install_dependencies() {
  print_header "Comprobando dependencias"

  # Paquetes necesarios
  local dependencies=("curl" "jq" "python3" "pip" "npm" "nodejs")

  for dep in "${dependencies[@]}"; do
    if ! check_dependency "$dep"; then
      case "$dep" in
      "curl" | "jq")
        sudo apt-get update && sudo apt-get install -y "$dep"
        ;;
      "python3" | "pip")
        sudo apt-get update && sudo apt-get install -y python3 python3-pip
        ;;
      "npm" | "nodejs")
        sudo apt-get update && sudo apt-get install -y nodejs npm
        ;;
      esac
    else
      info_message "$dep ya está instalado."
    fi
  done

  # Verificamos si ya están instaladas las bibliotecas Python necesarias
  if ! pip list | grep -q "google-generativeai"; then
    info_message "Instalando bibliotecas Python necesarias..."
    pip install --user google-generativeai openai prompt_toolkit colorama
  fi
}

# Función para configurar la API de Gemini
configure_gemini() {
  print_header "Configuración de Gemini API"

  # Crear directorio de configuración si no existe
  mkdir -p "$CONFIG_DIR"

  # Verificar si ya existe la configuración
  if [ -f "$CONFIG_DIR/gemini_api_key.txt" ]; then
    info_message "La API de Gemini ya está configurada."
    read -p "¿Desea reconfigurar? (s/n): " reconfigure
    if [[ "$reconfigure" != "s" ]]; then
      return
    fi
  fi

  # Solicitar API key de Gemini
  echo -e "${CYAN}Por favor, ingrese su API key de Google Gemini:${RESET}"
  read -s gemini_api_key

  # Guardar API key
  echo "$gemini_api_key" >"$CONFIG_DIR/gemini_api_key.txt"
  chmod 600 "$CONFIG_DIR/gemini_api_key.txt"

  ai_message "API de Gemini configurada correctamente."
}

# Función para configurar GitHub Copilot CLI
configure_copilot() {
  print_header "Configuración de GitHub Copilot"

  # Verificar si npm está disponible
  if ! command -v npm &>/dev/null; then
    info_message "npm no está disponible. Por favor, instale Node.js y npm primero."
    return 1
  fi

  # Verificar si GitHub Copilot CLI está instalado
  if ! npm list -g | grep -q "@githubnext/github-copilot-cli"; then
    info_message "Instalando GitHub Copilot CLI..."
    npm install -g @githubnext/github-copilot-cli
  else
    info_message "GitHub Copilot CLI ya está instalado."
  fi

  # Configurar GitHub Copilot
  info_message "Iniciando autenticación con GitHub Copilot..."
  github-copilot-cli auth

  ai_message "GitHub Copilot configurado correctamente."
}

# Función para configurar soporte MCP (Model Context Protocol)
configure_mcp() {
  print_header "Configuración de soporte MCP"

  # Crear directorios necesarios
  mkdir -p "$PLUGINS_DIR"

  # Verificar si Node.js y npm están disponibles
  if ! command -v npm &>/dev/null; then
    info_message "npm no está disponible. Por favor, instale Node.js y npm primero."
    return 1
  fi

  # Crear archivo de configuración MCP
  cat >"$CONFIG_DIR/mcp-config.json" <<EOF
{
    "serverPort": 8080,
    "pluginsDir": "$PLUGINS_DIR",
    "models": {
        "gemini": {
            "enabled": true,
            "apiKeyFile": "$CONFIG_DIR/gemini_api_key.txt"
        },
        "copilot": {
            "enabled": true
        }
    }
}
EOF

  info_message "¿Desea instalar un servidor MCP ahora? Esto le permitirá ampliar las funcionalidades de los asistentes."
  read -p "Instalar servidor MCP (s/n): " install_mcp

  if [[ "$install_mcp" == "s" ]]; then
    info_message "Instalando servidor MCP básico..."
    # En lugar de instalar un paquete específico, proporcionamos instrucciones para hacerlo manualmente
    cat >"$CONFIG_DIR/mcp-server.js" <<EOF
#!/usr/bin/env node

// Script básico de servidor MCP
const http = require('http');
const fs = require('fs');
const path = require('path');

const CONFIG_PATH = path.join('${CONFIG_DIR}', 'mcp-config.json');
const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/v1/chat/completions') {
    let body = '';
    req.on('data', chunk => { body += chunk.toString(); });
    req.on('end', () => {
      console.log('Solicitud recibida:', body);
      
      // Ejemplo de respuesta
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        id: 'mcp-' + Date.now(),
        object: 'chat.completion',
        created: Math.floor(Date.now() / 1000),
        model: 'gemini-pro',
        choices: [{
          index: 0,
          message: {
            role: 'assistant',
            content: 'Servidor MCP funcionando correctamente. Este es un mensaje de prueba.'
          },
          finish_reason: 'stop'
        }]
      }));
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(config.serverPort, () => {
  console.log(\`Servidor MCP iniciado en el puerto \${config.serverPort}\`);
});
EOF
    chmod +x "$CONFIG_DIR/mcp-server.js"
  fi

  ai_message "Soporte MCP configurado correctamente."
}

# Formarmateo de condiciones de respuesta en json
fomrat_conditions_response() {
  local conditions_file="$CONDITIONS_RESPONSE_DIR"
  fomrat_conditions=$(jq -n --arg condition "$condition" '{conditions: [$condition]}')
  echo "$fomrat_conditions" >"$conditions_file"
}

# Funcion para configurar condiciones de respuesta\

configure_conditions_response() {
  echo -e "${CYAN}Por favor, ingrese una condicion:${RESET}"
  read condition
  fomrat_conditions_response "${condition}"
  echo -e "${CYAN}Condición guardada correctamente.${RESET}"
}

# Función para procesar consultas con Gemini con soporte de memoria
process_with_gemini() {
  local query="$1"
  local api_key=$(cat "$CONFIG_DIR/gemini_api_key.txt")
  local memory_file="${MEMORY_DIR}"
  local condition_file="${CONDITIONS_RESPONSE_DIR}"

  # Revisar si el archivo de condiciones existe
  if [ ! -f "$condition_file" ]; then
    echo '[]' >"$condition_file"
  fi

  # leer condiciones de respuesta
  local conditions_response=$(cat "$condition_file")

  # Crear archivo de memoria si no existe
  if [ ! -f "$memory_file" ]; then
    echo '[]' >"$memory_file"
  fi

  # Leer el historial de conversación
  local conversation_history=$(cat "$memory_file")

  # Escapar caracteres especiales en la consulta
  query=$(echo "$query" | sed 's/"/\\"/g')

  # Añadir mensaje del usuario al historial
  local updated_history=$(echo "$conversation_history" | jq '. + [{"role":"user","parts":[{"text":"'"$query"'"}]}]')
  echo "$updated_history" >"$memory_file"

  # Envio de consulta a la API de Gemini
  # Mantenemos el historial y las condiciones separadas para formatear correctamente la petición
  
  # Realizar la petición a la API de Gemini con el historial completo
  response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$api_key" \
    -H 'Content-Type: application/json' \
    -X POST \
    -d "{
      \"contents\": $updated_history,
      \"systemInstruction\": {
        \"parts\": [{ \"text\": $(echo "$conditions_response" | jq '.conditions[0]') }]
      }
    }")

  # Extraer la respuesta
  if command -v jq &>/dev/null; then
    assistant_response=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // "Error al procesar la consulta."')
  else
    # Alternativa básica si jq no está disponible
    assistant_response=$(echo "$response" | grep -o '"text":"[^"]*"' | sed 's/"text":"//;s/"$//')
  fi

  # Actualizar el historial con la respuesta del asistente
  updated_history=$(echo "$updated_history" | jq '. + [{"role":"model","parts":[{"text":"'"$assistant_response"'"}]}]')
  echo "$updated_history" >"$memory_file"

  echo "$assistant_response"
}

# Función para iniciar el asistente con soporte de Gemini
start_assistant() {
  print_header "Asistente Virtual Iniciado"

  # Verificar si existe la API key de Gemini
  if [ ! -f "$CONFIG_DIR/gemini_api_key.txt" ]; then
    info_message "No se ha configurado la API de Gemini. Configure primero la API."
    return 1
  fi

  ai_message "¡Hola! Soy tu asistente virtual. Puedo ayudarte con diversas tareas."
  ai_message "Escribe 'ayuda' para ver opciones o 'salir' para terminar."

  local current_mode="gemini"
  local mcp_server_pid=""

  # Bucle principal del asistente
  while true; do
    echo -e "${GREEN}Usuario > ${RESET}"
    read user_input

    case "$user_input" in
    "salir" | "exit" | "quit")
      ai_message "Cerrando asistente. ¡Hasta pronto!"
      # Si hay un servidor MCP en ejecución, detenerlo
      if [ -n "$mcp_server_pid" ]; then
        kill $mcp_server_pid 2>/dev/null
      fi
      break
      ;;
    "ayuda" | "help")
      echo -e "${FUCHSIA}AI Assistant: ${RESET}Comandos disponibles:"
      echo -e "  ${CYAN}gemini${RESET} - Activa el modo Gemini AI"
      echo -e "  ${CYAN}copilot${RESET} - Activa el modo GitHub Copilot"
      echo -e "  ${CYAN}mcp iniciar${RESET} - Inicia el servidor MCP"
      echo -e "  ${CYAN}mcp detener${RESET} - Detiene el servidor MCP"
      echo -e "  ${CYAN}mcp status${RESET} - Muestra el estado del servidor MCP"
      echo -e "  ${CYAN}salir${RESET} - Cierra el asistente"
      ;;
    "gemini")
      current_mode="gemini"
      ai_message "Modo Gemini activado. Tus consultas serán procesadas por Gemini AI."
      ;;
    "copilot")
      current_mode="copilot"
      ai_message "Modo GitHub Copilot activado. Usaré GitHub Copilot para responder a tus consultas de código."
      ;;
    "mcp iniciar")
      if [ -n "$mcp_server_pid" ]; then
        ai_message "El servidor MCP ya está en ejecución."
      else
        # Iniciar el servidor MCP
        if [ -f "$CONFIG_DIR/mcp-server.js" ]; then
          node "$CONFIG_DIR/mcp-server.js" >/tmp/mcp-server.log 2>&1 &
          mcp_server_pid=$!
          ai_message "Servidor MCP iniciado en puerto 8080 (PID: $mcp_server_pid)"
        else
          ai_message "No se encontró el servidor MCP. Configure primero el soporte MCP."
        fi
      fi
      ;;
    "mcp detener")
      if [ -n "$mcp_server_pid" ]; then
        kill $mcp_server_pid 2>/dev/null
        mcp_server_pid=""
        ai_message "Servidor MCP detenido."
      else
        ai_message "El servidor MCP no está en ejecución."
      fi
      ;;
    "mcp status")
      if [ -n "$mcp_server_pid" ] && kill -0 $mcp_server_pid 2>/dev/null; then
        ai_message "El servidor MCP está en ejecución (PID: $mcp_server_pid)"
      else
        ai_message "El servidor MCP no está en ejecución."
        mcp_server_pid=""
      fi
      ;;
    *)
      case "$current_mode" in
      "gemini")
        echo -e "${FUCHSIA}AI Assistant: Procesando tu consulta...${RESET}"
        response=$(process_with_gemini "$user_input")
        ai_message "$response"
        ;;
      "copilot")
        echo -e "${FUCHSIA}AI Assistant: Consultando a GitHub Copilot...${RESET}"
        # Si está disponible GitHub Copilot CLI, lo usamos
        if command -v github-copilot-cli &>/dev/null; then
          response=$(echo "$user_input" | github-copilot-cli --pipe)
          ai_message "$response"
        else
          ai_message "GitHub Copilot CLI no está disponible. Por favor, configúrelo primero."
        fi
        ;;
      esac
      ;;
    esac
  done
}

# Borrar memoria
remove_memory() {
  rm -f "$MEMORY_DIR"
  echo -e "${YELLOW}Memoria borrada.${RESET}"
}

# Menú principal
main_menu() {
  while true; do
    print_header "Asistentes Virtuales - Menú Principal"
    echo -e "1. ${CYAN}Instalar dependencias${RESET}"
    echo -e "2. ${CYAN}Configurar API de Gemini${RESET}"
    echo -e "3. ${CYAN}Configurar GitHub Copilot${RESET}"
    echo -e "4. ${CYAN}Configurar soporte MCP${RESET}"
    echo -e "5. ${CYAN}Añadir condiciones de respuesta${RESET}"
    echo -e "6. ${CYAN}Iniciar asistente virtual${RESET}"
    echo -e "7. ${CYAN}Borrar memoria${RESET}"
    echo -e "0. ${CYAN}Salir${RESET}"
    echo -e "\n${GREEN}Seleccione una opción: ${RESET}"
    read option

    case $option in
    1)
      install_dependencies
      ;;
    2)
      configure_gemini
      ;;
    3)
      configure_copilot
      ;;
    4)
      configure_mcp
      ;;
    5)
      configure_conditions_response
      ;;
    6)
      start_assistant
      ;;
    7)
      remove_memory
      ;;
    0)
      echo -e "${YELLOW}¡Hasta pronto!${RESET}"
      exit 0
      ;;
    *)
      echo -e "${YELLOW}Opción inválida. Por favor, intente de nuevo.${RESET}"
      ;;
    esac
  done
}

# Comprobar si el script se ejecuta como root
if [ "$EUID" -eq 0 ]; then
  echo -e "${YELLOW}Este script no debe ejecutarse como root.${RESET}"
  exit 1
fi

# Iniciar el menú principal
main_menu
