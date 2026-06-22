import React, { useEffect, useRef, useState } from "react"
import { motion } from "framer-motion"
import { Download, Plus, Users, ShieldAlert, CheckCircle, Clock, TrendingUp, Sparkles, Building2, Flame } from "lucide-react"
import { Link } from "react-router-dom"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts"
import { useDashboardStats, useMonthlyGrowth, useDepartmentDistribution } from "@/lib/hooks/useAnalytics"
import { useAuth } from "@/lib/auth"

function CountUp({ end, duration = 1500 }: { end: number; duration?: number }) {
  const [count, setCount] = useState(0)
  const ref = useRef<HTMLSpanElement>(null)
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true
          const start = performance.now()
          const animate = (now: number) => {
            const elapsed = now - start
            const progress = Math.min(elapsed / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            setCount(Math.floor(eased * end))
            if (progress < 1) requestAnimationFrame(animate)
          }
          requestAnimationFrame(animate)
        }
      },
      { threshold: 0.3 }
    )
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [end, duration])

  return <span ref={ref}>{count.toLocaleString("ar-SA")}</span>
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.15 },
  },
}

const cardVariants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] as const } },
}

export default function DashboardPage() {
  const { user } = useAuth()
  const { data: stats, isLoading: statsLoading } = useDashboardStats()
  const { data: growthData, isLoading: growthLoading } = useMonthlyGrowth()
  const { data: deptData, isLoading: deptLoading } = useDepartmentDistribution()

  const statCards = [
    {
      label: "إجمالي اللاعبين",
      value: stats?.total_athletes ?? 0,
      icon: Users,
      color: "text-primary",
      bg: "bg-primary/10",
      gradient: "from-primary/20 to-primary/5",
      badge: stats?.new_this_month ? `+${stats.new_this_month} هذا الشهر` : null,
      badgeIcon: TrendingUp,
      badgeColor: "text-secondary",
    },
    {
      label: "اشتراكات نشطة",
      value: stats?.active_memberships ?? 0,
      icon: CheckCircle,
      color: "text-secondary",
      bg: "bg-secondary/10",
      gradient: "from-secondary/20 to-secondary/5",
      badge: null,
      badgeIcon: null,
      badgeColor: "",
    },
    {
      label: "اشتراكات منتهية",
      value: stats?.expired_memberships ?? 0,
      icon: ShieldAlert,
      color: "text-error",
      bg: "bg-error/10",
      gradient: "from-error/20 to-error/5",
      badge: null,
      badgeIcon: null,
      badgeColor: "",
    },
    {
      label: "تنتهي قريباً (7 أيام)",
      value: stats?.expiring_soon ?? 0,
      icon: Clock,
      color: "text-amber-600",
      bg: "bg-amber-500/10",
      gradient: "from-amber-500/20 to-amber-500/5",
      badge: "تتطلب المتابعة",
      badgeIcon: Sparkles,
      badgeColor: "text-amber-600",
    },
  ]

  const chartData = (growthData || []).map((d) => {
    const date = new Date(d.month)
    const months = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"]
    return { name: months[date.getMonth()], value: d.count }
  })

  const branches = (deptData || []).map((d, i) => ({
    name: d.department__name_ar,
    revenue: `${d.count} لاعب`,
    percent: Math.min(Math.round((d.count / (stats?.total_athletes || 1)) * 100), 100),
    color: i === 0 ? "bg-gradient-to-r from-primary to-primary/70" : "bg-gradient-to-r from-secondary to-secondary/70",
    iconColor: i === 0 ? "text-primary" : "text-secondary",
  }))

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-8 select-none"
    >
      <motion.div variants={cardVariants} className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h2 className="text-3xl font-extrabold text-foreground flex items-center gap-2">
            مرحباً بك، {user?.full_name_ar || "المسؤول"}
            <Flame className="w-8 h-8 text-primary animate-pulse-soft" />
          </h2>
          <p className="text-muted-foreground mt-2 text-sm">
            إليك نظرة عامة على أداء الأكاديمية ونشاط المشتركين اليوم.
          </p>
        </div>
        <div className="flex gap-3">
          <motion.button whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}
            className="glass-card px-5 py-2.5 rounded-xl text-sm font-semibold text-primary hover:bg-white transition-all flex items-center gap-2"
          >
            <Download className="w-4 h-4" />
            تحميل التقرير
          </motion.button>
          <Link to="/dashboard/athletes/add">
            <motion.button whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}
              className="bg-gradient-to-r from-primary to-primary-container text-primary-foreground px-5 py-2.5 rounded-xl text-sm font-semibold shadow-lg shadow-primary/20 flex items-center gap-2"
            >
              <Plus className="w-4 h-4" />
              إضافة لاعب جديد
            </motion.button>
          </Link>
        </div>
      </motion.div>

      <motion.div variants={cardVariants} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {statCards.map((card, idx) => {
          const Icon = card.icon
          return (
            <motion.div
              key={idx}
              whileHover={{ y: -4, transition: { duration: 0.2 } }}
              className="relative overflow-hidden rounded-2xl bg-white dark:bg-card border border-border/30 shadow-sm hover:shadow-xl hover:shadow-primary/5 hover:border-primary/20 transition-all p-6 group"
            >
              <div className={`absolute inset-0 bg-gradient-to-br ${card.gradient} opacity-50`} />
              <div className="relative z-10">
                <div className="flex justify-between items-start mb-4">
                  <span className="text-sm font-medium text-muted-foreground">{card.label}</span>
                  <div className={`w-10 h-10 rounded-xl ${card.bg} flex items-center justify-center ${card.color} shadow-sm`}>
                    <Icon className="w-5 h-5" />
                  </div>
                </div>
                <div className="text-3xl font-extrabold text-foreground">
                  {statsLoading ? (
                    <span className="animate-pulse bg-muted rounded w-16 h-8 inline-block" />
                  ) : (
                    <CountUp end={card.value} />
                  )}
                </div>
                {card.badge && (
                  <div className={`flex items-center gap-1.5 mt-3 ${card.badgeColor} text-xs font-semibold`}>
                    {card.badgeIcon && <card.badgeIcon className="w-3.5 h-3.5" />}
                    <span>{card.badge}</span>
                  </div>
                )}
              </div>
              <div className="absolute -bottom-4 -right-4 w-16 h-16 rounded-full bg-gradient-to-br from-white/40 to-transparent blur-2xl group-hover:scale-150 transition-transform duration-500" />
            </motion.div>
          )
        })}
      </motion.div>

      <motion.div variants={cardVariants} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="relative overflow-hidden rounded-3xl bg-white dark:bg-card border border-border/30 shadow-sm p-6 lg:col-span-2 flex flex-col min-h-[400px] hover:shadow-lg transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-primary/[0.02] to-transparent" />
          <div className="relative">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-lg font-bold text-foreground">نمو الاشتراكات الشهري</h3>
              <div className="flex gap-2">
                <button className="px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-medium shadow-sm">شهر</button>
              </div>
            </div>
            <div className="w-full min-h-[280px]">
              {growthLoading ? (
                <div className="h-[280px] flex items-center justify-center">
                  <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full" />
                </div>
              ) : (
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                    <XAxis dataKey="name" stroke="var(--outline)" fontSize={12} tickLine={false} />
                    <YAxis stroke="var(--outline)" fontSize={12} tickLine={false} />
                    <Tooltip
                      contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", borderRadius: "8px", boxShadow: "0 8px 24px rgba(0,0,0,0.08)" }}
                      labelStyle={{ fontWeight: "bold" }}
                    />
                    <Bar dataKey="value" fill="var(--primary)" radius={[6, 6, 0, 0]} maxBarSize={48} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </div>
        </div>

        <div className="relative overflow-hidden rounded-3xl bg-white dark:bg-card border border-border/30 shadow-sm p-6 flex flex-col justify-between gap-6 hover:shadow-lg transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary/[0.02] to-transparent" />
          <div className="relative space-y-6">
            <h3 className="text-lg font-bold text-foreground">أداء الأقسام</h3>
            {deptLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin w-6 h-6 border-2 border-primary border-t-transparent rounded-full" />
              </div>
            ) : branches.length === 0 ? (
              <p className="text-muted-foreground text-sm text-center py-8">لا توجد بيانات</p>
            ) : (
              <div className="space-y-4">
                {branches.map((branch, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + index * 0.1 }}
                    className="p-4 rounded-2xl bg-gradient-to-br from-surface-container-low to-white dark:from-card dark:to-card border border-border/30 hover:border-primary/30 transition-all"
                  >
                    <div className="flex justify-between items-center mb-3">
                      <div className="flex items-center gap-3">
                        <div className={`w-8 h-8 rounded-lg ${branch.iconColor === "text-primary" ? "bg-primary/10" : "bg-secondary/10"} flex items-center justify-center ${branch.iconColor}`}>
                          <Building2 className="w-4 h-4" />
                        </div>
                        <span className="text-sm font-bold text-foreground">{branch.name}</span>
                      </div>
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-xs text-muted-foreground">
                        <span>عدد اللاعبين</span>
                        <span className="text-foreground font-semibold">{branch.revenue}</span>
                      </div>
                      <div className="w-full bg-muted rounded-full h-2.5 overflow-hidden">
                        <motion.div
                          initial={{ width: 0 }}
                          animate={{ width: `${branch.percent}%` }}
                          transition={{ duration: 1, delay: 0.5 + index * 0.1, ease: [0.22, 1, 0.36, 1] }}
                          className={`${branch.color} h-full rounded-full shadow-sm`}
                        />
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            )}
          </div>
          <Link to="/dashboard/reports">
            <motion.button whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
              className="w-full py-3 rounded-xl border border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container hover:text-primary transition-all"
            >
              عرض التقارير التفصيلية
            </motion.button>
          </Link>
        </div>
      </motion.div>
    </motion.div>
  )
}
