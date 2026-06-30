import { useState, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { useAuth } from "@/lib/auth"
import { useRenewSubscription } from "@/lib/hooks/useSubscriptions"
import { useQueryClient } from "@tanstack/react-query"
import type { Subscription, ParentAthlete } from "@/lib/types"
import { CreditCard, Plus, RefreshCw, Clock, User, Users, ChevronLeft } from "lucide-react"

const statusMap: Record<string, { label: string; cls: string }> = {
  active: { label: "نشط", cls: "bg-green-100 text-green-700 border border-green-200" },
  expired: { label: "منتهي", cls: "bg-red-100 text-red-700 border border-red-200" },
  pending: { label: "قيد الانتظار", cls: "bg-amber-100 text-amber-700 border border-amber-200" },
  rejected: { label: "مرفوض", cls: "bg-red-100 text-red-700 border border-red-200" },
}

const formatDate = (d: string) =>
  new Date(d).toLocaleDateString("ar-SA-u-nu-latn", { year: "numeric", month: "numeric", day: "numeric" })

function daysRemaining(endDate: string): number {
  const now = new Date()
  const end = new Date(endDate)
  const diff = end.getTime() - now.getTime()
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)))
}

export default function UserSubscriptions() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const isParent = user?.role === "parent"
  const renewMut = useRenewSubscription()

  const [subscriptions, setSubscriptions] = useState<Subscription[]>([])
  const [parentAthletes, setParentAthletes] = useState<ParentAthlete[]>([])
  const [athleteSubsMap, setAthleteSubsMap] = useState<Record<number, Subscription[]>>({})
  const [loading, setLoading] = useState(true)
  const [renewingId, setRenewingId] = useState<number | null>(null)
  const [renewError, setRenewError] = useState<string | null>(null)

  const athleteProfile = user?.athlete_detail

  useEffect(() => {
    if (isParent) {
      fetchParentData()
    } else if (athleteProfile) {
      fetchMySubscriptions()
    } else {
      setLoading(false)
    }
  }, [isParent, athleteProfile?.id])

  const fetchMySubscriptions = async () => {
    setLoading(true)
    try {
      const res = await api.get<{ results: Subscription[] } | Subscription[]>("/subscriptions/", { page_size: "50" })
      setSubscriptions(extractResults(res))
    } catch {
      setRenewError("تعذر تحميل الاشتراكات")
    } finally {
      setLoading(false)
    }
  }

  const fetchParentData = async () => {
    setLoading(true)
    try {
      const athletesRes = await api.get<{ results: ParentAthlete[] } | ParentAthlete[]>("/athletes/parent/athletes/")
      const athletes = extractResults(athletesRes)
      setParentAthletes(athletes)

      const map: Record<number, Subscription[]> = {}
      for (const a of athletes) {
        try {
          const subRes = await api.get<{ results: Subscription[] } | Subscription[]>("/subscriptions/", {
            athlete: String(a.athlete),
            page_size: "20",
          })
          map[a.athlete] = extractResults(subRes)
        } catch {
          map[a.athlete] = []
        }
      }
      setAthleteSubsMap(map)
    } catch {
      setRenewError("تعذر تحميل بيانات الرياضيين")
    } finally {
      setLoading(false)
    }
  }

  const handleRenew = async (sub: Subscription) => {
    setRenewingId(sub.id)
    setRenewError(null)
    try {
      const months = 1
      await renewMut.mutateAsync({ id: sub.id, months, amount: sub.amount })
      await queryClient.invalidateQueries({ queryKey: ["subscriptions"] })
      if (isParent) {
        await fetchParentData()
      } else {
        await fetchMySubscriptions()
      }
    } catch (err: any) {
      setRenewError(err?.message || "فشل التجديد")
    } finally {
      setRenewingId(null)
    }
  }

  const SubCard = ({ sub }: { sub: Subscription }) => {
    const remaining = daysRemaining(sub.end_date)
    const status = statusMap[sub.status] || { label: sub.status, cls: "" }
    return (
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-card border border-border rounded-2xl p-4 space-y-3"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="font-bold">{sub.package_name}</p>
            {sub.department_name && (
              <p className="text-xs text-muted-foreground">{sub.department_name}</p>
            )}
          </div>
          <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${status.cls}`}>
            {status.label}
          </span>
        </div>

        <div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground">
          <div>
            <span className="block font-semibold text-foreground">من {formatDate(sub.start_date)}</span>
          </div>
          <div>
            <span className="block font-semibold text-foreground">إلى {formatDate(sub.end_date)}</span>
          </div>
        </div>

        {sub.status === "active" && (
          <div className="flex items-center gap-1.5 text-xs">
            <Clock className="w-3.5 h-3.5 text-muted-foreground" />
            <span className={remaining <= 7 ? "text-red-600 font-semibold" : "text-muted-foreground"}>
              متبقي {remaining} يوم
            </span>
          </div>
        )}

        <div className="flex items-center justify-between pt-1">
          <span className="text-sm font-bold">{Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</span>
          {(sub.status === "active" || sub.status === "expired") && (
            <Button
              size="sm"
              variant="outline"
              disabled={renewingId === sub.id}
              onClick={() => void handleRenew(sub)}
              className="text-xs gap-1"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${renewingId === sub.id ? "animate-spin" : ""}`} />
              {renewingId === sub.id ? "جاري..." : "تجديد"}
            </Button>
          )}
        </div>
      </motion.div>
    )
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="space-y-5">
      {renewError && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {renewError}
        </div>
      )}

      {isParent ? (
        <>
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">اشتراكات الرياضيين</h2>
            <Button size="sm" onClick={() => navigate("/user/subscribe")}>
              <Plus className="w-4 h-4 ml-1" /> اشتراك جديد
            </Button>
          </div>

          {parentAthletes.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <Users className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>لم تقم بإضافة أي رياضي بعد</p>
              <Button size="sm" className="mt-3" onClick={() => navigate("/user/athlete")}>
                إضافة رياضي
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              {parentAthletes.map((pa) => {
                const subs = athleteSubsMap[pa.athlete] || []
                const activeSub = subs.find((s) => s.status === "active")
                return (
                  <div key={pa.id} className="bg-card border border-border rounded-2xl p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                          <User className="w-5 h-5 text-primary" />
                        </div>
                        <div>
                          <p className="font-semibold">{pa.athlete_name}</p>
                          <p className="text-xs text-muted-foreground">{pa.athlete_membership}</p>
                        </div>
                      </div>
                      {activeSub ? (
                        <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-green-100 text-green-700 border border-green-200">
                          {statusMap[activeSub.status]?.label}
                        </span>
                      ) : (
                        <span className="text-xs text-muted-foreground">لا يوجد اشتراك</span>
                      )}
                    </div>

                    {subs.length > 0 ? (
                      <div className="space-y-2">
                        {subs.map((sub) => (
                          <div key={sub.id} className="bg-surface-container-low rounded-xl p-3 flex items-center justify-between">
                            <div>
                              <p className="text-sm font-medium">{sub.package_name}</p>
                              <p className="text-xs text-muted-foreground">
                                {formatDate(sub.start_date)} - {formatDate(sub.end_date)}
                              </p>
                            </div>
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-bold">{Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</span>
                              {(sub.status === "active" || sub.status === "expired") && (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  disabled={renewingId === sub.id}
                                  onClick={() => void handleRenew(sub)}
                                  className="text-xs"
                                >
                                  <RefreshCw className={`w-3 h-3 ml-1 ${renewingId === sub.id ? "animate-spin" : ""}`} />
                                  تجديد
                                </Button>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <Button size="sm" variant="outline" className="w-full text-xs" onClick={() => navigate("/user/subscribe")}>
                        <Plus className="w-3.5 h-3.5 ml-1" /> تسجيل اشتراك
                      </Button>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </>
      ) : !athleteProfile ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-amber-100 flex items-center justify-center mx-auto mb-4">
            <Clock className="w-8 h-8 text-amber-600" />
          </div>
          <h2 className="text-lg font-bold mb-2">بانتظار الموافقة</h2>
          <p className="text-sm text-muted-foreground">
            حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك فور الموافقة.
          </p>
        </div>
      ) : subscriptions.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
            <CreditCard className="w-8 h-8 text-primary" />
          </div>
          <h2 className="text-lg font-bold mb-2">لا يوجد اشتراك</h2>
          <p className="text-sm text-muted-foreground mb-4">
            لم تقم بالتسجيل في أي باقة بعد. اختر باقتك المفضلة وابدأ التدريب!
          </p>
          <Button onClick={() => navigate("/user/subscribe")}>
            <Plus className="w-4 h-4 ml-1" /> سجل اشتراك جديد
          </Button>
        </div>
      ) : (
        <>
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold">اشتراكاتي</h2>
            <Button size="sm" onClick={() => navigate("/user/subscribe")}>
              <Plus className="w-4 h-4 ml-1" /> اشتراك جديد
            </Button>
          </div>

          <div className="space-y-3">
            {subscriptions.map((sub) => (
              <SubCard key={sub.id} sub={sub} />
            ))}
          </div>
        </>
      )}
    </div>
  )
}
