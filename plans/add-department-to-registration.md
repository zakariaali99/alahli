# Plan: Add Department/Academy Selector to Registration Form

## Problem

When an athlete self-registers, the `Athlete` record is created with `department=None`. The admin must manually:

1. Go to NewAthletes → click "إنشاء رياضي"
2. Pick an academy (department) from a dropdown
3. Then go back and click "اعتماد"

This is an unnecessary extra step — the athlete could simply pick their academy during registration.

## Goal

Let athletes pick their academy (department) during self-registration, so `Athlete.department` is set immediately. The admin then just reviews and approves — no "إنشاء رياضي" needed.

## Changes

### 1. Backend `serializers.py` — Add department to `RegisterSerializer`

Add an optional `department` field (department ID, validated to exist):

```python
department = serializers.IntegerField(required=False, allow_null=True)
```

### 2. Backend `views.py` (`register_view`) — Use department when creating Athlete

Pass `department_id` to `Athlete.objects.create()`:

```python
athlete = Athlete.objects.create(
    ...
    department_id=serializer.validated_data.get("department"),
)
```

### 3. Backend `serializers.py` — Expose department in `RegistrationRequestSerializer`

Add `athlete_department_name` so the admin can see which academy the athlete chose:

```python
athlete_department_name = serializers.CharField(
    source="athlete.department.name_ar", read_only=True, allow_null=True
)
```

### 4. Frontend `RegisterAthlete.tsx` — Add department dropdown

- Fetch `GET /departments/` on mount
- Add a `<select>` dropdown labeled "الأكاديمية / القسم"
- Include `department` in the `POST /auth/register/` payload:

```json
{
  "role": "athlete",
  "department": 2,
  ...
}
```

### 5. Frontend `NewAthletes.tsx` — Display chosen department

Add a box in the admin review grid showing `registration.athlete_department_name`.

## Phases

### Phase 1: Backend Schema & Serializers
- Add `department` field to `RegisterSerializer`
- Add `athlete_department_name` to `RegistrationRequestSerializer`
- **Files:** `backend/apps/athletes/serializers.py`
- **Test:** `python manage.py test athletes`

### Phase 2: Backend View
- Update `register_view` to pass `department_id` to `Athlete.objects.create()`
- **File:** `backend/apps/athletes/views.py`
- **Test:** POST `/auth/register/` with `department` → athlete has department set

### Phase 3: Frontend Registration Form
- Fetch departments list via `GET /departments/`
- Add department `<select>` dropdown to `RegisterAthlete.tsx`
- Send `department` in POST body
- **File:** `frontend/src/pages/RegisterAthlete.tsx`
- **Test:** Registration form shows departments, data sent correctly

### Phase 4: Frontend Admin View
- Display `athlete_department_name` in `NewAthletes.tsx` registration card
- **File:** `frontend/src/pages/admin/NewAthletes.tsx`
- **Verify:** Admin sees chosen academy in pending registrations

### Phase 5: Cleanup & Verify
- Run `python manage.py test athletes subscriptions accounts`
- Run `npx tsc --noEmit` (frontend type check)
- Verify `vite build` succeeds

## What this achieves

- Athlete picks academy during registration → `Athlete.department` set immediately
- Admin sees chosen academy in the registration request card
- Admin clicks "اعتماد" — done, no "إنشاء رياضي" needed
- `Athlete.department` is always populated (or `null` if athlete skipped the field)

## What stays the same

- The checkout wizard (`SubscriptionPage.tsx`) still lets the athlete/parent pick academy → sport → group for the subscription
- `Athlete.department` and the subscription's group→sport→department chain are independent by default, but they'll align if the athlete picks the same academy at registration and checkout
- The "إنشاء رياضي" button in `NewAthletes.tsx` still exists as a safety net for edge cases
- All existing endpoints, models, and serializers remain backward-compatible
