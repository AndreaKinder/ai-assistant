#!/bin/bash

# Asistente virtual con Gemini - v1.0
# Fecha: 23 de abril de 2025

source $HOME/Proyectos/macros/ai-assistant/global_config.sh

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
