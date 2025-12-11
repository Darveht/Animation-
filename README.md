# 🎬 ANIMFLIX - Sistema de Animación Estilo Netflix

## 📋 Descripción
AnimFlix es un sistema completo de creación, publicación y visualización de animaciones para Roblox, ahora con un diseño moderno inspirado en Netflix.

## ✨ Características Principales

### 🎨 Interfaz Moderna Netflix
- **Colores**: Esquema de colores rojo Netflix (#E50914) con fondos oscuros elegantes
- **Gradientes**: Efectos visuales suaves y modernos
- **Animaciones**: Transiciones fluidas y efectos hover sofisticados
- **Tipografía**: Fuentes Gotham para una apariencia profesional

### 🛠️ Funcionalidades
- **Editor de Animación**: Herramientas profesionales de dibujo
- **Sistema de Frames**: Timeline interactivo para animaciones
- **Onion Skinning**: Visualización de frames anteriores
- **Categorización**: Terror, Comedia, Acción, Drama, Aventura
- **Sistema de Likes**: Interacción social
- **Búsqueda Avanzada**: Encuentra animaciones por título o descripción
- **Reproductor**: Visualización fluida con controles personalizados

### 🎯 Mejoras Visuales Netflix
1. **Paleta de Colores**:
   - Rojo principal: `#E50914` (229, 9, 20)
   - Fondos oscuros: `#141414` (20, 20, 20)
   - Paneles: `#232323` (35, 35, 35)
   - Elementos interactivos: `#373737` (55, 55, 55)

2. **Efectos Visuales**:
   - Gradientes diagonales en botones
   - Efectos hover con transiciones suaves
   - Sombras sutiles en elementos importantes
   - Bordes redondeados consistentes

3. **Experiencia de Usuario**:
   - Carruseles horizontales estilo Netflix
   - Tarjetas que crecen al hacer hover
   - Barra de búsqueda integrada
   - Notificaciones elegantes

## 📁 Estructura de Archivos

```
Animation-/
├── localscript.lua     # Script principal del cliente (Netflix Style)
├── serverscript.lua    # Script del servidor
└── README.md          # Documentación
```

## 🚀 Instalación

1. **LocalScript**: Coloca `localscript.lua` en `StarterPlayer > StarterPlayerScripts`
2. **ServerScript**: Coloca `serverscript.lua` en `ServerScriptService`
3. Los RemoteEvents se crean automáticamente

## 🎮 Uso

### Para Usuarios
1. **Explorar**: Navega por las categorías en la pantalla principal
2. **Buscar**: Usa la barra de búsqueda para encontrar animaciones específicas
3. **Ver**: Haz clic en cualquier animación para ver detalles y reproducir
4. **Interactuar**: Da like a tus animaciones favoritas

### Para Creadores
1. **Crear**: Haz clic en "➕ CREAR" para abrir el editor
2. **Dibujar**: Usa las herramientas de lápiz y borrador
3. **Animar**: Agrega múltiples frames para crear movimiento
4. **Publicar**: Completa la información y publica tu animación

## 🛠️ Herramientas del Editor

- **✏️ Lápiz**: Dibujo libre con grosor ajustable
- **🧹 Borrador**: Elimina trazos específicos
- **🎨 Paleta**: 8 colores predefinidos
- **📏 Grosor**: Control deslizante de 3-20px
- **🧅 Onion Skin**: Visualización de frame anterior
- **🎞️ Timeline**: Gestión de frames con vista previa

## 💾 Persistencia de Datos

- **DataStore Global**: Todas las animaciones se guardan permanentemente
- **Categorización Automática**: Las animaciones se organizan por categoría
- **Sistema de Likes**: Los likes se guardan por usuario
- **Estadísticas**: Visualizaciones y likes se rastrean automáticamente

## 🎨 Personalización

### Cambiar Colores
Modifica las variables de color en `localscript.lua`:
```lua
-- Color principal Netflix
Color3.fromRGB(229, 9, 20)

-- Fondos oscuros
Color3.fromRGB(20, 20, 20)
Color3.fromRGB(35, 35, 35)
```

### Agregar Categorías
Edita el array de categorías en ambos scripts:
```lua
local categories = {"Terror", "Comedia", "Accion", "Drama", "Aventura", "NuevaCategoria"}
```

## 🔧 Configuración Avanzada

### FPS de Reproducción
```lua
local fps = 12 -- Frames por segundo
```

### Límites de Frames
```lua
-- Máximo 20 frames recientes en la categoría "Recientes"
if #AnimationsByCategory.Recientes > 20 then
    table.remove(AnimationsByCategory.Recientes, #AnimationsByCategory.Recientes)
end
```

## 📱 Responsive Design

La interfaz se adapta automáticamente a diferentes tamaños de pantalla:
- **Pantalla completa**: Sin márgenes para máxima inmersión
- **Aspect Ratio**: Mantiene proporciones 16:9 en el canvas
- **Escalado automático**: Los elementos se ajustan al tamaño de pantalla

## 🎭 Categorías Disponibles

1. **🎃 Terror**: Animaciones de miedo y suspenso
2. **😂 Comedia**: Contenido humorístico y divertido
3. **⚔️ Acción**: Escenas dinámicas y emocionantes
4. **🎭 Drama**: Historias emotivas y profundas
5. **🗺️ Aventura**: Exploraciones y viajes épicos

## 🏆 Características Premium

- **Autoguardado**: Cada 5 minutos automáticamente
- **Notificaciones**: Sistema de alertas en tiempo real
- **Búsqueda Inteligente**: Busca en títulos y descripciones
- **Editor Profesional**: Herramientas avanzadas de dibujo
- **Reproducción Fluida**: 12 FPS con controles completos

## 🔄 Actualizaciones Recientes

### v2.0 - Netflix Style Update
- ✅ Rediseño completo con colores Netflix
- ✅ Gradientes y efectos visuales modernos
- ✅ Mejores transiciones y animaciones
- ✅ Tipografía Gotham profesional
- ✅ Efectos hover sofisticados
- ✅ Interfaz más elegante y minimalista

---

**Desarrollado con ❤️ para la comunidad de Roblox**