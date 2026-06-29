import React, { useState, useMemo } from "react"
import { motion, type Variants } from "framer-motion"
import {
  Bell,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Trash2,
  Calendar,
  BellRing,
  Volume2,
  Mail,
  CreditCard,
  Settings,
  HelpCircle,
  Megaphone,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  useNotifications,
  useMarkNotificationRead,
  useMarkAllNotificationsRead,
  useDeleteNotification,
} from "@/lib/hooks/useNotifications"
import { useAnnouncements } from "@/lib/hooks/useAnnouncements"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.06, delayChildren: 0.1 },
  },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 24, scale: 0.97 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: 0.45, ease: [0.22, 1, 0.36, 1] },
  },
}

interface Notification {
  id: number
  athlete: number | null
  title: string
  body: string
  is_read: boolean
  created_at: string
}

export default function NotificationsPage() {
  const [filter, setFilter] = useState<"all" | "unread" | "memberships" | "system">("all")
  const { data, isLoading } = useNotifications({
    is_read: filter === "unread" ? "false" : undefined,
  })
  const { data: announcementsData } = useAnnouncements()
  const announcements = announcementsData?.results ?? []
  const markRead = useMarkNotificationRead()
  const markAllRead = useMarkAllNotificationsRead()
  const deleteNotif = useDeleteNotification()

  const [toggles, setToggles] = useState({
    paymentAlerts: true,
    systemAlerts: true,
    emailAlerts: false,
  })

  const notifications: Notification[] = data?.results || []

  const filteredNotifications = useMemo(() => {
    return notifications.filter((n) => {
      if (filter === "unread") return !n.is_read
      if (filter === "memberships") {
        return n.title.includes("اشتراك") || n.title.includes("تجديد") || n.title.includes("دفع")
      }
      if (filter === "system") {
        return n.title.includes("صيانة") || n.title.includes("إعلان") || n.title.includes("نظام")
      }
      return true
    })
  }, [data, filter])

  const formatRelativeTime = (d: string): string => {
    const date = new Date(d)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    if (diff < 60_000) return "الآن"
    if (diff < 3_600_000) return `منذ ${Math.floor(diff / 60_000)} دقيقة`
    if (diff < 86_400_000) return `منذ ${Math.floor(diff / 3_600_000)} ساعة`
    return date.toLocaleDateString("ar-SA-u-nu-latn", { month: "short", day: "numeric" })
  }

  const typeIcon = (title: string) => {
    if (title.includes("انتهاء") || title.includes("منتهي")) return AlertCircle
    if (title.includes("تجديد") || title.includes("تذكير")) return RefreshCw
    if (title.includes("نجاح") || title.includes("تم") || title.includes("تسجيل")) return CheckCircle2
    return Bell
  }

  const typeIconColor = (title: string): string => {
    if (title.includes("انتهاء") || title.includes("منتهي")) return "bg-rose-500/10 text-rose-600"
    if (title.includes("تجديد") || title.includes("تذكير")) return "bg-sky-500/10 text-sky-600"
    if (title.includes("نجاح") || title.includes("تم") || title.includes("تسجيل")) return "bg-emerald-500/10 text-emerald-600"
    return "bg-[#00288e]/10 text-[#00288e]"
  }

  return (
    <motion.div
      className="space-y-8"
      dir="rtl"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Page Header */}
      <motion.div
        variants={itemVariants}
        className="flex flex-col sm:flex-row sm:items-center justify-between gap-4"
      >
        <div>
          <h1 className="text-3xl font-extrabold text-[#0b1c30] tracking-tight">مركز التنبيهات</h1>
          <p className="text-muted-foreground mt-1 text-sm">
            ابق على اطلاع بآخر المستجدات والإشعارات الهامة
          </p>
        </div>
        <Button
          onClick={() => markAllRead.mutate()}
          disabled={markAllRead.isPending || notifications.length === 0}
          size="lg"
          className="bg-[#00288e] text-white hover:bg-[#00288e]/90 shadow-md flex items-center gap-2 rounded-xl"
        >
          <CheckCircle2 className="w-5 h-5" />
          تحديد الكل كمقروء
        </Button>
      </motion.div>

      {/* Bento Grid Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Main Notifications List (Span 8) */}
        <div className="lg:col-span-8 space-y-5">
          {/* Filters/Tabs */}
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 md:mx-0 md:px-0">
            {[
              { key: "all" as const, label: `الكل (${notifications.length})` },
              { key: "unread" as const, label: `غير مقروءة (${notifications.filter((n) => !n.is_read).length})` },
              { key: "memberships" as const, label: "الاشتراكات" },
              { key: "system" as const, label: "النظام" },
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => setFilter(tab.key)}
                className={`whitespace-nowrap px-5 py-2.5 rounded-full text-xs font-bold transition-all ${
                  filter === tab.key
                    ? "bg-[#00288e] text-white shadow-md shadow-[#00288e]/20"
                    : "bg-white/70 border border-white/50 backdrop-blur-md text-muted-foreground hover:text-[#0b1c30] hover:bg-white"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* List Container */}
          <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl overflow-hidden shadow-sm divide-y divide-gray-100">
            {isLoading ? (
              <div className="p-12 text-center text-muted-foreground">
                <div className="w-8 h-8 border-[3px] border-[#00288e] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
                <span className="text-sm">جاري التحميل...</span>
              </div>
            ) : filteredNotifications.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-20 text-center">
                <div className="w-20 h-20 rounded-full bg-gray-50 flex items-center justify-center mb-4">
                  <BellRing className="w-10 h-10 text-muted-foreground/30" />
                </div>
                <h4 className="text-base font-bold text-[#0b1c30]">لا توجد تنبيهات</h4>
                <p className="text-xs text-muted-foreground mt-1">ليس لديك إشعارات في هذا القسم حالياً</p>
              </div>
            ) : (
              filteredNotifications.map((notif) => {
                const Icon = typeIcon(notif.title)
                const iconColorCls = typeIconColor(notif.title)
                return (
                  <div
                    key={notif.id}
                    className={`p-5 flex gap-4 hover:bg-white/40 transition-colors relative ${
                      !notif.is_read ? "bg-[#00288e]/[0.02]" : ""
                    }`}
                  >
                    {!notif.is_read && (
                      <div className="absolute right-0 top-0 bottom-0 w-1 bg-[#00288e]" />
                    )}

                    <div className="shrink-0">
                      <div className={`w-12 h-12 rounded-full flex items-center justify-center ${iconColorCls}`}>
                        <Icon className="w-5 h-5 fill-none" />
                      </div>
                    </div>

                    <div className="flex-1 space-y-2">
                      <div className="flex justify-between items-start gap-4">
                        <h3 className={`text-base leading-snug text-[#0b1c30] ${!notif.is_read ? "font-extrabold" : "font-semibold"}`}>
                          {notif.title}
                        </h3>
                        <span className="text-xs text-muted-foreground/80 font-medium whitespace-nowrap">
                          {formatRelativeTime(notif.created_at)}
                        </span>
                      </div>
                      <p className="text-xs text-[#444653] leading-relaxed">
                        {notif.body}
                      </p>

                      {/* Dynamic Action Buttons based on content */}
                      <div className="flex gap-2 pt-2">
                        {notif.title.includes("اشتراك") && (
                          <button className="px-3.5 py-1.5 bg-[#00288e] text-white text-xs font-bold rounded-lg hover:bg-[#00288e]/95 transition-colors">
                            تجديد الآن
                          </button>
                        )}
                        {!notif.is_read && (
                          <button
                            onClick={() => markRead.mutate(notif.id)}
                            disabled={markRead.isPending}
                            className="px-3.5 py-1.5 bg-gray-50 border border-gray-100 text-[#0b1c30] text-xs font-bold rounded-lg hover:bg-gray-100 transition-colors"
                          >
                            تحديد كمقروء
                          </button>
                        )}
                        <button
                          onClick={() => deleteNotif.mutate(notif.id)}
                          disabled={deleteNotif.isPending}
                          className="px-3.5 py-1.5 text-red-600 hover:bg-red-50 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          حذف
                        </button>
                      </div>
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </div>

        {/* Side Panel (Span 4) */}
        <div className="lg:col-span-4 space-y-6">
          {/* Admin Announcements Card */}
          <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 shadow-sm relative overflow-hidden border-t-4 border-t-[#00288e]">
            <div className="flex items-center gap-3 mb-5">
              <div className="p-2.5 bg-[#00288e]/10 text-[#00288e] rounded-xl">
                <Megaphone className="w-5 h-5" />
              </div>
              <h3 className="font-extrabold text-[#0b1c30]">إعلانات الإدارة</h3>
            </div>
            <div className="space-y-4">
              {(announcements || []).length === 0 ? (
                <p className="text-xs text-muted-foreground text-center py-4">لا توجد إعلانات حالياً</p>
              ) : (
                (announcements || []).slice(0, 5).map((ann) => (
                  <div key={ann.id} className="bg-white/50 p-4 rounded-xl border border-gray-100 hover:border-[#00288e]/20 transition-all cursor-pointer">
                    <div className="flex justify-between items-center mb-2">
                      <span className="text-[10px] font-bold text-[#006d30] bg-[#006d30]/10 px-2.5 py-0.5 rounded-full">إعلان</span>
                      <span className="text-[10px] text-muted-foreground">
                        {new Date(ann.created_at).toLocaleDateString("ar-SA-u-nu-latn", { month: "short", day: "numeric" })}
                      </span>
                    </div>
                    <h4 className="font-bold text-sm text-[#0b1c30] mb-1">{ann.title}</h4>
                    <p className="text-xs text-[#444653] leading-relaxed line-clamp-2">{ann.body}</p>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Quick Settings Card */}
          <div className="bg-white/70 border border-white/50 backdrop-blur-md rounded-2xl p-6 shadow-sm">
            <h3 className="font-extrabold text-[#0b1c30] mb-5 flex items-center gap-2">
              <Settings className="w-5 h-5 text-muted-foreground" />
              إعدادات سريعة
            </h3>
            <div className="space-y-4">
              <label className="flex items-center justify-between cursor-pointer group">
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-[#0b1c30]">تنبيهات الدفع</span>
                  <span className="text-[10px] text-muted-foreground mt-0.5">استلام إشعار عند كل عملية دفع</span>
                </div>
                <div className="relative inline-flex items-center">
                  <input
                    type="checkbox"
                    checked={toggles.paymentAlerts}
                    onChange={(e) => setToggles({ ...toggles, paymentAlerts: e.target.checked })}
                    className="sr-only peer"
                  />
                  <div className="w-10 h-5.5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4.5 after:w-4.5 after:transition-all peer-checked:bg-[#00288e]" />
                </div>
              </label>

              <label className="flex items-center justify-between cursor-pointer group">
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-[#0b1c30]">تنبيهات النظام</span>
                  <span className="text-[10px] text-muted-foreground mt-0.5">إعلانات الإدارة والتحديثات</span>
                </div>
                <div className="relative inline-flex items-center">
                  <input
                    type="checkbox"
                    checked={toggles.systemAlerts}
                    onChange={(e) => setToggles({ ...toggles, systemAlerts: e.target.checked })}
                    className="sr-only peer"
                  />
                  <div className="w-10 h-5.5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4.5 after:w-4.5 after:transition-all peer-checked:bg-[#00288e]" />
                </div>
              </label>

              <label className="flex items-center justify-between cursor-pointer group">
                <div className="flex flex-col">
                  <span className="text-xs font-bold text-[#0b1c30]">البريد الإلكتروني</span>
                  <span className="text-[10px] text-muted-foreground mt-0.5">تلقي ملخص يومي</span>
                </div>
                <div className="relative inline-flex items-center">
                  <input
                    type="checkbox"
                    checked={toggles.emailAlerts}
                    onChange={(e) => setToggles({ ...toggles, emailAlerts: e.target.checked })}
                    className="sr-only peer"
                  />
                  <div className="w-10 h-5.5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4.5 after:w-4.5 after:transition-all peer-checked:bg-[#00288e]" />
                </div>
              </label>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}
