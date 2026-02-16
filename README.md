# VibeTag

Aplicación iOS que utiliza inteligencia artificial para etiquetar y organizar automáticamente tu biblioteca de Apple Music con "vibes" semánticos (estados de ánimo, temáticas, energía). A partir de estos tags, los usuarios pueden generar playlists personalizadas describiendo lo que sienten o necesitan en lenguaje natural.

El proyecto sigue una filosofía **offline-first**: toda la funcionalidad está disponible sin conexión a internet, con sincronización automática en segundo plano cuando el usuario inicia sesión.

## Stack tecnológico

### iOS

| Tecnología | Uso |
|---|---|
| **Swift 6** | Lenguaje principal con strict concurrency |
| **SwiftUI** | Framework de interfaz declarativa |
| **SwiftData** | Persistencia local (fuente de verdad) |
| **MusicKit** | Acceso a la biblioteca de Apple Music |
| **AuthenticationServices** | Sign in with Apple |
| **XCTest** | Testing unitario |

### Backend

| Tecnología | Uso |
|---|---|
| **Node.js + TypeScript** | Runtime y lenguaje |
| **Express.js v5** | Framework HTTP |
| **PostgreSQL 16** | Base de datos relacional |
| **Prisma v7** | ORM y migraciones |
| **Vercel AI SDK** | Abstracción sobre proveedores de IA |
| **Google Gemini 2.0 Flash** | Modelo de IA para análisis y generación |
| **Zod v4** | Validación de esquemas |
| **JWT** | Autenticación basada en tokens |
| **Vitest** | Testing unitario |
| **Sentry** | Monitorización de errores |

### Infraestructura

| Tecnología | Uso |
|---|---|
| **Render** | Hosting del backend |
| **Neon** | PostgreSQL serverless (producción) |
| **Docker** | PostgreSQL local (desarrollo) |
| **TestFlight** | Distribución de la app iOS |

## Instalación y ejecución

### Requisitos previos

- **Xcode 16+** con iOS 18 SDK
- **Node.js 20+**
- **Docker** (para PostgreSQL local)
- Cuenta de desarrollador de Apple (para MusicKit y Sign in with Apple)
- API key de Google Gemini

### Backend

1. **Clonar el repositorio e instalar dependencias:**

```bash
cd backend
npm install
```

2. **Iniciar la base de datos local:**

```bash
docker-compose up -d
```

Esto levanta un contenedor PostgreSQL 16 en el puerto `5432` con las credenciales configuradas en `docker-compose.yml`.

3. **Configurar variables de entorno:**

Crear un archivo `.env` en `backend/` con las siguientes variables:

```env
NODE_ENV=dev
DATABASE_URL_DEV=postgresql://user:password@localhost:5432/vibetag
DATABASE_URL_PRO=<url_de_neon_postgres>
GEMINI_API_KEY=<tu_api_key_de_gemini>
GROQ_API_KEY=<opcional>
APPLE_CLIENT_ID=<tu_apple_client_id>
JWT_SECRET=<cadena_de_al_menos_32_caracteres>
SENTRY_DSN=<opcional>
PORT=3000
```

4. **Ejecutar migraciones y arrancar el servidor:**

```bash
npx prisma migrate dev
npm run dev
```

El servidor arranca en `http://localhost:3000` con hot-reload vía `tsx watch`.

### Scripts disponibles (backend)

| Comando | Descripción |
|---|---|
| `npm run dev` | Servidor de desarrollo con hot-reload |
| `npm run build` | Compilar TypeScript a `dist/` |
| `npm start` | Ejecutar servidor compilado |
| `npm test` | Ejecutar tests con Vitest |
| `npm run lint` | Linting con ESLint |
| `npm run format` | Formateo con Prettier |

### iOS

1. **Abrir el proyecto en Xcode:**

```bash
cd ios
open VibeTag.xcodeproj
```

2. **Configurar el entorno:**

En `VibeTag/Core/Configuration/Environment.swift`, la app selecciona automáticamente la URL del backend según la build configuration:

- **Debug**: apunta a la IP local del backend (`http://192.168.1.x:3000`)
- **Release**: apunta al servidor de producción en Render

3. **Ejecutar en simulador o dispositivo físico** desde Xcode (esquema `VibeTag`).

> **Nota**: Para probar funcionalidades de MusicKit (importación de biblioteca), se requiere un dispositivo físico con una suscripción activa a Apple Music.

## Estructura del proyecto

```
VibeTag/
├── backend/                          # Servidor Node.js/TypeScript
│   ├── src/
│   │   ├── domain/                   # Capa de dominio (lógica de negocio pura)
│   │   │   ├── entities/             # Song, User, Analysis, VibeTag, SongTag
│   │   │   ├── value-objects/        # Email, SongMetadata, VTDate, IDs
│   │   │   ├── services/             # Interfaces de servicios de IA
│   │   │   └── errors/               # Jerarquía de errores de dominio
│   │   ├── application/              # Capa de aplicación (casos de uso)
│   │   │   ├── use-cases/            # AnalyzeUseCase, GeneratePlaylistUseCase, etc.
│   │   │   ├── dtos/                 # Objetos de transferencia de datos
│   │   │   └── ports/                # Interfaces de repositorios y servicios
│   │   ├── infrastructure/           # Capa de infraestructura (adaptadores)
│   │   │   ├── http/                 # Controladores y rutas Express
│   │   │   ├── persistence/          # Repositorios Prisma
│   │   │   ├── database/             # Esquema Prisma
│   │   │   ├── services/             # GeminiAIService, GroqAIService
│   │   │   └── security/             # JWT, Apple Auth
│   │   ├── composition/              # Inyección de dependencias
│   │   │   └── config/               # Validación de entorno (Zod)
│   │   ├── tests/                    # Tests unitarios por capa
│   │   └── shared/                   # Utilidades (Result type, sanitización)
│   ├── prisma/                       # Esquema y migraciones de base de datos
│   ├── docker-compose.yml            # PostgreSQL local
│   └── package.json
│
├── ios/                              # Aplicación iOS
│   ├── VibeTag/
│   │   ├── Features/                 # Funcionalidades (organización por feature)
│   │   │   ├── Home/                 # Biblioteca y buscador
│   │   │   ├── SongDetail/           # Detalle de canción y etiquetado
│   │   │   ├── Tags/                 # Gestión de tags
│   │   │   ├── Playlist/             # Generación y exportación de playlists
│   │   │   ├── Settings/             # Ajustes y cuenta
│   │   │   └── Root/                 # Flujo de autenticación y tab bar principal
│   │   ├── Sheets/                   # Modales (asignación de tags, creación, input)
│   │   ├── Domain/                   # Modelos, casos de uso, interfaces, errores
│   │   ├── Core/                     # Infraestructura
│   │   │   ├── DI/                   # AppContainer (raíz de inyección)
│   │   │   ├── Data/                 # APIClient, repositorios, DTOs, endpoints
│   │   │   ├── Services/             # SyncEngine, SessionManager, NetworkMonitor
│   │   │   ├── Navigation/           # AppRouter
│   │   │   ├── Design/               # Tokens del sistema de diseño
│   │   │   └── Configuration/        # Variables de entorno
│   │   └── Components/               # Componentes UI reutilizables
│   ├── VibeTagTests/                 # Tests unitarios
│   └── VibeTag.xcodeproj
│
└── docs/                             # Documentación del proyecto
    ├── adr/                          # Architecture Decision Records
    └── context/                      # Requisitos funcionales y arquitectura
```

### Arquitectura

**Backend** — Arquitectura Hexagonal (Ports & Adapters) con cuatro capas estrictas donde las internas no tienen conocimiento de las externas. Todos los casos de uso devuelven un tipo `Result<T, E>` en lugar de lanzar excepciones para el control de flujo.

**iOS** — MVVM + Clean Architecture con tres capas (Presentation, Domain, Infrastructure). Los ViewModels son `@MainActor @Observable` y reciben sus dependencias por inyección en el constructor a través de `AppContainer`.

## Funcionalidades principales

### Auto-etiquetado con IA

El usuario puede analizar cualquier canción de su biblioteca. El backend envía los metadatos (título, artista, álbum, género) a Google Gemini, que devuelve un conjunto de "vibes" semánticos (por ejemplo: *Nostálgico*, *Road Trip*, *Melancólico*). Estos tags se almacenan tanto en el servidor como localmente en SwiftData. Se soporta análisis individual y por lotes.

### Generación inteligente de playlists

El usuario describe lo que busca en lenguaje natural (por ejemplo: *"Música para programar de noche"*). El backend utiliza la IA para extraer keywords del prompt, busca coincidencias entre los tags de las canciones del usuario, y devuelve un ranking de hasta 50 canciones ordenadas por relevancia. La playlist resultante se puede exportar directamente a Apple Music con un solo tap.

### Gestión de tags personalizados

Además de los tags generados por IA (tags de sistema), el usuario puede crear sus propios tags con nombre y color personalizado, y asignarlos a cualquier canción. Los tags tienen una relación muchos-a-muchos con las canciones.

### Sincronización offline-first

SwiftData actúa como fuente única de verdad. La app funciona completamente sin conexión: las canciones se importan, etiquetan y organizan localmente. Cuando el usuario inicia sesión con Apple y hay conectividad, `VibeTagSyncEngine` sincroniza automáticamente los cambios pendientes con el servidor en segundo plano. Al iniciar sesión por primera vez, los datos locales se fusionan con los de la nube.

### Modo invitado

Toda la funcionalidad está disponible sin autenticación. El almacenamiento es exclusivamente local. Si el usuario decide registrarse posteriormente, los datos locales se sincronizan con su cuenta en la nube.

### API REST

El backend expone los siguientes endpoints bajo `/api/v1`:

| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/auth/login` | Autenticación con Apple Sign-In |
| `POST` | `/auth/delete` | Eliminación de cuenta |
| `POST` | `/analyze/song` | Análisis de una canción con IA |
| `POST` | `/analyze/batch` | Análisis por lotes |
| `GET` | `/songs` | Obtener biblioteca del usuario |
| `PATCH` | `/songs/:id/tags` | Actualizar tags de una canción |
| `POST` | `/playlists/generate` | Generar playlist por prompt |
| `GET` | `/health` | Health check del servidor |
