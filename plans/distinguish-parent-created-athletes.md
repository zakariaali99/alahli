# Plan: Distinguish Parent-Created Athletes in Admin UI

## Problem

When a parent creates an athlete profile for their child via `POST /athletes/parent/athletes/`, the system:

1. Creates a new `User(role="athlete")` for the child
2. Creates a `RegistrationRequest(role_choice="athlete")`
3. Creates an `Athlete` linked to that request
4. Creates a `ParentAthlete` record linking the parent to the athlete

The admin sees this in the registration list (`NewAthletes.tsx`) with the **child's name and phone** as `user_name`/`user_phone` — identical to a self-registered athlete. There is **no visual indicator** distinguishing:

| Aspect | Self-Registered | Parent-Created |
|--------|----------------|----------------|
| `role_choice` | `"athlete"` | `"athlete"` |
| `user_name` | Athlete's name | Child's name |
| `user_phone` | Athlete's phone | Child's phone |

The only way to tell them apart is checking the `ParentAthlete` table (`athlete.parents.exists()`), which is currently not exposed.

## Goal

Add a visual indicator in the admin registration list showing:

- Whether the registration came from a parent creating a child athlete
- Who the parent is (parent's name/phone)

## Changes

### 1. Backend `serializers.py` — Add parent info to `RegistrationRequestSerializer`

```python
class RegistrationRequestSerializer(serializers.ModelSerializer):
    has_parent = serializers.SerializerMethodField()
    parent_name = serializers.SerializerMethodField()
    parent_phone = serializers.SerializerMethodField()

    def get_has_parent(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return False
        return athlete.parents.exists()

    def get_parent_name(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return None
        parent_link = athlete.parents.first()
        if parent_link is None:
            return None
        return parent_link.parent.full_name_ar

    def get_parent_phone(self, obj):
        athlete = getattr(obj, "athlete", None)
        if athlete is None:
            return None
        parent_link = athlete.parents.first()
        if parent_link is None:
            return None
        return parent_link.parent.phone
```

### 2. Backend `models.py` — Optimize `RegistrationRequestViewSet` queryset

```python
def get_queryset(self):
    return RegistrationRequest.objects.all().select_related(
        "user", "reviewed_by", "athlete", "athlete__department"
    ).prefetch_related("athlete__parents__parent")
```

### 3. Frontend `types.ts` — Update `RegistrationRequest` interface

```typescript
export interface RegistrationRequest {
    has_parent: boolean
    parent_name: string | null
    parent_phone: string | null
}
```

### 4. Frontend `NewAthletes.tsx` — Display parent indicator

In the info grid, add a badge when the athlete was created by a parent:

```tsx
{registration.has_parent && (
    <div className="rounded-xl border border-info/30 bg-info/10 px-3 py-2">
        <p className="text-muted-foreground text-xs">تمت الإضافة بواسطة</p>
        <p className="font-semibold text-xs">{registration.parent_name}</p>
        <p className="text-[11px] text-muted-foreground">{registration.parent_phone}</p>
    </div>
)}
```

## Phases

### Phase 1: Backend Serializer
- Add `has_parent`, `parent_name`, `parent_phone` serializer method fields to `RegistrationRequestSerializer`
- **File:** `backend/apps/athletes/serializers.py`
- **Test:** `GET /athletes/registrations/` returns new fields

### Phase 2: Backend Queryset Optimization
- Update `RegistrationRequestViewSet.get_queryset()` to prefetch `athlete__parents__parent`
- **File:** `backend/apps/athletes/views.py`
- **Verify:** No N+1 queries when serializing parent info

### Phase 3: Frontend Types & UI
- Add `has_parent`, `parent_name`, `parent_phone` to `RegistrationRequest` TypeScript interface
- Display parent info badge in `NewAthletes.tsx` registration card
- **Files:** `frontend/src/lib/types.ts`, `frontend/src/pages/admin/NewAthletes.tsx`
- **Verify:** Parent-created athletes show parent info; self-registered athletes don't

### Phase 4: Cleanup & Verify
- Run `python manage.py test athletes`
- Run `npx tsc --noEmit`
- Verify `vite build` succeeds

## What this achieves

- Admin instantly sees which registrations are parent-created
- Parent's name and phone are displayed alongside the child's info
- No schema change needed — uses existing `ParentAthlete` relation

## What stays the same

- No database migrations required
- Self-registered athletes show `has_parent: false` with no parent info
- All existing flows (registration, checkout, approval) are unchanged
- The `ParentAthlete` model and its creation logic are untouched
