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




# Función para descubrir herramientas disponibles
discover_mcp_tools() {
  local tools_array=()
  for plugin in "$MCP_PLUGINS_DIR"/*.py; do
    if [ -f "$plugin" ]; then
      # Extraer descripción y nombre de la herramienta del archivo
      local tool_name=$(basename "$plugin" .py)
      local tool_description=$(grep -m 1 "# Description:" "$plugin" | sed 's/# Description: //')
      tools_array+=("\"$tool_name\": {\"name\": \"$tool_name\", \"description\": \"$tool_description\"}")
    fi
  done
  echo "{$(IFS=,; echo "${tools_array[*]}")}"
}

# Función para ejecutar una herramienta MCP
execute_mcp_tool() {
  local tool_name="$1"
  local args="$2"
  local plugin_path="$MCP_PLUGINS_DIR/${tool_name}.py"
  
  if [ -f "$plugin_path" ]; then
    python3 "$plugin_path" "$args"
    return $?
  else
    echo "Herramienta no encontrada: $tool_name"
    return 1
  fi
}


# Función para procesar consultas con Gemini con soporte de memoria
process_with_gemini() {
  local query="$1"
  local api_key=$(cat "$CONFIG_DIR/gemini_api_key.txt")
  local memory_file="${MEMORY_DIR}"
  local condition_file="${CONDITIONS_RESPONSE_DIR}"
  local mcp_tools=$(discover_mcp_tools)

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
      },
      \"tools\": [{
        \"function_declarations\": $mcp_tools
      }]
    }")

 # Extraer la respuesta y verificar si hay llamadas a herramientas
  if command -v jq &>/dev/null; then
    if echo "$response" | jq -e '.candidates[0].content.parts[0].functionCall' >/dev/null 2>&1; then
      local tool_name=$(echo "$response" | jq -r '.candidates[0].content.parts[0].functionCall.name')
      local tool_args=$(echo "$response" | jq -r '.candidates[0].content.parts[0].functionCall.args')
      
      # Ejecutar la herramienta MCP
      info_message "Ejecutando herramienta MCP: $tool_name"
      local tool_response=$(execute_mcp_tool "$tool_name" "$tool_args")
      
      # Enviar la respuesta de la herramienta de vuelta a Gemini
      # Código adicional para manejar la respuesta...
    else
      assistant_response=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // "Error al procesar la consulta."')
    fi
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