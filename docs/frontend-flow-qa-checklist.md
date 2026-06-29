# Frontend Flow QA Checklist

This checklist verifies that the core flow works across the frontend:

1. Create user
2. Login
3. Select academy
4. Select sport
5. Select group
6. Checkout subscription

## Preconditions

- Backend is running and reachable via `VITE_API_URL`.
- Frontend is running with fresh local storage.
- QA seed data prepared:
  - At least one active academy, sport, group, and package.
  - At least one trainer user for group forms.

## Test Matrix

| ID | Scenario | Route | Expected Result |
|---|---|---|---|
| F1 | Athlete self-registration | `/register/athlete` | Account created; success message; redirected to login |
| F2 | Parent self-registration | `/register/parent` | Account created; success message; redirected to login |
| F3 | Athlete login | `/login` | Redirect to `/user` |
| F4 | Parent login | `/login` | Redirect to `/user` |
| F5 | Parent with no linked athletes | `/user` | Clear message to add athlete first (no blank page) |
| F6 | Parent add athlete | `/user/athlete` | Athlete added and appears in parent list |
| F7 | Athlete academy selection | `/user` | Academies list visible, selectable |
| F8 | Sport selection | `/user` step 2 | Sports list for selected academy visible |
| F9 | Group selection | `/user` step 3 | Groups list for selected sport visible |
| F10 | Package selection | `/user` step 4 | Packages list visible and sorted |
| F11 | Cash checkout | `/user` final step | Subscription request created successfully |
| F12 | Bank transfer checkout | `/user` final step | Reject non-PDF; accept PDF; request created |
| F13 | Admin review pending registrations | `/dashboard/registrations` | Pending items visible and actionable |
| F14 | Approve registration | `/dashboard/registrations` | Request status updates and disappears from pending list |
| F15 | Reject registration | `/dashboard/registrations` | Request status updates and disappears from pending list |

## Edge Cases

### Data absence states

- No academies -> show explicit empty state, not empty blank body.
- Academy with no sports -> show explicit empty state.
- Sport with no groups -> show explicit empty state.
- No packages -> show explicit empty state.

### API shape resilience

For list endpoints used in the flow, frontend must handle both:

- paginated: `{ count, next, previous, results: [...] }`
- direct array: `[...]`

Endpoints:

- `GET /departments/`
- `GET /sports/?department=<id>`
- `GET /groups/?sport=<id>`
- `GET /packages/`
- `GET /athletes/parent/athletes/`
- `GET /athletes/registrations/?status=pending`
- `GET /subscriptions/?status=pending`

### Session and routing

- Expired access token should refresh transparently.
- Failed refresh should redirect to `/login` (not blank page).
- Role redirects:
  - `athlete`/`parent` -> `/user`
  - `super_admin`/`reception` -> `/dashboard`

## Data Integrity Checks

After successful checkout, verify in backend/admin API:

- `athlete_id` matches selected athlete.
- `sport_id`, `group_id`, `package_id` match selected entities.
- `payment_method` matches selected payment option.
- `invoice_pdf` exists only when payment method is bank transfer.

After approval/rejection:

- Registration `status` reflects action.
- Pending lists refresh and remove processed item.

## Quick Command Gate

Run before merging:

```bash
npm run lint
npx tsc --noEmit
npm run build
```

Optional backend checks:

```bash
python3 manage.py check
python3 -m pytest -q
```
