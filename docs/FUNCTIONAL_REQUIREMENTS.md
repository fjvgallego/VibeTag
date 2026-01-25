# VibeTag: Functional Requirements & Business Rules

## Overview
An offline-first iOS application designed to organize Apple Music libraries using semantic tags ("Vibes") and AI.

## Key Functionalities

1. **Shadow Sync (Library Import):**
   - The app reads the user's Apple Music library via `MusicKit`.
   - It stores lightweight references (ID, Title, Artist, ArtworkURL) in the local database (SwiftData).
   - **Constraint:** Audio files are never downloaded.

2. **Tag Management:**
   - Users can create custom tags (Name + Color).
   - **Relationship:** Many-to-Many (One song can have multiple tags).
   - **Scope:** Tags are private per user (User Scope), though System Tags may exist globally.

3. **Semantic Search:**
   - Local search using Apple's `NLTagger`.
   - **Logic:** Input "Music for studying" -> System lemmatizes input -> Searches for tags like `#Study` or `#Focus`.

4. **Synchronization (Lazy Auth):**
   - **Guest Mode:** Users can use full core features without logging in.
   - **Merge Strategy:** Upon signing in with Apple (SIWA), local data is merged with the cloud account.

5. **AI Auto-Tagger:**
   - **On-Demand Analysis:** The user triggers analysis for a playlist or batch of songs.
   - The Backend queries an **external LLM provider** (e.g., OpenAI, Anthropic, or DeepSeek) to suggest tags based on song metadata.