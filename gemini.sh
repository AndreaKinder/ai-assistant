#!/bin/bash

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

# Función para mostrar mensajes de información
info_message() {
  echo -e "${YELLOW}Información: ${1}${RESET}"
}
# Función para mostrar mensajes de advertencia
warning_message() {
  echo -e "${YELLOW}Advertencia: ${1}${RESET}"
}
# Función para mostrar mensajes de error
error_message() {
  echo -e "${YELLOW}Error: ${1}${RESET}"
}
# Función para verificar la configuración inicial
check_initial_setup() {
  if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "${CYAN}Directorio de configuración creado en $CONFIG_DIR${RESET}"
  fi

  if [ ! -f "$CONFIG_DIR/gemini_api_key.txt" ]; then
    echo -e "${YELLOW}No se encontró la clave API de Gemini. Por favor, configúrela.${RESET}"
  fi

  if [ ! -f "$CONFIG_DIR/mcp-server.js" ]; then
    echo -e "${YELLOW}No se encontró el servidor MCP. Por favor, configúrelo.${RESET}"
  fi
}
# Función para chat
chat() {
  print_header "Chat con Gemini"
  echo -e "${CYAN}Escribe 'salir' para terminar
el chat.${RESET}"
    while true; do
        echo -e "${GREEN}Usuario > ${RESET}"
        read user_input
        if [ "$user_input" == "salir" ]; then
        break
        fi
        echo -e "${FUCHSIA}AI Assistant: ${RESET}${CYAN}Procesando tu consulta...${RESET}"
        response=$(process_with_gemini "$user_input")
        echo -e "${FUCHSIA}AI Assistant: ${response}${RESET}"
        ai_message "$response"
    done
    }
# Función principal
main() {
  check_initial_setup
  start_assistant
}
# Llamar a la función principal
main