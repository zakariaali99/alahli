import React, { useState, useRef } from "react"
import { motion, type Variants } from "framer-motion"
import { useNavigate } from "react-router-dom"
import { ArrowRight, User, Phone, Calendar, UserCheck, Tag, Upload, AlertCircle, FileText } from "lucide-react"
import { Link } from "react-router-dom"
import { useCreateAthlete } from "@/lib/hooks/useAthletes"
import { useDepartments } from "@/lib/hooks/useDepartments"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.07, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

export default function AddAthletePage() {
  const navigate = useNavigate()
  const { data: deptData } = useDepartments()
  const createAthlete = useCreateAthlete()
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const [form, setForm] = useState({
    fullName: "",
    phone: "",
    parentPhone: "",
    birthDate: "",
    gender: "male",
    department: "",
    notes: "",
  })

  const departments = deptData?.results || []

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setPhotoFile(file)
      const reader = new FileReader()
      reader.onloadend = () => setPhotoPreview(reader.result as string)
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)

    if (!form.fullName.trim() || !form.phone.trim() || !form.birthDate || !form.department) {
      setErrorMessage("الرجاء تعبئة جميع الحقول المطلوبة")
      return
    }

    const fd = new FormData()
    fd.append("full_name", form.fullName)
    fd.append("phone", form.phone)
    fd.append("birth_date", form.birthDate)
    fd.append("gender", form.gender)
    fd.append("department", form.department)
    if (form.parentPhone) fd.append("parent_phone", form.parentPhone)
    if (form.notes) fd.append("notes", form.notes)
    if (photoFile) fd.append("photo", photoFile)

    try {
      await createAthlete.mutateAsync(fd)
      navigate("/dashboard/athletes")
    } catch (err: any) {
      setErrorMessage(err.message || "حدث خطأ أثناء حفظ البيانات")
    }
  }

  const update = (field: string, value: string) => setForm((f) => ({ ...f, [field]: value }))

  return (
    <motion.div className="space-y-6 select-none" variants={containerVariants} initial="hidden" animate="visible">
      <motion.div className="flex items-center gap-3" variants={itemVariants}>
        <Link to="/dashboard/athletes" className="text-muted-foreground hover:text-foreground transition-colors">
          <ArrowRight className="w-6 h-6" />
        </Link>
        <div>
          <h1 className="text-2xl font-extrabold text-foreground">إضافة رياضي جديد</h1>
          <p className="text-xs text-muted-foreground mt-1">تعبئة نموذج تسجيل رياضي جديد وتحديد الفرع الرياضي له.</p>
        </div>
      </motion.div>

      {errorMessage && (
        <div className="p-4 rounded-xl bg-error/15 border border-error/30 text-error text-sm flex items-center gap-2">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      <motion.div className="glass-card rounded-3xl p-6 md:p-8 border border-border/20 shadow-sm" variants={itemVariants}>
        <form onSubmit={handleSubmit} className="space-y-8">
          <div className="flex flex-col sm:flex-row items-center gap-6 pb-6 border-b border-border/20">
            <div className="relative w-28 h-28 rounded-full overflow-hidden bg-surface-container border border-border/40 shrink-0 flex items-center justify-center">
              {photoPreview ? (
                <img alt="صورة الرياضي" src={photoPreview} className="object-cover w-full h-full" />
              ) : (
                <User className="w-12 h-12 text-muted-foreground" />
              )}
            </div>
            <div className="flex-1 flex flex-col items-center sm:items-start gap-2">
              <h4 className="text-sm font-bold text-foreground">صورة اللاعب الشخصية</h4>
              <p className="text-xs text-muted-foreground text-center sm:text-right">
                الرجاء رفع صورة واضحة للاعب. الصيغ المدعومة: JPG, PNG.
              </p>
              <label className="mt-2 cursor-pointer bg-primary text-primary-foreground text-xs font-semibold px-4 py-2.5 rounded-lg hover:bg-primary/95 transition-all flex items-center gap-2">
                <Upload className="w-4 h-4" />
                تحميل الصورة
                <input type="file" accept="image/*" onChange={handlePhotoUpload} className="hidden" />
              </label>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-bold text-foreground mb-2">الاسم الكامل للرياضي</label>
              <div className="relative">
                <User className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  type="text"
                  placeholder="أحمد علي الورفلي"
                  value={form.fullName}
                  onChange={(e) => update("fullName", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold text-foreground mb-2">رقم الهاتف</label>
              <div className="relative">
                <Phone className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  type="tel"
                  placeholder="0911234567"
                  value={form.phone}
                  onChange={(e) => update("phone", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold text-foreground mb-2">رقم هاتف ولي الأمر (اختياري)</label>
              <div className="relative">
                <Phone className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  type="tel"
                  placeholder="0921234567"
                  value={form.parentPhone}
                  onChange={(e) => update("parentPhone", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold text-foreground mb-2">تاريخ الميلاد</label>
              <div className="relative">
                <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <input
                  type="date"
                  value={form.birthDate}
                  onChange={(e) => update("birthDate", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold text-foreground mb-2">الجنس</label>
              <div className="relative">
                <UserCheck className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <select
                  value={form.gender}
                  onChange={(e) => update("gender", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none cursor-pointer appearance-none"
                >
                  <option value="male">ذكر</option>
                  <option value="female">أنثى</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-bold text-foreground mb-2">الفرع / القسم الرياضي</label>
              <div className="relative">
                <Tag className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
                <select
                  value={form.department}
                  onChange={(e) => update("department", e.target.value)}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none cursor-pointer appearance-none"
                  required
                >
                  <option value="">اختر القسم...</option>
                  {departments.map((d: any) => (
                    <option key={d.id} value={d.id}>{d.name_ar}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-bold text-foreground mb-2">ملاحظات إضافية</label>
            <div className="relative">
              <FileText className="absolute right-3 top-4 text-muted-foreground w-4 h-4" />
              <textarea
                rows={4}
                placeholder="أدخل أي ملاحظات..."
                value={form.notes}
                onChange={(e) => update("notes", e.target.value)}
                className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
              />
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-border/20">
            <Link to="/dashboard/athletes">
              <button
                type="button"
                className="px-6 py-3 rounded-xl border border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container transition-all"
              >
                إلغاء
              </button>
            </Link>
            <button
              type="submit"
              disabled={createAthlete.isPending}
              className="bg-primary text-primary-foreground font-semibold px-8 py-3 rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all text-sm disabled:opacity-50"
            >
              {createAthlete.isPending ? "جاري الحفظ..." : "حفظ البيانات"}
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  )
}
