import type { Department } from "@/lib/types"

export function isParentAcademy(dept: Department | null | undefined): boolean {
  if (!dept) return false
  const name = (dept.name || "").toLowerCase()
  const nameAr = dept.name_ar || ""
  return name.includes("aws") || nameAr.includes("أوس")
}

export function getAcademyLogo(dept: Department | null | undefined): string {
  if (!dept) return "/logo.png"
  if (dept.logo) return dept.logo
  const name = (dept.name || "").toLowerCase()
  const nameAr = dept.name_ar || ""
  if (name.includes("aws") || nameAr.includes("أوس") || dept.id === 5 || dept.id === 3) {
    return "/alaws_logo.png"
  }
  return "/logo.png"
}
