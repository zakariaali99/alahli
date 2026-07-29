import { useState } from "react"
import { Link } from "react-router-dom"
import { motion, type Variants } from "framer-motion"
import {
  Users, Search, Filter, Phone, Shield, CheckCircle2,
  Clock, XCircle, ChevronLeft, ChevronRight, User, UserX,
  RefreshCw, Dumbbell,
} from "lucide-react"
import { useQuery } from "@tanstack/react-query"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input, Select } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
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

interface Account {
  id: number
  phone: string
  full_name_ar: string
  role: string
  is_active: boolean
  residence: string
  whatsapp_phone: string
  academy_name: string | null
  registration_status: "pending" | "approved" | "rejected" | null
  created_at?: string
}

const ROLE_LABELS: Record<string, string> = {
  athlete: "رياضي",
  parent: "ولي أمر",
  super_admin: "مدير عام",
  academy_manager: "مدير أكاديمية",
  reception: "استقبال",
  trainer: "مدرب",
  viewer: "مشاهد",
}

const ROLE_COLORS: Record<string, string> = {
  athlete: "bg-blue-500/15 text-blue-600",
  parent: "bg-emerald-500/15 text-emerald-600",
  super_admin: "bg-purple-500/15 text-purple-700",
  academy_manager: "bg-indigo-500/15 text-indigo-700",
  reception: "bg-amber-500/15 text-amber-700",
  trainer: "bg-orange-500/15 text-orange-700",
  viewer: "bg-slate-500/15 text-slate-600",
}

function formatDate(d?: string) {
  if (!d) return "—"
  return new Date(d).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric", month: "short", day: "numeric",
  })
}

function RegistrationStatusBadge({ status }: { status: Account["registration_status"] }) {
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

export default function AccountsPage() {
  const [search, setSearch] = useState("")
  const [roleFilter, setRoleFilter] = useState("all")
  const [statusFilter, setStatusFilter] = useState("all")
  const [page, setPage] = useState(1)
  const PAGE_SIZE = 20

  // Build params
  const params: Record<string, string> = {
    page: String(page),
    page_size: String(PAGE_SIZE),
  }
  if (roleFilter !== "all") params.role_choice = roleFilter
  if (statusFilter !== "all") params.status = statusFilter

  // Query registrations (athletes + parents)
  const { data: regData, isLoading: regLoading, refetch } = useQuery({
    queryKey: ["accounts-registrations", params],
    queryFn: async () => {
      const res = await api.get<PaginatedResponse<any> | any[]>("/athletes/registrations/", params)
      return res
    },
  })

  const rawRegs = regData ? extractResults(regData as any) : []

  // Map to account-like structure, apply client-side search
  const accounts: Account[] = rawRegs
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
      role: r.role_choice || "",
      is_active: r.status === "approved",
      residence: "",
      whatsapp_phone: "",
      academy_name: r.athlete_department_name || null,
      registration_status: r.status,
      created_at: r.created_at,
    }))

  const totalFromReg = regData && !Array.isArray(regData) ? (regData as any).count : accounts.length
  const totalPages = Math.ceil(totalFromReg / PAGE_SIZE)

  const isLoading = regLoading

  return (
    <motion.div
      className="space-y-8"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Ambient glows */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      {/* Header */}
      <motion.div variants={itemVariants} className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <h1 className="section-header text-3xl font-extrabold">الحسابات</h1>
          <p className="text-sm text-muted-foreground mt-2">
            عرض وإدارة جميع حسابات الرياضيين وأولياء الأمور المسجلين في النظام.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            <RefreshCw className="w-4 h-4" />
            تحديث
          </Button>
          <Link to="/dashboard/athletes/add">
            <Button size="sm" className="bg-gradient-to-r from-primary to-primary-container text-primary-foreground shadow-lg shadow-primary/20">
              <User className="w-4 h-4" />
              إضافة حساب
            </Button>
          </Link>
        </div>
      </motion.div>

      {/* Filters */}
      <motion.div
        variants={itemVariants}
        className="glass-card rounded-3xl p-4 flex flex-col lg:flex-row gap-3 items-center"
      >
        {/* Search */}
        <div className="flex-1 w-full">
          <Input
            type="text"
            placeholder="البحث بالاسم أو رقم الهاتف..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            icon={<Search className="w-4 h-4 text-muted-foreground" />}
          />
        </div>

        {/* Role filter */}
        <div className="min-w-[180px]">
          <Select
            value={roleFilter}
            onChange={(e) => { setRoleFilter(e.target.value); setPage(1) }}
            icon={<Filter className="w-4 h-4 text-muted-foreground" />}
          >
            <option value="all">النوع: الكل</option>
            <option value="athlete">رياضي</option>
            <option value="parent">ولي أمر</option>
          </Select>
        </div>

        {/* Status filter */}
        <div className="min-w-[200px]">
          <Select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
            icon={<Shield className="w-4 h-4 text-muted-foreground" />}
          >
            <option value="all">الحالة: الكل</option>
            <option value="approved">مقبول</option>
            <option value="pending">قيد المراجعة</option>
            <option value="rejected">مرفوض</option>
          </Select>
        </div>
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
          <table className="w-full text-right border-collapse min-w-[700px]">
            <thead>
              <tr className="bg-surface-container-lowest/50 border-b border-outline-variant/30 text-muted-foreground text-xs font-semibold">
                <th className="py-4 px-5 font-semibold">المستخدم</th>
                <th className="py-4 px-5 font-semibold">رقم الهاتف</th>
                <th className="py-4 px-5 font-semibold">النوع</th>
                <th className="py-4 px-5 font-semibold">الأكاديمية</th>
                <th className="py-4 px-5 font-semibold">حالة الطلب</th>
                <th className="py-4 px-5 font-semibold">تاريخ التسجيل</th>
                <th className="py-4 px-5 font-semibold text-left">إجراءات</th>
              </tr>
            </thead>
            <tbody className="text-sm divide-y divide-outline-variant/10">
              {accounts.length > 0 ? (
                accounts.map((account, idx) => (
                  <motion.tr
                    key={`${account.id}-${idx}`}
                    variants={itemVariants}
                    className="group transition-colors hover:bg-surface-container-lowest/80"
                  >
                    {/* Name */}
                    <td className="py-3 px-5">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-sm shrink-0">
                          {account.full_name_ar.charAt(0) || "؟"}
                        </div>
                        <div>
                          <p className="font-semibold text-foreground text-sm">{account.full_name_ar || "—"}</p>
                          <p className="text-[11px] text-muted-foreground">#{account.id}</p>
                        </div>
                      </div>
                    </td>

                    {/* Phone */}
                    <td className="py-3 px-5 text-foreground text-sm" dir="ltr">{account.phone || "—"}</td>

                    {/* Role */}
                    <td className="py-3 px-5">
                      <span className={`inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-1 rounded-full ${ROLE_COLORS[account.role] || "bg-muted text-muted-foreground"}`}>
                        {account.role === "athlete" ? <Dumbbell className="w-3 h-3" /> : <Users className="w-3 h-3" />}
                        {ROLE_LABELS[account.role] || account.role}
                      </span>
                    </td>

                    {/* Academy */}
                    <td className="py-3 px-5 text-muted-foreground text-xs">{account.academy_name || "—"}</td>

                    {/* Registration status */}
                    <td className="py-3 px-5">
                      <RegistrationStatusBadge status={account.registration_status} />
                    </td>

                    {/* Date */}
                    <td className="py-3 px-5 text-muted-foreground text-xs">{formatDate(account.created_at)}</td>

                    {/* Actions */}
                    <td className="py-3 px-5 text-left">
                      {account.role === "athlete" && (
                        <Link
                          to={`/dashboard/registrations`}
                          className="text-xs text-primary hover:underline opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          عرض الطلب
                        </Link>
                      )}
                    </td>
                  </motion.tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-16 h-16 rounded-2xl bg-muted flex items-center justify-center">
                        <UserX className="w-8 h-8 text-muted-foreground" />
                      </div>
                      <p className="text-muted-foreground text-sm font-medium">لا توجد حسابات مطابقة</p>
                      <p className="text-muted-foreground text-xs">حاول تغيير معايير البحث أو الفلتر</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          {/* Pagination */}
          <div className="border-t border-outline-variant/20 p-4 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-muted-foreground">
            <span>عرض {accounts.length} حساب</span>
            {totalPages > 1 && (
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
            )}
          </div>
        </motion.div>
      )}
    </motion.div>
  )
}
