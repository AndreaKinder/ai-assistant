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

ai_message() {
  echo -e "${FUCHSIA}AI Assistant: ${1}${RESET}"
}

user_message() {
  echo -e "${GREEN}User: ${1}${RESET}"
}

# Función para imprimir información
info_message() {
  echo -e "${YELLOW}[INFO] ${1}${RESET}"
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
    while true; do
        read -p "$(echo -e ${GREEN}User: ${RESET})" user_input
        echo -e "${FUCHSIA}AI Assistant: Procesando tu consulta...${RESET}"
        response=$(process_with_gemini "$user_input")
        ai_message "$response"
    done
}

# Start the assistant
start_assistant