import React, { useState } from "react"
import { Link } from "react-router-dom"
import { motion } from "framer-motion"
import { Plus, Search, Filter, ArrowDown, LayoutGrid, TableProperties, Eye, Edit2, MoreVertical, ChevronRight, ChevronLeft } from "lucide-react"
import { useAthletes } from "@/lib/hooks/useAthletes"

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] as const } },
}

export default function AthletesPage() {
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [viewMode, setViewMode] = useState<"table" | "grid">("table")
  const [page, setPage] = useState(1)

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
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold gap-1 bg-secondary/15 text-secondary">
          <span className="w-1.5 h-1.5 rounded-full bg-secondary" />
          نشط
        </span>
      )
    }
    return (
      <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold gap-1 bg-error/15 text-error">
        <span className="w-1.5 h-1.5 rounded-full bg-error" />
        غير نشط
      </span>
    )
  }

  const formatDate = (d: string) => {
    return new Date(d).toLocaleDateString("ar-SA", { year: "numeric", month: "long", day: "numeric" })
  }

  return (
    <motion.div className="space-y-8 select-none" variants={containerVariants} initial="hidden" animate="visible">
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />

      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground">إدارة اللاعبين</h1>
          <p className="text-sm text-muted-foreground mt-2">
            عرض وإدارة بيانات جميع الرياضيين المسجلين في النظام.
          </p>
        </div>
        <Link to="/dashboard/athletes/add">
          <button className="bg-primary text-primary-foreground font-semibold px-5 py-2.5 rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all flex items-center gap-2 text-sm">
            <Plus className="w-4 h-4" />
            إضافة رياضي جديد
          </button>
        </Link>
      </div>

      <div className="glass-card rounded-2xl p-4 flex flex-col md:flex-row gap-4 items-center justify-between shadow-sm">
        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto flex-1">
          <div className="relative w-full max-w-sm">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
            <input
              type="text"
              placeholder="ابحث بالاسم، رقم الهاتف أو رقم العضوية..."
              value={searchQuery}
              onChange={(e) => { setSearchQuery(e.target.value); setPage(1) }}
              className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
            />
          </div>

          <div className="relative w-full sm:w-44">
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary outline-none cursor-pointer appearance-none"
            >
              <option value="all">حالة الاشتراك: الكل</option>
              <option value="active">نشط</option>
              <option value="inactive">غير نشط</option>
            </select>
            <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="h-6 w-px bg-border/50 mx-2" />
          <button
            onClick={() => setViewMode("table")}
            className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
              viewMode === "table" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
            }`}
          >
            <TableProperties className="w-4 h-4" />
          </button>
          <button
            onClick={() => setViewMode("grid")}
            className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
              viewMode === "grid" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
            }`}
          >
            <LayoutGrid className="w-4 h-4" />
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
        </div>
      ) : viewMode === "table" ? (
        <div className="glass-card rounded-2xl overflow-hidden shadow-sm flex flex-col border border-border/20">
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[800px]">
              <thead>
                <tr className="bg-surface-container-lowest/50 border-b border-border/40 text-muted-foreground text-xs font-semibold">
                  <th className="py-4 px-4">الرياضي</th>
                  <th className="py-4 px-4">رقم العضوية</th>
                  <th className="py-4 px-4">رقم الهاتف</th>
                  <th className="py-4 px-4">القسم</th>
                  <th className="py-4 px-4">الحالة</th>
                  <th className="py-4 px-4">تاريخ الانضمام</th>
                  <th className="py-4 px-6 text-left">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="text-sm divide-y divide-border/20">
                {athletes.map((athlete) => (
                  <motion.tr key={athlete.id} variants={itemVariants} className="hover:bg-surface-container-lowest/80 transition-colors group">
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full overflow-hidden bg-muted border border-border/50 shrink-0 relative">
                          {athlete.photo ? (
                            <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-primary bg-primary-container/20 font-bold">
                              {athlete.full_name.charAt(0)}
                            </div>
                          )}
                        </div>
                        <div>
                          <p className="font-semibold text-foreground">{athlete.full_name}</p>
                        </div>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-foreground font-mono text-xs">{athlete.membership_number}</td>
                    <td className="py-3 px-4 text-foreground font-medium" dir="ltr">{athlete.phone}</td>
                    <td className="py-3 px-4 text-foreground">{athlete.department_name || "—"}</td>
                    <td className="py-3 px-4">{statusBadge(athlete.is_active)}</td>
                    <td className="py-3 px-4 text-muted-foreground text-xs">{formatDate(athlete.created_at)}</td>
                    <td className="py-3 px-6 text-left">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <Link to={`/dashboard/athletes/${athlete.id}`}>
                          <button className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors" title="عرض التفاصيل">
                            <Eye className="w-4 h-4" />
                          </button>
                        </Link>
                        <button className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors" title="تعديل">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button className="p-2 rounded-lg text-muted-foreground hover:text-error hover:bg-error-container/50 transition-colors" title="المزيد">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </motion.tr>
                ))}
                {athletes.length === 0 && (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-muted-foreground text-sm">
                      لا يوجد لاعبين مطابقين للبحث
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="bg-white/50 border-t border-border/20 p-4 flex items-center justify-between text-xs text-muted-foreground">
            <span>عرض {athletes.length} من أصل {data?.count || 0} لاعب</span>
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted disabled:opacity-40 transition-colors"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                const p = i + 1
                return (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={`w-8 h-8 rounded-lg flex items-center justify-center font-semibold transition-colors ${
                      page === p ? "bg-primary text-primary-foreground" : "hover:bg-muted"
                    }`}
                  >
                    {p}
                  </button>
                )
              })}
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={page >= totalPages}
                className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted disabled:opacity-40 transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {athletes.map((athlete) => (
            <motion.div key={athlete.id} variants={itemVariants} className="glass-card p-6 rounded-2xl flex flex-col justify-between gap-4 hover:shadow-md transition-all group">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-muted border border-border/50 shrink-0 relative">
                    {athlete.photo ? (
                      <img alt={athlete.full_name} src={athlete.photo} className="object-cover w-full h-full" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-primary bg-primary-container/20 font-bold text-lg">
                        {athlete.full_name.charAt(0)}
                      </div>
                    )}
                  </div>
                  <div>
                    <h4 className="font-bold text-foreground text-sm">{athlete.full_name}</h4>
                    <p className="text-xs text-muted-foreground font-mono">{athlete.membership_number}</p>
                  </div>
                </div>
                {statusBadge(athlete.is_active)}
              </div>
              <div className="space-y-2 text-xs text-muted-foreground border-t border-border/20 pt-4">
                <div className="flex justify-between">
                  <span>الهاتف:</span>
                  <span className="text-foreground font-medium" dir="ltr">{athlete.phone}</span>
                </div>
                <div className="flex justify-between">
                  <span>القسم:</span>
                  <span className="text-foreground font-semibold">{athlete.department_name || "—"}</span>
                </div>
                <div className="flex justify-between">
                  <span>تاريخ الانضمام:</span>
                  <span className="text-foreground">{formatDate(athlete.created_at)}</span>
                </div>
              </div>
              <div className="flex gap-2 mt-2">
                <Link to={`/dashboard/athletes/${athlete.id}`} className="flex-1">
                  <button className="w-full py-2 bg-primary-container/20 text-primary hover:bg-primary-container/40 text-xs font-semibold rounded-lg transition-colors flex items-center justify-center gap-1">
                    <Eye className="w-3.5 h-3.5" /> التفاصيل
                  </button>
                </Link>
                <button className="py-2 px-3 border border-border/60 hover:bg-muted text-muted-foreground hover:text-foreground rounded-lg transition-all">
                  <Edit2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </motion.div>
  )
}
