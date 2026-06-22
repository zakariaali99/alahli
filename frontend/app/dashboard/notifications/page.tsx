"use client";

import React, { useState } from "react";
import {
  EventBusy,
  PersonAdd,
  Campaign,
  Payments,
  CheckCircle2,
  RefreshCw,
  Bell,
  Megaphone,
  Settings,
} from "lucide-react";
import {
  CalendarClock,
  UserPlus,
  Volume2,
  DollarSign,
  Star,
  Calendar,
} from "lucide-react";

type Tab = "all" | "unread" | "subscriptions" | "system";
type NotifType = "expiry" | "new_member" | "system" | "payment";

interface Notification {
  id: number;
  type: NotifType;
  title: string;
  body: string;
  time: string;
  read: boolean;
  actions?: { label: string; style: "primary" | "secondary" }[];
}

const initialNotifications: Notification[] = [
  {
    id: 1,
    type: "expiry",
    title: "اشتراك يوشك على الانتهاء",
    body: 'اشتراك اللاعب "أحمد محمود" في الباقة الاحترافية سينتهي خلال 3 أيام. يرجى التواصل لتجديد الاشتراك.',
    time: "الآن",
    read: false,
    actions: [
      { label: "تجديد الآن", style: "primary" },
      { label: "إرسال تذكير", style: "secondary" },
    ],
  },
  {
    id: 2,
    type: "new_member",
    title: "تسجيل جديد",
    body: 'تم تسجيل متدرب جديد "خالد السعيد" بنجاح عبر التطبيق.',
    time: "منذ ساعتين",
    read: false,
  },
  {
    id: 3,
    type: "system",
    title: "إعلان نظام",
    body: "سيتم إجراء صيانة مجدولة للنظام يوم الجمعة القادم من الساعة 2 صباحاً حتى 4 صباحاً. نعتذر عن أي إزعاج.",
    time: "أمس، 14:30",
    read: true,
  },
  {
    id: 4,
    type: "payment",
    title: "دفعة مستلمة",
    body: 'تم استلام دفعة بقيمة 500 ريال من "ياسر الشهراني" بنجاح.',
    time: "منذ يومين",
    read: true,
  },
  {
    id: 5,
    type: "expiry",
    title: "اشتراك منتهي",
    body: 'انتهى اشتراك اللاعب "فيصل الدوسري". يُستحسن التواصل فوراً.',
    time: "منذ 3 أيام",
    read: true,
  },
];

const typeConfig: Record<
  NotifType,
  { icon: React.ElementType; bg: string; iconColor: string }
> = {
  expiry: {
    icon: CalendarClock,
    bg: "bg-[#ffdad6]",
    iconColor: "text-[#93000a]",
  },
  new_member: {
    icon: UserPlus,
    bg: "bg-[#92f5a4]",
    iconColor: "text-[#007233]",
  },
  system: {
    icon: Volume2,
    bg: "bg-surface-variant",
    iconColor: "text-muted-foreground",
  },
  payment: {
    icon: DollarSign,
    bg: "bg-surface-variant",
    iconColor: "text-muted-foreground",
  },
};

const adminAnnouncements = [
  {
    id: 1,
    badge: "تحديث جديد",
    badgeCls: "bg-[#92f5a4] text-[#007233]",
    date: "12 مايو",
    title: "إطلاق ميزة التقارير المتقدمة",
    body: "تم تفعيل نظام التقارير المتقدمة لجميع المدربين. يمكنك الآن تتبع أداء اللاعبين بدقة أكبر.",
  },
  {
    id: 2,
    badge: "فعالية",
    badgeCls: "bg-primary-container text-on-primary-container",
    date: "05 مايو",
    title: "بطولة الأكاديمية الصيفية",
    body: "بدأ التسجيل في البطولة الصيفية الداخلية. يرجى حث اللاعبين على المشاركة.",
  },
];

export default function NotificationsPage() {
  const [activeTab, setActiveTab] = useState<Tab>("all");
  const [notifications, setNotifications] =
    useState<Notification[]>(initialNotifications);
  const [settings, setSettings] = useState({
    payments: true,
    system: true,
    email: false,
  });

  const unreadCount = notifications.filter((n) => !n.read).length;

  const filteredNotifications = notifications.filter((n) => {
    if (activeTab === "all") return true;
    if (activeTab === "unread") return !n.read;
    if (activeTab === "subscriptions")
      return n.type === "expiry" || n.type === "payment";
    if (activeTab === "system") return n.type === "system";
    return true;
  });

  const markAllRead = () =>
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));

  const markRead = (id: number) =>
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );

  const tabs: { key: Tab; label: string }[] = [
    { key: "all", label: `الكل (${notifications.length})` },
    { key: "unread", label: `غير مقروءة (${unreadCount})` },
    { key: "subscriptions", label: "الاشتراكات" },
    { key: "system", label: "النظام" },
  ];

  return (
    <div className="space-y-6 animate-fade-in" dir="rtl">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold text-foreground">مركز التنبيهات</h2>
          <p className="text-muted-foreground mt-1 text-sm">
            ابق على اطلاع بآخر المستجدات والإشعارات الهامة
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={markAllRead}
            className="bg-white/70 backdrop-blur-md border border-white/50 text-primary px-4 py-2 rounded-lg text-sm font-semibold flex items-center gap-2 hover:bg-surface-container-low transition-colors shadow-sm"
          >
            <CheckCircle2 className="w-4 h-4" />
            تحديد الكل كمقروء
          </button>
          <button className="bg-surface-container text-foreground px-4 py-2 rounded-lg text-sm font-semibold flex items-center gap-2 hover:bg-surface-container-high transition-colors">
            <Settings className="w-4 h-4" />
            التفضيلات
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Main Notifications List (Span 8) */}
        <div className="lg:col-span-8 flex flex-col gap-4">
          {/* Tabs */}
          <div className="flex gap-2 overflow-x-auto pb-1">
            {tabs.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`whitespace-nowrap px-5 py-2 rounded-full text-sm font-semibold transition-all ${
                  activeTab === tab.key
                    ? "bg-primary text-white shadow-md shadow-primary/20"
                    : "bg-white/70 backdrop-blur-md border border-white/50 text-muted-foreground hover:text-foreground hover:bg-surface-container"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Notification List */}
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl overflow-hidden shadow-lg shadow-primary/5 divide-y divide-border/10">
            {filteredNotifications.length === 0 && (
              <div className="px-6 py-12 text-center text-muted-foreground text-sm">
                لا توجد تنبيهات في هذه الفئة
              </div>
            )}
            {filteredNotifications.map((notif) => {
              const cfg = typeConfig[notif.type];
              const Icon = cfg.icon;
              return (
                <div
                  key={notif.id}
                  onClick={() => markRead(notif.id)}
                  className={`p-4 md:p-6 flex gap-4 hover:bg-surface-container-low/50 transition-colors cursor-pointer relative ${
                    !notif.read ? "bg-primary/5" : "opacity-90 hover:opacity-100"
                  }`}
                >
                  {/* Unread indicator stripe */}
                  {!notif.read && (
                    <div className="absolute left-0 top-0 w-1 h-full bg-primary rounded-r-full" />
                  )}

                  {/* Icon */}
                  <div className="shrink-0 mt-1">
                    <div
                      className={`w-12 h-12 rounded-full ${cfg.bg} ${cfg.iconColor} flex items-center justify-center`}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                  </div>

                  {/* Content */}
                  <div className="flex-1">
                    <div className="flex justify-between items-start mb-1">
                      <h3
                        className={`text-base font-semibold text-foreground ${
                          !notif.read ? "font-bold" : ""
                        }`}
                      >
                        {notif.title}
                      </h3>
                      <span
                        className={`text-xs whitespace-nowrap ${
                          !notif.read ? "text-primary font-semibold" : "text-muted-foreground"
                        }`}
                      >
                        {notif.time}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground mb-3 line-clamp-2">
                      {notif.body}
                    </p>
                    {notif.actions && !notif.read && (
                      <div className="flex gap-2">
                        {notif.actions.map((action, i) => (
                          <button
                            key={i}
                            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                              action.style === "primary"
                                ? "bg-primary text-white hover:bg-primary/90"
                                : "bg-white border border-border/40 text-foreground hover:bg-surface-container"
                            }`}
                          >
                            {action.label}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Unread dot */}
                  {!notif.read && (
                    <div className="shrink-0 flex items-center">
                      <div className="w-3 h-3 rounded-full bg-primary shadow-[0_0_8px_rgba(0,40,142,0.5)]" />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Load more */}
          <div className="flex justify-center">
            <button className="text-primary hover:bg-primary/10 px-6 py-2 rounded-full transition-colors flex items-center gap-2 text-sm font-semibold">
              عرض المزيد
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Side Panel (Span 4) */}
        <div className="lg:col-span-4 flex flex-col gap-5">
          {/* Admin Announcements */}
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5 bg-gradient-to-br from-white/70 to-primary/5 border-t-4 border-t-primary relative overflow-hidden">
            <div className="absolute top-0 right-0 -mr-6 -mt-6 w-24 h-24 bg-primary opacity-5 rounded-full blur-xl" />
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-primary text-white rounded-lg">
                <Star className="w-5 h-5" />
              </div>
              <h3 className="text-lg font-bold text-foreground">
                إعلانات الإدارة
              </h3>
            </div>
            <div className="space-y-3">
              {adminAnnouncements.map((ann) => (
                <div
                  key={ann.id}
                  className="bg-white/60 p-4 rounded-xl border border-border/10 hover:border-primary/30 transition-colors cursor-pointer"
                >
                  <div className="flex justify-between items-center mb-2">
                    <span
                      className={`text-xs font-bold px-2 py-0.5 rounded-full ${ann.badgeCls}`}
                    >
                      {ann.badge}
                    </span>
                    <span className="text-xs text-muted-foreground">{ann.date}</span>
                  </div>
                  <h4 className="font-bold text-foreground text-sm mb-1">{ann.title}</h4>
                  <p className="text-xs text-muted-foreground line-clamp-2">{ann.body}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Settings */}
          <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl p-6 shadow-lg shadow-primary/5">
            <h3 className="text-lg font-bold text-foreground mb-4 flex items-center gap-2">
              <Settings className="w-5 h-5 text-muted-foreground" />
              إعدادات سريعة
            </h3>
            <div className="space-y-4">
              {[
                {
                  key: "payments" as const,
                  label: "تنبيهات الدفع",
                  desc: "استلام إشعار عند كل عملية دفع",
                },
                {
                  key: "system" as const,
                  label: "تنبيهات النظام",
                  desc: "إعلانات الإدارة والتحديثات",
                },
                {
                  key: "email" as const,
                  label: "البريد الإلكتروني",
                  desc: "تلقي ملخص يومي",
                },
              ].map((setting) => (
                <label
                  key={setting.key}
                  className="flex items-center justify-between cursor-pointer"
                >
                  <div className="flex flex-col">
                    <span className="text-sm font-semibold text-foreground">
                      {setting.label}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {setting.desc}
                    </span>
                  </div>
                  <div className="relative">
                    <input
                      type="checkbox"
                      className="sr-only peer"
                      checked={settings[setting.key]}
                      onChange={(e) =>
                        setSettings((prev) => ({
                          ...prev,
                          [setting.key]: e.target.checked,
                        }))
                      }
                    />
                    <div
                      className={`w-11 h-6 rounded-full transition-colors ${
                        settings[setting.key]
                          ? "bg-primary"
                          : "bg-border/50"
                      } relative after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border after:rounded-full after:h-5 after:w-5 after:transition-all ${
                        settings[setting.key]
                          ? "after:translate-x-full rtl:after:-translate-x-full"
                          : ""
                      }`}
                    />
                  </div>
                </label>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
