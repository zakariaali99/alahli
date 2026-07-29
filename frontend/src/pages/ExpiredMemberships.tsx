import { useState } from "react"
import { Link, useSearchParams } from "react-router-dom"
import { motion, type Variants } from "framer-motion"
import {
  Search, Filter, AlertTriangle, Phone, Calendar, ChevronLeft,
  ChevronRight, RefreshCw, BadgeAlert, ExternalLink, Dumbbell,
  Clock, Building2,
} from "lucide-react"
import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input, Select } from "@/components/ui/input"
import { TableSkeleton } from "@/components/ui/loading-spinner"
import { extractResults } from "@/lib/response"
import type { PaginatedResponse } from "@/lib/types"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.05, delayChildren: 0.1 } },
}
const itemVariants: Variants = {
  hidden: { opacity: 0, y: 16 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.35, ease: [0.22, 1, 0.36, 1] } },
}

interface ExpiredSub {
  id: number
  athlete: number
  athlete_name: string
  membership_number: string
  department_name: string | null
  package_name: string
  start_date: string
  end_date: string
  amount: string
  status: string
}

function daysSinceExpiry(endDate: string): number {
  const diff = Date.now() - new Date(endDate).getTime()
  return Math.floor(diff / (1000 * 60 * 60 * 24))
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric",
    month: "short",
    day: "numeric",
  })
}

function ExpiryBadge({ endDate }: { endDate: string }) {
  const days = daysSinceExpiry(endDate)
  if (days <= 7)
    return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
        <Clock className="w-3 h-3" />
        منذ {days} {days === 1 ? "يوم" : "أيام"}
      </span>
    )
  if (days <= 30)
    return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-1 rounded-full bg-orange-50 text-orange-700 border border-orange-200">
        <AlertTriangle className="w-3 h-3" />
        منذ {days} يوم
      </span>
    )
  return (
    <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-1 rounded-full bg-red-50 text-red-700 border border-red-200">
      <BadgeAlert className="w-3 h-3" />
      منذ {days} يوم
    </span>
  )
}

export default function ExpiredMembershipsPage() {
  const [search, setSearch] = useState("")
  const [deptFilter, setDeptFilter] = useState("all")
  const [page, setPage] = useState(1)
  const PAGE_SIZE = 20
  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")

  const params: Record<string, string> = {
    status: "expired",
    page: String(page),
    page_size: String(PAGE_SIZE),
    ordering: "-end_date",
  }
  if (search) params.search = search
  if (deptParam) params.athlete__department = deptParam

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["expired-memberships", params],
    queryFn: () =>
      api.get<PaginatedResponse<ExpiredSub> | ExpiredSub[]>("/subscriptions/", params),
    staleTime: 60_000,
  })

  const raw = (data ? extractResults(data as any) : []) as ExpiredSub[]
  const subs: ExpiredSub[] = deptFilter === "all"
    ? raw
    : raw.filter((s: ExpiredSub) => s.department_name === deptFilter)

  const totalCount = data && !Array.isArray(data) ? (data as any).count : subs.length
  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  // Unique departments from results (for client-side dept filter)
  const departments = Array.from(
    new Set(raw.map((s: ExpiredSub) => s.department_name).filter(Boolean))
  ) as string[]

  return (
    <motion.div
      className="space-y-8"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Ambient glows */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-error/5 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-amber-500/5 blur-[100px] -z-10 pointer-events-none" />

      {/* Header */}
      <motion.div variants={itemVariants} className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-xl bg-error/10 flex items-center justify-center">
              <BadgeAlert className="w-5 h-5 text-error" />
            </div>
            <h1 className="section-header text-3xl font-extrabold">الاشتراكات المنتهية</h1>
          </div>
          <p className="text-sm text-muted-foreground mt-2">
            الرياضيون الذين انتهت اشتراكاتهم ولم يتم التجديد بعد.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            <RefreshCw className="w-4 h-4" />
            تحديث
          </Button>
          <Link to={`/dashboard/memberships${deptParam ? `?department=${deptParam}` : ""}`}>
            <Button size="sm" className="bg-gradient-to-r from-primary to-primary-container text-primary-foreground shadow-lg shadow-primary/20">
              <Dumbbell className="w-4 h-4" />
              إدارة الاشتراكات
            </Button>
          </Link>
        </div>
      </motion.div>

      {/* Stats banner */}
      {!isLoading && totalCount > 0 && (
        <motion.div variants={itemVariants}>
          <div className="rounded-2xl border border-error/20 bg-gradient-to-l from-error/5 to-transparent p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-error/10 flex items-center justify-center shrink-0">
              <AlertTriangle className="w-5 h-5 text-error" />
            </div>
            <div>
              <p className="font-bold text-error">
                {totalCount} اشتراك منتهي
              </p>
              <p className="text-xs text-muted-foreground">
                هؤلاء الرياضيون بحاجة إلى تجديد الاشتراك للاستمرار في التدريب
              </p>
            </div>
          </div>
        </motion.div>
      )}

      {/* Filters */}
      <motion.div
        variants={itemVariants}
        className="glass-card rounded-3xl p-4 flex flex-col lg:flex-row gap-3 items-center"
      >
        <div className="flex-1 w-full">
          <Input
            type="text"
            placeholder="البحث بالاسم أو رقم العضوية..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            icon={<Search className="w-4 h-4 text-muted-foreground" />}
          />
        </div>

        {!deptParam && departments.length > 0 && (
          <div className="min-w-[200px]">
            <Select
              value={deptFilter}
              onChange={(e) => { setDeptFilter(e.target.value); setPage(1) }}
              icon={<Building2 className="w-4 h-4 text-muted-foreground" />}
            >
              <option value="all">الأكاديمية: الكل</option>
              {departments.map((d) => (
                <option key={d} value={d}>{d}</option>
              ))}
            </Select>
          </div>
        )}
      </motion.div>

      {/* Table */}
      {isLoading ? (
        <div className="glass-card rounded-3xl overflow-hidden shadow-sm border border-border/20">
          <TableSkeleton />
        </div>
      ) : (
        <motion.div
          variants={itemVariants}
          className="glass-card rounded-3xl overflow-x-auto shadow-sm border border-border/20"
        >
          <table className="w-full text-right border-collapse min-w-[750px]">
            <thead>
              <tr className="bg-surface-container-lowest/50 border-b border-outline-variant/30 text-muted-foreground text-xs font-semibold">
                <th className="py-4 px-5 font-semibold">الرياضي</th>
                <th className="py-4 px-5 font-semibold">الأكاديمية</th>
                <th className="py-4 px-5 font-semibold">الباقة</th>
                <th className="py-4 px-5 font-semibold">تاريخ الانتهاء</th>
                <th className="py-4 px-5 font-semibold">مدة الانقطاع</th>
                <th className="py-4 px-5 font-semibold text-left">إجراءات</th>
              </tr>
            </thead>
            <tbody className="text-sm divide-y divide-outline-variant/10">
              {subs.length > 0 ? (
                subs.map((sub) => (
                  <motion.tr
                    key={sub.id}
                    variants={itemVariants}
                    className="group transition-colors hover:bg-surface-container-lowest/80"
                  >
                    {/* Athlete */}
                    <td className="py-3 px-5">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-error/10 flex items-center justify-center text-error font-bold text-sm shrink-0">
                          {sub.athlete_name.charAt(0)}
                        </div>
                        <div>
                          <p className="font-semibold text-foreground text-sm">{sub.athlete_name}</p>
                          <p className="text-[11px] text-muted-foreground font-mono">{sub.membership_number}</p>
                        </div>
                      </div>
                    </td>

                    {/* Academy */}
                    <td className="py-3 px-5 text-muted-foreground text-xs">
                      <div className="flex items-center gap-1.5">
                        <Building2 className="w-3.5 h-3.5 shrink-0" />
                        {sub.department_name || "—"}
                      </div>
                    </td>

                    {/* Package */}
                    <td className="py-3 px-5 text-xs">
                      <span className="bg-surface-container-low px-2.5 py-1 rounded-lg text-foreground font-medium">
                        {sub.package_name || "—"}
                      </span>
                    </td>

                    {/* End date */}
                    <td className="py-3 px-5">
                      <div className="flex items-center gap-1.5 text-error text-xs font-medium">
                        <Calendar className="w-3.5 h-3.5 shrink-0" />
                        {formatDate(sub.end_date)}
                      </div>
                    </td>

                    {/* Days since expiry */}
                    <td className="py-3 px-5">
                      <ExpiryBadge endDate={sub.end_date} />
                    </td>

                    {/* Actions */}
                    <td className="py-3 px-5 text-left">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <Link to={`/dashboard/athletes/${sub.athlete}`}>
                          <button
                            title="ملف الرياضي"
                            className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary/10 transition-colors"
                          >
                            <ExternalLink className="w-4 h-4" />
                          </button>
                        </Link>
                        <Link to={`/dashboard/memberships?athlete=${sub.athlete}`}>
                          <button
                            title="تجديد الاشتراك"
                            className="px-3 py-1.5 rounded-lg bg-primary text-primary-foreground text-xs font-semibold hover:bg-primary/90 transition-colors"
                          >
                            تجديد
                          </button>
                        </Link>
                      </div>
                    </td>
                  </motion.tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="py-20 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 flex items-center justify-center">
                        <Dumbbell className="w-8 h-8 text-emerald-500" />
                      </div>
                      <p className="text-muted-foreground text-sm font-medium">
                        {search || deptFilter !== "all"
                          ? "لا توجد نتائج مطابقة للبحث"
                          : "🎉 لا توجد اشتراكات منتهية"}
                      </p>
                      <p className="text-muted-foreground text-xs">
                        {search || deptFilter !== "all"
                          ? "حاول تغيير معايير البحث أو الفلتر"
                          : "جميع الاشتراكات فعّالة حالياً"}
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="border-t border-outline-variant/20 p-4 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-muted-foreground">
              <span>عرض {subs.length} من أصل {totalCount} اشتراك منتهٍ</span>
              <div className="flex items-center gap-1">
                <Button
                  variant="ghost" size="sm"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="w-8 h-8 rounded-lg p-0"
                >
                  <ChevronRight className="w-4 h-4" />
                </Button>
                {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                  const p = i + 1
                  return (
                    <button
                      key={p}
                      onClick={() => setPage(p)}
                      className={`min-w-[36px] h-8 rounded-lg flex items-center justify-center font-semibold text-xs transition-all ${
                        page === p
                          ? "bg-primary text-primary-foreground shadow-sm"
                          : "hover:bg-surface-container-high text-muted-foreground"
                      }`}
                    >
                      {p}
                    </button>
                  )
                })}
                <Button
                  variant="ghost" size="sm"
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page >= totalPages}
                  className="w-8 h-8 rounded-lg p-0"
                >
                  <ChevronLeft className="w-4 h-4" />
                </Button>
              </div>
            </div>
          )}
        </motion.div>
      )}
    </motion.div>
  )
}
