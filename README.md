# VibeTag

Aplicacion iOS que utiliza inteligencia artificial para etiquetar y organizar automaticamente tu biblioteca de Apple Music con "vibes" semanticos (estados de animo, tematicas, energia). A partir de estos tags, los usuarios pueden generar playlists personalizadas describiendo lo que sienten o necesitan en lenguaje natural.

El proyecto sigue una filosofia **offline-first**: toda la funcionalidad esta disponible sin conexion a internet, con sincronizacion automatica en segundo plano cuando el usuario inicia sesion.

## Stack tecnologico

### iOS

| Tecnologia | Uso |
|---|---|
| **Swift 6** | Lenguaje principal con strict concurrency |
| **SwiftUI** | Framework de interfaz declarativa |
| **SwiftData** | Persistencia local (fuente de verdad) |
| **MusicKit** | Acceso a la biblioteca de Apple Music |
| **AuthenticationServices** | Sign in with Apple |
| **XCTest** | Testing unitario |

### Backend

| Tecnologia | Uso |
|---|---|
| **Node.js + TypeScript** | Runtime y lenguaje |
| **Express.js v5** | Framework HTTP |
| **PostgreSQL 16** | Base de datos relacional |
| **Prisma v7** | ORM y migraciones |
| **Vercel AI SDK** | Abstraccion sobre proveedores de IA |
| **Google Gemini 2.0 Flash** | Modelo de IA para analisis y generacion |
| **Zod v4** | Validacion de esquemas |
| **JWT** | Autenticacion basada en tokens |
| **Vitest** | Testing unitario |
| **Sentry** | Monitorizacion de errores |

### Infraestructura

| Tecnologia | Uso |
|---|---|
| **Render** | Hosting del backend |
| **Neon** | PostgreSQL serverless (produccion) |
| **Docker** | PostgreSQL local (desarrollo) |
| **TestFlight** | Distribucion de la app iOS |

## Instalacion y ejecucion

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

El servidor arranca en `http://localhost:3000` con hot-reload via `tsx watch`.

### Scripts disponibles (backend)

| Comando | Descripcion |
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

En `VibeTag/Core/Configuration/Environment.swift`, la app selecciona automaticamente la URL del backend segun la build configuration:

- **Debug**: apunta a la IP local del backend (`http://192.168.1.x:3000`)
- **Release**: apunta al servidor de produccion en Render

3. **Ejecutar en simulador o dispositivo fisico** desde Xcode (esquema `VibeTag`).

> **Nota**: Para probar funcionalidades de MusicKit (importacion de biblioteca), se requiere un dispositivo fisico con una suscripcion activa a Apple Music.

## Estructura del proyecto

```
VibeTag/
├── backend/                          # Servidor Node.js/TypeScript
│   ├── src/
│   │   ├── domain/                   # Capa de dominio (logica de negocio pura)
│   │   │   ├── entities/             # Song, User, Analysis, VibeTag, SongTag
│   │   │   ├── value-objects/        # Email, SongMetadata, VTDate, IDs
│   │   │   ├── services/             # Interfaces de servicios de IA
│   │   │   └── errors/               # Jerarquia de errores de dominio
│   │   ├── application/              # Capa de aplicacion (casos de uso)
│   │   │   ├── use-cases/            # AnalyzeUseCase, GeneratePlaylistUseCase, etc.
│   │   │   ├── dtos/                 # Objetos de transferencia de datos
│   │   │   └── ports/                # Interfaces de repositorios y servicios
│   │   ├── infrastructure/           # Capa de infraestructura (adaptadores)
│   │   │   ├── http/                 # Controladores y rutas Express
│   │   │   ├── persistence/          # Repositorios Prisma
│   │   │   ├── database/             # Esquema Prisma
│   │   │   ├── services/             # GeminiAIService, GroqAIService
│   │   │   └── security/             # JWT, Apple Auth
│   │   ├── composition/              # Inyeccion de dependencias
│   │   │   └── config/               # Validacion de entorno (Zod)
│   │   ├── tests/                    # Tests unitarios por capa
│   │   └── shared/                   # Utilidades (Result type, sanitizacion)
│   ├── prisma/                       # Esquema y migraciones de base de datos
│   ├── docker-compose.yml            # PostgreSQL local
│   └── package.json
│
├── ios/                              # Aplicacion iOS
│   ├── VibeTag/
│   │   ├── Features/                 # Funcionalidades (organizacion por feature)
│   │   │   ├── Home/                 # Biblioteca y buscador
│   │   │   ├── SongDetail/           # Detalle de cancion y etiquetado
│   │   │   ├── Tags/                 # Gestion de tags
│   │   │   ├── Playlist/             # Generacion y exportacion de playlists
│   │   │   ├── Settings/             # Ajustes y cuenta
│   │   │   └── Root/                 # Flujo de autenticacion y tab bar principal
│   │   ├── Sheets/                   # Modales (asignacion de tags, creacion, input)
│   │   ├── Domain/                   # Modelos, casos de uso, interfaces, errores
│   │   ├── Core/                     # Infraestructura
│   │   │   ├── DI/                   # AppContainer (raiz de inyeccion)
│   │   │   ├── Data/                 # APIClient, repositorios, DTOs, endpoints
│   │   │   ├── Services/             # SyncEngine, SessionManager, NetworkMonitor
│   │   │   ├── Navigation/           # AppRouter
│   │   │   ├── Design/               # Tokens del sistema de diseno
│   │   │   └── Configuration/        # Variables de entorno
│   │   └── Components/               # Componentes UI reutilizables
│   ├── VibeTagTests/                 # Tests unitarios
│   └── VibeTag.xcodeproj
│
└── docs/                             # Documentacion del proyecto
    ├── adr/                          # Architecture Decision Records
    └── context/                      # Requisitos funcionales y arquitectura
```

### Arquitectura

**Backend** — Arquitectura Hexagonal (Ports & Adapters) con cuatro capas estrictas donde las internas no tienen conocimiento de las externas. Todos los casos de uso devuelven un tipo `Result<T, E>` en lugar de lanzar excepciones para el control de flujo.

**iOS** — MVVM + Clean Architecture con tres capas (Presentation, Domain, Infrastructure). Los ViewModels son `@MainActor @Observable` y reciben sus dependencias por inyeccion en el constructor a traves de `AppContainer`.

## Funcionalidades principales

### Auto-etiquetado con IA

El usuario puede analizar cualquier cancion de su biblioteca. El backend envia los metadatos (titulo, artista, album, genero) a Google Gemini, que devuelve un conjunto de "vibes" semanticos (por ejemplo: *Nostalgico*, *Road Trip*, *Melancolico*). Estos tags se almacenan tanto en el servidor como localmente en SwiftData. Se soporta analisis individual y por lotes.

### Generacion inteligente de playlists

El usuario describe lo que busca en lenguaje natural (por ejemplo: *"Musica para programar de noche"*). El backend utiliza la IA para extraer keywords del prompt, busca coincidencias entre los tags de las canciones del usuario, y devuelve un ranking de hasta 50 canciones ordenadas por relevancia. La playlist resultante se puede exportar directamente a Apple Music con un solo tap.

### Gestion de tags personalizados

Ademas de los tags generados por IA (tags de sistema), el usuario puede crear sus propios tags con nombre y color personalizado, y asignarlos a cualquier cancion. Los tags tienen una relacion muchos-a-muchos con las canciones.

### Sincronizacion offline-first

SwiftData actua como fuente unica de verdad. La app funciona completamente sin conexion: las canciones se importan, etiquetan y organizan localmente. Cuando el usuario inicia sesion con Apple y hay conectividad, `VibeTagSyncEngine` sincroniza automaticamente los cambios pendientes con el servidor en segundo plano. Al iniciar sesion por primera vez, los datos locales se fusionan con los de la nube.

### Modo invitado

Toda la funcionalidad esta disponible sin autenticacion. El almacenamiento es exclusivamente local. Si el usuario decide registrarse posteriormente, los datos locales se sincronizan con su cuenta en la nube.

### API REST

El backend expone los siguientes endpoints bajo `/api/v1`:

| Metodo | Ruta | Descripcion |
|---|---|---|
| `POST` | `/auth/login` | Autenticacion con Apple Sign-In |
| `POST` | `/auth/delete` | Eliminacion de cuenta |
| `POST` | `/analyze/song` | Analisis de una cancion con IA |
| `POST` | `/analyze/batch` | Analisis por lotes |
| `GET` | `/songs` | Obtener biblioteca del usuario |
| `PATCH` | `/songs/:id/tags` | Actualizar tags de una cancion |
| `POST` | `/playlists/generate` | Generar playlist por prompt |
| `GET` | `/health` | Health check del servidor |
