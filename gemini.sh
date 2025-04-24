#!/bin/bash

source $HOME/Proyectos/macros/ai-assistant/global_config.sh

# Verificar la configuración inicial
if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR"
  echo -e "${CYAN}Directorio de configuración creado en $CONFIG_DIR${RESET}"
fi

if [ ! -f "$CONFIG_DIR/gemini_api_key.txt" ]; then
  echo -e "${YELLOW}No se encontró la clave API de Gemini. Por favor, configúrela.${RESET}"
  configure_gemini
fi

# Crear archivo de memoria si no existe
if [ ! -f "$MEMORY_DIR" ]; then
  mkdir -p "$(dirname "$MEMORY_DIR")"
  echo '[]' > "$MEMORY_DIR"
fi

# Variable para controlar el servidor MCP
mcp_server_pid=""

# Función para iniciar el servidor MCP
start_mcp_server() {
  if [ -n "$mcp_server_pid" ] && kill -0 $mcp_server_pid 2>/dev/null; then
    info_message "El servidor MCP ya está en ejecución (PID: $mcp_server_pid)"
    return 0
  fi
  
  if [ -f "$CONFIG_DIR/mcp-server.js" ]; then
    node "$CONFIG_DIR/mcp-server.js" >/tmp/mcp-server.log 2>&1 &
    mcp_server_pid=$!
    info_message "Servidor MCP iniciado en puerto 8080 (PID: $mcp_server_pid)"
    return 0
  else
    info_message "No se encontró el servidor MCP. Configurando..."
    configure_mcp
    
    if [ -f "$CONFIG_DIR/mcp-server.js" ]; then
      node "$CONFIG_DIR/mcp-server.js" >/tmp/mcp-server.log 2>&1 &
      mcp_server_pid=$!
      info_message "Servidor MCP iniciado en puerto 8080 (PID: $mcp_server_pid)"
      return 0
    else
      error_message "No se pudo configurar el servidor MCP."
      return 1
    fi
  fi
}

# Función para detener el servidor MCP
stop_mcp_server() {
  if [ -n "$mcp_server_pid" ]; then
    kill $mcp_server_pid 2>/dev/null
    mcp_server_pid=""
    info_message "Servidor MCP detenido."
  else
    info_message "El servidor MCP no está en ejecución."
  fi
}

# Iniciar chat con Gemini
print_header "Chat con Gemini - $(date '+%d de %B de %Y')"
echo -e "${CYAN}Comandos disponibles:${RESET}"
echo -e "  ${CYAN}mcp iniciar${RESET} - Inicia el servidor MCP"
echo -e "  ${CYAN}mcp detener${RESET} - Detiene el servidor MCP"
echo -e "  ${CYAN}mcp status${RESET} - Muestra el estado del servidor MCP"
echo -e "  ${CYAN}salir${RESET} - Termina el chat"

# Intentar iniciar el servidor MCP automáticamente
if [ -f "$CONFIG_DIR/mcp-server.js" ]; then
  info_message "Iniciando servidor MCP..."
  start_mcp_server
fi

while true; do
  echo -e "${GREEN}Usuario > ${RESET}"
  read user_input
  
  case "$user_input" in
    "salir")
      # Detener el servidor MCP si está en ejecución
      if [ -n "$mcp_server_pid" ]; then
        stop_mcp_server
      fi
      echo -e "${YELLOW}Chat finalizado. ¡Hasta pronto!${RESET}"
      break
      ;;
    "mcp iniciar")
      start_mcp_server
      ;;
    "mcp detener")
      stop_mcp_server
      ;;
    "mcp status")
      if [ -n "$mcp_server_pid" ] && kill -0 $mcp_server_pid 2>/dev/null; then
        info_message "El servidor MCP está en ejecución (PID: $mcp_server_pid)"
      else
        info_message "El servidor MCP no está en ejecución."
        mcp_server_pid=""
      fi
      ;;
    *)
      echo -e "${FUCHSIA}AI Assistant: ${RESET}${CYAN}Procesando tu consulta...${RESET}"
      # Si el servidor MCP está activo, usar ese procesamiento
      if [ -n "$mcp_server_pid" ] && kill -0 $mcp_server_pid 2>/dev/null; then
        # Procesar con MCP (simplificado para este ejemplo)
        # En una implementación real, aquí se enviaría la consulta al servidor MCP
        info_message "Utilizando servidor MCP para procesar la consulta..."
        # Por ahora, seguimos usando process_with_gemini pero podría modificarse para usar MCP
      fi
      response=$(process_with_gemini "$user_input")
      echo -e "${FUCHSIA}AI Assistant: ${response}${RESET}"
      ;;
  esac
done