import { useState, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { useAuth } from "@/lib/auth"
import { useRenewSubscription } from "@/lib/hooks/useSubscriptions"
import { useQueryClient } from "@tanstack/react-query"
import CameraCapture from "@/components/ui/camera-capture"
import type { ParentAthlete, Subscription } from "@/lib/types"
import { Users, Plus, User, Package, RefreshCw, Clock, Edit2, Save, X, HeartPulse, MapPin } from "lucide-react"

const statusMap: Record<string, { label: string; cls: string }> = {
  active: { label: "نشط", cls: "bg-green-100 text-green-700 border border-green-200" },
  expired: { label: "منتهي", cls: "bg-red-100 text-red-700 border border-red-200" },
  pending: { label: "قيد الانتظار", cls: "bg-amber-100 text-amber-700 border border-amber-200" },
  rejected: { label: "مرفوض", cls: "bg-red-100 text-red-700 border border-red-200" },
}

const formatDate = (d: string) =>
  new Date(d).toLocaleDateString("ar-SA-u-nu-latn", { year: "numeric", month: "numeric", day: "numeric" })

export default function AthletePage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const renewMut = useRenewSubscription()
  
  const [athletes, setAthletes] = useState<ParentAthlete[]>([])
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([])
  const [parentAthleteSubs, setParentAthleteSubs] = useState<Record<number, Subscription[]>>({})
  const [loading, setLoading] = useState(true)
  const [renewingId, setRenewingId] = useState<number | null>(null)

  // Parent Profile Edit State
  const [isEditingParent, setIsEditingParent] = useState(false)
  const [parentEditForm, setParentEditForm] = useState({
    first_name_ar: user?.first_name_ar || "",
    phone: user?.phone || "",
    whatsapp_phone: "",
    residence: "",
  })

  // Athlete Self Edit State
  const [isEditingSelf, setIsEditingSelf] = useState(false)
  const [selfEditForm, setSelfEditForm] = useState({
    full_name: user?.athlete_detail?.full_name || user?.full_name_ar || "",
    phone: user?.athlete_detail?.phone || user?.phone || "",
    residence: "",
    health_status: "",
  })

  // Parent Child Edit State
  const [editingChildId, setEditingChildId] = useState<number | null>(null)
  const [childEditForm, setChildEditForm] = useState({
    full_name: "",
    residence: "",
    health_status: "",
  })

  const [showAddForm, setShowAddForm] = useState(false)
  const [addForm, setAddForm] = useState({ full_name: "", phone: "", birth_day: "", birth_month: "", birth_year: "", residence: "", health_status: "" })
  const [photo, setPhoto] = useState<string | null>(null)
  const [addError, setAddError] = useState("")
  const [pageError, setPageError] = useState("")
  const [successMsg, setSuccessMsg] = useState("")

  const isParent = user?.role === "parent"

  useEffect(() => {
    void (isParent ? fetchParentData() : fetchMyData())
    if (user) {
      setParentEditForm({
        first_name_ar: user.first_name_ar || "",
        phone: user.phone || "",
        whatsapp_phone: user.whatsapp_phone || "",
        residence: user.residence || "",
      })
      setSelfEditForm({
        full_name: user.athlete_detail?.full_name || user.full_name_ar || "",
        phone: user.athlete_detail?.phone || user.phone || "",
        residence: user.residence || user.athlete_detail?.residence || "",
        health_status: user.athlete_detail?.health_status || "",
      })
    }
  }, [user, isParent])


  const fetchMyData = async () => {
    setPageError("")
    try {
      const res = await api.get<{ results: Subscription[] } | Subscription[]>("/subscriptions/", { page_size: "50" })
      setSubscriptions(extractResults(res))
    } catch {
      setPageError("تعذر تحميل بيانات الاشتراك")
    } finally { setLoading(false) }
  }

  const fetchParentData = async () => {
    setPageError("")
    try {
      const athletesRes = await api.get<{ results: ParentAthlete[] } | ParentAthlete[]>("/athletes/parent/athletes/")
      const items = extractResults(athletesRes)
      setAthletes(items)

      const map: Record<number, Subscription[]> = {}
      for (const a of items) {
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
      setParentAthleteSubs(map)
    } catch {
      setPageError("تعذر تحميل الرياضيين")
    } finally { setLoading(false) }
  }

  const handleRenew = async (sub: Subscription) => {
    setRenewingId(sub.id)
    try {
      await renewMut.mutateAsync({ id: sub.id, months: 1, amount: sub.amount })
      await queryClient.invalidateQueries({ queryKey: ["subscriptions"] })
      if (isParent) {
        await fetchParentData()
      } else {
        await fetchMyData()
      }
    } catch {
      setPageError("فشل التجديد")
    } finally {
      setRenewingId(null)
    }
  }

  const handleSaveParentProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await api.patch("/auth/profile/", parentEditForm)
      setIsEditingParent(false)
      setSuccessMsg("تم حفظ بيانات ولي الأمر بنجاح")
      setTimeout(() => setSuccessMsg(""), 3000)
    } catch (err: any) {
      setPageError(err.message || "فشل حفظ البيانات")
    }
  }

  const handleSaveSelfProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await api.patch("/auth/profile/", {
        first_name_ar: selfEditForm.full_name,
        phone: selfEditForm.phone,
        residence: selfEditForm.residence,
      })
      if (user?.athlete_detail?.id) {
        await api.patch(`/athletes/${user.athlete_detail.id}/`, {
          full_name: selfEditForm.full_name,
          phone: selfEditForm.phone,
          residence: selfEditForm.residence,
          health_status: selfEditForm.health_status,
        })
      }
      setIsEditingSelf(false)
      setSuccessMsg("تم حفظ بياناتك الشخصية بنجاح")
      setTimeout(() => setSuccessMsg(""), 3000)
    } catch (err: any) {
      setPageError(err.message || "فشل حفظ البيانات")
    }
  }

  const handleSaveChildProfile = async (athleteId: number, e: React.FormEvent) => {
    e.preventDefault()
    try {
      await api.patch(`/athletes/${athleteId}/`, childEditForm)
      setEditingChildId(null)
      fetchParentData()
      setSuccessMsg("تم تحديث بيانات الرياضي بنجاح")
      setTimeout(() => setSuccessMsg(""), 3000)
    } catch (err: any) {
      setPageError(err.message || "فشل تعديل بيانات الرياضي")
    }
  }

  const handleAddAthlete = async (e: React.FormEvent) => {
    e.preventDefault()
    setAddError("")
    try {
      const payload: Record<string, any> = {
        full_name: addForm.full_name,
        birth_day: parseInt(addForm.birth_day),
        birth_month: parseInt(addForm.birth_month),
        birth_year: parseInt(addForm.birth_year),
        residence: addForm.residence,
        health_status: addForm.health_status,
      }
      if (photo) {
        payload.photo = photo
      }
      await api.post("/athletes/parent/athletes/", payload)
      setShowAddForm(false)
      setAddForm({ full_name: "", phone: "", birth_day: "", birth_month: "", birth_year: "", residence: "", health_status: "" })
      setPhoto(null)
      fetchParentData()
    } catch (err: any) {
      setAddError(err.message || "فشل إضافة رياضي")
    }
  }


  if (loading) return <LoadingSpinner />

  return (
    <div className="space-y-6" dir="rtl">
      {successMsg && (
        <div className="p-3 bg-green-50 border border-green-200 text-green-700 rounded-xl text-xs font-bold text-center">
          {successMsg}
        </div>
      )}

      {pageError && (
        <div className="rounded-2xl border border-destructive/20 bg-destructive/5 p-4 text-center">
          <p className="text-sm text-destructive">{pageError}</p>
          <Button className="mt-3" onClick={() => void (isParent ? fetchParentData() : fetchMyData())} size="sm" variant="outline">
            إعادة المحاولة
          </Button>
        </div>
      )}

      {/* PARENT VIEW */}
      {isParent ? (
        <div className="space-y-6">
          {/* Parent Personal Data Card */}
          <div className="bg-white border border-border/60 rounded-3xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-base font-black text-[#102033]">بيانات ولي الأمر (أكاديمية الأوس)</h2>
                <p className="text-xs text-muted-foreground">يمكنك تعديل بياناتك الشخصية والسكن لمطابقتها مع أطفالك</p>
              </div>
              <Button size="sm" variant="outline" onClick={() => setIsEditingParent(!isEditingParent)} className="rounded-xl gap-1 text-xs">
                {isEditingParent ? <X className="w-3.5 h-3.5" /> : <Edit2 className="w-3.5 h-3.5" />}
                {isEditingParent ? "إلغاء" : "تعديل بياناتي"}
              </Button>
            </div>

            {isEditingParent ? (
              <form onSubmit={handleSaveParentProfile} className="space-y-3">
                <div>
                  <label className="block text-xs font-bold mb-1">الاسم بالكامل</label>
                  <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" value={parentEditForm.first_name_ar} onChange={(e) => setParentEditForm({ ...parentEditForm, first_name_ar: e.target.value })} required />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="block text-xs font-bold mb-1">رقم الهاتف</label>
                    <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" dir="ltr" value={parentEditForm.phone} onChange={(e) => setParentEditForm({ ...parentEditForm, phone: e.target.value })} required />
                  </div>
                  <div>
                    <label className="block text-xs font-bold mb-1">رقم الواتساب</label>
                    <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" dir="ltr" value={parentEditForm.whatsapp_phone} onChange={(e) => setParentEditForm({ ...parentEditForm, whatsapp_phone: e.target.value })} />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">السكن / العنوان</label>
                  <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" value={parentEditForm.residence} onChange={(e) => setParentEditForm({ ...parentEditForm, residence: e.target.value })} placeholder="مصراتة - ..." />
                </div>
                <Button type="submit" size="sm" className="w-full bg-[#0F4C81] font-bold rounded-xl">
                  <Save className="w-3.5 h-3.5 ml-1" /> حفظ التعديلات
                </Button>
              </form>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
                <div className="bg-[#f8fafc] p-3 rounded-xl border">
                  <span className="text-muted-foreground block">الاسم:</span>
                  <span className="font-bold text-[#102033]">{user?.full_name_ar}</span>
                </div>
                <div className="bg-[#f8fafc] p-3 rounded-xl border">
                  <span className="text-muted-foreground block">رقم الهاتف:</span>
                  <span className="font-bold text-[#102033]" dir="ltr">{user?.phone}</span>
                </div>
                <div className="bg-[#f8fafc] p-3 rounded-xl border">
                  <span className="text-muted-foreground block">السكن:</span>
                  <span className="font-bold text-[#102033]">{user?.residence || user?.athlete_detail?.residence || "غير محدد"}</span>
                </div>
              </div>
            )}
          </div>

          {/* Children Athletes List */}
          <div>
            <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="text-base font-black text-[#102033]">الأطفال / الرياضيون التابعون لك</h2>
              <Button size="sm" className="w-full sm:w-auto bg-[#0F4C81] rounded-xl font-bold" onClick={() => setShowAddForm(true)}>
                <Plus className="w-4 h-4 ml-1" /> إضافة طفل / رياضي جديد
              </Button>
            </div>

            {showAddForm && (
              <motion.form initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }}
                onSubmit={handleAddAthlete} className="bg-white border border-border/80 rounded-3xl p-5 space-y-3 mb-4 shadow-sm"
              >
                <h3 className="text-xs font-black text-[#102033]">بيانات الرياضي الجديد</h3>
                <CameraCapture onCapture={setPhoto} preview={photo || undefined} />
                <input placeholder="اسم الطفل بالكامل" className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2.5 text-sm"
                  value={addForm.full_name} onChange={(e) => setAddForm({ ...addForm, full_name: e.target.value })} required />
                <input placeholder="السكن / العنوان" className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2.5 text-sm"
                  value={addForm.residence} onChange={(e) => setAddForm({ ...addForm, residence: e.target.value })} />
                <input placeholder="الحالة الصحية / ملاحظات طبية" className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2.5 text-sm"
                  value={addForm.health_status} onChange={(e) => setAddForm({ ...addForm, health_status: e.target.value })} />
                <div className="grid grid-cols-3 gap-2">
                  <input type="number" min={1} max={31} placeholder="اليوم" className="bg-[#f8fafc] border rounded-xl px-3 py-2 text-sm text-center"
                    value={addForm.birth_day} onChange={(e) => setAddForm({ ...addForm, birth_day: e.target.value })} required />
                  <input type="number" min={1} max={12} placeholder="الشهر" className="bg-[#f8fafc] border rounded-xl px-3 py-2 text-sm text-center"
                    value={addForm.birth_month} onChange={(e) => setAddForm({ ...addForm, birth_month: e.target.value })} required />
                  <input type="number" min={1900} max={2026} placeholder="السنة" className="bg-[#f8fafc] border rounded-xl px-3 py-2 text-sm text-center"
                    value={addForm.birth_year} onChange={(e) => setAddForm({ ...addForm, birth_year: e.target.value })} required />
                </div>

                {addError && <p className="text-destructive text-xs font-bold">{addError}</p>}
                <div className="flex gap-2">
                  <Button type="submit" size="sm" className="bg-[#0F4C81] font-bold rounded-xl">حفظ وإضافة</Button>
                  <Button type="button" variant="ghost" size="sm" className="rounded-xl" onClick={() => setShowAddForm(false)}>إلغاء</Button>
                </div>
              </motion.form>
            )}

            <div className="space-y-4">
              {athletes.length === 0 && !showAddForm && (
                <div className="text-center py-12 text-muted-foreground bg-white rounded-3xl border border-dashed">
                  <Users className="w-12 h-12 mx-auto mb-2 opacity-40" />
                  <p>لم تقم بإضافة أي طفل بعد</p>
                </div>
              )}
              {athletes.map((a) => {
                const subs = parentAthleteSubs[a.athlete] || []
                const activeSub = subs.find((s) => s.status === "active")
                const isEditingThisChild = editingChildId === a.athlete

                return (
                  <div key={a.id} className="bg-white border border-border/70 rounded-3xl p-5 space-y-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-11 h-11 rounded-2xl bg-[#0F4C81]/10 text-[#0F4C81] flex items-center justify-center font-bold">
                          <User className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="font-bold text-[#102033]">{a.athlete_name}</p>
                          <p className="text-xs text-muted-foreground">{a.athlete_membership}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {activeSub ? (
                          <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${statusMap[activeSub.status]?.cls}`}>
                            {statusMap[activeSub.status]?.label}
                          </span>
                        ) : (
                          <span className="text-xs text-muted-foreground">لا يوجد اشتراك</span>
                        )}
                        <Button size="sm" variant="ghost" className="h-8 rounded-lg text-xs" onClick={() => {
                          if (isEditingThisChild) {
                            setEditingChildId(null)
                          } else {
                            setEditingChildId(a.athlete)
                            setChildEditForm({ full_name: a.athlete_name, residence: "", health_status: "" })
                          }
                        }}>
                          <Edit2 className="w-3.5 h-3.5 ml-1" />
                          {isEditingThisChild ? "إلغاء" : "تعديل البيانات"}
                        </Button>
                      </div>
                    </div>

                    {/* Child Profile Edit Form */}
                    {isEditingThisChild && (
                      <form onSubmit={(e) => handleSaveChildProfile(a.athlete, e)} className="bg-[#f8fafc] border rounded-2xl p-4 space-y-3">
                        <h4 className="text-xs font-black text-[#102033]">تعديل بيانات الطفل</h4>
                        <div>
                          <label className="block text-xs font-bold mb-1">الاسم بالكامل</label>
                          <input className="w-full bg-white border rounded-xl px-3 py-1.5 text-xs" value={childEditForm.full_name} onChange={(e) => setChildEditForm({ ...childEditForm, full_name: e.target.value })} required />
                        </div>
                        <div>
                          <label className="block text-xs font-bold mb-1">السكن / العنوان</label>
                          <input className="w-full bg-white border rounded-xl px-3 py-1.5 text-xs" value={childEditForm.residence} onChange={(e) => setChildEditForm({ ...childEditForm, residence: e.target.value })} />
                        </div>
                        <div>
                          <label className="block text-xs font-bold mb-1">الحالة الصحية / ملاحظات طبية</label>
                          <input className="w-full bg-white border rounded-xl px-3 py-1.5 text-xs" value={childEditForm.health_status} onChange={(e) => setChildEditForm({ ...childEditForm, health_status: e.target.value })} />
                        </div>
                        <Button type="submit" size="sm" className="bg-[#0F4C81] text-xs font-bold rounded-xl w-full">
                          حفظ التعديلات
                        </Button>
                      </form>
                    )}

                    {subs.length > 0 ? (
                      <div className="space-y-2">
                        {subs.map((sub) => (
                          <div key={sub.id} className="bg-[#f8fafc] rounded-2xl p-3 flex items-center justify-between border">
                            <div className="flex-1">
                              <p className="text-xs font-bold text-[#102033]">{sub.package_name}</p>
                              <p className="text-[11px] text-muted-foreground">
                                {formatDate(sub.start_date)} - {formatDate(sub.end_date)}
                              </p>
                            </div>
                            <span className="text-xs font-black text-[#0F4C81]">{Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</span>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <Button size="sm" variant="outline" className="w-full text-xs rounded-xl" onClick={() => navigate("/user/subscribe")}>
                        <Plus className="w-3.5 h-3.5 ml-1" /> اشتراك جديد
                      </Button>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      ) : (
        /* ATHLETE VIEW */
        <div className="space-y-6">
          <div className="bg-white border border-border/70 rounded-3xl p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-black text-[#102033]">بياناتي الرياضية (مركز الأهلي الرياضي)</h2>
              <Button size="sm" variant="outline" className="rounded-xl text-xs gap-1" onClick={() => setIsEditingSelf(!isEditingSelf)}>
                {isEditingSelf ? <X className="w-3.5 h-3.5" /> : <Edit2 className="w-3.5 h-3.5" />}
                {isEditingSelf ? "إلغاء" : "تعديل بياني"}
              </Button>
            </div>

            {isEditingSelf ? (
              <form onSubmit={handleSaveSelfProfile} className="space-y-3">
                <div>
                  <label className="block text-xs font-bold mb-1">الاسم بالكامل</label>
                  <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" value={selfEditForm.full_name} onChange={(e) => setSelfEditForm({ ...selfEditForm, full_name: e.target.value })} required />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">رقم الهاتف</label>
                  <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" dir="ltr" value={selfEditForm.phone} onChange={(e) => setSelfEditForm({ ...selfEditForm, phone: e.target.value })} required />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">السكن / العنوان</label>
                  <input className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" value={selfEditForm.residence} onChange={(e) => setSelfEditForm({ ...selfEditForm, residence: e.target.value })} placeholder="مصراتة - ..." />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">الحالة الصحية / ملاحظات طبية</label>
                  <textarea rows={2} className="w-full bg-[#f8fafc] border rounded-xl px-3.5 py-2 text-sm" value={selfEditForm.health_status} onChange={(e) => setSelfEditForm({ ...selfEditForm, health_status: e.target.value })} />
                </div>
                <Button type="submit" size="sm" className="w-full bg-[#0F4C81] font-bold rounded-xl">
                  <Save className="w-3.5 h-3.5 ml-1" /> حفظ التعديلات
                </Button>
              </form>
            ) : (
              <div className="flex flex-col sm:flex-row items-center gap-4">
                <div className="w-20 h-20 rounded-full bg-[#0F4C81]/10 overflow-hidden flex items-center justify-center border-2 border-[#0F4C81]">
                  {user?.athlete_detail?.photo ? (
                    <img alt={user?.full_name_ar} className="h-full w-full object-cover" src={user.athlete_detail.photo} />
                  ) : (
                    <User className="w-10 h-10 text-[#0F4C81]" />
                  )}
                </div>
                <div className="space-y-1 text-center sm:text-right">
                  <h3 className="font-black text-lg text-[#102033]">{user?.athlete_detail?.full_name || user?.full_name_ar}</h3>
                  <p className="text-xs text-muted-foreground font-semibold" dir="ltr">{user?.phone}</p>
                  {user?.athlete_detail?.membership_number && (
                    <p className="text-xs font-bold text-[#0F4C81]">عضوية رقم: {user.athlete_detail.membership_number}</p>
                  )}
                </div>
              </div>
            )}
          </div>

          {subscriptions.length > 0 && (
            <div className="bg-white border border-border/70 rounded-3xl p-6 shadow-sm space-y-4">
              <h3 className="text-sm font-black text-[#102033]">سجل الاشتراكات</h3>
              <div className="space-y-3">
                {subscriptions.map((sub) => {
                  const status = statusMap[sub.status] || { label: sub.status, cls: "" }
                  return (
                    <div key={sub.id} className="bg-[#f8fafc] border border-border/60 rounded-2xl p-4 space-y-2">
                      <div className="flex items-center justify-between">
                        <p className="font-bold text-[#102033]">{sub.package_name}</p>
                        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${status.cls}`}>
                          {status.label}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 gap-2 text-xs text-muted-foreground">
                        <div>من {formatDate(sub.start_date)}</div>
                        <div>إلى {formatDate(sub.end_date)}</div>
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <span className="text-sm font-black text-[#0F4C81]">{Number(sub.amount).toLocaleString("ar-SA-u-nu-latn")} د.ل</span>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
