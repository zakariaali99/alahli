import { useEffect, useRef, useState, type FormEvent } from "react"
import { AnimatePresence, motion } from "framer-motion"
import { Plus, Pencil, X, Users, Dumbbell, ChevronLeft } from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { useToast } from "@/lib/toast"
import { validateLibyanPhone } from "@/lib/utils"
import type { Group } from "@/lib/types"

type Coach = {
  id: number
  phone: string
  first_name_ar: string
  last_name_ar: string
  full_name_ar: string
  role: string
  is_active: boolean
  photo: string | null
}

export default function CoachesManagement() {
  const toast = useToast()
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [groupsByCoach, setGroupsByCoach] = useState<Record<number, Group[]>>({})
  const [loading, setLoading] = useState(true)
  const [pageError, setPageError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [editingCoach, setEditingCoach] = useState<Coach | null>(null)
  const [selectedCoachId, setSelectedCoachId] = useState<number | null>(null)
  const [stage, setStage] = useState<"coaches" | "details">("coaches")
  const [modalError, setModalError] = useState<string | null>(null)

  const [form, setForm] = useState({ first_name_ar: "", last_name_ar: "", phone: "", password: "" })
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => { void fetchCoaches() }, [])

  const fetchCoaches = async () => {
    setLoading(true); setPageError(null)
    try {
      const data = await api.get<{ results: Coach[] } | Coach[]>("/auth/users/?role=trainer")
      const list = extractResults(data)
      setCoaches(list)
      list.forEach((c) => void fetchCoachGroups(c.id))
    } catch { setPageError("تعذر تحميل المدربين") }
    finally { setLoading(false) }
  }

  const fetchCoachGroups = async (coachId: number) => {
    try {
      const data = await api.get<{ results: Group[] } | Group[]>(`/groups/?coach=${coachId}`)
      setGroupsByCoach((prev) => ({ ...prev, [coachId]: extractResults(data) }))
    } catch { /* ignore */ }
  }

  const openCoachDetails = (coachId: number) => {
    setSelectedCoachId(coachId)
    setStage("details")
  }

  const openCreateModal = () => {
    setEditingCoach(null)
    setForm({ first_name_ar: "", last_name_ar: "", phone: "", password: "" })
    setPhotoFile(null)
    setModalError(null)
    setShowModal(true)
  }

  const openEditModal = (coach: Coach) => {
    setEditingCoach(coach)
    setForm({ first_name_ar: coach.first_name_ar, last_name_ar: coach.last_name_ar, phone: coach.phone, password: "" })
    setPhotoFile(null)
    setModalError(null)
    setShowModal(true)
  }

  const closeModal = () => { if (!submitting) { setShowModal(false); setModalError(null); setEditingCoach(null) } }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setModalError(null)

    if (!form.first_name_ar.trim() || !form.phone.trim()) {
      setModalError("الاسم ورقم الهاتف مطلوبان")
      return
    }

    const phoneErr = validateLibyanPhone(form.phone)
    if (phoneErr) { setModalError(phoneErr); return }

    if (!editingCoach && !form.password.trim()) {
      setModalError("كلمة المرور مطلوبة للمدرب الجديد")
      return
    }

    try {
      setSubmitting(true)
      const fd = new FormData()
      fd.append("first_name_ar", form.first_name_ar.trim())
      fd.append("last_name_ar", form.last_name_ar.trim())
      fd.append("phone", form.phone.trim())
      fd.append("role", "trainer")
      fd.append("is_active", "true")
      if (form.password) fd.append("password", form.password)
      if (photoFile) fd.append("photo", photoFile)

      if (editingCoach) {
        await api.patch(`/auth/users/${editingCoach.id}/`, fd, { formData: true })
        toast.success("تم تحديث المدرب")
      } else {
        await api.post("/auth/users/", fd, { formData: true })
        toast.success("تم إنشاء المدرب")
      }

      closeModal()
      await fetchCoaches()
    } catch (err: any) {
      setModalError(err?.message || "فشل الحفظ")
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) return <LoadingSpinner />

  const selectedCoach = coaches.find((c) => c.id === selectedCoachId) ?? null
  const selectedCoachGroups = selectedCoachId ? groupsByCoach[selectedCoachId] || [] : []

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between rounded-2xl border border-border bg-card p-5">
        <div>
          <h2 className="text-xl font-bold">المدربون</h2>
          <p className="mt-1 text-xs text-muted-foreground">إدارة ملفات المدربين وصورهم والمجموعات المسندة إليهم.</p>
        </div>
        <Button onClick={openCreateModal}><Plus className="h-4 w-4" /> إضافة مدرب</Button>
      </div>

      {pageError && <div className="rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">{pageError}</div>}

      {/* Breadcrumb */}
      {stage !== "coaches" && (
        <div className="flex flex-wrap items-center gap-1 text-sm">
          <button className="font-semibold text-primary hover:underline" onClick={() => setStage("coaches")}>
            المدربون
          </button>
          {selectedCoach && (
            <>
              <ChevronLeft className="h-4 w-4 text-muted-foreground" />
              <span className="font-bold text-muted-foreground">{selectedCoach.full_name_ar}</span>
            </>
          )}
        </div>
      )}

      {/* Stage: Coaches List */}
      {stage === "coaches" && (
        <div className="space-y-4">
          {coaches.length === 0 ? (
            <div className="rounded-2xl border border-border bg-card p-10 text-center text-muted-foreground">
              <Dumbbell className="mx-auto mb-2 h-10 w-10 opacity-40" />
              <p>لا يوجد مدربون بعد. ابدأ بإضافة مدرب جديد.</p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {coaches.map((coach) => {
                const groups = groupsByCoach[coach.id] || []
                return (
                  <motion.div
                    key={coach.id}
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    whileHover={{ y: -4 }}
                    className="group relative cursor-pointer rounded-2xl border-2 border-border bg-card p-5 transition hover:border-primary"
                    onClick={() => openCoachDetails(coach.id)}
                  >
                    <button
                      className="absolute left-2 top-2 z-10 flex h-7 w-7 items-center justify-center rounded-lg bg-primary/10 text-primary opacity-0 transition hover:bg-primary/20 group-hover:opacity-100"
                      onClick={(e) => {
                        e.stopPropagation()
                        openEditModal(coach)
                      }}
                    >
                      <Pencil className="h-3.5 w-3.5" />
                    </button>
                    <div className="flex items-start gap-3">
                      {coach.photo ? (
                        <img src={coach.photo} alt={coach.full_name_ar} className="h-12 w-12 rounded-xl object-cover shadow" />
                      ) : (
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-lg font-bold text-primary shadow">
                          {(coach.full_name_ar || "?").charAt(0)}
                        </div>
                      )}
                      <div className="flex-1">
                        <p className="font-bold">{coach.full_name_ar}</p>
                        <p className="text-xs text-muted-foreground" dir="ltr">{coach.phone}</p>
                      </div>
                    </div>
                    <div className="mt-3 flex items-center justify-between">
                      <div className="flex items-center gap-1 text-xs text-muted-foreground">
                        <Users className="h-3.5 w-3.5" />
                        {groups.length} مجموعة
                      </div>
                      <div className="flex items-center gap-1">
                        <span className={`h-2 w-2 rounded-full ${coach.is_active ? "bg-secondary" : "bg-error"}`} />
                        <span className="text-[10px] text-muted-foreground">{coach.is_active ? "نشط" : "موقوف"}</span>
                      </div>
                    </div>
                  </motion.div>
                )
              })}
            </div>
          )}
        </div>
      )}

      {/* Stage: Coach Details */}
      {stage === "details" && selectedCoach && (
        <motion.div
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-2xl border border-border bg-card overflow-hidden"
        >
          {/* Profile header */}
          <div className="relative h-32 bg-gradient-to-br from-primary/10 to-secondary/10">
            <div className="absolute -bottom-12 right-6">
              {selectedCoach.photo ? (
                <img src={selectedCoach.photo} alt={selectedCoach.full_name_ar} className="h-24 w-24 rounded-2xl border-4 border-card object-cover shadow-lg" />
              ) : (
                <div className="flex h-24 w-24 items-center justify-center rounded-2xl border-4 border-card bg-primary/20 text-3xl font-bold text-primary shadow-lg">
                  {(selectedCoach.full_name_ar || "?").charAt(0)}
                </div>
              )}
            </div>
            <button
              className="absolute left-4 top-4 z-10 flex h-8 w-8 items-center justify-center rounded-xl bg-card/80 text-muted-foreground shadow-sm backdrop-blur transition hover:bg-card hover:text-foreground"
              onClick={(e) => {
                e.stopPropagation()
                openEditModal(selectedCoach)
              }}
            >
              <Pencil className="h-4 w-4" />
            </button>
            <div className="absolute left-4 bottom-4 flex items-center gap-1.5">
              <span className={`h-2.5 w-2.5 rounded-full ${selectedCoach.is_active ? "bg-secondary" : "bg-error"}`} />
              <span className="text-xs text-muted-foreground">{selectedCoach.is_active ? "نشط" : "موقوف"}</span>
            </div>
          </div>
          <div className="p-5 pt-16">
            <p className="text-lg font-bold">{selectedCoach.full_name_ar}</p>
            <p className="text-sm text-muted-foreground" dir="ltr">{selectedCoach.phone}</p>

            <h3 className="mt-5 mb-3 text-sm font-bold">المجموعات المسندة</h3>
            {selectedCoachGroups.length === 0 ? (
              <p className="rounded-xl border border-border bg-surface-container-low p-4 text-center text-sm text-muted-foreground">
                لا مجموعات مسندة لهذا المدرب.
              </p>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {selectedCoachGroups.map((g) => (
                  <div key={g.id} className="rounded-xl border border-border bg-surface-container-low p-3">
                    <p className="text-sm font-semibold">{g.name_ar}</p>
                    <p className="text-xs text-muted-foreground" dir="ltr">{g.start_time} - {g.end_time}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Modal */}
      <AnimatePresence>
        {showModal && (
          <motion.div animate={{ opacity: 1 }} className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" exit={{ opacity: 0 }} initial={{ opacity: 0 }} onClick={closeModal}>
            <motion.div animate={{ opacity: 1, scale: 1 }} className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-border bg-card p-5" exit={{ opacity: 0, scale: 0.96 }} initial={{ opacity: 0, scale: 0.96 }} onClick={(e) => e.stopPropagation()}>
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">{editingCoach ? "تعديل مدرب" : "إضافة مدرب جديد"}</h3>
                <button aria-label="close" className="text-muted-foreground hover:text-foreground" onClick={closeModal} type="button"><X className="h-5 w-5" /></button>
              </div>
              <form className="space-y-3" onSubmit={handleSubmit}>
                <div className="grid grid-cols-2 gap-3">
                  <div><label className="mb-1 block text-xs text-muted-foreground">الاسم</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={form.first_name_ar} onChange={(e) => setForm((p) => ({ ...p, first_name_ar: e.target.value }))} required /></div>
                  <div><label className="mb-1 block text-xs text-muted-foreground">اللقب</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={form.last_name_ar} onChange={(e) => setForm((p) => ({ ...p, last_name_ar: e.target.value }))} /></div>
                </div>
                <div><label className="mb-1 block text-xs text-muted-foreground">رقم الهاتف</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={form.phone} onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))} required /></div>
                <div><label className="mb-1 block text-xs text-muted-foreground">كلمة المرور {editingCoach && "(ترك فارغ = لا تغيير)"}</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="password" value={form.password} onChange={(e) => setForm((p) => ({ ...p, password: e.target.value }))} required={!editingCoach} minLength={8} /></div>
                <div>
                  <label className="mb-1 block text-xs text-muted-foreground">صورة شخصية</label>
                  <div className="flex items-center gap-3">
                    {photoFile ? (
                      <img src={URL.createObjectURL(photoFile)} alt="preview" className="h-16 w-16 rounded-xl object-cover" />
                    ) : editingCoach?.photo ? (
                      <img src={editingCoach.photo} alt={editingCoach.full_name_ar} className="h-16 w-16 rounded-xl object-cover" />
                    ) : (
                      <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-muted"><Dumbbell className="h-6 w-6 text-muted-foreground" /></div>
                    )}
                    <button type="button" onClick={() => fileInputRef.current?.click()} className="rounded-xl border border-border px-3 py-2 text-xs">اختر صورة</button>
                    <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={(e) => setPhotoFile(e.target.files?.[0] || null)} />
                  </div>
                </div>
                {modalError && <p className="text-xs text-error">{modalError}</p>}
                <div className="flex justify-end gap-2"><Button type="button" variant="ghost" onClick={closeModal}>إلغاء</Button><Button type="submit" disabled={submitting}>{submitting ? "جارٍ..." : "حفظ"}</Button></div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}