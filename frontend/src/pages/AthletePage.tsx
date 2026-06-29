import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { useAuth } from "@/lib/auth"
import CameraCapture from "@/components/ui/camera-capture"
import type { ParentAthlete, Subscription } from "@/lib/types"
import { Users, Plus, User, Package } from "lucide-react"

export default function AthletePage() {
  const { user } = useAuth()
  const [athletes, setAthletes] = useState<ParentAthlete[]>([])
  const [mySubscription, setMySubscription] = useState<Subscription | null>(null)
  const [loading, setLoading] = useState(true)
  const [showAddForm, setShowAddForm] = useState(false)
  const [addForm, setAddForm] = useState({ full_name: "", phone: "", password: "Athlete@123", birth_day: "", birth_month: "", birth_year: "", weight: "", height: "" })
  const [photo, setPhoto] = useState<string | null>(null)
  const [addError, setAddError] = useState("")
  const [pageError, setPageError] = useState("")

  const isParent = user?.role === "parent"

  useEffect(() => {
    void (isParent ? fetchAthletes() : fetchMySubscription())
  }, [isParent])

  const fetchAthletes = async () => {
    setPageError("")
    try {
      const res = await api.get<{ results: ParentAthlete[] } | ParentAthlete[]>("/athletes/parent/athletes/")
      setAthletes(extractResults(res))
    } catch {
      setPageError("تعذر تحميل الرياضيين")
    } finally { setLoading(false) }
  }

  const fetchMySubscription = async () => {
    setPageError("")
    try {
      const res = await api.get<{ results: Subscription[] } | Subscription[]>("/subscriptions/")
      setMySubscription(extractResults(res)[0] || null)
    } catch {
      setPageError("تعذر تحميل بيانات الاشتراك")
    } finally { setLoading(false) }
  }

  const handleAddAthlete = async (e: React.FormEvent) => {
    e.preventDefault()
    setAddError("")
    if (!photo) {
      setAddError("يرجى التقاط صورة شخصية للرياضي")
      return
    }
    try {
      await api.post("/athletes/parent/athletes/", {
        full_name: addForm.full_name,
        phone: addForm.phone,
        birth_day: parseInt(addForm.birth_day),
        birth_month: parseInt(addForm.birth_month),
        birth_year: parseInt(addForm.birth_year),
        weight: parseFloat(addForm.weight),
        height: parseFloat(addForm.height),
        photo,
      })
      setShowAddForm(false)
      setAddForm({ full_name: "", phone: "", password: "Athlete@123", birth_day: "", birth_month: "", birth_year: "", weight: "", height: "" })
      setPhoto(null)
      fetchAthletes()
    } catch (err: any) {
      setAddError(err.message || "فشل إضافة رياضي")
    }
  }

  if (loading) return <LoadingSpinner />

  if (pageError) {
    return (
      <div className="rounded-2xl border border-destructive/20 bg-destructive/5 p-4 text-center">
        <p className="text-sm text-destructive">{pageError}</p>
        <Button
          className="mt-3"
          onClick={() => void (isParent ? fetchAthletes() : fetchMySubscription())}
          size="sm"
          variant="outline"
        >
          إعادة المحاولة
        </Button>
      </div>
    )
  }

  if (isParent) {
    return (
      <div className="overflow-hidden">
        <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <h2 className="text-lg font-bold">الرياضيون المسجلون</h2>
          <Button size="sm" className="w-full sm:w-auto" onClick={() => setShowAddForm(true)}>
            <Plus className="w-4 h-4 ml-1" /> إضافة رياضي
          </Button>
        </div>

        {showAddForm && (
          <motion.form initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }}
            onSubmit={handleAddAthlete} className="bg-card border border-border rounded-2xl p-4 space-y-3 mb-4"
          >
            <CameraCapture onCapture={setPhoto} preview={photo || undefined} />
            <input placeholder="الاسم الكامل" className="w-full bg-surface-container-low border border-border rounded-xl px-4 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              value={addForm.full_name} onChange={(e) => setAddForm({ ...addForm, full_name: e.target.value })} required />
            <input placeholder="رقم الهاتف" dir="ltr" className="w-full bg-surface-container-low border border-border rounded-xl px-4 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
              value={addForm.phone} onChange={(e) => setAddForm({ ...addForm, phone: e.target.value })} required />
            <div className="grid grid-cols-3 gap-2">
              <input type="number" min={1} max={31} placeholder="DD"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                value={addForm.birth_day} onChange={(e) => setAddForm({ ...addForm, birth_day: e.target.value })} required />
              <input type="number" min={1} max={12} placeholder="MM"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                value={addForm.birth_month} onChange={(e) => setAddForm({ ...addForm, birth_month: e.target.value })} required />
              <input type="number" min={1900} max={2026} placeholder="YY"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                value={addForm.birth_year} onChange={(e) => setAddForm({ ...addForm, birth_year: e.target.value })} required />
            </div>
            <div className="grid grid-cols-2 gap-2">
              <input type="number" step="0.1" placeholder="الوزن"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                value={addForm.weight} onChange={(e) => setAddForm({ ...addForm, weight: e.target.value })} />
              <input type="number" step="0.1" placeholder="الطول"
                className="bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                value={addForm.height} onChange={(e) => setAddForm({ ...addForm, height: e.target.value })} />
            </div>
            {addError && <p className="text-destructive text-sm">{addError}</p>}
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button type="submit" size="sm" className="w-full sm:w-auto">حفظ</Button>
              <Button type="button" variant="ghost" size="sm" className="w-full sm:w-auto" onClick={() => setShowAddForm(false)}>إلغاء</Button>
            </div>
          </motion.form>
        )}

        <div className="space-y-3">
          {athletes.length === 0 && !showAddForm && (
            <div className="text-center py-12 text-muted-foreground">
              <Users className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>لم تقم بإضافة أي رياضي بعد</p>
            </div>
          )}
          {athletes.map((a) => (
            <div key={a.id} className="bg-card border border-border rounded-2xl p-4 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                <User className="w-5 h-5 text-primary" />
              </div>
              <div className="flex-1">
                <p className="font-semibold">{a.athlete_name}</p>
                <p className="text-xs text-muted-foreground">{a.athlete_membership}</p>
              </div>
              <Package className="w-4 h-4 text-muted-foreground" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div>
      <h2 className="text-lg font-bold mb-4">بياناتي الرياضية</h2>
      <div className="bg-card border border-border rounded-2xl p-6 text-center">
        <div className="w-20 h-20 rounded-full bg-primary/10 overflow-hidden flex items-center justify-center mx-auto mb-3">
          {user?.athlete_detail?.photo ? (
            <img alt={user?.full_name_ar} className="h-full w-full object-cover" src={user.athlete_detail.photo} />
          ) : (
            <User className="w-10 h-10 text-primary" />
          )}
        </div>
        <p className="font-bold text-lg">{user?.athlete_detail?.full_name || user?.full_name_ar}</p>
        <p className="text-sm text-muted-foreground">{user?.athlete_detail?.phone || user?.phone}</p>
        {user?.athlete_detail?.membership_number && (
          <p className="text-xs text-muted-foreground mt-1">{user.athlete_detail.membership_number}</p>
        )}
        {user?.athlete_detail?.department_name && (
          <p className="text-xs text-muted-foreground mt-1">{user.athlete_detail.department_name}</p>
        )}
        {mySubscription && (
          <div className="mt-4 p-3 bg-surface-container-low rounded-xl">
            <p className="text-sm font-medium">{mySubscription.package_name}</p>
            <p className={`text-xs mt-1 ${mySubscription.status === "active" ? "text-green-600" : "text-amber-600"}`}>
              {mySubscription.status === "active" ? "نشط" : mySubscription.status === "pending" ? "قيد الانتظار" : "منتهي"}
            </p>
          </div>
        )}
      </div>
    </div>
  )
}
