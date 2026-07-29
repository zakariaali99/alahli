import type { Department } from "@/lib/types"

export function isParentAcademy(dept: Department | null | undefined): boolean {
  if (!dept) return false
  const name = (dept.name || "").toLowerCase()
  const nameAr = dept.name_ar || ""
  return name.includes("aws") || nameAr.includes("أوس")
}
