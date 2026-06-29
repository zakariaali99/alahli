import { useEffect, useMemo, useState } from "react"
import { motion } from "framer-motion"
import { useNavigate } from "react-router-dom"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import type { RegistrationRequest, Subscription } from "@/lib/types"
import { Building2, Check, Eye, FileText, UserRound, X } from "lucide-react"
import { toAbsoluteMediaUrl } from "@/lib/media"

function formatDate(value?: string | null) {
  if (!value) return "-"
  return new Date(value).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  })
}

export default function NewAthletes() {
  const navigate = useNavigate()
  const [registrations, setRegistrations] = useState<RegistrationRequest[]>([])
  const [pendingSubscriptions, setPendingSubscriptions] = useState<Subscription[]>([])
  const [loading, setLoading] = useState(true)
  const [actionLoadingId, setActionLoadingId] = useState<number | null>(null)
  const [confirmAction, setConfirmAction] = useState<{
    id: number
    userName: string
    type: "approve" | "reject"
  } | null>(null)
  const [rejectNote, setRejectNote] = useState("")
  const [actionError, setActionError] = useState<string | null>(null)

  useEffect(() => {
    void fetchAll()
  }, [])

  const fetchAll = async () => {
    setLoading(true)
    try {
      setActionError(null)
      const [regs, subs] = await Promise.all([
        api.get<{ results: RegistrationRequest[] } | RegistrationRequest[]>("/athletes/registrations/?status=pending"),
        api.get<{ results: Subscription[] } | Subscription[]>("/subscriptions/?status=pending"),
      ])
      setRegistrations(extractResults(regs))
      setPendingSubscriptions(extractResults(subs))
    } finally {
      setLoading(false)
    }
  }

  const subscriptionByAthleteId = useMemo(() => {
    return pendingSubscriptions.reduce<Record<number, Subscription>>((acc, sub) => {
      if (!acc[sub.athlete]) {
        acc[sub.athlete] = sub
      }
      return acc
    }, {})
  }, [pendingSubscriptions])

  const approve = async (id: number) => {
    try {
      setActionLoadingId(id)
      await api.post(`/athletes/registrations/${id}/approve/`)
      await fetchAll()
    } catch (err: any) {
      setActionError(err?.message || "تعذر اعتماد الطلب حالياً")
    } finally {
      setActionLoadingId(null)
    }
  }

  const reject = async (id: number) => {
    try {
      setActionLoadingId(id)
      await api.post(`/athletes/registrations/${id}/reject/`, rejectNote.trim() ? { note: rejectNote.trim() } : undefined)
      await fetchAll()
    } catch (err: any) {
      setActionError(err?.message || "تعذر رفض الطلب حالياً")
    } finally {
      setActionLoadingId(null)
    }
  }

  const openConfirmation = (registration: RegistrationRequest, type: "approve" | "reject") => {
    setConfirmAction({ id: registration.id, userName: registration.user_name, type })
    setRejectNote("")
    setActionError(null)
  }

  const submitConfirmedAction = async () => {
    if (!confirmAction) return
    if (confirmAction.type === "approve") {
      await approve(confirmAction.id)
    } else {
      await reject(confirmAction.id)
    }
    setConfirmAction(null)
    setRejectNote("")
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-bold">الطلبات الجديدة</h2>
        <p className="text-xs text-muted-foreground">مراجعة بيانات التسجيل وحالة الدفع قبل الاعتماد.</p>
      </div>

      {actionError && (
        <div className="rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">
          {actionError}
        </div>
      )}

      {registrations.length === 0 ? (
        <div className="rounded-2xl border border-border bg-card p-10 text-center text-muted-foreground">
          <Eye className="mx-auto mb-2 h-10 w-10 opacity-40" />
          <p>لا توجد طلبات تسجيل معلقة حالياً</p>
        </div>
      ) : (
        <div className="grid gap-3">
          {registrations.map((registration) => {
            const linkedSub = registration.athlete_id ? subscriptionByAthleteId[registration.athlete_id] : undefined
            const paymentMethod = linkedSub?.payment_method === "bank_transfer" ? "تحويل بنكي" : linkedSub?.payment_method === "cash" ? "نقدي" : "غير مكتمل"
            const needsAthleteProfile = registration.role_choice === "athlete" && !registration.athlete_id

            return (
              <motion.article
                key={registration.id}
                className="rounded-2xl border border-border bg-card p-4"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <div className="grid gap-4 md:grid-cols-[1fr_auto]">
                  <div className="space-y-3">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                        {registration.role_choice === "athlete" ? <UserRound className="h-5 w-5" /> : <Building2 className="h-5 w-5" />}
                      </div>
                      {registration.athlete_photo && (
                        <img alt={registration.user_name} className="h-10 w-10 rounded-xl object-cover" src={registration.athlete_photo} />
                      )}
                      <div>
                        <p className="font-semibold">{registration.user_name}</p>
                        <p className="text-xs text-muted-foreground">{registration.user_phone}</p>
                        {registration.athlete_membership_number && (
                          <p className="text-[11px] text-muted-foreground">{registration.athlete_membership_number}</p>
                        )}
                      </div>
                    </div>

                    <div className="grid gap-2 text-xs sm:grid-cols-2 lg:grid-cols-4">
                      <div className="rounded-xl border border-border bg-surface-container-low px-3 py-2">
                        <p className="text-muted-foreground">نوع الحساب</p>
                        <p className="font-semibold">{registration.role_choice === "athlete" ? "رياضي" : "ولي أمر"}</p>
                      </div>
                      <div className="rounded-xl border border-border bg-surface-container-low px-3 py-2">
                        <p className="text-muted-foreground">تاريخ الطلب</p>
                        <p className="font-semibold">{formatDate(registration.created_at)}</p>
                      </div>
                      <div className="rounded-xl border border-border bg-surface-container-low px-3 py-2">
                        <p className="text-muted-foreground">طريقة الدفع</p>
                        <p className="font-semibold">{paymentMethod}</p>
                      </div>
                      <div className="rounded-xl border border-border bg-surface-container-low px-3 py-2">
                        <p className="text-muted-foreground">حالة الرياضي</p>
                        <p className="font-semibold">{registration.athlete_id ? "ملف مكتمل" : "بحاجة إنشاء ملف"}</p>
                      </div>
                    </div>

                    {needsAthleteProfile && (
                      <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs text-amber-700">
                        هذا الطلب يحتاج إنشاء ملف رياضي يدوياً قبل الاعتماد.
                      </div>
                    )}

                    {linkedSub?.invoice_pdf_url && (
                      <a
                        className="inline-flex items-center gap-1 rounded-lg border border-primary/25 bg-primary/8 px-3 py-1.5 text-xs font-semibold text-primary hover:bg-primary/12"
                        href={toAbsoluteMediaUrl(linkedSub.invoice_pdf_url) || "#"}
                        rel="noreferrer"
                        target="_blank"
                      >
                        <FileText className="h-4 w-4" /> عرض إيصال التحويل (PDF)
                      </a>
                    )}
                  </div>

                  <div className="flex items-center gap-2 md:flex-col md:justify-center">
                    {registration.role_choice === "athlete" && !registration.athlete_id && (
                      <Button
                        className="min-w-24"
                        onClick={() => navigate(`/dashboard/athletes/add?registration=${registration.id}`)}
                        size="sm"
                        variant="secondary"
                      >
                        إنشاء رياضي
                      </Button>
                    )}
                    {registration.athlete_id && (
                      <Button
                        className="min-w-24"
                        onClick={() => navigate(`/dashboard/athletes/${registration.athlete_id}`)}
                        size="sm"
                        variant="ghost"
                      >
                        عرض الملف
                      </Button>
                    )}
                    <Button
                      className="min-w-24"
                      disabled={actionLoadingId === registration.id || needsAthleteProfile}
                      onClick={() => openConfirmation(registration, "approve")}
                      size="sm"
                      variant="outline"
                    >
                      <Check className="h-4 w-4" />
                      اعتماد
                    </Button>
                    <Button
                      className="min-w-24"
                      disabled={actionLoadingId === registration.id}
                      onClick={() => openConfirmation(registration, "reject")}
                      size="sm"
                      variant="destructive"
                    >
                      <X className="h-4 w-4" />
                      رفض
                    </Button>
                  </div>
                </div>
              </motion.article>
            )
          })}
        </div>
      )}

      {confirmAction && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" onClick={() => setConfirmAction(null)}>
          <div className="w-full max-w-md rounded-2xl border border-border bg-card p-5" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-base font-bold">
              {confirmAction.type === "approve" ? "تأكيد اعتماد الطلب" : "تأكيد رفض الطلب"}
            </h3>
            <p className="mt-2 text-sm text-muted-foreground">
              {confirmAction.type === "approve"
                ? `سيتم اعتماد طلب ${confirmAction.userName}. هل تريد المتابعة؟`
                : `سيتم رفض طلب ${confirmAction.userName}. هل تريد المتابعة؟`}
            </p>

            {confirmAction.type === "reject" && (
              <div className="mt-3">
                <label className="mb-1 block text-xs text-muted-foreground" htmlFor="reject-note">سبب الرفض (اختياري)</label>
                <textarea
                  id="reject-note"
                  rows={3}
                  value={rejectNote}
                  onChange={(e) => setRejectNote(e.target.value)}
                  className="w-full rounded-xl border border-border bg-surface-container-low px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-primary"
                  placeholder="اكتب سبباً مختصراً يظهر لفريق الإدارة"
                />
              </div>
            )}

            <div className="mt-4 flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setConfirmAction(null)}>إلغاء</Button>
              <Button
                type="button"
                variant={confirmAction.type === "approve" ? "outline" : "destructive"}
                disabled={actionLoadingId === confirmAction.id}
                onClick={() => void submitConfirmedAction()}
              >
                {actionLoadingId === confirmAction.id ? "جاري التنفيذ..." : confirmAction.type === "approve" ? "تأكيد الاعتماد" : "تأكيد الرفض"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
