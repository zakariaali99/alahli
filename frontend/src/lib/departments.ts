import type { Department } from "@/lib/types"

export function normalizeText(str: string | null | undefined): string {
  if (!str) return ""
  return str
    .toLowerCase()
    .replace(/[أإآ]/g, "ا")
    .replace(/ة/g, "ه")
    .trim()
}

export function isParentAcademy(dept: Department | null | undefined): boolean {
  if (!dept) return false
  const name = (dept.name || "").toLowerCase()
  const nameAr = normalizeText(dept.name_ar)
  return name.includes("aws") || nameAr.includes("اوس")
}

export function getAcademyLogo(dept: Department | null | undefined): string {
  if (!dept) return "/logo.png"
  if (dept.logo) return dept.logo
  if (isParentAcademy(dept)) {
    return "/alaws_logo.png"
  }
  return "/logo.png"
}
