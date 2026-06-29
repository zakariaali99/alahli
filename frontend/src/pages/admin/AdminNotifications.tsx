import { useEffect, useMemo, useState } from "react"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import type { PaginatedResponse, Subscription } from "@/lib/types"
import { AlertCircle, AlertTriangle, CalendarClock } from "lucide-react"

function formatDate(value: string) {
  return new Date(value).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
}

export default function AdminNotifications() {
  const [activeSubscriptions, setActiveSubscriptions] = useState<Subscription[]>([])
  const [expiredSubscriptions, setExpiredSubscriptions] = useState<Subscription[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    void fetchAlerts()
  }, [])

  const fetchAllSubscriptionsByStatus = async (status: "active" | "expired") => {
    let page = 1
    let allResults: Subscription[] = []

    while (true) {
      const response = await api.get<PaginatedResponse<Subscription>>("/subscriptions/", {
        status,
        page: String(page),
      })
      allResults = [...allResults, ...response.results]

      if (!response.next) {
        break
      }

      page += 1
    }

    return allResults
  }

  const fetchAlerts = async () => {
    setLoading(true)
    try {
      const [active, expired] = await Promise.all([
        fetchAllSubscriptionsByStatus("active"),
        fetchAllSubscriptionsByStatus("expired"),
      ])
      setActiveSubscriptions(active)
      setExpiredSubscriptions(expired)
    } catch {
      setActiveSubscriptions([])
      setExpiredSubscriptions([])
    } finally {
      setLoading(false)
    }
  }

  const expiringSoon = useMemo(() => {
    const now = new Date()
    const inSevenDays = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
    return activeSubscriptions.filter((sub) => {
      const end = new Date(sub.end_date)
      return end >= now && end <= inSevenDays
    })
  }, [activeSubscriptions])

  if (loading) return <LoadingSpinner />

  const totalAlerts = expiredSubscriptions.length + expiringSoon.length

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-border bg-card p-4">
        <h2 className="text-xl font-bold">تنبيهات الاشتراكات</h2>
        <p className="mt-1 text-xs text-muted-foreground">تنبيهات عالية الأهمية للاشتراكات المنتهية والقريبة من الانتهاء.</p>
        <p className="mt-2 inline-flex items-center gap-1 rounded-full border border-primary/20 bg-primary/8 px-3 py-1 text-xs font-bold text-primary">
          <CalendarClock className="h-3.5 w-3.5" /> إجمالي التنبيهات: {totalAlerts.toLocaleString("ar-SA-u-nu-latn")}
        </p>
      </div>

      {expiredSubscriptions.length > 0 && (
        <section className="rounded-2xl border border-[#A63F3F]/25 bg-[#A63F3F]/7 p-4">
          <div className="mb-3 flex items-center gap-2 text-[#A63F3F]">
            <AlertCircle className="h-5 w-5" />
            <h3 className="font-bold">اشتراكات منتهية ({expiredSubscriptions.length.toLocaleString("ar-SA-u-nu-latn")})</h3>
          </div>
          <div className="grid gap-2">
            {expiredSubscriptions.map((sub) => (
              <article className="rounded-xl border border-[#A63F3F]/20 bg-white/70 p-3" key={sub.id}>
                <p className="text-sm font-semibold">{sub.athlete_name}</p>
                <p className="text-xs text-[#5a6672]">{sub.package_name} • انتهى في {formatDate(sub.end_date)}</p>
              </article>
            ))}
          </div>
        </section>
      )}

      {expiringSoon.length > 0 && (
        <section className="rounded-2xl border border-[#B36B00]/25 bg-[#B36B00]/7 p-4">
          <div className="mb-3 flex items-center gap-2 text-[#B36B00]">
            <AlertTriangle className="h-5 w-5" />
            <h3 className="font-bold">اشتراكات تنتهي قريباً ({expiringSoon.length.toLocaleString("ar-SA-u-nu-latn")})</h3>
          </div>
          <div className="grid gap-2">
            {expiringSoon.map((sub) => (
              <article className="rounded-xl border border-[#B36B00]/20 bg-white/70 p-3" key={sub.id}>
                <p className="text-sm font-semibold">{sub.athlete_name}</p>
                <p className="text-xs text-[#5a6672]">{sub.package_name} • ينتهي في {formatDate(sub.end_date)}</p>
              </article>
            ))}
          </div>
        </section>
      )}

      {totalAlerts === 0 && (
        <div className="rounded-2xl border border-border bg-card p-10 text-center text-muted-foreground">
          لا توجد تنبيهات حالياً
        </div>
      )}
    </div>
  )
}
