
import React from "react"
import { motion, type Variants } from "framer-motion"
import {
  BarChart3,
  TrendingDown,
  TrendingUp,
  Users,
  CreditCard,
  AlertTriangle,
  Download,
  FileText,
} from "lucide-react"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}
import {
  useDashboardStats,
  useMonthlyGrowth,
  useDepartmentDistribution,
} from "@/lib/hooks/useAnalytics"

export default function ReportsPage() {
  const { data: stats, isLoading: statsLoading } = useDashboardStats()
  const { data: monthlyGrowth, isLoading: growthLoading } = useMonthlyGrowth()
  const { data: departments, isLoading: deptLoading } = useDepartmentDistribution()

  return (
    <motion.div className="space-y-6" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <motion.div className="flex flex-col md:flex-row md:items-center justify-between gap-4" variants={itemVariants}>
        <div>
          <h2 className="text-3xl font-bold text-foreground">التقارير</h2>
          <p className="text-muted-foreground mt-1 text-sm">إحصائيات وتحليلات الأداء الرياضي.</p>
        </div>
        <div className="flex gap-3">
          <button className="flex items-center gap-2 bg-surface-container-low border border-border/40 px-4 py-2.5 rounded-xl text-sm font-semibold text-foreground hover:bg-surface-container transition-all">
            <Download className="w-4 h-4" />
            تصدير PDF
          </button>
          <button className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2.5 rounded-xl text-sm font-semibold shadow-md hover:bg-primary/95 transition-all">
            <FileText className="w-4 h-4" />
            إنشاء تقرير
          </button>
        </div>
      </motion.div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {[
          { label: "إجمالي اللاعبين", value: stats?.total_athletes ?? 0, icon: Users, color: "text-primary", bg: "bg-primary/10" },
          { label: "اشتراكات نشطة", value: stats?.active_memberships ?? 0, icon: CreditCard, color: "text-secondary", bg: "bg-secondary/10" },
          { label: "اشتراكات منتهية", value: stats?.expired_memberships ?? 0, icon: AlertTriangle, color: "text-error", bg: "bg-error/10" },
          { label: "تنتهي قريباً", value: stats?.expiring_soon ?? 0, icon: TrendingDown, color: "text-warning", bg: "bg-warning/10" },
        ].map((card, i) => {
          const Icon = card.icon
          return (
            <motion.div key={i} className="glass-card rounded-2xl p-5 border border-border/20 shadow-sm" variants={itemVariants}>
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-semibold text-muted-foreground">{card.label}</span>
                <div className={`w-9 h-9 rounded-lg ${card.bg} flex items-center justify-center`}>
                  <Icon className={`w-4 h-4 ${card.color}`} />
                </div>
              </div>
              <p className={`text-2xl font-extrabold ${card.color}`}>
                {statsLoading ? <span className="animate-pulse bg-muted rounded w-12 inline-block">&nbsp;</span> : card.value}
              </p>
            </motion.div>
          )
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <motion.div className="glass-card rounded-3xl p-6 border border-border/20 shadow-sm" variants={itemVariants}>
          <h3 className="text-lg font-bold text-foreground mb-5 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-primary" />
            النمو الشهري
          </h3>
          {growthLoading ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin w-6 h-6 border-4 border-primary border-t-transparent rounded-full" />
            </div>
          ) : monthlyGrowth && monthlyGrowth.length > 0 ? (
            <div className="space-y-4">
              {monthlyGrowth.map((item, i) => {
                const maxCount = Math.max(...monthlyGrowth.map((m) => m.count), 1)
                const pct = (item.count / maxCount) * 100
                return (
                  <div key={i} className="flex items-center gap-4">
                    <span className="text-xs text-muted-foreground w-16 shrink-0">{item.month}</span>
                    <div className="flex-1 bg-surface-container-low rounded-full h-3 overflow-hidden">
                      <div
                        className="bg-primary h-full rounded-full transition-all duration-500"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                    <span className="text-sm font-bold text-foreground w-8 text-left">{item.count}</span>
                  </div>
                )
              })}
            </div>
          ) : (
            <p className="text-muted-foreground text-sm text-center py-8">لا توجد بيانات كافية</p>
          )}
        </motion.div>

        <motion.div className="glass-card rounded-3xl p-6 border border-border/20 shadow-sm" variants={itemVariants}>
          <h3 className="text-lg font-bold text-foreground mb-5 flex items-center gap-2">
            <Users className="w-5 h-5 text-secondary" />
            توزيع الأقسام
          </h3>
          {deptLoading ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin w-6 h-6 border-4 border-primary border-t-transparent rounded-full" />
            </div>
          ) : departments && departments.length > 0 ? (
            <div className="space-y-4">
              {departments.map((item, i) => {
                const maxCount = Math.max(...departments.map((d) => d.count), 1)
                const pct = (item.count / maxCount) * 100
                const colors = ["bg-primary", "bg-secondary", "bg-accent", "bg-warning", "bg-error"]
                return (
                  <div key={i} className="flex items-center gap-4">
                    <span className="text-sm font-semibold text-foreground w-24 shrink-0 truncate">{item.department__name_ar}</span>
                    <div className="flex-1 bg-surface-container-low rounded-full h-3 overflow-hidden">
                      <div
                        className={`${colors[i % colors.length]} h-full rounded-full transition-all duration-500`}
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                    <span className="text-sm font-bold text-foreground w-8 text-left">{item.count}</span>
                  </div>
                )
              })}
            </div>
          ) : (
            <p className="text-muted-foreground text-sm text-center py-8">لا توجد بيانات كافية</p>
          )}
        </motion.div>
      </div>
    </motion.div>
  )
}
