import { useEffect, useState, type FormEvent } from "react"
import { AnimatePresence, motion } from "framer-motion"
import { Plus, Pencil, X, UserCog, ShieldCheck, SearchIcon, Trash2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import { validateLibyanPhone } from "@/lib/utils"
import { useToast } from "@/lib/toast"

type StaffUser = {
  id: number
  phone: string
  first_name_ar: string
  last_name_ar: string
  full_name_ar: string
  role: string
  is_active: boolean
  photo: string | null
  academy: number | null
  academy_name: string
}

type Department = {
  id: number
  name_ar: string
  name: string
}

const ROLE_LABELS: Record<string, string> = {
  super_admin: "مدير عام",
  reception: "موظف استقبال",
  academy_manager: "مدير أكاديمية",
  trainer: "مدرب",
  viewer: "مشاهد",
}

const ROLE_COLORS: Record<string, string> = {
  super_admin: "bg-primary/10 text-primary",
  reception: "bg-secondary/10 text-secondary",
  academy_manager: "bg-purple-500/10 text-purple-600",
  trainer: "bg-amber-500/10 text-amber-600",
  viewer: "bg-muted text-muted-foreground",
}

export default function StaffManagement() {
  const toast = useToast()
  const [users, setUsers] = useState<StaffUser[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [pageError, setPageError] = useState<string | null>(null)
  const [search, setSearch] = useState("")
  const [roleFilter, setRoleFilter] = useState("")
  const [submitting, setSubmitting] = useState(false)
  const [editingUser, setEditingUser] = useState<StaffUser | null>(null)
  const [showModal, setShowModal] = useState(false)

  const [form, setForm] = useState({
    first_name_ar: "",
    last_name_ar: "",
    phone: "",
    password: "",
    role: "reception",
    is_active: true,
    academy: "" as string | number,
  })
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [modalError, setModalError] = useState<string | null>(null)

  useEffect(() => {
    void fetchUsers()
    void fetchDepartments()
  }, [])

  const fetchUsers = async () => {
    setLoading(true); setPageError(null)
    try {
      const data = await api.get<{ results: StaffUser[] } | StaffUser[]>("/auth/users/")
      setUsers(extractResults(data))
    } catch { setPageError("تعذر تحميل المستخدمين") }
    finally { setLoading(false) }
  }

  const fetchDepartments = async () => {
    try {
      const data = await api.get<Department[] | { results: Department[] }>("/departments/")
      setDepartments(extractResults(data))
    } catch (e) {
      console.error("فشل تحميل الأكاديميات:", e)
    }
  }

  const filtered = (Array.isArray(users) ? users : []).filter((u) => {
    if (u.role === "athlete" || u.role === "parent") return false
    if (roleFilter && u.role !== roleFilter) return false
    if (search) {
      const q = search.toLowerCase()
      return u.full_name_ar?.toLowerCase().includes(q) || u.phone?.includes(q)
    }
    return true
  })

  const openCreateModal = () => {
    setEditingUser(null)
    setModalError(null)
    setForm({ first_name_ar: "", last_name_ar: "", phone: "", password: "", role: "reception", is_active: true, academy: "" })
    setPhotoFile(null)
    setShowModal(true)
  }

  const openEditModal = (user: StaffUser) => {
    setEditingUser(user)
    setModalError(null)
    setForm({
      first_name_ar: user.first_name_ar,
      last_name_ar: user.last_name_ar,
      phone: user.phone,
      password: "",
      role: user.role,
      is_active: user.is_active,
      academy: user.academy !== null ? user.academy : "",
    })
    setPhotoFile(null)
    setShowModal(true)
  }

  const closeModal = () => { if (!submitting) { setShowModal(false); setModalError(null); setEditingUser(null) } }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setModalError(null)

    if (!form.first_name_ar.trim() || !form.phone.trim()) {
      setModalError("الاسم ورقم الهاتف مطلوبان")
      return
    }

    const phoneErr = validateLibyanPhone(form.phone)
    if (phoneErr) { setModalError(phoneErr); return }

    if (!editingUser && !form.password.trim()) {
      setModalError("كلمة المرور مطلوبة للمستخدم الجديد")
      return
    }

    try {
      setSubmitting(true)
      const fd = new FormData()
      fd.append("first_name_ar", form.first_name_ar.trim())
      fd.append("last_name_ar", form.last_name_ar.trim())
      fd.append("phone", form.phone.trim())
      fd.append("role", form.role)
      fd.append("is_active", String(form.is_active))
      if (form.password) fd.append("password", form.password)
      if (photoFile) fd.append("photo", photoFile)

      if (form.academy !== "") {
        fd.append("academy", String(form.academy))
      } else {
        fd.append("academy", "")
      }

      if (editingUser) {
        await api.patch(`/auth/users/${editingUser.id}/`, fd, { formData: true })
        toast.success("تم تحديث المستخدم")
      } else {
        await api.post("/auth/users/", fd, { formData: true })
        toast.success("تم إنشاء المستخدم")
      }

      closeModal()
      await fetchUsers()
    } catch (err: any) {
      setModalError(err?.message || "فشل الحفظ")
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (user: StaffUser) => {
    if (!window.confirm(`هل أنت متأكد من حذف الحساب "${user.full_name_ar}" نهائياً؟`)) return
    try {
      setLoading(true)
      await api.delete(`/auth/users/${user.id}/`)
      toast.success("تم حذف المستخدم بنجاح")
      await fetchUsers()
    } catch (err: any) {
      toast.error(`فشل الحذف: ${err.message || err}`)
    } finally {
      setLoading(false)
    }
  }

  if (loading && users.length === 0) return <LoadingSpinner />

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-border bg-card p-5">
        <h2 className="text-xl font-bold">إدارة الإدارة والموظفين</h2>
        <p className="mt-1 text-xs text-muted-foreground">جدول موحد لكل الإداريين والمدربين والمشاهدين.</p>
      </div>

      {pageError && <div className="rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">{pageError}</div>}

      <div className="flex flex-col gap-3 rounded-2xl border border-border bg-card p-4 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <SearchIcon className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input className="w-full rounded-xl border border-border bg-surface-container-low py-2.5 pr-10 pl-3 text-sm outline-none" placeholder="بحث بالاسم أو الهاتف..." value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <select className="rounded-xl border border-border bg-surface-container-low px-3 py-2.5 text-sm outline-none" value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
          <option value="">جميع الأدوار</option>
          <option value="super_admin">مدير عام</option>
          <option value="reception">موظف استقبال</option>
          <option value="academy_manager">مدير أكاديمية</option>
          <option value="trainer">مدرب</option>
          <option value="viewer">مشاهد</option>
        </select>
        <Button onClick={openCreateModal}><Plus className="h-4 w-4" /> إضافة موظف</Button>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-border bg-card">
        <table className="w-full min-w-[640px] text-right text-sm">
          <thead>
            <tr className="border-b border-border text-xs text-muted-foreground">
              <th className="px-4 py-3">المستخدم</th>
              <th className="px-4 py-3">الهاتف</th>
              <th className="px-4 py-3">الدور</th>
              <th className="px-4 py-3">الأكاديمية المعين بها</th>
              <th className="px-4 py-3">الحالة</th>
              <th className="px-4 py-3 text-center">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="py-10 text-center text-muted-foreground">لا مستخدمين مطابقين</td></tr>
            )}
            {filtered.map((user) => (
              <tr key={user.id} className="border-b border-border/50 hover:bg-surface-container-low/50">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    {user.photo ? <img src={user.photo} alt={user.full_name_ar} className="h-9 w-9 rounded-full object-cover" /> : <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">{(user.full_name_ar || "?").charAt(0)}</div>}
                    <span className="font-semibold">{user.full_name_ar}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-muted-foreground" dir="ltr">{user.phone}</td>
                <td className="px-4 py-3"><span className={`rounded-full px-2.5 py-1 text-xs font-bold ${ROLE_COLORS[user.role] || ""}`}>{ROLE_LABELS[user.role] || user.role}</span></td>
                <td className="px-4 py-3 text-muted-foreground">{user.academy_name || "—"}</td>
                <td className="px-4 py-3"><span className={`inline-flex items-center gap-1 text-xs ${user.is_active ? "text-secondary" : "text-error"}`}><span className={`h-1.5 w-1.5 rounded-full ${user.is_active ? "bg-secondary" : "bg-error"}`} />{user.is_active ? "نشط" : "موقوف"}</span></td>
                <td className="px-4 py-3 text-center">
                  <div className="flex justify-center gap-1">
                    <Button size="sm" variant="ghost" onClick={() => openEditModal(user)}><Pencil className="h-4 w-4" /></Button>
                    <Button size="sm" variant="ghost" className="text-error hover:bg-error/10" onClick={() => handleDelete(user)}><Trash2 className="h-4 w-4" /></Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <AnimatePresence>
        {showModal && (
          <motion.div animate={{ opacity: 1 }} className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" exit={{ opacity: 0 }} initial={{ opacity: 0 }} onClick={closeModal}>
            <motion.div animate={{ opacity: 1, scale: 1 }} className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-border bg-card p-5" exit={{ opacity: 0, scale: 0.96 }} initial={{ opacity: 0, scale: 0.96 }} onClick={(e) => e.stopPropagation()}>
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">{editingUser ? "تعديل مستخدم" : "إضافة موظف جديد"}</h3>
                <button aria-label="close" className="text-muted-foreground hover:text-foreground" onClick={closeModal} type="button"><X className="h-5 w-5" /></button>
              </div>
              <form className="space-y-3" onSubmit={handleSubmit}>
                <div className="grid grid-cols-2 gap-3">
                  <div><label className="mb-1 block text-xs text-muted-foreground">الاسم (عربي)</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={form.first_name_ar} onChange={(e) => setForm((p) => ({ ...p, first_name_ar: e.target.value }))} required /></div>
                  <div><label className="mb-1 block text-xs text-muted-foreground">اللقب (عربي)</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={form.last_name_ar} onChange={(e) => setForm((p) => ({ ...p, last_name_ar: e.target.value }))} /></div>
                </div>
                <div><label className="mb-1 block text-xs text-muted-foreground">رقم الهاتف</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={form.phone} onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))} required /></div>
                <div><label className="mb-1 block text-xs text-muted-foreground">كلمة المرور {editingUser && "(ترك فارغ = لا تغيير)"}</label><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="password" value={form.password} onChange={(e) => setForm((p) => ({ ...p, password: e.target.value }))} required={!editingUser} minLength={8} /></div>
                
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="mb-1 block text-xs text-muted-foreground">الدور</label>
                    <select className="w-full appearance-none cursor-pointer bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={form.role} onChange={(e) => setForm((p) => ({ ...p, role: e.target.value }))}>
                      <option value="super_admin">مدير عام</option>
                      <option value="reception">موظف استقبال</option>
                      <option value="academy_manager">مدير أكاديمية</option>
                      <option value="trainer">مدرب</option>
                      <option value="viewer">مشاهد</option>
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-xs text-muted-foreground">الحالة</label>
                    <select className="w-full appearance-none cursor-pointer bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={String(form.is_active)} onChange={(e) => setForm((p) => ({ ...p, is_active: e.target.value === "true" }))}>
                      <option value="true">نشط</option>
                      <option value="false">موقوف</option>
                    </select>
                  </div>
                </div>

                {form.role !== "super_admin" && (
                  <div>
                    <label className="mb-1 block text-xs text-muted-foreground">الأكاديمية التابعة (يترك فارغاً للكل)</label>
                    <select
                      className="w-full appearance-none cursor-pointer bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors"
                      value={form.academy}
                      onChange={(e) => setForm((p) => ({ ...p, academy: e.target.value === "" ? "" : Number(e.target.value) }))}
                    >
                      <option value="">جميع الأكاديميات (كامل الصلاحية)</option>
                      {departments.map((d) => (
                        <option key={d.id} value={d.id}>{d.name_ar}</option>
                      ))}
                    </select>
                  </div>
                )}

                <div>
                  <label className="mb-1 block text-xs text-muted-foreground">صورة شخصية (اختياري)</label>
                  <input type="file" accept="image/*" className="w-full file:ml-3 file:rounded-lg file:border-0 file:bg-primary file:px-3 file:py-1.5 file:text-primary-foreground bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" onChange={(e) => setPhotoFile(e.target.files?.[0] || null)} />
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