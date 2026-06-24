import React, { useState, useRef } from "react"
import { motion, type Variants } from "framer-motion"
import { useNavigate } from "react-router-dom"
import {
  ArrowRight, User, Phone, Calendar, UserCheck, Tag, AlertCircle,
  FileText, Loader2, ChevronDown, Camera, X,
} from "lucide-react"
import { Link } from "react-router-dom"
import { useCreateAthlete } from "@/lib/hooks/useAthletes"
import { useDepartments } from "@/lib/hooks/useDepartments"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] } },
}

const photoVariants: Variants = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}

export default function AddAthletePage() {
  const navigate = useNavigate()
  const { data: deptData } = useDepartments()
  const createAthlete = useCreateAthlete()
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [dragOver, setDragOver] = useState(false)
  const [focusedField, setFocusedField] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

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

  const handleFile = (file: File) => {
    if (!file.type.startsWith("image/")) {
      setErrorMessage("الرجاء اختيار صورة بصيغة صالحة")
      return
    }
    if (file.size > 5 * 1024 * 1024) {
      setErrorMessage("حجم الصورة يجب ألا يتجاوز 5 ميجابايت")
      return
    }
    setErrorMessage(null)
    setPhotoFile(file)
    const reader = new FileReader()
    reader.onloadend = () => setPhotoPreview(reader.result as string)
    reader.readAsDataURL(file)
  }

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) handleFile(file)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setDragOver(false)
    const file = e.dataTransfer.files?.[0]
    if (file) handleFile(file)
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setDragOver(true)
  }

  const handleDragLeave = () => setDragOver(false)

  const removePhoto = () => {
    setPhotoFile(null)
    setPhotoPreview(null)
    if (fileInputRef.current) fileInputRef.current.value = ""
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

  const isFloating = (field: string) => focusedField === field || (form as any)[field].length > 0

  const FloatField = ({
    field,
    label,
    Icon,
    type = "text",
    required = false,
  }: {
    field: string
    label: string
    Icon: React.ComponentType<any>
    type?: string
    required?: boolean
  }) => {
    const floating = isFloating(field)
    return (
      <div className="relative group">
        <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none z-10 transition-colors duration-300 text-muted-foreground/40 group-focus-within:text-primary">
          <Icon className="w-4 h-4" />
        </div>
        <input
          type={type}
          placeholder=" "
          value={(form as any)[field]}
          onChange={(e) => update(field, e.target.value)}
          onFocus={() => setFocusedField(field)}
          onBlur={() => setFocusedField(null)}
          required={required}
          dir="rtl"
          className="w-full bg-surface-container-low text-sm text-foreground rounded-xl pt-5 pb-2 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary/20 focus:border-primary focus:bg-white outline-none transition-all duration-300 peer"
        />
        <label
          className={`absolute right-10 pointer-events-none transition-all duration-200 ${
            floating
              ? "top-2 text-[11px] font-medium text-primary"
              : "top-1/2 -translate-y-1/2 text-sm text-muted-foreground/60"
          }`}
        >
          {label}
          {required && <span className="text-error mr-0.5">*</span>}
        </label>
      </div>
    )
  }

  const TextareaField = ({
    field,
    label,
    Icon,
    required = false,
  }: {
    field: string
    label: string
    Icon: React.ComponentType<any>
    required?: boolean
  }) => {
    const floating = isFloating(field)
    return (
      <div className="relative group">
        <div className="absolute right-3 top-4 pointer-events-none z-10 transition-colors duration-300 text-muted-foreground/40 group-focus-within:text-primary">
          <Icon className="w-4 h-4" />
        </div>
        <textarea
          placeholder=" "
          value={(form as any)[field]}
          onChange={(e) => update(field, e.target.value)}
          onFocus={() => setFocusedField(field)}
          onBlur={() => setFocusedField(null)}
          required={required}
          dir="rtl"
          rows={4}
          className="w-full bg-surface-container-low text-sm text-foreground rounded-xl pt-5 pb-2 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary/20 focus:border-primary focus:bg-white outline-none transition-all duration-300 peer resize-none"
        />
        <label
          className={`absolute right-10 pointer-events-none transition-all duration-200 ${
            floating
              ? "top-2 text-[11px] font-medium text-primary"
              : "top-4 text-sm text-muted-foreground/60"
          }`}
        >
          {label}
        </label>
      </div>
    )
  }

  return (
    <motion.div
      className="space-y-6 select-none"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      dir="rtl"
    >
      <motion.div className="flex items-center gap-3" variants={itemVariants}>
        <Link
          to="/dashboard/athletes"
          className="text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowRight className="w-6 h-6" />
        </Link>
        <div>
          <h1 className="text-2xl font-extrabold gradient-text">إضافة رياضي جديد</h1>
          <p className="text-xs text-muted-foreground mt-1">
            تعبئة نموذج تسجيل رياضي جديد وتحديد الفرع الرياضي له.
          </p>
        </div>
      </motion.div>

      {errorMessage && (
        <motion.div
          variants={itemVariants}
          className="p-4 rounded-xl bg-error/15 border border-error/30 text-error text-sm flex items-center gap-2"
        >
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{errorMessage}</span>
        </motion.div>
      )}

      <motion.div
        className="glass-card-premium rounded-3xl p-6 md:p-8 border border-border/20 shadow-sm"
        variants={itemVariants}
      >
        <form onSubmit={handleSubmit} className="space-y-8">
          <motion.div variants={photoVariants}>
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
              className={`relative rounded-2xl border-2 border-dashed transition-all duration-300 cursor-pointer overflow-hidden ${
                dragOver
                  ? "border-primary bg-primary/5 scale-[1.02]"
                  : "border-border/40 hover:border-primary/50 hover:bg-surface-container-low"
              }`}
            >
              {photoPreview ? (
                <div className="relative flex items-center justify-center p-4">
                  <img
                    src={photoPreview}
                    alt="صورة الرياضي"
                    className="w-36 h-36 rounded-xl object-cover shadow-md"
                  />
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      removePhoto()
                    }}
                    className="absolute top-2 left-2 bg-error/90 text-white p-1.5 rounded-full shadow-md hover:bg-error transition-colors"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                  <div className="absolute inset-0 bg-black/0 hover:bg-black/10 transition-colors rounded-2xl" />
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center gap-3 py-10 px-4">
                  <div className="w-14 h-14 rounded-full bg-surface-container flex items-center justify-center group-hover:bg-primary/10 transition-colors duration-300">
                    <Camera className="w-6 h-6 text-muted-foreground/60 group-hover:text-primary transition-colors duration-300" />
                  </div>
                  <div className="text-center">
                    <p className="text-sm font-semibold text-foreground">
                      اسحب وأفلت الصورة هنا
                    </p>
                    <p className="text-xs text-muted-foreground/60 mt-1">
                      أو اضغط لاختيار صورة
                    </p>
                  </div>
                  <p className="text-[11px] text-muted-foreground/40">
                    JPG, PNG - الحد الأقصى 5MB
                  </p>
                </div>
              )}
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handlePhotoUpload}
                className="hidden"
              />
            </div>
          </motion.div>

          <div className="space-y-5">
            <motion.div variants={itemVariants} className="section-header">
              <h3 className="gradient-text text-base font-bold">المعلومات الشخصية</h3>
              <div className="h-px w-full bg-gradient-to-l from-primary/40 via-primary/10 to-transparent rounded-full" />
            </motion.div>

            <motion.div
              variants={itemVariants}
              className="grid grid-cols-1 md:grid-cols-2 gap-5"
            >
              <FloatField field="fullName" label="الاسم الكامل للرياضي" Icon={User} required />
              <FloatField field="birthDate" label="تاريخ الميلاد" Icon={Calendar} type="date" required />

              <div className="relative group">
                <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none z-10 transition-colors duration-300 text-muted-foreground/40 group-focus-within:text-primary">
                  <UserCheck className="w-4 h-4" />
                </div>
                <div className="bg-surface-container-low border border-border/40 rounded-xl overflow-hidden transition-all duration-300 focus-within:ring-2 focus-within:ring-primary/20 focus-within:border-primary">
                  <div className="flex gap-1 p-1">
                    {["male", "female"].map((g) => (
                      <button
                        key={g}
                        type="button"
                        onClick={() => update("gender", g)}
                        className={`flex-1 py-2.5 px-4 rounded-lg text-sm font-semibold transition-all duration-300 ${
                          form.gender === g
                            ? "bg-primary text-primary-foreground shadow-md shadow-primary/25"
                            : "text-muted-foreground hover:text-foreground bg-transparent"
                        }`}
                      >
                        {g === "male" ? "ذكر" : "أنثى"}
                      </button>
                    ))}
                  </div>
                </div>
                <label className="absolute -top-2.5 right-3 px-1.5 text-[11px] font-medium text-primary bg-surface-container-low rounded">
                  الجنس
                  <span className="text-error mr-0.5">*</span>
                </label>
              </div>
            </motion.div>
          </div>

          <div className="space-y-5">
            <motion.div variants={itemVariants} className="section-header">
              <h3 className="gradient-text text-base font-bold">معلومات الاتصال</h3>
              <div className="h-px w-full bg-gradient-to-l from-primary/40 via-primary/10 to-transparent rounded-full" />
            </motion.div>

            <motion.div
              variants={itemVariants}
              className="grid grid-cols-1 md:grid-cols-2 gap-5"
            >
              <FloatField field="phone" label="رقم الهاتف" Icon={Phone} type="tel" required />
              <FloatField field="parentPhone" label="رقم هاتف ولي الأمر" Icon={Phone} type="tel" />
            </motion.div>
          </div>

          <div className="space-y-5">
            <motion.div variants={itemVariants} className="section-header">
              <h3 className="gradient-text text-base font-bold">تفاصيل إضافية</h3>
              <div className="h-px w-full bg-gradient-to-l from-primary/40 via-primary/10 to-transparent rounded-full" />
            </motion.div>

            <motion.div
              variants={itemVariants}
              className="grid grid-cols-1 md:grid-cols-2 gap-5"
            >
              <div className="relative group">
                <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none z-10 transition-colors duration-300 text-muted-foreground/40 group-focus-within:text-primary">
                  <Tag className="w-4 h-4" />
                </div>
                <select
                  value={form.department}
                  onChange={(e) => update("department", e.target.value)}
                  onFocus={() => setFocusedField("department")}
                  onBlur={() => setFocusedField(null)}
                  required
                  dir="rtl"
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-xl pt-5 pb-2 pr-10 pl-10 border border-border/40 focus:ring-2 focus:ring-primary/20 focus:border-primary focus:bg-white outline-none transition-all duration-300 appearance-none cursor-pointer"
                >
                  <option value="" disabled></option>
                  {departments.map((d: any) => (
                    <option key={d.id} value={d.id}>
                      {d.name_ar}
                    </option>
                  ))}
                </select>
                <label
                  className={`absolute right-10 pointer-events-none transition-all duration-200 ${
                    isFloating("department")
                      ? "top-2 text-[11px] font-medium text-primary"
                      : "top-1/2 -translate-y-1/2 text-sm text-muted-foreground/60"
                  }`}
                >
                  الفرع / القسم الرياضي
                  <span className="text-error mr-0.5">*</span>
                </label>
                <ChevronDown className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground/40 pointer-events-none transition-colors duration-300 group-focus-within:text-primary" />
              </div>
            </motion.div>

            <motion.div variants={itemVariants}>
              <TextareaField field="notes" label="ملاحظات إضافية" Icon={FileText} />
            </motion.div>
          </div>

          <motion.div
            variants={itemVariants}
            className="flex justify-end gap-3 pt-6 border-t border-border/20"
          >
            <Link to="/dashboard/athletes">
              <button
                type="button"
                className="px-6 py-3 rounded-xl border-2 border-border/60 text-sm font-semibold text-muted-foreground hover:bg-surface-container hover:text-foreground hover:border-border transition-all duration-300"
              >
                إلغاء
              </button>
            </Link>
            <button
              type="submit"
              disabled={createAthlete.isPending}
              className="relative overflow-hidden px-8 py-3 rounded-xl bg-gradient-to-l from-primary to-primary/80 text-primary-foreground font-semibold text-sm shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/30 hover:from-primary/90 hover:to-primary/70 active:scale-[0.98] transition-all duration-300 disabled:opacity-60 disabled:cursor-not-allowed disabled:active:scale-100"
            >
              {createAthlete.isPending ? (
                <span className="flex items-center gap-2">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  جاري الحفظ...
                </span>
              ) : (
                "حفظ البيانات"
              )}
            </button>
          </motion.div>
        </form>
      </motion.div>
    </motion.div>
  )
}
