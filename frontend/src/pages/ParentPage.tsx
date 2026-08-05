import { useState, useRef, type ChangeEvent, type FormEvent } from "react"
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { motion } from "framer-motion"
import {
  ArrowRight, Users, Phone, MapPin, CheckCircle2, Clock, XCircle,
  UserPlus, ImagePlus, Loader2, X, AlertCircle, ChevronRight, Sparkles, Pencil,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { api } from "@/lib/api"
import { useToast } from "@/lib/toast"
import { extractResults } from "@/lib/response"

interface ParentRegistration {
  id: number
  user: number
  user_name: string
  user_phone: string
  residence: string
  status: "pending" | "approved" | "rejected"
  created_at: string
  athlete_id: number | null
}

interface ChildAthlete {
  id: number
  full_name: string
  phone: string
  photo: string | null
  birth_date: string | null
  health_status: string
  residence: string
  membership_number: string
  department: number | null
  department_name: string | null
  sport: number | null
  is_active: boolean
}

const defaultChildForm = {
  full_name: "",
  birth_day: "",
  birth_month: "",
  birth_year: "",
  health_status: "",
}

const inputCls = "w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"

function formatDate(d?: string | null) {
  if (!d) return "—"
  return new Date(d).toLocaleDateString("ar-SA-u-nu-latn", {
    year: "numeric", month: "short", day: "numeric",
  })
}

export default function ParentPage() {
  const navigate = useNavigate()
  const toast = useToast()
  const queryClient = useQueryClient()
  const { id } = useParams()
  const [searchParams] = useSearchParams()
  const deptParam = searchParams.get("department")
  const sportParam = searchParams.get("sport")
  const photoInputRef = useRef<HTMLInputElement>(null)

  const [showAddModal, setShowAddModal] = useState(false)
  const [childForm, setChildForm] = useState(defaultChildForm)
  const [childPhoto, setChildPhoto] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState("")

  const [showEditModal, setShowEditModal] = useState(false)
  const [editForm, setEditForm] = useState({ full_name: "", whatsapp_phone: "", residence: "" })
  const [editSubmitting, setEditSubmitting] = useState(false)
  const [editError, setEditError] = useState("")

  const { data: regData, isLoading: regLoading, refetch: refetchParent } = useQuery({
    queryKey: ["parent-registration", id],
    queryFn: () =>
      api.get<{ results: ParentRegistration[] } | ParentRegistration[]>(
        "/athletes/registrations/",
        { role_choice: "parent", user: String(id) },
      ),
    enabled: !!id,
  })
  const regs = regData ? extractResults<ParentRegistration>(regData as any) : []
  const parent = regs[0]

  const { data: userData } = useQuery({
    queryKey: ["user-parent-fallback", id],
    queryFn: () => api.get<{ id: number; full_name_ar: string; phone: string; residence?: string }>(`/auth/users/${id}/`),
    enabled: !!id,
  })

  const parentName = parent?.user_name || userData?.full_name_ar || "ولي الأمر"
  const parentPhone = parent?.user_phone || userData?.phone || "—"
  const parentResidence = parent?.residence || userData?.residence || "—"

  const openEditModal = () => {
    setEditForm({
      full_name: parentName,
      whatsapp_phone: parentPhone !== "—" ? parentPhone : "",
      residence: parentResidence !== "—" ? parentResidence : "",
    })
    setEditError("")
    setShowEditModal(true)
  }

  const submitParentEdit = async (e: FormEvent) => {
    e.preventDefault()
    setEditError("")
    if (!parent) return
    if (!editForm.full_name.trim()) {
      setEditError("يرجى إدخال اسم ولي الأمر")
      return
    }

    try {
      setEditSubmitting(true)
      await api.patch(`/athletes/registrations/${parent.id}/parent-update/`, {
        full_name: editForm.full_name.trim(),
        whatsapp_phone: editForm.whatsapp_phone.trim(),
        residence: editForm.residence.trim(),
      })
      toast.success("تم تحديث بيانات ولي الأمر بنجاح")
      setShowEditModal(false)
      await refetchParent()
      await queryClient.invalidateQueries({ queryKey: ["parents-registrations"] })
    } catch (err: any) {
      setEditError(api.getErrorMessage(err, "تعذر تحديث البيانات"))
    } finally {
      setEditSubmitting(false)
    }
  }

  const { data: childrenData, isLoading: childrenLoading, refetch: refetchChildren } = useQuery({
    queryKey: ["parent-children", id, deptParam],
    queryFn: () =>
      api.get<ChildAthlete[]>("/athletes/parent/athletes/children_of/", {
        parent_id: String(id),
        ...(deptParam ? { department: deptParam } : {}),
      }),
    enabled: !!id,
  })
  const children = childrenData ? extractResults<ChildAthlete>(childrenData as any) : []

  const onChildPhotoFile = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result
      if (typeof result === "string") setChildPhoto(result)
    }
    reader.readAsDataURL(file)
    event.target.value = ""
  }

  const openAddModal = () => {
    setChildForm(defaultChildForm)
    setChildPhoto(null)
    setError("")
    setShowAddModal(true)
  }

  const submitChild = async (e: FormEvent) => {
    e.preventDefault()
    setError("")
    if (!id || !childForm.full_name.trim() || !childForm.birth_day || !childForm.birth_month || !childForm.birth_year) {
      setError("يرجى استكمال الاسم وتاريخ الميلاد")
      return
    }

    try {
      setSubmitting(true)
      const body: Record<string, any> = {
        parent_id: Number(id),
        full_name: childForm.full_name.trim(),
        birth_day: parseInt(childForm.birth_day),
        birth_month: parseInt(childForm.birth_month),
        birth_year: parseInt(childForm.birth_year),
        health_status: childForm.health_status,
      }
      if (childPhoto) body.photo = childPhoto
      if (sportParam) body.sport = Number(sportParam)

      await api.post("/athletes/parent/athletes/", body)
      toast.success("تمت إضافة الابن بنجاح")
      setShowAddModal(false)
      await refetchChildren()
      await queryClient.invalidateQueries({ queryKey: ["athletes"] })
      await queryClient.invalidateQueries({ queryKey: ["parents-registrations"] })
    } catch (err: any) {
      setError(api.getErrorMessage(err, "تعذر إضافة الابن"))
    } finally {
      setSubmitting(false)
    }
  }

  const statusBadge = () => {
    if (!parent) return null
    if (parent.status === "approved") return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-600 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">
        <CheckCircle2 className="w-3 h-3" /> مقبول
      </span>
    )
    if (parent.status === "pending") return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-600 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full">
        <Clock className="w-3 h-3" /> قيد المراجعة
      </span>
    )
    return (
      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-red-600 bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">
        <XCircle className="w-3 h-3" /> مرفوض
      </span>
    )
  }

  return (
    <motion.div
      className="space-y-8"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, transition: { staggerChildren: 0.06 } }}
    >
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none" />

      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <Link
            to={`/dashboard/parents${deptParam ? `?department=${deptParam}` : ""}`}
            className="flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-card text-muted-foreground hover:text-primary hover:border-primary/40 transition-colors"
            aria-label="رجوع"
          >
            <ChevronRight className="w-4 h-4" />
          </Link>
          <div>
            <h1 className="text-2xl font-extrabold gradient-text">صفحة ولي الأمر</h1>
            <p className="text-sm text-muted-foreground mt-0.5">إدارة بيانات ولي الأمر والأبناء الرياضيين.</p>
          </div>
        </div>
        <Button className="bg-primary text-primary-foreground hover:bg-primary/90 rounded-xl font-bold" onClick={openAddModal}>
          <UserPlus className="w-4 h-4" />
          إضافة ابن / ابنة
        </Button>
      </div>

      {/* Parent info */}
      <motion.div className="glass-card rounded-3xl p-6 md:p-8">
        {regLoading && (
          <div className="flex items-center justify-center gap-2 py-8 text-muted-foreground text-sm">
            <Loader2 className="w-4 h-4 animate-spin" /> جاري تحميل البيانات...
          </div>
        )}
        {!regLoading && !parent && !userData && (
          <div className="flex flex-col items-center justify-center gap-3 py-8 text-muted-foreground">
            <AlertCircle className="w-8 h-8 opacity-40" />
            <p className="text-sm">لم يتم العثور على ولي الأمر</p>
          </div>
        )}
        {(parent || userData) && (
          <div className="flex flex-col md:flex-row gap-6 items-start md:items-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-600 shrink-0">
              <Users className="w-8 h-8" />
            </div>
            <div className="flex-1 space-y-3">
              <div className="flex flex-wrap items-center gap-3">
                <h2 className="text-xl font-extrabold">{parentName}</h2>
                {statusBadge()}
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-2 text-sm">
                <p className="flex items-center gap-2 text-muted-foreground">
                  <Phone className="w-4 h-4 text-primary" />
                  <span dir="ltr">{parentPhone}</span>
                  <span className="text-[10px] bg-primary/10 text-primary px-1.5 py-0.5 rounded-full">الهاتف</span>
                </p>
                <p className="flex items-center gap-2 text-muted-foreground">
                  <MapPin className="w-4 h-4 text-primary" />
                  {parentResidence}
                </p>
              </div>
              {parent?.created_at && (
                <p className="text-xs text-muted-foreground">
                  تاريخ التسجيل: {formatDate(parent.created_at)}
                </p>
              )}
            </div>
            <Button type="button" variant="outline" onClick={openEditModal}>
              <Pencil className="w-4 h-4" />
              تعديل البيانات
            </Button>
          </div>
        )}
      </motion.div>

      {/* Children */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h3 className="section-header">الأبناء الرياضيون</h3>
          <span className="text-xs text-muted-foreground font-semibold">{children.length} ابن</span>
        </div>

        {childrenLoading ? (
          <div className="flex items-center justify-center gap-2 py-12 text-muted-foreground text-sm">
            <Loader2 className="w-4 h-4 animate-spin" /> جاري تحميل الأبناء...
          </div>
        ) : children.length === 0 ? (
          <div className="glass-card rounded-3xl flex flex-col items-center justify-center gap-3 py-14 text-muted-foreground">
            <UserPlus className="w-10 h-10 opacity-30" />
            <p className="text-sm font-semibold">لا يوجد أبناء مسجلون لهذا ولي الأمر</p>
            <Button variant="outline" size="sm" onClick={openAddModal}>
              <UserPlus className="w-4 h-4" />
              إضافة ابن / ابنة
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {children.map((child) => (
              <motion.div
                key={child.id}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                whileHover={{ y: -3 }}
                className="glass-card rounded-2xl p-5 cursor-pointer transition-all"
                onClick={() => navigate(`/dashboard/athletes/${child.id}`)}
              >
                <div className="flex items-center gap-3">
                  {child.photo ? (
                    <img src={child.photo} alt={child.full_name} className="h-14 w-14 rounded-full object-cover border-2 border-primary/20 shrink-0" />
                  ) : (
                    <div className="flex h-14 w-14 items-center justify-center rounded-full bg-surface-container-high text-primary text-lg font-bold shrink-0">
                      {(child.full_name || "?").charAt(0)}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <h4 className="font-bold truncate">{child.full_name}</h4>
                    <p className="text-[11px] text-muted-foreground mt-0.5" dir="ltr">
                      {child.membership_number || "—"}
                    </p>
                  </div>
                  <Sparkles className="w-4 h-4 text-amber-500 shrink-0" />
                </div>
                <div className="mt-4 grid grid-cols-2 gap-2 text-xs text-muted-foreground">
                  <p>تاريخ الميلاد: <span className="text-foreground font-semibold">{formatDate(child.birth_date)}</span></p>
                  <p>الأكاديمية: <span className="text-foreground font-semibold">{child.department_name || "—"}</span></p>
                </div>
                {child.health_status && (
                  <p className="mt-3 rounded-xl border border-error/20 bg-error/5 px-3 py-2 text-[11px] text-error">
                    {child.health_status}
                  </p>
                )}
                <div className="mt-4 flex items-center justify-between">
                  <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${
                    child.is_active ? "bg-secondary/10 text-secondary" : "bg-error/10 text-error"
                  }`}>
                    {child.is_active ? "نشط" : "غير مفعل"}
                  </span>
                  <span className="text-[11px] font-bold text-primary flex items-center gap-1">
                    فتح الملف <ArrowRight className="w-3 h-3" />
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {/* Add child modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => setShowAddModal(false)}>
          <form
            className="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl border border-border bg-card p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
            onSubmit={submitChild}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">إضافة ابن / ابنة</h3>
              <button type="button" onClick={() => setShowAddModal(false)}>
                <X className="w-5 h-5 text-muted-foreground" />
              </button>
            </div>

            <div className="flex items-center gap-3">
              {childPhoto ? (
                <div className="w-16 h-16 rounded-full overflow-hidden border-2 border-primary shrink-0">
                  <img src={childPhoto} alt="" className="w-full h-full object-cover" />
                </div>
              ) : (
                <div className="w-16 h-16 rounded-full bg-surface-container-high flex items-center justify-center border-2 border-dashed border-border shrink-0">
                  <ImagePlus className="w-6 h-6 text-muted-foreground" />
                </div>
              )}
              <div className="space-y-1">
                <Button type="button" variant="outline" size="sm" onClick={() => photoInputRef.current?.click()}>
                  <ImagePlus className="w-4 h-4 ml-1" />
                  صورة شخصية (اختياري)
                </Button>
                {childPhoto && (
                  <button type="button" className="block text-xs text-error font-semibold hover:underline" onClick={() => setChildPhoto(null)}>
                    إزالة الصورة
                  </button>
                )}
              </div>
            </div>
            <input ref={photoInputRef} type="file" accept="image/*" className="hidden" onChange={onChildPhotoFile} />

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">اسم الابن بالكامل <span className="text-error">*</span></label>
              <input
                className={inputCls}
                value={childForm.full_name}
                onChange={(e) => setChildForm((p) => ({ ...p, full_name: e.target.value }))}
                placeholder="أدخل اسم الابن الرباعي"
                required
              />
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">تاريخ الميلاد <span className="text-error">*</span></label>
              <div className="grid grid-cols-3 gap-2">
                <input type="number" min={1} max={31} placeholder="اليوم" className={inputCls + " text-center"} value={childForm.birth_day} onChange={(e) => setChildForm((p) => ({ ...p, birth_day: e.target.value }))} required />
                <input type="number" min={1} max={12} placeholder="الشهر" className={inputCls + " text-center"} value={childForm.birth_month} onChange={(e) => setChildForm((p) => ({ ...p, birth_month: e.target.value }))} required />
                <input type="number" min={1900} max={2026} placeholder="السنة" className={inputCls + " text-center"} value={childForm.birth_year} onChange={(e) => setChildForm((p) => ({ ...p, birth_year: e.target.value }))} required />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">الحالة الصحية / ملاحظات طبية</label>
              <textarea
                rows={2}
                className={inputCls + " resize-none"}
                value={childForm.health_status}
                onChange={(e) => setChildForm((p) => ({ ...p, health_status: e.target.value }))}
                placeholder="أدخل أي حالة صحية أو ملاحظات طبية خاصة..."
              />
            </div>

            {error && (
              <div className="flex items-center gap-2 rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">
                <AlertCircle className="w-4 h-4 shrink-0" />
                {error}
              </div>
            )}

            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setShowAddModal(false)}>إلغاء</Button>
              <Button type="submit" disabled={submitting}>
                {submitting ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span> : "إضافة الابن"}
              </Button>
            </div>
          </form>
        </div>
      )}
      {/* Edit parent modal */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => setShowEditModal(false)}>
          <form
            className="w-full max-w-lg rounded-2xl border border-border bg-card p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
            onSubmit={submitParentEdit}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold">تعديل بيانات ولي الأمر</h3>
              <button type="button" onClick={() => setShowEditModal(false)}>
                <X className="w-5 h-5 text-muted-foreground" />
              </button>
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">الاسم بالكامل <span className="text-error">*</span></label>
              <input
                className={inputCls}
                value={editForm.full_name}
                onChange={(e) => setEditForm((p) => ({ ...p, full_name: e.target.value }))}
                placeholder="أدخل اسم ولي الأمر"
                required
              />
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">رقم الهاتف (الواتساب)</label>
              <input
                className={inputCls}
                dir="ltr"
                value={editForm.whatsapp_phone}
                onChange={(e) => setEditForm((p) => ({ ...p, whatsapp_phone: e.target.value }))}
                placeholder="09xxxxxxxx"
              />
            </div>

            <div>
              <label className="mb-1 block text-xs text-muted-foreground">السكن / العنوان</label>
              <input
                className={inputCls}
                value={editForm.residence}
                onChange={(e) => setEditForm((p) => ({ ...p, residence: e.target.value }))}
                placeholder="أدخل السكن أو العنوان"
              />
            </div>

            {editError && (
              <div className="flex items-center gap-2 rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">
                <AlertCircle className="w-4 h-4 shrink-0" />
                {editError}
              </div>
            )}

            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => setShowEditModal(false)}>إلغاء</Button>
              <Button type="submit" disabled={editSubmitting}>
                {editSubmitting ? <span className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> جاري...</span> : "حفظ التعديلات"}
              </Button>
            </div>
          </form>
        </div>
      )}
    </motion.div>
  )
}
