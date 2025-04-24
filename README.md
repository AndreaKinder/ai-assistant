# Asistentes Virtuales con Gemini y GitHub Copilot

![Tema Dracula](https://draculatheme.com/static/img/dracula.gif)

## Descripción
Este proyecto proporciona un script para configurar y utilizar asistentes de IA en una interfaz de terminal con el tema Dracula. Permite interactuar con Gemini AI y GitHub Copilot directamente desde la línea de comandos, con soporte para memoria de conversación y Model Context Protocol (MCP).

## Características
- 🧠 Integración con Gemini y GitHub Copilot
- 🎨 Interfaz de terminal con tema Dracula
- 💾 Memoria de conversación persistente
- 🔌 Soporte para MCP (Model Context Protocol)
- 🔄 Cambio entre diferentes modelos de IA
- 🎯 Configuración de condiciones de respuesta personalizadas

## Requisitos
- Linux
- Bash
- curl, jq, Python 3, pip, Node.js, npm

## Instalación
1. Clone este repositorio:
```bash
git clone https://github.com/tuusuario/ai-assistant.git
cd ai-assistant
```

2. Haga ejecutable el script:
```bash
chmod +x ai-assistants.sh
```

3. Ejecute el script y siga las instrucciones del menú:
```bash
./ai-assistants.sh
```

## Uso
El script proporciona un menú interactivo con las siguientes opciones:
1. Instalar dependencias
2. Configurar API de Gemini
3. Configurar GitHub Copilot
4. Configurar soporte MCP
5. Añadir condiciones de respuesta
6. Iniciar asistente virtual
7. Borrar memoria
0. Salir

Una vez iniciado el asistente virtual, puede utilizar comandos como:
- `gemini`: Activa el modo Gemini AI
- `copilot`: Activa el modo GitHub Copilot
- `mcp iniciar`: Inicia el servidor MCP
- `mcp detener`: Detiene el servidor MCP
- `mcp status`: Muestra el estado del servidor MCP
- `salir`: Cierra el asistente

## Licencia
Este proyecto está bajo la Licencia MIT. Consulte el archivo [LICENSE](LICENSE) para más detalles.

---

# Virtual Assistants with Gemini and GitHub Copilot

![Dracula Theme](https://draculatheme.com/static/img/dracula.gif)

## Description
This project provides a script to set up and use AI assistants in a terminal interface with the Dracula theme. It allows you to interact with Gemini AI and GitHub Copilot directly from the command line, with support for conversation memory and Model Context Protocol (MCP).

## Features
- 🧠 Integration with Gemini and GitHub Copilot
- 🎨 Terminal interface with Dracula theme
- 💾 Persistent conversation memory
- 🔌 Support for MCP (Model Context Protocol)
- 🔄 Switch between different AI models
- 🎯 Custom response conditions configuration

## Requirements
- Linux
- Bash
- curl, jq, Python 3, pip, Node.js, npm

## Installation
1. Clone this repository:
```bash
git clone https://github.com/yourusername/ai-assistant.git
cd ai-assistant
```

2. Make the script executable:
```bash
chmod +x ai-assistants.sh
```

3. Run the script and follow the menu instructions:
```bash
./ai-assistants.sh
```

## Usage
The script provides an interactive menu with the following options:
1. Install dependencies
2. Configure Gemini API
3. Configure GitHub Copilot
4. Configure MCP support
5. Add response conditions
6. Start virtual assistant
7. Clear memory
0. Exit

Once the virtual assistant is started, you can use commands like:
- `gemini`: Activates Gemini AI mode
- `copilot`: Activates GitHub Copilot mode
- `mcp start`: Starts the MCP server
- `mcp stop`: Stops the MCP server
- `mcp status`: Shows the MCP server status
- `exit`: Closes the assistant

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.