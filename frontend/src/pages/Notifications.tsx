
import React, { useState } from "react"
import { motion, type Variants } from "framer-motion"
import {
  Bell,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Trash2,
} from "lucide-react"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.05, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}
import { useNotifications, useMarkNotificationRead, useMarkAllNotificationsRead, useDeleteNotification } from "@/lib/hooks/useNotifications"

export default function NotificationsPage() {
  const [filter, setFilter] = useState<"all" | "unread">("all")
  const { data, isLoading } = useNotifications({ is_read: filter === "unread" ? "false" : undefined })
  const markRead = useMarkNotificationRead()
  const markAllRead = useMarkAllNotificationsRead()
  const deleteNotif = useDeleteNotification()

  const notifications = data?.results || []

  const formatTime = (d: string) => {
    const date = new Date(d)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    if (diff < 60_000) return "الآن"
    if (diff < 3_600_000) return `منذ ${Math.floor(diff / 60_000)} دقيقة`
    if (diff < 86_400_000) return `منذ ${Math.floor(diff / 3_600_000)} ساعة`
    return date.toLocaleDateString("ar-SA", { month: "short", day: "numeric" })
  }

  const typeIcon = (title: string) => {
    if (title.includes("انتهاء") || title.includes("منتهي")) return AlertCircle
    return Bell
  }

  return (
    <motion.div className="space-y-6" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold text-foreground">التنبيهات</h2>
          <p className="text-muted-foreground mt-1 text-sm">إشعارات النظام والتذكيرات بالاشتراكات.</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => markAllRead.mutate()}
            disabled={markAllRead.isPending}
            className="flex items-center gap-2 bg-surface-container-low border border-border/40 px-4 py-2 rounded-xl text-sm font-semibold text-foreground hover:bg-surface-container transition-all"
          >
            <CheckCircle2 className="w-4 h-4" />
            تحديد الكل كمقروء
          </button>
        </div>
      </div>

      <div className="flex gap-2 border-b border-border/20 pb-4">
        {[
          { key: "all", label: "الكل" },
          { key: "unread", label: "غير مقروء" },
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key as typeof filter)}
            className={`px-5 py-2 rounded-full text-sm font-semibold transition-all ${
              filter === tab.key
                ? "bg-primary text-primary-foreground shadow-sm"
                : "text-muted-foreground hover:bg-surface-container"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-16">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : notifications.length === 0 ? (
          <div className="text-center py-16 text-muted-foreground">
            <Bell className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>لا توجد إشعارات</p>
          </div>
        ) : (
          notifications.map((notif) => {
            const Icon = typeIcon(notif.title)
            return (
              <motion.div
                key={notif.id}
                variants={itemVariants}
                className={`glass-card rounded-2xl p-5 flex items-start gap-4 transition-all hover:shadow-md ${
                  !notif.is_read ? "border-r-4 border-r-primary" : ""
                }`}
              >
                <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                  !notif.is_read ? "bg-primary-container/20 text-primary" : "bg-surface-container text-muted-foreground"
                }`}>
                  <Icon className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-start gap-4">
                    <div>
                      <h4 className={`text-sm ${!notif.is_read ? "font-bold text-foreground" : "font-semibold text-foreground"}`}>
                        {notif.title}
                      </h4>
                      <p className="text-xs text-muted-foreground mt-1 line-clamp-2">{notif.body}</p>
                    </div>
                    <span className="text-xxs text-muted-foreground shrink-0 whitespace-nowrap">
                      {formatTime(notif.created_at)}
                    </span>
                  </div>
                  <div className="flex gap-2 mt-3">
                    {!notif.is_read && (
                      <button
                        onClick={() => markRead.mutate(notif.id)}
                        className="text-xs font-semibold text-primary hover:bg-primary/10 px-3 py-1 rounded-lg transition-colors"
                      >
                        تحديد كمقروء
                      </button>
                    )}
                    <button
                      onClick={() => deleteNotif.mutate(notif.id)}
                      className="text-xs font-semibold text-error hover:bg-error/10 px-3 py-1 rounded-lg transition-colors"
                    >
                      <Trash2 className="w-3 h-3 inline ml-1" />
                      حذف
                    </button>
                  </div>
                </div>
              </motion.div>
            )
          })
        )}
      </div>
    </motion.div>
  )
}
