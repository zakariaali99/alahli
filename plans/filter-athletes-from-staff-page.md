# Plan: Filter Athletes and Parents from Staff Management Page

## Problem

The `UserViewSet` at `GET /auth/users/` returns **all users** regardless of role (`User.objects.all()`). The frontend `StaffManagement.tsx` fetches this endpoint with no role filter and defaults to showing all roles. As a result, athletes and parents appear in the staff management page alongside admins, receptionists, trainers, and managers.

## Goal

Exclude `athlete` and `parent` roles from the staff management endpoint. The staff page should only show staff-like roles: `super_admin`, `reception`, `academy_manager`, `trainer`, `viewer`.

## Changes

### 1. Backend `accounts/views.py` — Filter queryset by role

```python
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.filter(
        role__in=["super_admin", "reception", "academy_manager", "trainer", "viewer"]
    ).order_by("-id")
```

This is the primary fix — the backend simply never serves non-staff users to this endpoint.

### 2. Frontend `StaffManagement.tsx` — Defensive filter (optional)

Add a client-side filter as a safety net:

```tsx
const filtered = (Array.isArray(users) ? users : []).filter((u) => {
    if (u.role === "athlete" || u.role === "parent") return false
    if (roleFilter && u.role !== roleFilter) return false
    // ... search logic ...
    return true
})
```

### 3. Backend `accounts/serializers.py` — Update UserSerializer if needed

No changes needed — `UserSerializer` already handles all roles generically.

## Phases

### Phase 1: Backend Filter
- Update `UserViewSet.queryset` in `accounts/views.py` to filter by staff roles only
- **File:** `backend/apps/accounts/views.py`
- **Test:** `GET /auth/users/` returns only staff roles; `GET /auth/users/?role=athlete` returns empty

### Phase 2: Frontend Defensive Filter
- Add client-side `athlete`/`parent` skip in `StaffManagement.tsx` filter chain
- **File:** `frontend/src/pages/admin/StaffManagement.tsx`
- **Verify:** Staff page shows no athletes/parents even with empty role filter

### Phase 3: Cleanup & Verify
- Run `python manage.py test accounts`
- Run `npx tsc --noEmit`
- Verify `vite build` succeeds

## What this achieves

- Staff management page only shows staff users
- Athletes and parents never appear in the list
- Admins, receptionists, academy managers, trainers, and viewers are shown
- Defense in depth: both backend and frontend filter

## What stays the same

- All other endpoints (`/auth/me/`, `/athletes/`, `/athletes/registrations/`, etc.) are unaffected
- Athletes can still be managed via the athletes list page (`/dashboard/athletes`)
- Parents can still be managed via registration requests
- Role-based permissions (`IsReceptionOrAbove`) are unchanged
