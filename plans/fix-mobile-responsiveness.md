# Plan: Fix Mobile Responsiveness (UI Stuck to the Right)

## Problem

On mobile devices (viewport < 768px), the dashboard UI overflows horizontally — content is "stuck to the right" and the user cannot see what's on the left side.

## Root Causes

### Cause 1 (Primary): Sidebar `translate-x-full` in RTL mode

**File:** `DashboardLayout.tsx:116`

```tsx
className={`fixed top-0 right-0 h-screen ... w-72 ...
    ${sidebarOpen ? "translate-x-0" : "translate-x-full opacity-0 pointer-events-none"}`}
```

When closed on mobile, the sidebar is `fixed` at `right: 0` with `width: 288px`. `translate-x-full` moves it **288px to the right**. Some mobile browsers still expand the viewport to include this off-screen element.

### Cause 2: Wide tables with `min-w` breaking containers

Files: `AthletesList.tsx` (min-w-[800px]), `Memberships.tsx` (min-w-[680px]), `AthleteProfile.tsx` (min-w-[600px]), `StaffManagement.tsx` (min-w-[640px])

The parent card uses `overflow-hidden` while the child wrapper uses `overflow-x-auto`. The combination clips the scrollable region — the table expands the parent card, which overflows the main content area.

### Cause 3: `#root` div unstyled

`index.html` has `<div id="root"></div>` with no `overflow-x-hidden`. Although `<html>` and `<body>` have it, the `#root` element sits between them without clipping.

### Cause 4: `vw`-based background decorations extend beyond viewport

Decorative blobs with `w-[60vw]` + `-right-[10%]` extend 70% beyond the viewport. Some browsers compute scrollable width including these.

## Changes

### 1. `frontend/index.html` — Clip root element

```diff
- <div id="root"></div>
+ <div id="root" class="overflow-x-hidden max-w-full"></div>
```

Also clip `<html>`:

```diff
- <html lang="ar" dir="rtl">
+ <html lang="ar" dir="rtl" class="overflow-x-hidden">
```

### 2. `frontend/src/pages/DashboardLayout.tsx` — Fix sidebar RTL overflow

```diff
- ${sidebarOpen ? "translate-x-0 opacity-100" : "translate-x-full opacity-0 pointer-events-none"}
+ ${sidebarOpen ? "translate-x-0 opacity-100" : "max-md:translate-x-full opacity-0 pointer-events-none"}
```

Add `max-w-[100vw]` to the root flex container:

```diff
- <div className="min-h-screen bg-background text-foreground flex overflow-x-hidden">
+ <div className="min-h-screen bg-background text-foreground flex overflow-x-hidden max-w-[100vw]">
```

Add `min-w-0` to main content area to allow flex shrink:

```diff
- <div className={`flex-1 flex flex-col min-h-screen transition-all ... ${sidebarOpen ? "md:mr-64" : "md:mr-0"}`}>
+ <div className={`flex-1 flex flex-col min-h-screen min-w-0 transition-all ... ${sidebarOpen ? "md:mr-64" : "md:mr-0"}`}>
```

### 3. Fix table containers across pages

For `AthletesList.tsx`, `Memberships.tsx`, `AthleteProfile.tsx`, `StaffManagement.tsx`:

```diff
- <div className="glass-card rounded-3xl overflow-hidden shadow-sm border border-border/20">
+ <div className="glass-card rounded-3xl overflow-x-auto shadow-sm border border-border/20">
```

## Phases

### Phase 1: Root HTML + Dashboard Layout
- Add `overflow-x-hidden` to `<html>` and `#root` div in `index.html`
- Fix sidebar RTL overflow: use `max-md:translate-x-full` instead of `translate-x-full`
- Add `max-w-[100vw]` and `min-w-0` to dashboard layout containers
- **Files:** `frontend/index.html`, `frontend/src/pages/DashboardLayout.tsx`
- **Verify:** Mobile sidebar toggle no longer causes horizontal scroll

### Phase 2: Table Containers
- Change `overflow-hidden` → `overflow-x-auto` on table card wrappers in:
  - `AthletesList.tsx`
  - `Memberships.tsx`
  - `AthleteProfile.tsx`
  - `StaffManagement.tsx`
- **Verify:** Wide tables scroll horizontally within their cards on mobile

### Phase 3: Cleanup & Verify
- Test on mobile viewport (375px) in browser devtools
- Test sidebar open/close on mobile
- Test each table page for horizontal scroll behavior
- Verify desktop layout is unaffected

## What this achieves

- Mobile viewport no longer overflows horizontally
- Sidebar correctly hides off-screen without expanding the viewport
- Wide tables scroll horizontally within their containers
- Background decorations don't affect viewport width
- RTL layout preserved

## What to test

1. Mobile (375px viewport) — all dashboard pages load without horizontal scroll
2. Sidebar open/close on mobile — content snaps correctly
3. Tables (athletes list, memberships) — scroll horizontally within cards
4. Desktop unaffected — sidebar still works as before
