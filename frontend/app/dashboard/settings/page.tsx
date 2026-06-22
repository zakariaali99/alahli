"use client";

import React, { useState } from "react";
import {
  User,
  Bell,
  Shield,
  Palette,
  Globe,
  Database,
  ChevronLeft,
  Save,
  Camera,
  Eye,
  EyeOff,
} from "lucide-react";
import Image from "next/image";

type SettingsTab = "profile" | "notifications" | "security" | "appearance";

const tabs: { key: SettingsTab; label: string; icon: React.ElementType }[] = [
  { key: "profile", label: "الملف الشخصي", icon: User },
  { key: "notifications", label: "الإشعارات", icon: Bell },
  { key: "security", label: "الأمان", icon: Shield },
  { key: "appearance", label: "المظهر", icon: Palette },
];

function Toggle({
  checked,
  onChange,
}: {
  checked: boolean;
  onChange: () => void;
}) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      onClick={onChange}
      className={`relative inline-flex w-11 h-6 rounded-full transition-colors duration-300 focus:outline-none ${
        checked ? "bg-primary" : "bg-border/50"
      }`}
    >
      <span
        className={`absolute top-[2px] start-[2px] w-5 h-5 rounded-full bg-white shadow transition-transform duration-300 ${
          checked ? "translate-x-full rtl:-translate-x-full" : ""
        }`}
      />
    </button>
  );
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<SettingsTab>("profile");
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [saved, setSaved] = useState(false);

  const [profileForm, setProfileForm] = useState({
    fullName: "أحمد عبدالله المدير",
    email: "ahmed.manager@ahly.sa",
    phone: "0501234567",
    role: "مدير أكاديمية",
    academy: "الأهلي للياقة البدنية",
  });

  const [notifSettings, setNotifSettings] = useState({
    paymentAlerts: true,
    expiryAlerts: true,
    newMembers: true,
    systemAnnouncements: true,
    dailyEmail: false,
    weeklyReport: true,
  });

  const [appearance, setAppearance] = useState({
    theme: "light",
    language: "ar",
    density: "comfortable",
  });

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  return (
    <div className="space-y-6 animate-fade-in" dir="rtl">
      {/* Header */}
      <div>
        <h2 className="text-3xl font-bold text-foreground">الإعدادات</h2>
        <p className="text-muted-foreground mt-1 text-sm">
          إدارة حسابك وإعدادات النظام
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Sidebar tabs */}
        <div className="lg:col-span-3">
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-lg shadow-primary/5 space-y-1">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.key}
                  id={`settings-tab-${tab.key}`}
                  onClick={() => setActiveTab(tab.key)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all text-right ${
                    activeTab === tab.key
                      ? "bg-primary text-white shadow-md"
                      : "text-muted-foreground hover:bg-surface-container hover:text-foreground"
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content area */}
        <div className="lg:col-span-9">
          {/* Profile Tab */}
          {activeTab === "profile" && (
            <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 space-y-6">
              <h3 className="text-xl font-bold text-foreground border-b border-border/30 pb-4">
                الملف الشخصي
              </h3>

              {/* Avatar */}
              <div className="flex items-center gap-5">
                <div className="relative w-20 h-20 rounded-full overflow-hidden border-4 border-primary-container shrink-0">
                  <Image
                    src="https://lh3.googleusercontent.com/aida-public/AB6AXuDGGWjdYMNAuEUlX3_EM-M5C_X614HuhQqcHXtUnmVNwOn2aqxNwXRB09c0OeQ6gxeSE7UazvUXA4Gjgy2hJUp-LfKNqbbVPm_77o2WuyzuqdCBpU67sTF3-J2D7CVq9ETiX9l2QMxRML3H4n3sWfSJ8UZh-NCco85SYTmIrveHsRx-2i0JNzQP02SdZEiVY4uN60EbtggO81P4E0E4wIf6-9zJbKHTkJTPMAVktn1AIXIK5XQTfDJZQz5oHgfIhNJ-rt9bOUbosws"
                    alt="صورة المستخدم"
                    fill
                    sizes="80px"
                    className="object-cover"
                  />
                </div>
                <div>
                  <button className="flex items-center gap-2 text-sm font-semibold text-primary border border-primary/30 px-4 py-2 rounded-lg hover:bg-primary/5 transition-colors">
                    <Camera className="w-4 h-4" />
                    تغيير الصورة
                  </button>
                  <p className="text-xs text-muted-foreground mt-2">
                    JPG، PNG أو GIF · الحجم الأقصى 2MB
                  </p>
                </div>
              </div>

              {/* Form fields */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {[
                  {
                    key: "fullName" as const,
                    label: "الاسم الكامل",
                    type: "text",
                    id: "profile-name",
                  },
                  {
                    key: "email" as const,
                    label: "البريد الإلكتروني",
                    type: "email",
                    id: "profile-email",
                  },
                  {
                    key: "phone" as const,
                    label: "رقم الجوال",
                    type: "tel",
                    id: "profile-phone",
                  },
                  {
                    key: "role" as const,
                    label: "الدور الوظيفي",
                    type: "text",
                    id: "profile-role",
                  },
                  {
                    key: "academy" as const,
                    label: "الأكاديمية",
                    type: "text",
                    id: "profile-academy",
                  },
                ].map((field) => (
                  <div key={field.key} className="flex flex-col gap-1.5">
                    <label
                      htmlFor={field.id}
                      className="text-xs font-semibold text-muted-foreground"
                    >
                      {field.label}
                    </label>
                    <input
                      id={field.id}
                      type={field.type}
                      value={profileForm[field.key]}
                      onChange={(e) =>
                        setProfileForm((prev) => ({
                          ...prev,
                          [field.key]: e.target.value,
                        }))
                      }
                      className="bg-surface-container-low border border-border/40 rounded-xl px-4 py-2.5 text-sm text-foreground focus:ring-2 focus:ring-primary focus:border-primary outline-none transition-all"
                    />
                  </div>
                ))}
              </div>

              {/* Save button */}
              <div className="flex justify-end">
                <button
                  onClick={handleSave}
                  className={`flex items-center gap-2 px-6 py-2.5 rounded-full text-sm font-bold transition-all shadow-md ${
                    saved
                      ? "bg-[#006d30] text-white"
                      : "bg-primary text-white hover:bg-primary/90"
                  }`}
                >
                  {saved ? (
                    <>
                      <ChevronLeft className="w-4 h-4" /> تم الحفظ بنجاح
                    </>
                  ) : (
                    <>
                      <Save className="w-4 h-4" /> حفظ التغييرات
                    </>
                  )}
                </button>
              </div>
            </div>
          )}

          {/* Notifications Tab */}
          {activeTab === "notifications" && (
            <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 space-y-6">
              <h3 className="text-xl font-bold text-foreground border-b border-border/30 pb-4">
                تفضيلات الإشعارات
              </h3>

              <div className="space-y-5">
                {[
                  {
                    key: "paymentAlerts" as const,
                    title: "تنبيهات الدفع",
                    desc: "استلام إشعار عند كل عملية دفع أو تحصيل",
                  },
                  {
                    key: "expiryAlerts" as const,
                    title: "تنبيهات انتهاء الاشتراكات",
                    desc: "إشعار قبل 7 أيام من انتهاء أي اشتراك",
                  },
                  {
                    key: "newMembers" as const,
                    title: "تسجيلات أعضاء جدد",
                    desc: "إشعار عند تسجيل عضو جديد عبر التطبيق",
                  },
                  {
                    key: "systemAnnouncements" as const,
                    title: "إعلانات النظام",
                    desc: "تحديثات المنصة وإعلانات الإدارة",
                  },
                  {
                    key: "dailyEmail" as const,
                    title: "ملخص يومي عبر البريد",
                    desc: "تلقي ملخص يومي بأهم الأحداث",
                  },
                  {
                    key: "weeklyReport" as const,
                    title: "تقرير أسبوعي",
                    desc: "ملخص أسبوعي شامل بالإحصاءات والمؤشرات",
                  },
                ].map((setting) => (
                  <div
                    key={setting.key}
                    className="flex items-center justify-between py-3 border-b border-border/20 last:border-0"
                  >
                    <div>
                      <p className="text-sm font-semibold text-foreground">
                        {setting.title}
                      </p>
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {setting.desc}
                      </p>
                    </div>
                    <Toggle
                      checked={notifSettings[setting.key]}
                      onChange={() =>
                        setNotifSettings((prev) => ({
                          ...prev,
                          [setting.key]: !prev[setting.key],
                        }))
                      }
                    />
                  </div>
                ))}
              </div>

              <div className="flex justify-end">
                <button
                  onClick={handleSave}
                  className={`flex items-center gap-2 px-6 py-2.5 rounded-full text-sm font-bold transition-all shadow-md ${
                    saved
                      ? "bg-[#006d30] text-white"
                      : "bg-primary text-white hover:bg-primary/90"
                  }`}
                >
                  <Save className="w-4 h-4" />
                  {saved ? "تم الحفظ" : "حفظ التغييرات"}
                </button>
              </div>
            </div>
          )}

          {/* Security Tab */}
          {activeTab === "security" && (
            <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 space-y-6">
              <h3 className="text-xl font-bold text-foreground border-b border-border/30 pb-4">
                الأمان وكلمة المرور
              </h3>

              {/* Current password */}
              <div className="space-y-4">
                <div className="flex flex-col gap-1.5">
                  <label
                    htmlFor="current-password"
                    className="text-xs font-semibold text-muted-foreground"
                  >
                    كلمة المرور الحالية
                  </label>
                  <div className="relative">
                    <input
                      id="current-password"
                      type={showPassword ? "text" : "password"}
                      placeholder="أدخل كلمة المرور الحالية"
                      className="bg-surface-container-low border border-border/40 rounded-xl px-4 py-2.5 text-sm text-foreground w-full focus:ring-2 focus:ring-primary focus:border-primary outline-none transition-all"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
                    >
                      {showPassword ? (
                        <EyeOff className="w-4 h-4" />
                      ) : (
                        <Eye className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label
                    htmlFor="new-password"
                    className="text-xs font-semibold text-muted-foreground"
                  >
                    كلمة المرور الجديدة
                  </label>
                  <div className="relative">
                    <input
                      id="new-password"
                      type={showNewPassword ? "text" : "password"}
                      placeholder="أدخل كلمة المرور الجديدة"
                      className="bg-surface-container-low border border-border/40 rounded-xl px-4 py-2.5 text-sm text-foreground w-full focus:ring-2 focus:ring-primary focus:border-primary outline-none transition-all"
                    />
                    <button
                      type="button"
                      onClick={() => setShowNewPassword(!showNewPassword)}
                      className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
                    >
                      {showNewPassword ? (
                        <EyeOff className="w-4 h-4" />
                      ) : (
                        <Eye className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
                <div className="flex flex-col gap-1.5">
                  <label
                    htmlFor="confirm-password"
                    className="text-xs font-semibold text-muted-foreground"
                  >
                    تأكيد كلمة المرور
                  </label>
                  <input
                    id="confirm-password"
                    type="password"
                    placeholder="أعد إدخال كلمة المرور الجديدة"
                    className="bg-surface-container-low border border-border/40 rounded-xl px-4 py-2.5 text-sm text-foreground focus:ring-2 focus:ring-primary focus:border-primary outline-none transition-all"
                  />
                </div>
              </div>

              {/* Two-factor auth */}
              <div className="bg-surface-container-low rounded-2xl p-5 border border-border/20">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-sm font-bold text-foreground">
                      المصادقة الثنائية (2FA)
                    </h4>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      أضف طبقة حماية إضافية لحسابك
                    </p>
                  </div>
                  <span className="text-xs font-bold bg-[#ffdad6] text-[#93000a] px-3 py-1 rounded-full">
                    غير مفعّل
                  </span>
                </div>
                <button className="mt-4 text-sm font-semibold text-primary border border-primary/30 px-4 py-2 rounded-lg hover:bg-primary/5 transition-colors">
                  تفعيل المصادقة الثنائية
                </button>
              </div>

              <div className="flex justify-end">
                <button
                  onClick={handleSave}
                  className="flex items-center gap-2 px-6 py-2.5 rounded-full text-sm font-bold bg-primary text-white hover:bg-primary/90 transition-all shadow-md"
                >
                  <Save className="w-4 h-4" />
                  تحديث كلمة المرور
                </button>
              </div>
            </div>
          )}

          {/* Appearance Tab */}
          {activeTab === "appearance" && (
            <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 space-y-6">
              <h3 className="text-xl font-bold text-foreground border-b border-border/30 pb-4">
                إعدادات المظهر
              </h3>

              {/* Theme selection */}
              <div>
                <p className="text-sm font-bold text-foreground mb-3">
                  السمة
                </p>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { key: "light", label: "فاتح", bg: "bg-white border-border" },
                    {
                      key: "dark",
                      label: "داكن",
                      bg: "bg-[#1e293b] border-border",
                    },
                    {
                      key: "system",
                      label: "تلقائي",
                      bg: "bg-gradient-to-br from-white to-[#1e293b] border-border",
                    },
                  ].map((opt) => (
                    <button
                      key={opt.key}
                      id={`theme-${opt.key}`}
                      onClick={() =>
                        setAppearance((prev) => ({ ...prev, theme: opt.key }))
                      }
                      className={`p-4 rounded-xl border-2 text-center transition-all ${
                        appearance.theme === opt.key
                          ? "border-primary ring-2 ring-primary/20"
                          : "border-border/30 hover:border-border"
                      }`}
                    >
                      <div
                        className={`w-8 h-8 rounded-lg mx-auto mb-2 border ${opt.bg}`}
                      />
                      <span className="text-xs font-semibold text-foreground">
                        {opt.label}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Density */}
              <div>
                <p className="text-sm font-bold text-foreground mb-3">
                  كثافة العرض
                </p>
                <div className="flex gap-3">
                  {[
                    { key: "compact", label: "مضغوط" },
                    { key: "comfortable", label: "مريح" },
                    { key: "spacious", label: "واسع" },
                  ].map((d) => (
                    <button
                      key={d.key}
                      id={`density-${d.key}`}
                      onClick={() =>
                        setAppearance((prev) => ({ ...prev, density: d.key }))
                      }
                      className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all border-2 ${
                        appearance.density === d.key
                          ? "border-primary bg-primary/5 text-primary"
                          : "border-border/30 text-muted-foreground hover:border-border hover:text-foreground"
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Color accent preview */}
              <div>
                <p className="text-sm font-bold text-foreground mb-3">
                  لون الأكاديمية النشطة
                </p>
                <div className="flex gap-3">
                  <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl border-2 border-primary bg-primary/5 text-primary text-sm font-semibold">
                    <div className="w-4 h-4 rounded-full bg-primary" />
                    الأهلي (أزرق)
                  </button>
                  <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl border-2 border-border/30 text-muted-foreground text-sm font-semibold hover:border-[#006d30]">
                    <div className="w-4 h-4 rounded-full bg-[#006d30]" />
                    أكاديمية العوز (أخضر)
                  </button>
                </div>
              </div>

              <div className="flex justify-end">
                <button
                  onClick={handleSave}
                  className={`flex items-center gap-2 px-6 py-2.5 rounded-full text-sm font-bold transition-all shadow-md ${
                    saved
                      ? "bg-[#006d30] text-white"
                      : "bg-primary text-white hover:bg-primary/90"
                  }`}
                >
                  <Save className="w-4 h-4" />
                  {saved ? "تم الحفظ" : "تطبيق الإعدادات"}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
