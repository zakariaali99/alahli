import React, { useState } from "react"
import { Link } from "react-router-dom"
import { motion, type Variants } from "framer-motion"
import {
  Plus, Search, Filter, LayoutGrid, TableProperties, Eye, Edit2,
  ChevronRight, ChevronLeft, Users, UserX, MoreVertical,
} from "lucide-react"
import { useAthletes } from "@/lib/hooks/useAthletes"
import { Button } from "@/components/ui/button"
import { TableSkeleton } from "@/components/ui/loading-spinner"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

const departmentIcons: Record<string, string> = {
  "الأهلي للياقة": "🏋️",
  "أكاديمية كرة القدم": "⚽",
  "السباحة": "🏊",
}

function DepartmentDisplay({ name }: { name: string | null }) {
  if (!name) return <span className="text-muted-foreground">—</span>
  const icon = departmentIcons[name] || null
  return (
    <div className="flex items-center gap-2">
      {icon && (
        <div className="w-6 h-6 rounded bg-primary-container/20 flex items-center justify-center text-xs shrink-0">
          {icon}
        </div>
      )}
      <span>{name}</span>
    </div>
  )
}

export default function AthletesPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [viewMode, setViewMode] = useState<"table" | "grid">("table")
  const [page, setPage] = useState(1)
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set())
  const [selectAll, setSelectAll] = useState(false)

  const { data, isLoading } = useAthletes({
    page,
    page_size: 20,
    search: searchQuery || undefined,
    ...(statusFilter !== "all" ? { is_active: statusFilter === "active" ? "true" : "false" } : {}),
  })

  const athletes = data?.results || []
  const totalPages = data ? Math.ceil(data.count / 20) : 0

  const statusBadge = (isActive: boolean) => {
    if (isActive) {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold bg-secondary/10 text-secondary border border-secondary/10">
          <span className="w-1.5 h-1.5 rounded-full bg-secondary" />
          نشط
        </span>
      )
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold bg-error-container/30 text-error border border-error/10">
        <span className="w-1.5 h-1.5 rounded-full bg-error" />
        غير نشط
      </span>
    )
  }

  const formatDate = (d: string) => {
    return new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "long", day: "numeric" })
  }

  const toggleSelectAll = () => {
    if (selectAll) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(athletes.map((a) => a.id)))
    }
    setSelectAll(!selectAll)
  }

  const toggleSelect = (id: number) => {
    const next = new Set(selectedIds)
    if (next.has(id)) {
      next.delete(id)
    } else {
      next.add(id)
    }
    setSelectedIds(next)
    setSelectAll(next.size === athletes.length && athletes.length > 0)
  }

  return (
    <motion.div
      className="space-y-8 select-none"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* ── Ambient Background Glow ── */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      {/* ── Premium Header ── */}
      <motion.div variants={itemVariants} className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <h1 className="section-header text-3xl font-extrabold">إدارة اللاعبين</h1>
          </div>
          <p className="text-sm text-muted-foreground mt-4">
            عرض وإدارة بيانات جميع الرياضيين المسجلين في النظام.
          </p>
        </div>
        <Link to="/dashboard/athletes/add">
          <Button size="lg" className="bg-gradient-to-r from-primary to-primary-container text-primary-foreground shadow-lg shadow-primary/20 hover:shadow-primary/30">
            <Plus className="w-4 h-4" />
            إضافة رياضي جديد
          </Button>
        </Link>
      </motion.div>

      {/* ── Filter Bar ── */}
      <motion.div
        variants={itemVariants}
        className="glass-card rounded-2xl p-4 flex flex-col lg:flex-row gap-4 items-center justify-between"
      >
        <div className="flex flex-wrap gap-3 w-full lg:w-auto">
          {/* Status Filter */}
          <div className="relative min-w-[160px]">
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="w-full appearance-none bg-surface-container-low border border-outline-variant/30 text-foreground text-sm rounded-xl px-4 py-2.5 pr-10 focus:ring-2 focus:ring-primary focus:border-primary hover:bg-surface-container-high cursor-pointer transition-colors outline-none"
            >
              <option value="all">حالة الاشتراك: الكل</option>
              <option value="active">نشط</option>
              <option value="inactive">غير نشط</option>
            </select>
            <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
          </div>
        </div>

        {/* Sort & View Toggles */}
        <div className="flex items-center gap-2 w-full lg:w-auto justify-between lg:justify-end">
          <div className="flex items-center gap-1.5 bg-surface-container-low rounded-lg p-1">
            <button
              onClick={() => setViewMode("table")}
              className={`w-9 h-9 rounded-md flex items-center justify-center transition-all ${
                viewMode === "table"
                  ? "bg-white dark:bg-card shadow-sm text-primary"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <TableProperties className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode("grid")}
              className={`w-9 h-9 rounded-md flex items-center justify-center transition-all ${
                viewMode === "grid"
                  ? "bg-white dark:bg-card shadow-sm text-primary"
                  : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
          </div>
        </div>
      </motion.div>

      {/* ── Search ── */}
      <div className="relative w-full max-w-md -mt-4">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
        <input
          type="text"
          placeholder="البحث عن رياضي..."
          value={searchQuery}
          onChange={(e) => { setSearchQuery(e.target.value); setPage(1) }}
          className="w-full bg-surface-container-low text-sm text-foreground rounded-xl py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
        />
      </div>

      {/* ── Loading State ── */}
      {isLoading ? (
        viewMode === "table" ? (
          <div className="glass-card rounded-2xl overflow-hidden shadow-sm border border-border/20">
            <TableSkeleton />
          </div>
        ) : (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full" />
          </div>
        )
      ) : viewMode === "table" ? (
        /* ── Table View ── */
        <motion.div
          variants={itemVariants}
          className="glass-card rounded-2xl overflow-hidden shadow-sm border border-border/20"
        >
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[800px]">
              <thead>
                <tr className="bg-surface-container-lowest/50 border-b border-outline-variant/30 text-muted-foreground text-xs font-semibold">
                  <th className="py-4 px-4 w-12">
                    <input
                      type="checkbox"
                      checked={selectAll}
                      onChange={toggleSelectAll}
                      className="rounded border-outline-variant text-primary focus:ring-primary w-4 h-4 cursor-pointer"
                    />
                  </th>
                  <th className="py-4 px-4 font-semibold">الرياضي</th>
                  <th className="py-4 px-4 font-semibold">رقم الهاتف</th>
                  <th className="py-4 px-4 font-semibold">القسم</th>
                  <th className="py-4 px-4 font-semibold">الحالة</th>
                  <th className="py-4 px-4 font-semibold">تاريخ الانضمام</th>
                  <th className="py-4 px-4 font-semibold text-left">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="text-sm divide-y divide-outline-variant/10">
                {athletes.length > 0 ? (
                  athletes.map((athlete) => (
                    <motion.tr
                      key={athlete.id}
                      variants={itemVariants}
                      className="relative group transition-colors hover:bg-surface-container-lowest/80"
                    >
                      <td className="py-3 px-4">
                        <input
                          type="checkbox"
                          checked={selectedIds.has(athlete.id)}
                          onChange={() => toggleSelect(athlete.id)}
                          className="rounded border-outline-variant text-primary focus:ring-primary w-4 h-4 cursor-pointer opacity-50 group-hover:opacity-100 transition-opacity"
                        />
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full overflow-hidden bg-surface-container-high border border-outline-variant/20 shrink-0">
                            {athlete.photo ? (
                              <img
                                alt={athlete.full_name}
                                src={athlete.photo}
                                className="object-cover w-full h-full"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center text-primary font-bold text-sm">
                                {athlete.full_name.charAt(0)}
                              </div>
                            )}
                          </div>
                          <div>
                            <p className="font-semibold text-foreground text-sm">{athlete.full_name}</p>
                            <p className="text-[11px] text-muted-foreground font-mono">{athlete.membership_number}</p>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-foreground text-sm" dir="ltr">{athlete.phone}</td>
                      <td className="py-3 px-4">
                        <DepartmentDisplay name={athlete.department_name} />
                      </td>
                      <td className="py-3 px-4">{statusBadge(athlete.is_active)}</td>
                      <td className="py-3 px-4 text-muted-foreground text-xs">{formatDate(athlete.created_at)}</td>
                      <td className="py-3 px-4 text-left">
                        <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-all duration-200">
                          <Link to={`/dashboard/athletes/${athlete.id}`}>
                            <motion.button
                              whileHover={{ scale: 1.1 }}
                              whileTap={{ scale: 0.9 }}
                              className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors"
                              title="عرض التفاصيل"
                            >
                              <Eye className="w-4 h-4" />
                            </motion.button>
                          </Link>
                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors"
                            title="تعديل"
                          >
                            <Edit2 className="w-4 h-4" />
                          </motion.button>
                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            className="p-2 rounded-lg text-muted-foreground hover:text-error hover:bg-error-container/30 transition-colors"
                            title="المزيد"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </motion.button>
                        </div>
                      </td>
                    </motion.tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={8} className="py-16 text-center">
                      <div className="flex flex-col items-center gap-3">
                        <div className="w-16 h-16 rounded-2xl bg-muted flex items-center justify-center">
                          <UserX className="w-8 h-8 text-muted-foreground" />
                        </div>
                        <p className="text-muted-foreground text-sm font-medium">لا يوجد لاعبين مطابقين للبحث</p>
                        <p className="text-muted-foreground text-xs">حاول تغيير معايير البحث أو تصفية الحالة</p>
                      </div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* ── Pagination ── */}
          <div className="border-t border-outline-variant/20 p-4 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-muted-foreground">
            <span>عرض {athletes.length} من أصل {data?.count || 0} لاعب</span>
            {totalPages > 0 && (
              <div className="flex items-center gap-1">
                <Button
                  variant="ghost"
                  size="sm"
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
                  variant="ghost"
                  size="sm"
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page >= totalPages}
                  className="w-8 h-8 rounded-lg p-0"
                >
                  <ChevronLeft className="w-4 h-4" />
                </Button>
              </div>
            )}
          </div>
        </motion.div>
      ) : (
        /* ── Grid View ── */
        <motion.div
          variants={itemVariants}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {athletes.length > 0 ? (
            athletes.map((athlete) => (
              <motion.div
                key={athlete.id}
                variants={itemVariants}
                whileHover={{ y: -6, transition: { duration: 0.2 } }}
                className="relative overflow-hidden glass-card rounded-2xl p-6 flex flex-col justify-between gap-4 hover:shadow-xl transition-all group"
              >
                <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-primary via-secondary to-primary opacity-60" />

                <div className="flex items-start justify-between relative">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full overflow-hidden bg-surface-container-high border border-outline-variant/20 shrink-0 shadow-sm">
                      {athlete.photo ? (
                        <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-primary font-bold text-lg">
                          {athlete.full_name.charAt(0)}
                        </div>
                      )}
                    </div>
                    <div>
                      <h4 className="font-bold text-foreground text-sm">{athlete.full_name}</h4>
                      <p className="text-xs text-muted-foreground font-mono mt-0.5">{athlete.membership_number}</p>
                    </div>
                  </div>
                  {statusBadge(athlete.is_active)}
                </div>

                <div className="space-y-2.5 text-xs text-muted-foreground border-t border-border/20 pt-4 relative">
                  <div className="flex justify-between">
                    <span className="font-medium">الهاتف:</span>
                    <span className="text-foreground font-medium" dir="ltr">{athlete.phone}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium">القسم:</span>
                    <span className="text-foreground font-semibold">{athlete.department_name || "—"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-medium">تاريخ الانضمام:</span>
                    <span className="text-foreground">{formatDate(athlete.created_at)}</span>
                  </div>
                </div>

                <div className="flex gap-2 mt-2 relative">
                  <Link to={`/dashboard/athletes/${athlete.id}`} className="flex-1">
                    <motion.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      className="w-full py-2.5 bg-gradient-to-r from-primary/10 to-primary/5 text-primary hover:from-primary/20 hover:to-primary/10 text-xs font-semibold rounded-xl transition-all flex items-center justify-center gap-1.5 border border-primary/10"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      التفاصيل
                    </motion.button>
                  </Link>
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="py-2.5 px-3.5 border border-border/60 hover:bg-surface-container-low text-muted-foreground hover:text-foreground rounded-xl transition-all"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </motion.button>
                </div>
              </motion.div>
            ))
          ) : (
            <div className="col-span-full flex flex-col items-center justify-center py-20 gap-3">
              <div className="w-20 h-20 rounded-[1.25rem] bg-muted flex items-center justify-center">
                <Users className="w-10 h-10 text-muted-foreground/60" />
              </div>
              <p className="text-muted-foreground text-sm font-medium">لا يوجد لاعبين مطابقين للبحث</p>
              <p className="text-muted-foreground text-xs">حاول تغيير معايير البحث أو تصفية الحالة</p>
            </div>
          )}
        </motion.div>
      )}
    </motion.div>
  )
}
