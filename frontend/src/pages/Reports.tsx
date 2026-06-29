import React, { useState, useEffect } from "react"
import { motion, type Variants } from "framer-motion"
import {
  Users,
  DollarSign,
  Activity,
  FileSpreadsheet,
  FileText,
  Percent,
  Calendar,
  CreditCard,
  Building,
} from "lucide-react"
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts"
import {
  useDashboardStats,
  useRevenue,
  useDepartmentDistribution,
} from "@/lib/hooks/useAnalytics"
import { useSubscriptions } from "@/lib/hooks/useSubscriptions"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { useAuth } from "@/lib/auth"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

const monthNames = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"]

function CustomTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-card/90 backdrop-blur-md rounded-xl px-4 py-3 shadow-lg border border-border/50 text-sm">
      <p className="font-bold text-foreground">{label}</p>
      <p className="text-primary font-extrabold mt-0.5">{payload[0].value.toLocaleString("ar-SA-u-nu-latn")} د.ل</p>
    </div>
  )
}

type Department = {
  id: number
  name_ar: string
  name: string
}

export default function ReportsPage() {
  const { user } = useAuth()
  const [departments, setDepartments] = useState<Department[]>([])
  const [selectedAcademy, setSelectedAcademy] = useState<number | undefined>(
    user?.academy ? Number(user.academy) : undefined
  )

  useEffect(() => {
    if (!user?.academy) {
      void fetchDepartments()
    }
  }, [user])

  const fetchDepartments = async () => {
    try {
      const data = await api.get<Department[] | { results: Department[] }>("/departments/")
      setDepartments(extractResults(data))
    } catch (e) {
      console.error(e)
    }
  }

  const { data: stats, isLoading: statsLoading } = useDashboardStats(selectedAcademy)
  const { data: revenueData, isLoading: revenueLoading } = useRevenue(selectedAcademy)
  const { data: departmentDistribution, isLoading: deptLoading } = useDepartmentDistribution(selectedAcademy)
  
  // Fetch latest 5 subscriptions for the payment details table
  const { data: subListData, isLoading: subListLoading } = useSubscriptions({
    page: 1,
    page_size: 5,
    ordering: "-id",
  })
  const recentPayments = subListData?.results || []

  const monthlyRevenueData = (revenueData || []).map((d) => {
    const date = new Date(d.month)
    return { name: monthNames[date.getMonth()], revenue: d.revenue }
  })

  const distributionData = departmentDistribution && departmentDistribution.length > 0 
    ? departmentDistribution.map((d) => ({
        name: d.department__name_ar || "أخرى",
        value: d.count
      }))
    : []

  const totalDistribution = distributionData.reduce((acc, curr) => acc + curr.value, 0)

  const totalRevenue = stats?.total_revenue ?? 0
  const activeMemberships = stats?.active_memberships ?? 0
  const renewalRate = stats?.renewal_rate ?? 0

  const COLORS = ["#00288e", "#006d30", "#e67e22", "#7c3aed", "#c62828"]

  const kpiCards = [
    {
      label: "إجمالي الإيرادات",
      value: `${totalRevenue.toLocaleString("ar-SA-u-nu-latn")} د.ل`,
      icon: DollarSign,
      iconBg: "bg-primary/10 text-primary",
    },
    {
      label: "اللاعبين النشطين",
      value: activeMemberships.toLocaleString("ar-SA-u-nu-latn"),
      icon: Users,
      iconBg: "bg-secondary/10 text-secondary",
    },
    {
      label: "معدل التجديد",
      value: `${renewalRate}%`,
      icon: Percent,
      iconBg: "bg-amber-500/10 text-amber-600",
    },
    {
      label: "إجمالي اللاعبين",
      value: (stats?.total_athletes ?? 0).toLocaleString("ar-SA-u-nu-latn"),
      icon: Activity,
      iconBg: "bg-primary/10 text-primary",
    },
  ]

  return (
    <motion.div className="space-y-8" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      {/* ── Ambient Background ── */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />
      <div className="fixed bottom-[-15%] left-[-10%] w-[40vw] h-[40vw] rounded-full bg-secondary/5 blur-[100px] -z-10 pointer-events-none" />

      {/* Page Header */}
      <motion.div className="flex flex-col md:flex-row md:items-end justify-between gap-4" variants={itemVariants}>
        <div>
          <h2 className="text-3xl font-extrabold text-foreground tracking-tight">نظرة عامة على الأداء</h2>
          <p className="text-muted-foreground mt-1 text-sm">تحليل شامل لبيانات اللاعبين والاشتراكات والإيرادات.</p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Academy Filter Option for Super Admins */}
          {!user?.academy && (
            <div className="flex items-center gap-2 bg-card border border-border px-3 py-1.5 rounded-xl shadow-sm">
              <Building className="w-4 h-4 text-muted-foreground" />
              <select
                className="text-xs font-semibold bg-transparent text-foreground outline-none cursor-pointer pr-5"
                value={selectedAcademy || ""}
                onChange={(e) => setSelectedAcademy(e.target.value === "" ? undefined : Number(e.target.value))}
              >
                <option value="">جميع الأكاديميات</option>
                {departments.map((d) => (
                  <option key={d.id} value={d.id}>{d.name_ar}</option>
                ))}
              </select>
            </div>
          )}

          <Button variant="outline" size="lg" className="glass-card flex items-center gap-2 rounded-xl text-primary cursor-pointer">
            <FileText className="w-4 h-4" />
            تصدير PDF
          </Button>
          <Button variant="outline" size="lg" className="glass-card flex items-center gap-2 rounded-xl text-secondary cursor-pointer">
            <FileSpreadsheet className="w-4 h-4" />
            تصدير Excel
          </Button>
        </div>
      </motion.div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {kpiCards.map((card, idx) => {
          const Icon = card.icon
          return (
            <motion.div
              key={idx}
              variants={itemVariants}
              className="glass-card rounded-2xl p-6 relative overflow-hidden"
            >
              <div className="absolute top-0 right-0 w-24 h-24 bg-primary/5 rounded-bl-full -z-10" />
              <div className="flex justify-between items-start mb-4">
                <span className="text-sm font-medium text-muted-foreground">{card.label}</span>
                <div className={`w-10 h-10 rounded-xl ${card.iconBg} flex items-center justify-center`}>
                  <Icon className="w-5 h-5" />
                </div>
              </div>
              <div className="text-2xl font-extrabold text-foreground">
                {statsLoading ? (
                  <span className="animate-pulse bg-muted rounded w-16 h-8 inline-block" />
                ) : (
                  card.value
                )}
              </div>
            </motion.div>
          )
        })}
      </div>

      {/* Bento Grid Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Bar Chart (Span 2) */}
        <motion.div variants={itemVariants} className="glass-card rounded-3xl p-6 lg:col-span-2 flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold text-foreground">تحليل الإيرادات (شهري)</h3>
            <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Calendar className="w-4 h-4" />
              <span>آخر 12 شهراً</span>
            </div>
          </div>
          <div className="flex-1 min-h-[300px]" dir="ltr">
            {revenueLoading ? (
              <div className="h-[300px] flex items-center justify-center">
                <div className="w-8 h-8 border-[3px] border-primary border-t-transparent rounded-full animate-spin" />
              </div>
            ) : monthlyRevenueData.length === 0 ? (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground text-sm">
                لا توجد بيانات إيرادات
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={monthlyRevenueData} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} opacity={0.5} />
                  <XAxis dataKey="name" tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: "var(--muted-fg)" }} />
                  <YAxis tickLine={false} axisLine={false} tickFormatter={(v) => `${v.toLocaleString("en")} د.ل`} tick={{ fontSize: 12, fill: "var(--muted-fg)" }} />
                  <Tooltip content={<CustomTooltip />} cursor={{ fill: "rgba(0, 40, 142, 0.02)" }} />
                  <Bar dataKey="revenue" fill="var(--primary)" radius={[6, 6, 0, 0]} maxBarSize={48} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </motion.div>

        {/* Donut Distribution Chart */}
        <motion.div variants={itemVariants} className="glass-card rounded-3xl p-6 flex flex-col items-center">
          <div className="w-full flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold text-foreground">توزيع اللاعبين بالأقسام</h3>
          </div>
          {deptLoading ? (
            <div className="flex-1 flex items-center justify-center py-12">
              <div className="w-8 h-8 border-[3px] border-primary border-t-transparent rounded-full animate-spin" />
            </div>
          ) : distributionData.length === 0 ? (
            <div className="flex-1 flex items-center justify-center py-12 text-muted-foreground text-sm">
              لا توجد بيانات توزيع للاعبين
            </div>
          ) : (
            <div className="w-full flex-1 flex flex-col items-center justify-center">
              <div className="relative w-48 h-48 mb-6 flex items-center justify-center">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={distributionData}
                      cx="50%"
                      cy="50%"
                      innerRadius={65}
                      outerRadius={90}
                      dataKey="value"
                      stroke="none"
                    >
                      {distributionData.map((_, i) => (
                        <Cell key={i} fill={COLORS[i % COLORS.length]} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute flex flex-col items-center justify-center text-center">
                  <span className="text-3xl font-extrabold text-foreground leading-none">
                    {totalDistribution.toLocaleString("ar-SA-u-nu-latn")}
                  </span>
                  <span className="text-xs text-muted-foreground mt-1">الإجمالي</span>
                </div>
              </div>

              <div className="w-full space-y-3.5">
                {distributionData.map((d, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-3.5 h-3.5 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                      <span className="text-sm font-semibold text-muted-foreground">{d.name}</span>
                    </div>
                    <span className="text-sm font-extrabold text-foreground">
                      {d.value} ({totalDistribution > 0 ? `${Math.round((d.value / totalDistribution) * 100)}%` : '0%'})
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </motion.div>
      </div>

      {/* Recent Payments Table */}
      <motion.div variants={itemVariants} className="glass-card rounded-3xl p-6">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
              <CreditCard className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-foreground">آخر عمليات السداد والاشتراكات</h3>
              <p className="text-xs text-muted-foreground">أحدث 5 اشتراكات تم تسجيلها في النظام.</p>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-right text-sm">
            <thead>
              <tr className="border-b border-border text-xs text-muted-foreground">
                <th className="pb-3 pt-1 px-4">رقم العضوية</th>
                <th className="pb-3 pt-1 px-4">اللاعب</th>
                <th className="pb-3 pt-1 px-4">الباقة</th>
                <th className="pb-3 pt-1 px-4">المبلغ</th>
                <th className="pb-3 pt-1 px-4">طريقة الدفع</th>
                <th className="pb-3 pt-1 px-4">تاريخ الاشتراك</th>
              </tr>
            </thead>
            <tbody>
              {subListLoading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-muted-foreground">جارٍ تحميل البيانات...</td>
                </tr>
              ) : recentPayments.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-muted-foreground">لا توجد اشتراكات مسجلة</td>
                </tr>
              ) : (
                recentPayments.map((sub: any) => (
                  <tr key={sub.id} className="border-b border-border/40 hover:bg-surface-container-low/30 transition-colors">
                    <td className="py-3.5 px-4 font-mono font-medium text-xs">{sub.membership_number}</td>
                    <td className="py-3.5 px-4 font-semibold">{sub.athlete_name}</td>
                    <td className="py-3.5 px-4 text-muted-foreground">{sub.package_name}</td>
                    <td className="py-3.5 px-4 font-extrabold text-primary">{sub.amount.toLocaleString("ar-SA-u-nu-latn")} د.ل</td>
                    <td className="py-3.5 px-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${sub.payment_method === 'cash' ? 'bg-secondary/15 text-secondary' : 'bg-primary/15 text-primary'}`}>
                        {sub.payment_method === 'cash' ? 'نقدي' : 'تحويل مصرفي'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-muted-foreground text-xs">{new Date(sub.start_date).toLocaleDateString("ar-LY")}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </motion.div>
    </motion.div>
  )
}
