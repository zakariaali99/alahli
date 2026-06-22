
import React, { useState } from "react"
import { motion, type Variants } from "framer-motion"
import {
  User,
  Bell,
  Shield,
  Palette,
  Save,
  Eye,
  EyeOff,
} from "lucide-react"

const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.07, delayChildren: 0.1 } },
}

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.22, 1, 0.36, 1] } },
}
import { useAuth } from "@/lib/auth"
import { api } from "@/lib/api"

type SettingsTab = "profile" | "notifications" | "security" | "appearance"

const tabs: { key: SettingsTab; label: string; icon: React.ElementType }[] = [
  { key: "profile", label: "الملف الشخصي", icon: User },
  { key: "notifications", label: "الإشعارات", icon: Bell },
  { key: "security", label: "الأمان", icon: Shield },
  { key: "appearance", label: "المظهر", icon: Palette },
]

function Toggle({ checked, onChange }: { checked: boolean; onChange: () => void }) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      onClick={onChange}
      className={`relative inline-flex w-11 h-6 rounded-full transition-colors duration-300 focus:outline-none ${
        checked ? "bg-primary" : "bg-border/50"
      }`}
    >
      <span className={`absolute top-[2px] start-[2px] w-5 h-5 rounded-full bg-white shadow transition-transform duration-300 ${
        checked ? "translate-x-full rtl:-translate-x-full" : ""
      }`} />
    </button>
  )
}

export default function SettingsPage() {
  const { user, login } = useAuth()
  const [activeTab, setActiveTab] = useState<SettingsTab>("profile")
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [showOldPw, setShowOldPw] = useState(false)
  const [showNewPw, setShowNewPw] = useState(false)

  const [passwordForm, setPasswordForm] = useState({ oldPassword: "", newPassword: "" })

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setMessage(null)
    try {
      await api.post("/auth/change-password/", {
        old_password: passwordForm.oldPassword,
        new_password: passwordForm.newPassword,
      })
      setMessage("تم تغيير كلمة المرور بنجاح")
      setPasswordForm({ oldPassword: "", newPassword: "" })
    } catch (err: any) {
      setMessage(err.message || "فشل تغيير كلمة المرور")
    } finally {
      setSaving(false)
    }
  }

  return (
    <motion.div className="space-y-6" dir="rtl" variants={containerVariants} initial="hidden" animate="visible">
      <motion.div variants={itemVariants}>
        <h2 className="text-3xl font-bold text-foreground">الإعدادات</h2>
        <p className="text-muted-foreground mt-1 text-sm">إدارة إعدادات حسابك وتفضيلات النظام.</p>
      </motion.div>

      <div className="flex gap-2 border-b border-border/20 pb-4 overflow-x-auto">
        {tabs.map((tab) => {
          const Icon = tab.icon
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold transition-all whitespace-nowrap ${
                activeTab === tab.key
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-muted-foreground hover:bg-surface-container"
              }`}
            >
              <Icon className="w-4 h-4" />
              {tab.label}
            </button>
          )
        })}
      </div>

      {message && (
        <div className={`p-4 rounded-xl text-sm flex items-center gap-2 ${
          message.includes("نجاح") ? "bg-secondary/15 text-secondary border border-secondary/30" : "bg-error/15 text-error border border-error/30"
        }`}>
          {message}
        </div>
      )}

      <motion.div className="glass-card rounded-3xl p-6 md:p-8 border border-border/20 shadow-sm" variants={itemVariants}>
        {activeTab === "profile" && (
          <div className="space-y-6">
            <div className="flex items-center gap-6 pb-6 border-b border-border/20">
              <div className="w-20 h-20 rounded-full bg-primary-container/20 flex items-center justify-center text-primary text-3xl font-bold">
                {user?.full_name_ar?.charAt(0) || "م"}
              </div>
              <div>
                <h3 className="text-xl font-bold text-foreground">{user?.full_name_ar || "المسؤول"}</h3>
                <p className="text-sm text-muted-foreground">{user?.phone}</p>
                <span className="inline-block mt-1 px-3 py-0.5 rounded-full text-xs font-semibold bg-primary-container/20 text-primary">
                  {user?.role === "super_admin" ? "مدير النظام" : user?.role === "reception" ? "موظف استقبال" : "مشاهد"}
                </span>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-bold text-foreground mb-2">الاسم الأول</label>
                <input type="text" value={user?.first_name_ar || ""} readOnly className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 px-4 border border-border/40 outline-none" />
              </div>
              <div>
                <label className="block text-sm font-bold text-foreground mb-2">الاسم الأخير</label>
                <input type="text" value={user?.last_name_ar || ""} readOnly className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 px-4 border border-border/40 outline-none" />
              </div>
              <div>
                <label className="block text-sm font-bold text-foreground mb-2">رقم الهاتف</label>
                <input type="text" value={user?.phone || ""} readOnly className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 px-4 border border-border/40 outline-none" />
              </div>
            </div>
          </div>
        )}

        {activeTab === "notifications" && (
          <div className="space-y-6">
            {[
              { label: "إشعارات انتهاء الاشتراكات", desc: "تنبيه عند اقتراب موعد انتهاء اشتراك أي لاعب" },
              { label: "إشعارات التسجيلات الجديدة", desc: "تنبيه عند تسجيل لاعب جديد في النظام" },
              { label: "إشعارات الدفع", desc: "تنبيه عند تأكيد عملية دفع أو تجديد" },
              { label: "إشعارات النظام", desc: "تنبيهات الصيانة والتحديثات الأسبوعية" },
            ].map((item, i) => (
              <div key={i} className="flex items-center justify-between py-3 border-b border-border/20 last:border-0">
                <div>
                  <p className="text-sm font-semibold text-foreground">{item.label}</p>
                  <p className="text-xs text-muted-foreground">{item.desc}</p>
                </div>
                <Toggle checked={true} onChange={() => {}} />
              </div>
            ))}
          </div>
        )}

        {activeTab === "security" && (
          <form onSubmit={handleChangePassword} className="max-w-md space-y-6">
            <div>
              <label className="block text-sm font-bold text-foreground mb-2">كلمة المرور الحالية</label>
              <div className="relative">
                <input
                  type={showOldPw ? "text" : "password"}
                  value={passwordForm.oldPassword}
                  onChange={(e) => setPasswordForm((f) => ({ ...f, oldPassword: e.target.value }))}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 px-4 border border-border/40 focus:ring-2 focus:ring-primary outline-none transition-all"
                  required
                />
                <button type="button" onClick={() => setShowOldPw(!showOldPw)} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">
                  {showOldPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
            <div>
              <label className="block text-sm font-bold text-foreground mb-2">كلمة المرور الجديدة</label>
              <div className="relative">
                <input
                  type={showNewPw ? "text" : "password"}
                  value={passwordForm.newPassword}
                  onChange={(e) => setPasswordForm((f) => ({ ...f, newPassword: e.target.value }))}
                  className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-3 px-4 border border-border/40 focus:ring-2 focus:ring-primary outline-none transition-all"
                  required
                  minLength={8}
                />
                <button type="button" onClick={() => setShowNewPw(!showNewPw)} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">
                  {showNewPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              <p className="text-xs text-muted-foreground mt-1">يجب أن تكون 8 أحرف على الأقل</p>
            </div>
            <button
              type="submit"
              disabled={saving}
              className="flex items-center gap-2 bg-primary text-primary-foreground font-semibold px-6 py-3 rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all text-sm disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {saving ? "جاري الحفظ..." : "تغيير كلمة المرور"}
            </button>
          </form>
        )}

        {activeTab === "appearance" && (
          <div className="space-y-6">
            {[
              { label: "الوضع الداكن", desc: "تفعيل المظهر الداكن للنظام" },
              { label: "تقليل الحركة", desc: "إيقاف تأثيرات الحركة والانتقالات" },
            ].map((item, i) => (
              <div key={i} className="flex items-center justify-between py-3 border-b border-border/20 last:border-0">
                <div>
                  <p className="text-sm font-semibold text-foreground">{item.label}</p>
                  <p className="text-xs text-muted-foreground">{item.desc}</p>
                </div>
                <Toggle checked={false} onChange={() => {}} />
              </div>
            ))}
          </div>
        )}
      </motion.div>
    </motion.div>
  )
}
