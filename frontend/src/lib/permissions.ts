import type { User } from "./auth"

export type Role = User["role"]

export type Action =
  | "athletes:read"
  | "athletes:create"
  | "athletes:update"
  | "athletes:delete"
  | "subscriptions:read"
  | "subscriptions:create"
  | "subscriptions:update"
  | "subscriptions:delete"
  | "subscriptions:renew"
  | "packages:create"
  | "packages:update"
  | "packages:delete"
  | "departments:read"
  | "departments:create"
  | "departments:update"
  | "departments:delete"
  | "sports:create"
  | "sports:update"
  | "sports:delete"
  | "groups:create"
  | "groups:update"
  | "groups:delete"
  | "staff:read"
  | "staff:create"
  | "staff:update"
  | "staff:delete"
  | "coaches:read"
  | "coaches:create"
  | "coaches:update"
  | "coaches:delete"
  | "products:read"
  | "products:create"
  | "products:update"
  | "products:delete"
  | "registrations:read"
  | "registrations:approve"
  | "registrations:reject"
  | "settings:read"
  | "settings:update"
  | "reports:read"
  | "notifications:read"
  | "notifications:create"
  | "notifications:delete"
  | "analytics:read"
  | "attendance:create"
  | "verify:read"

const PERMISSIONS: Record<Action, Role[]> = {
  "athletes:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "athletes:create": ["super_admin", "academy_manager"],
  "athletes:update": ["super_admin", "academy_manager"],
  "athletes:delete": ["super_admin"],

  "subscriptions:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer", "athlete", "parent"],
  "subscriptions:create": ["super_admin", "academy_manager"],
  "subscriptions:update": ["super_admin", "academy_manager"],
  "subscriptions:delete": ["super_admin"],
  "subscriptions:renew": ["super_admin", "academy_manager"],

  "packages:create": ["super_admin", "academy_manager"],
  "packages:update": ["super_admin"],
  "packages:delete": ["super_admin"],

  "departments:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "departments:create": ["super_admin"],
  "departments:update": ["super_admin"],
  "departments:delete": ["super_admin"],

  "sports:create": ["super_admin", "academy_manager"],
  "sports:update": ["super_admin", "academy_manager"],
  "sports:delete": ["super_admin"],

  "groups:create": ["super_admin", "academy_manager"],
  "groups:update": ["super_admin", "academy_manager"],
  "groups:delete": ["super_admin"],

  "staff:read": ["super_admin", "academy_manager"],
  "staff:create": ["super_admin"],
  "staff:update": ["super_admin"],
  "staff:delete": ["super_admin"],

  "coaches:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "coaches:create": ["super_admin", "academy_manager"],
  "coaches:update": ["super_admin", "academy_manager"],
  "coaches:delete": ["super_admin"],

  "products:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "products:create": ["super_admin"],
  "products:update": ["super_admin"],
  "products:delete": ["super_admin"],

  "registrations:read": ["super_admin", "academy_manager"],
  "registrations:approve": ["super_admin", "academy_manager"],
  "registrations:reject": ["super_admin", "academy_manager"],

  "settings:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "settings:update": ["super_admin"],

  "reports:read": ["super_admin", "academy_manager"],

  "notifications:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
  "notifications:create": ["super_admin"],
  "notifications:delete": ["super_admin"],

  "analytics:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],

  "attendance:create": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],

  "verify:read": ["super_admin", "academy_manager", "reception", "trainer", "viewer"],
}

export function can(user: User | null, action: Action): boolean {
  if (!user) return false
  const roles = PERMISSIONS[action]
  return roles.includes(user.role)
}

export function roleLabel(role: Role): string {
  const labels: Record<Role, string> = {
    super_admin: "مدير النظام",
    academy_manager: "مدير الأكاديمية",
    reception: "موظف استقبال",
    trainer: "مدرب",
    viewer: "مشاهد",
    athlete: "رياضي",
    parent: "ولي أمر",
  }
  return labels[role] || role
}
