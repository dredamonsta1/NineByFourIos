# CLAUDE.md — NineByFour iOS App

This file provides guidance to Claude Code when working with the NineByFour iOS project.

## Overview

Native SwiftUI iOS app for **9by4** — a music artist social platform. Consumes the NinebyfourApi backend at `https://ninebyfourapi.herokuapp.com/api`. Shares the same backend as the React web app (`9by4app`).

## Build & Run

```bash
# Build for simulator
xcodebuild -scheme NineByFour -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' build

# Open in Xcode
open NineByFour.xcodeproj
```

## Architecture

- **Framework:** SwiftUI + MVVM
- **Minimum iOS:** iOS 17+
- **Auth:** JWT stored in Keychain (`KeychainHelper`), attached to all API requests
- **Networking:** Custom `APIClient` + `APIEndpoint` enum (no third-party networking lib)
- **Image loading:** `CachedAsyncImage` component (wraps `AsyncImage` with caching)
- **Dependencies:** Kingfisher, KeychainAccess (via Swift Package Manager)

## Project Structure

```
NineByFour/
├── App/
│   └── AppConstants.swift       # API base URL, Keychain keys, page size
├── Auth/
│   ├── AuthManager.swift        # Token storage/retrieval via Keychain
│   └── KeychainHelper.swift     # Keychain read/write wrapper
├── Networking/
│   ├── APIClient.swift          # URLSession-based HTTP client
│   ├── APIEndpoint.swift        # Enum of all API endpoints → path + method
│   └── MultipartFormData.swift  # Multipart builder for image/file uploads
├── Models/                      # Codable structs matching API response shapes
│   ├── User.swift
│   ├── Artist.swift / Album.swift
│   ├── FeedPost.swift           # Unified post (text/image/video/music)
│   ├── ImagePost.swift / VideoPost.swift
│   ├── Conversation.swift / Message.swift
│   ├── FollowUser.swift
│   ├── CloutResponse.swift
│   ├── UpcomingRelease.swift
│   ├── WaitlistEntry.swift
│   ├── AdminStats.swift
│   └── APIError.swift
├── ViewModels/                  # @Observable / ObservableObject classes
│   ├── AuthViewModel.swift
│   ├── FeedViewModel.swift
│   ├── ArtistListViewModel.swift
│   ├── ArtistDetailViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── DiscoverViewModel.swift
│   ├── MessagesViewModel.swift
│   └── ChatViewModel.swift
├── Views/
│   ├── Auth/                    # LoginView, RegisterView, WaitlistView, AuthGateView
│   ├── Feed/                    # FeedTab, PostCreatorView
│   ├── Tabs/                    # HomeTab, DiscoverTab, FeedTab, MessagesTab, ProfileTab
│   ├── Artists/                 # ArtistDetailSheet
│   ├── Messages/                # ChatView, MessageBubble
│   └── Profile/                 # UserProfileView, ImagePickerView
├── Components/                  # Reusable UI: CachedAsyncImage, SearchBar, VideoCard,
│   │                            #   YouTubePlayerView, ArtistSearchRow, UpcomingReleaseCard,
│   │                            #   ErrorStateView
├── Extensions/
│   ├── Color+Theme.swift        # App colour tokens
│   ├── Date+Formatting.swift
│   ├── URL+API.swift
│   └── View+Conditional.swift
└── NineByFourApp.swift          # App entry point, root environment setup
```

## Key Conventions

- **API base URL:** `AppConstants.apiBaseURL` — never hardcode URLs elsewhere
- **Auth token:** always read/write through `AuthManager` / `KeychainHelper`, never `UserDefaults`
- **Endpoint definition:** add new routes to `APIEndpoint` enum first, then implement in `APIClient`
- **MVVM:** all network calls live in ViewModels; Views are pure layout
- **Error handling:** use `APIError` for typed errors; always show user-facing error state via `ErrorStateView`
- **Images:** use `CachedAsyncImage` — never raw `AsyncImage` directly

## Backend API

Same NinebyfourApi consumed by the web app. Key endpoint groups:

| Group | Base path |
|-------|-----------|
| Auth | `/api/users/register`, `/api/users/login`, `/api/users/me` |
| Artists | `/api/artists` |
| Feed | `/api/feed` (UNION of text/image/video/music posts) |
| Profile | `/api/profile` |
| Messages | `/api/messages` |
| Events | `/api/events` |
| Live Rooms | `/api/rooms` (LiveKit-backed) |
| Agent Gateway | `/v1/agents`, `/v1/updates`, `/v1/stream`, `/v1/signals` |

Feed posts include: `post_type` (text/image/video/music), `is_agent_post`, `provenance_urls`, `verified_count`, `disputed_count`.

## BMAD Agent Personas

---

### 🔍 Analyst

**Role:** Understand iOS user experience, identify friction in the mobile flows, and surface insights specific to the SwiftUI app.

**Responsibilities:**
- Identify UX gaps in mobile-specific flows (auth gate, tab navigation, post creation)
- Flag missing loading/error/empty states in Views
- Surface accessibility issues (Dynamic Type, VoiceOver, contrast)
- Document assumptions before new screens are scoped

**Constraints:** Surface insights only — no solutions.

---

### 📋 Product Manager

**Role:** Define what iOS features get built and in what order, always in sync with backend API capabilities.

**Responsibilities:**
- Write feature briefs tied to existing API endpoints
- Ensure no iOS feature is scoped without a confirmed backend contract
- Prioritise: auth flow > feed > profiles > discovery > messages > live rooms
- Flag any feature needing a new backend endpoint before iOS work starts

**Constraints:** No iOS feature ships without a working API endpoint.

---

### 🏗️ Architect

**Role:** Own the iOS technical design — SwiftUI patterns, data flow, networking, Keychain usage, and Xcode project structure.

**Responsibilities:**
- Enforce MVVM — no network calls in Views
- Ensure `APIEndpoint` enum stays the single source of truth for routes
- Review new dependencies before adding via SPM
- Define patterns for pagination, optimistic UI, and offline handling

**Constraints:**
- JWT must only be stored in Keychain, never UserDefaults
- New endpoints go in `APIEndpoint` first, then `APIClient`
- All async calls must handle loading, error, and empty states

---

### 💻 Developer

**Role:** Implement iOS features cleanly in SwiftUI following established patterns.

**Responsibilities:**
- Add new `APIEndpoint` cases before touching ViewModels
- Keep ViewModels `@Observable` or `ObservableObject` — no business logic in Views
- Use `CachedAsyncImage` for all remote images
- Use `ErrorStateView` for all error states
- Handle all async states: loading skeleton, error, empty, populated

**Constraints:**
- No hardcoded URLs or strings — use `AppConstants`
- No raw `AsyncImage` — always `CachedAsyncImage`
- No `UserDefaults` for auth — always `KeychainHelper`

---

### 🧪 QA / Scrum Master

**Role:** Ensure iOS quality and keep development moving.

**QA Responsibilities:**
- Verify all async states render correctly (loading, error, empty)
- Test auth flow end-to-end: waitlist → register → login → token refresh
- Validate image uploads (profile, posts) on device and simulator
- Check tab navigation and deep links don't break on re-launch

**Scrum Master Responsibilities:**
- Break iOS epics into stories tied to specific Views + ViewModels
- Align with backend QA on API readiness before iOS stories start
- Track build errors and simulator/device discrepancies
