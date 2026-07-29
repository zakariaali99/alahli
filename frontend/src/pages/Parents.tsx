import { useState } from "react"
import { useSearchParams } from "react-router-dom"
import { motion, type Variants } from "framer-motion"
import {
  Users, Search, Filter, CheckCircle2,
  Clock, XCircle, ChevronLeft, ChevronRight, UserX,
  RefreshCw, Phone,
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
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}
const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.35, ease: [0.22, 1, 0.36, 1] } },
}

interface Parent {
  id: number
  phone: string
  full_name_ar: string
  is_active: boolean
  registration_status: "pending" | "approved" | "rejected" | null
  created_at?: string
}

function formatDate(d?: string) {
  if (!d) return "—"
  return new Date(d).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric", month: "short", day: "numeric",
  })
}

function RegistrationStatusBadge({ status }: { status: Parent["registration_status"] }) {
  if (!status) return null
  if (status === "approved") return (
    <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-600 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">
      <CheckCircle2 className="w-3 h-3" /> مقبول
    </span>
  )
  if (status === "pending") return (
    <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-600 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">
      <Clock className="w-3 h-3" /> قيد المراجعة
    </span>
  )
  return (
    <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-red-600 bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">
      <XCircle className="w-3 h-3" /> مرفوض
    </span>
  )
}

export default function ParentsPage() {
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")
  const [page, setPage] = useState(1)
  const PAGE_SIZE = 20
  const [showSyncModal, setShowSyncModal] = useState(false)

  const handleRefresh = async () => {
    setShowSyncModal(true)
    const startTime = Date.now()
    await refetch()
    const elapsedTime = Date.now() - startTime
    const delay = Math.max(0, 1000 - elapsedTime) // delay at least 1s
    setTimeout(() => {
      setShowSyncModal(false)
    }, delay)
  }

  const params: Record<string, string> = {
    page: String(page),
    page_size: String(PAGE_SIZE),
    role_choice: "parent",
    ...(deptParam ? { department: deptParam } : {}),
  }
  if (statusFilter !== "all") params.status = statusFilter

  const { data: regData, isLoading, isFetching, refetch } = useQuery({
    queryKey: ["parents-registrations", params],
    queryFn: async () => {
      const res = await api.get<PaginatedResponse<any> | any[]>("/athletes/registrations/", params)
      return res
    },
  })

  const rawRegs = regData ? extractResults(regData as any) : []

  const parents: Parent[] = rawRegs
    .filter((r: any) => {
      if (!search) return true
      const q = search.toLowerCase()
      return (
        (r.user_name || "").toLowerCase().includes(q) ||
        (r.user_phone || "").includes(q)
      )
    })
    .map((r: any) => ({
      id: r.user,
      phone: r.user_phone || "",
      full_name_ar: r.user_name || "",
      is_active: r.status === "approved",
      registration_status: r.status,
      created_at: r.created_at,
    }))

  const totalFromReg = regData && !Array.isArray(regData) ? (regData as any).count : parents.length
  const totalPages = Math.ceil(totalFromReg / PAGE_SIZE)

  return (
    <motion.div
      className="space-y-8"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      <motion.div variants={itemVariants} className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <h1 className="section-header text-3xl font-extrabold">أولياء الأمور</h1>
          <p className="text-sm text-muted-foreground mt-2">
            عرض وإدارة حسابات أولياء الأمور المسجلين في النظام.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={handleRefresh}>
            <RefreshCw className="w-4 h-4" />
            تحديث
          </Button>
        </div>
      </motion.div>

      <motion.div
        variants={itemVariants}
        className="glass-card rounded-3xl p-4 flex flex-col lg:flex-row gap-3 items-center"
      >
        <div className="flex-1 w-full">
          <Input
            type="text"
            placeholder="البحث بالاسم أو رقم الهاتف..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            icon={<Search className="w-4 h-4 text-muted-foreground" />}
          />
        </div>
        <div className="min-w-[180px]">
          <Select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
            icon={<Filter className="w-4 h-4 text-muted-foreground" />}
          >
            <option value="all">الحالة: الكل</option>
            <option value="pending">قيد المراجعة</option>
            <option value="approved">مقبول</option>
            <option value="rejected">مرفوض</option>
          </Select>
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[560px] text-right text-sm">
          <thead>
            <tr className="border-b border-border text-xs text-muted-foreground">
              <th className="px-4 py-3">الاسم</th>
              <th className="px-4 py-3">رقم الهاتف</th>
              <th className="px-4 py-3">تاريخ التسجيل</th>
              <th className="px-4 py-3">الحالة</th>
            </tr>
          </thead>
          <tbody>
            {isLoading && (
              <tr>
                <td colSpan={4}>
                  <TableSkeleton rows={8} />
                </td>
              </tr>
            )}
            {!isLoading && parents.length === 0 && (
              <tr>
                <td colSpan={4}>
                  <div className="flex flex-col items-center justify-center py-16 gap-3 text-muted-foreground">
                    <UserX className="w-10 h-10 opacity-30" />
                    <p className="text-sm">لا يوجد أولياء أمور مسجلين</p>
                  </div>
                </td>
              </tr>
            )}
            {!isLoading && parents.map((p) => (
              <tr key={p.id} className="border-b border-border/50 hover:bg-surface-container-low/50">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-emerald-500/10 text-xs font-bold text-emerald-600">
                      {(p.full_name_ar || "?").charAt(0)}
                    </div>
                    <span className="font-semibold">{p.full_name_ar || "—"}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-muted-foreground" dir="ltr">
                  <div className="flex items-center gap-1.5">
                    <Phone className="w-3.5 h-3.5" />
                    {p.phone || "—"}
                  </div>
                </td>
                <td className="px-4 py-3 text-muted-foreground text-xs">{formatDate(p.created_at)}</td>
                <td className="px-4 py-3">
                  <RegistrationStatusBadge status={p.registration_status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </motion.div>

      {totalPages > 1 && (
        <motion.div variants={itemVariants} className="flex items-center justify-between pt-2">
          <span className="text-xs text-muted-foreground">
            إجمالي: {totalFromReg} ولي أمر
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
            >
              <ChevronRight className="w-4 h-4" />
            </Button>
            <span className="text-xs text-muted-foreground px-1">{page} / {totalPages}</span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
            >
              <ChevronLeft className="w-4 h-4" />
            </Button>
          </div>
        </motion.div>
      )}

      <motion.div variants={itemVariants} className="flex items-center gap-6 text-xs text-muted-foreground pb-2">
        <span className="flex items-center gap-1"><Users className="w-3.5 h-3.5" /> {parents.length} ولي أمر في هذه الصفحة</span>
      </motion.div>

      {showSyncModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-md">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-card border border-border/40 p-8 rounded-3xl shadow-2xl flex flex-col items-center space-y-4 max-w-xs text-center"
          >
            <div className="relative w-16 h-16 flex items-center justify-center">
              <div className="absolute inset-0 rounded-full border-4 border-primary/20 animate-pulse" />
              <div className="absolute inset-0 rounded-full border-4 border-t-primary border-r-transparent border-b-transparent border-l-transparent animate-spin" />
              <RefreshCw className="w-6 h-6 text-primary animate-pulse" />
            </div>
            <div className="space-y-1">
              <h3 className="font-extrabold text-foreground text-lg">تحديث البيانات</h3>
              <p className="text-xs text-muted-foreground">يرجى الانتظار، جاري جلب أحدث البيانات...</p>
            </div>
          </motion.div>
        </div>
      )}
    </motion.div>
  )
}
