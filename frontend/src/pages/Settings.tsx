import React, { useState, useEffect } from "react"
import { motion, AnimatePresence, type Variants } from "framer-motion"
import {
  User,
  Bell,
  Shield,
  Palette,
  Save,
  Eye,
  EyeOff,
  Moon,
  Sun,
  SunDim,
  VolumeX,
  BellRing,
  UserPlus,
  CreditCard,
  AlertTriangle,
  Smartphone,
  Lock,
  CheckCircle2,
  ChevronLeft,
  BadgeCheck,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { useAuth } from "@/lib/auth"
import { api } from "@/lib/api"
import { usePreferences, useUpdatePreferences } from "@/lib/hooks/usePreferences"

type SettingsTab = "profile" | "notifications" | "security" | "appearance"

const tabs: { key: SettingsTab; label: string; icon: React.ElementType }[] = [
  { key: "profile", label: "الملف الشخصي", icon: User },
  { key: "notifications", label: "الإشعارات", icon: Bell },
  { key: "security", label: "الأمان", icon: Shield },
  { key: "appearance", label: "المظهر", icon: Palette },
]

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.45, ease: [0.22, 1, 0.36, 1] } },
}

const tabContentVariants: Variants = {
  hidden: { opacity: 0, x: 30 },
  visible: { opacity: 1, x: 0, transition: { duration: 0.35, ease: [0.22, 1, 0.36, 1] } },
  exit: { opacity: 0, x: -30, transition: { duration: 0.2 } },
}

const toggleVariants: Variants = {
  off: { x: 0 },
  on: { x: "100%" },
}

const roleLabel: Record<string, string> = {
  super_admin: "مدير النظام",
  reception: "موظف استقبال",
  viewer: "مشاهد",
}

const roleGradient: Record<string, string> = {
  super_admin: "from-violet-500 to-purple-600",
  reception: "from-emerald-500 to-teal-500",
  viewer: "from-amber-500 to-orange-500",
}

const notificationItems = [
  { label: "انتهاء الاشتراكات", desc: "تنبيه عند اقتراب موعد انتهاء اشتراك أي لاعب", icon: AlertTriangle, field: "notifications_enabled" as const },
  { label: "التسجيلات الجديدة", desc: "تنبيه عند تسجيل لاعب جديد في النظام", icon: UserPlus, field: "notifications_enabled" as const },
  { label: "المدفوعات", desc: "تنبيه عند تأكيد عملية دفع أو تجديد", icon: CreditCard, field: "email_enabled" as const },
  { label: "النظام", desc: "تنبيهات الصيانة والتحديثات الأسبوعية", icon: Smartphone, field: "sms_enabled" as const },
]

function Toggle({ checked, onChange, id }: { checked: boolean; onChange: () => void; id?: string }) {
  return (
    <button
      id={id}
      role="switch"
      aria-checked={checked}
      onClick={onChange}
      className={`relative inline-flex w-12 h-7 rounded-full transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:ring-offset-2 focus:ring-offset-transparent ${
        checked ? "bg-primary shadow-sm shadow-primary/30" : "bg-border/60"
      }`}
    >
      <motion.span
        layout
        transition={{ type: "spring", stiffness: 500, damping: 30 }}
        className={`absolute top-[3px] start-[3px] w-[22px] h-[22px] rounded-full bg-white shadow-sm ${
          checked ? "translate-x-full rtl:-translate-x-full" : ""
        }`}
      />
    </button>
  )
}

function TabPanel({ children, active }: { children: React.ReactNode; active: boolean }) {
  return (
    <AnimatePresence mode="wait">
      {active && (
        <motion.div
          key="panel"
          variants={tabContentVariants}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export default function SettingsPage() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState<SettingsTab>("profile")
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [messageType, setMessageType] = useState<"success" | "error">("success")
  const [showOldPw, setShowOldPw] = useState(false)
  const [showNewPw, setShowNewPw] = useState(false)
  const [passwordForm, setPasswordForm] = useState({ oldPassword: "", newPassword: "" })

  const { data: prefs } = usePreferences()
  const updatePrefs = useUpdatePreferences()

  const toggleNotif = (key: "notifications_enabled" | "sms_enabled" | "email_enabled") => {
    updatePrefs.mutate({ [key]: !(prefs ? prefs[key] : true) })
  }

  const [darkMode, setDarkMode] = useState(() => localStorage.getItem("theme") === "dark")
  const [reduceMotion, setReduceMotion] = useState(false)

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add("dark")
      localStorage.setItem("theme", "dark")
    } else {
      document.documentElement.classList.remove("dark")
      localStorage.setItem("theme", "light")
    }
  }, [darkMode])

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setMessage(null)
    try {
      await api.post("/auth/change-password/", {
        old_password: passwordForm.oldPassword,
        new_password: passwordForm.newPassword,
      })
      setMessageType("success")
      setMessage("تم تغيير كلمة المرور بنجاح")
      setPasswordForm({ oldPassword: "", newPassword: "" })
    } catch (err: any) {
      setMessageType("error")
      setMessage(err?.data?.old_password?.[0] || err?.message || "فشل تغيير كلمة المرور")
    } finally {
      setSaving(false)
    }
  }

  const showMessage = (text: string, type: "success" | "error") => {
    setMessage(text)
    setMessageType(type)
  }

  const role = user?.role || "super_admin"

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6 select-none"
      dir="rtl"
    >
      <motion.div variants={itemVariants} className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-extrabold gradient-text">الإعدادات</h1>
          <p className="text-muted-foreground mt-1.5 text-sm">
            إدارة إعدادات حسابك وتخصيص تفضيلات النظام.
          </p>
        </div>
      </motion.div>

      <motion.div variants={itemVariants} className="relative">
        <div className="glass-card-premium rounded-[2rem] p-1.5 overflow-hidden">
          <div className="flex gap-1.5 overflow-x-auto scrollbar-none">
            {tabs.map((tab) => {
              const Icon = tab.icon
              const isActive = activeTab === tab.key
              return (
                <Button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  variant={isActive ? "default" : "ghost"}
                  size="lg"
                  className={`relative flex-1 justify-center ${isActive ? "shadow-lg shadow-primary/25" : ""}`}
                >
                  {isActive && (
                    <motion.span
                      layoutId="activeTabPill"
                      className="absolute inset-0 rounded-2xl bg-primary"
                      transition={{ type: "spring", stiffness: 400, damping: 30 }}
                    />
                  )}
                  <span className="relative z-10 flex items-center gap-2.5">
                    <Icon className="w-4 h-4" />
                    {tab.label}
                  </span>
                </Button>
              )
            })}
          </div>
        </div>
      </motion.div>

      <AnimatePresence>
        {message && (
          <motion.div
            initial={{ opacity: 0, y: -10, height: 0 }}
            animate={{ opacity: 1, y: 0, height: "auto" }}
            exit={{ opacity: 0, y: -10, height: 0 }}
            className={`flex items-center gap-3 p-4 rounded-2xl text-sm font-medium border ${
              messageType === "success"
                ? "bg-secondary/10 text-secondary border-secondary/20"
                : "bg-error/10 text-error border-error/20"
            }`}
          >
            {messageType === "success" ? (
              <CheckCircle2 className="w-5 h-5 shrink-0" />
            ) : (
              <AlertTriangle className="w-5 h-5 shrink-0" />
            )}
            <span>{message}</span>
            <Button
              onClick={() => setMessage(null)}
              variant="ghost"
              size="icon-xs"
              className="mr-auto"
            >
              <ChevronLeft className="w-4 h-4" />
            </Button>
          </motion.div>
        )}
      </AnimatePresence>

      <motion.div variants={itemVariants} className="glass-card-premium rounded-[2rem] p-6 md:p-8 relative overflow-hidden">
        <div className="absolute -top-20 -left-20 w-60 h-60 rounded-full bg-primary/[0.03] blur-3xl pointer-events-none" />
        <div className="absolute -bottom-20 -right-20 w-60 h-60 rounded-full bg-secondary/[0.03] blur-3xl pointer-events-none" />

        <div className="relative z-10">
          <TabPanel active={activeTab === "profile"}>
            <div className="space-y-8">
              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6 pb-8 border-b border-border/20">
                <div className="relative shrink-0">
                  <div className="w-24 h-24 rounded-full bg-gradient-to-br from-primary via-primary/80 to-secondary p-0.5 shadow-lg shadow-primary/20">
                    <div className="w-full h-full rounded-full bg-card flex items-center justify-center">
                      <span className="text-3xl font-extrabold gradient-text">
                        {user?.full_name_ar?.charAt(0) || "م"}
                      </span>
                    </div>
                  </div>
                  <div className="absolute -bottom-1 -left-1 w-7 h-7 rounded-full bg-secondary flex items-center justify-center shadow-sm border-2 border-card">
                    <BadgeCheck className="w-3.5 h-3.5 text-white" />
                  </div>
                </div>
                <div className="text-center sm:text-right">
                  <h3 className="text-2xl font-extrabold text-foreground">{user?.full_name_ar || "المسؤول"}</h3>
                  <p className="text-sm text-muted-foreground mt-1 flex items-center justify-center sm:justify-start gap-1.5">
                    <Smartphone className="w-3.5 h-3.5" />
                    {user?.phone}
                  </p>
                  <span className={`inline-flex items-center gap-1.5 mt-3 px-4 py-1 rounded-full text-xs font-bold text-white bg-gradient-to-r ${roleGradient[role]} shadow-sm`}>
                    <BadgeCheck className="w-3.5 h-3.5" />
                    {roleLabel[role]}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <User className="w-4 h-4 text-primary" />
                    الاسم الأول
                  </label>
                  <div className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3 px-4 border border-border/30">
                    {user?.first_name_ar || "—"}
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <User className="w-4 h-4 text-primary" />
                    الاسم الأخير
                  </label>
                  <div className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3 px-4 border border-border/30">
                    {user?.last_name_ar || "—"}
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <Smartphone className="w-4 h-4 text-primary" />
                    رقم الهاتف
                  </label>
                  <div className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3 px-4 border border-border/30">
                    {user?.phone || "—"}
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <Shield className="w-4 h-4 text-primary" />
                    الصلاحية
                  </label>
                  <div className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3 px-4 border border-border/30">
                    {roleLabel[role]}
                  </div>
                </div>
              </div>
            </div>
          </TabPanel>

          <TabPanel active={activeTab === "notifications"}>
            <div className="space-y-1">
              <h3 className="section-header text-lg mb-6">إعدادات الإشعارات</h3>
              {notificationItems.map((item, i) => {
                const Icon = item.icon
                return (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, y: 12 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.05 }}
                    className="group flex items-center justify-between py-4 px-5 rounded-2xl hover:bg-surface-container/40 transition-all duration-200"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-xl bg-primary/10 dark:bg-primary/15 flex items-center justify-center shrink-0 group-hover:bg-primary/15 dark:group-hover:bg-primary/20 transition-colors">
                        <Icon className="w-4.5 h-4.5 text-primary" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-foreground">{item.label}</p>
                        <p className="text-xs text-muted-foreground mt-0.5">{item.desc}</p>
                      </div>
                    </div>
                    <Toggle checked={prefs ? prefs[item.field] : true} onChange={() => toggleNotif(item.field)} />
                  </motion.div>
                )
              })}
            </div>
          </TabPanel>

          <TabPanel active={activeTab === "security"}>
            <div className="max-w-lg">
              <h3 className="section-header text-lg mb-6">تغيير كلمة المرور</h3>
              <form onSubmit={handleChangePassword} className="space-y-6">
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <Lock className="w-4 h-4 text-primary" />
                    كلمة المرور الحالية
                  </label>
                  <div className="relative">
                    <input
                      type={showOldPw ? "text" : "password"}
                      value={passwordForm.oldPassword}
                      onChange={(e) => setPasswordForm((f) => ({ ...f, oldPassword: e.target.value }))}
                      placeholder="أدخل كلمة المرور الحالية"
                      className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3.5 px-4 pe-11 border border-border/30 focus:border-primary/50 focus:ring-2 focus:ring-primary/20 outline-none transition-all placeholder:text-muted-foreground/50"
                      required
                    />
                    <Button
                      type="button"
                      onClick={() => setShowOldPw(!showOldPw)}
                      variant="ghost"
                      size="icon-xs"
                      className="absolute left-3 top-1/2 -translate-y-1/2"
                    >
                      {showOldPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </Button>
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="flex items-center gap-2 text-sm font-bold text-foreground">
                    <Lock className="w-4 h-4 text-primary" />
                    كلمة المرور الجديدة
                  </label>
                  <div className="relative">
                    <input
                      type={showNewPw ? "text" : "password"}
                      value={passwordForm.newPassword}
                      onChange={(e) => setPasswordForm((f) => ({ ...f, newPassword: e.target.value }))}
                      placeholder="أدخل كلمة المرور الجديدة"
                      className="w-full bg-surface-container-low/50 text-sm text-foreground rounded-xl py-3.5 px-4 pe-11 border border-border/30 focus:border-primary/50 focus:ring-2 focus:ring-primary/20 outline-none transition-all placeholder:text-muted-foreground/50"
                      required
                    />
                    <Button
                      type="button"
                      onClick={() => setShowNewPw(!showNewPw)}
                      variant="ghost"
                      size="icon-xs"
                      className="absolute left-3 top-1/2 -translate-y-1/2"
                    >
                      {showNewPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </Button>
                  </div>
                </div>
                <Button
                  type="submit"
                  disabled={saving}
                  size="lg"
                  className="bg-gradient-to-r from-primary to-primary/90 text-primary-foreground shadow-lg shadow-primary/25"
                >
                  {saving ? (
                    <LoadingSpinner size="sm" />
                  ) : (
                    <Save className="w-4 h-4" />
                  )}
                  {saving ? "جاري الحفظ..." : "تغيير كلمة المرور"}
                </Button>
              </form>
            </div>
          </TabPanel>

          <TabPanel active={activeTab === "appearance"}>
            <div className="space-y-1">
              <h3 className="section-header text-lg mb-6">تخصيص المظهر</h3>
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0 }}
                className="group flex items-center justify-between py-5 px-6 rounded-2xl bg-gradient-to-r from-primary/[0.04] to-transparent dark:from-primary/[0.06] border border-primary/10 hover:border-primary/20 transition-all duration-200"
              >
                <div className="flex items-center gap-4">
                  <div className="w-11 h-11 rounded-xl bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center shrink-0">
                    {darkMode ? (
                      <Moon className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                    ) : (
                      <Sun className="w-5 h-5 text-amber-600 dark:text-amber-400" />
                    )}
                  </div>
                  <div>
                    <p className="text-sm font-bold text-foreground">الوضع الداكن</p>
                    <p className="text-xs text-muted-foreground mt-0.5">تفعيل المظهر الداكن للنظام</p>
                  </div>
                </div>
                <Toggle checked={darkMode} onChange={() => setDarkMode((p) => !p)} />
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.05 }}
                className="group flex items-center justify-between py-5 px-6 rounded-2xl hover:bg-surface-container/40 transition-all duration-200"
              >
                <div className="flex items-center gap-4">
                  <div className="w-11 h-11 rounded-xl bg-surface-container/50 flex items-center justify-center shrink-0">
                    <VolumeX className="w-5 h-5 text-muted-foreground" />
                  </div>
                  <div>
                    <p className="text-sm font-bold text-foreground">تقليل الحركة</p>
                    <p className="text-xs text-muted-foreground mt-0.5">إيقاف تأثيرات الحركة والانتقالات</p>
                  </div>
                </div>
                <Toggle checked={reduceMotion} onChange={() => setReduceMotion((p) => !p)} />
              </motion.div>

              <div className="mt-6 p-5 rounded-2xl bg-primary/[0.03] border border-primary/10">
                <div className="flex items-start gap-3">
                  <SunDim className="w-5 h-5 text-primary shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-semibold text-foreground">حفظ التفضيلات تلقائياً</p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      يتم حفظ اختيارات المظهر في المتصفح وتطبيقها تلقائياً في زيارتك القادمة.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </TabPanel>
        </div>
      </motion.div>
    </motion.div>
  )
}
