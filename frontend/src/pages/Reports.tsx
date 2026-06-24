import React from "react"
import { motion, type Variants } from "framer-motion"
import {
  Users,
  DollarSign,
  Activity,
  FileSpreadsheet,
  FileText,
  Percent,
  Calendar,
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
import { Button } from "@/components/ui/button"

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

export default function ReportsPage() {
  const { data: stats, isLoading: statsLoading } = useDashboardStats()
  const { data: revenueData, isLoading: revenueLoading } = useRevenue()
  const { data: departments, isLoading: deptLoading } = useDepartmentDistribution()

  const monthlyRevenueData = (revenueData || []).map((d) => {
    const date = new Date(d.month)
    return { name: monthNames[date.getMonth()], revenue: d.revenue }
  })

  const distributionData = departments && departments.length > 0 
    ? departments.map((d) => ({
        name: d.department__name_ar,
        value: d.count
      }))
    : []

  const totalDistribution = distributionData.reduce((acc, curr) => acc + curr.value, 0)

  const totalRevenue = stats?.total_revenue ?? 0
  const activeMemberships = stats?.active_memberships ?? 0
  const renewalRate = stats?.renewal_rate ?? 0

  const kpiCards = [
    {
      label: "إجمالي الإيرادات",
      value: totalRevenue.toLocaleString("ar-SA-u-nu-latn"),
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
        <div className="flex gap-3">
          <Button variant="outline" size="lg" className="glass-card flex items-center gap-2 rounded-xl text-primary">
            <FileText className="w-4 h-4" />
            تصدير PDF
          </Button>
          <Button variant="outline" size="lg" className="glass-card flex items-center gap-2 rounded-xl text-secondary">
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
              <div className="text-3xl font-extrabold text-foreground">
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
              <span>آخر 6 أشهر</span>
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
                  <YAxis tickLine={false} axisLine={false} tickFormatter={(v) => `${v / 1000}k`} tick={{ fontSize: 12, fill: "var(--muted-fg)" }} />
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
            <h3 className="text-lg font-bold text-foreground">توزيع اللاعبين</h3>
          </div>
          {deptLoading ? (
            <div className="flex-1 flex items-center justify-center py-12">
              <div className="w-8 h-8 border-[3px] border-primary border-t-transparent rounded-full animate-spin" />
            </div>
          ) : distributionData.length === 0 ? (
            <div className="flex-1 flex items-center justify-center py-12 text-muted-foreground text-sm">
              لا توجد بيانات توزيع
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
                        <Cell key={i} fill={i === 0 ? "var(--primary)" : "var(--secondary)"} />
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
                      <div className="w-3.5 h-3.5 rounded-full" style={{ backgroundColor: i === 0 ? "var(--primary)" : "var(--secondary)" }} />
                      <span className="text-sm font-semibold text-muted-foreground">{d.name}</span>
                    </div>
                    <span className="text-sm font-extrabold text-foreground">
                      {totalDistribution > 0 ? `${Math.round((d.value / totalDistribution) * 100)}%` : '0%'}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </motion.div>
  )
}
