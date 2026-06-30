# Plan: Link Packages to Academies (Departments)

## Problem

`SubscriptionPackage` is currently **standalone** — no foreign keys to any other model. During checkout, all packages are shown regardless of which academy/sport/group the user selected. This means:

- A package for "Football Training" shows up when the user selects "Swimming Academy"
- No way to scope pricing, duration, or features per academy
- Admin must manually remember which packages belong to which academy

## Goal

Link each package to a **Department** (academy), so only relevant packages appear when the user selects a given academy in the checkout wizard.

## Changes

### 1. Backend `packages/models.py` — Add `department` FK

```python
class SubscriptionPackage(models.Model):
    department = models.ForeignKey(
        "departments.Department", on_delete=models.CASCADE,
        null=True, blank=True, related_name="packages",
        help_text="Academy this package belongs to. Null = available to all academies.",
    )
```

### 2. Backend `packages/serializers.py` — Add `department_name`

```python
class SubscriptionPackageSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source="department.name_ar", read_only=True, allow_null=True)

    class Meta:
        model = SubscriptionPackage
        fields = "__all__"  # already includes department
```

### 3. Backend `packages/views.py` — Filter by department query param

```python
def get_queryset(self):
    qs = super().get_queryset()
    department_id = self.request.query_params.get("department")
    if department_id:
        qs = qs.filter(department_id=department_id)
    return qs
```

### 4. Frontend `SubscriptionPage.tsx` — Filter packages by selected academy

When fetching packages in step 4 (or 3 for non-parent), pass the selected academy's department ID:

```tsx
const fetchPackages = async (departmentId: number) => {
    const res = await api.get(`/packages/?department=${departmentId}`)
    setPackages(extractResults(res))
}
```

Update the `selectGroup` callback to pass the department ID:

```tsx
const selectGroup = (g: Group) => {
    setData((prev) => ({ ...prev, group: g }))
    fetchPackages(data.academy!.id)
    setStep(isParent ? 4 : 3)
}
```

### 5. Backend `packages/admin.py` — Show department in list

```python
list_display = ["name", "department", "price", "duration_value", "duration_type", "tag", "is_active"]
```

### 6. Migration

Create a migration to add the `department` field. Existing packages will have `department=None` (available globally) — backward compatible.

## Phases

### Phase 1: Backend Schema (Model + Migration)
- Add `department` FK to `SubscriptionPackage` model
- Create migration: `python manage.py makemigrations packages`
- Run migration: `python manage.py migrate`
- **File:** `backend/apps/packages/models.py`
- **Test:** `python manage.py test packages`

### Phase 2: Backend API (Serializer + View)
- Add `department_name` to `SubscriptionPackageSerializer`
- Override `get_queryset` in `SubscriptionPackageViewSet` to filter by `?department=` query param
- Update admin `list_display`
- **Files:** `backend/apps/packages/serializers.py`, `views.py`, `admin.py`

### Phase 3: Frontend Checkout Wizard
- Update `fetchPackages` in `SubscriptionPage.tsx` to accept `departmentId` and pass it as query param
- Call `fetchPackages(data.academy!.id)` in `selectGroup`
- **File:** `frontend/src/pages/SubscriptionPage.tsx`
- **Verify:** Selecting an academy filters packages shown in the next step

### Phase 4: Cleanup & Verify
- Run `python manage.py test packages subscriptions`
- Run `npx tsc --noEmit`
- Verify `vite build` succeeds

## What this achieves

- Each academy has its own set of packages
- Checkout wizard only shows packages relevant to the selected academy
- Global packages (no department) still appear across all academies
- Admin can assign packages per academy in the dashboard

## What stays the same

- The checkout flow steps (academy → sport → group → package → payment) remain identical
- All existing packages with `department=null` continue to work
- Parents, athletes, and subscription logic unchanged
