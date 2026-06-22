"use client";

import React, { useState } from "react";
import {
  CalendarDays,
  CalendarRange,
  Crown,
  CheckCircle2,
  Search,
  Filter,
  MoreVertical,
  CreditCard,
  Banknote,
  Building2,
  PlusCircle,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";

// ─── Types ────────────────────────────────────────────────────────────────────
type PaymentMethod = "بطاقة ائتمان" | "بطاقة مدى" | "تحويل بنكي" | "نقدي";
type Status = "نشط" | "منتهي" | "قارب على الانتهاء";

interface Subscription {
  id: number;
  initials: string;
  name: string;
  package: string;
  startDate: string;
  endDate: string;
  amount: string;
  paymentMethod: PaymentMethod;
  status: Status;
}

// ─── Mock Data ─────────────────────────────────────────────────────────────────
const subscriptions: Subscription[] = [
  {
    id: 1,
    initials: "أ.م",
    name: "أحمد محمد عبدالله",
    package: "3 أشهر",
    startDate: "15/10/2023",
    endDate: "15/01/2024",
    amount: "945 ر.س",
    paymentMethod: "بطاقة ائتمان",
    status: "نشط",
  },
  {
    id: 2,
    initials: "س.ع",
    name: "سالم علي حسن",
    package: "شهر واحد",
    startDate: "01/11/2023",
    endDate: "01/12/2023",
    amount: "350 ر.س",
    paymentMethod: "تحويل بنكي",
    status: "منتهي",
  },
  {
    id: 3,
    initials: "خ.س",
    name: "خالد سعد الغامدي",
    package: "12 شهر",
    startDate: "20/05/2023",
    endDate: "20/05/2024",
    amount: "3,360 ر.س",
    paymentMethod: "نقدي",
    status: "نشط",
  },
  {
    id: 4,
    initials: "ف.م",
    name: "فيصل محمد الدوسري",
    package: "6 أشهر",
    startDate: "10/08/2023",
    endDate: "10/02/2024",
    amount: "1,785 ر.س",
    paymentMethod: "بطاقة مدى",
    status: "قارب على الانتهاء",
  },
  {
    id: 5,
    initials: "م.ع",
    name: "محمد عبدالرحمن النعيمي",
    package: "3 أشهر",
    startDate: "01/12/2023",
    endDate: "01/03/2024",
    amount: "945 ر.س",
    paymentMethod: "بطاقة ائتمان",
    status: "نشط",
  },
];

const packages = [
  {
    id: 1,
    title: "شهر واحد",
    price: "350",
    icon: CalendarDays,
    badge: "شائع",
    badgeClass: "bg-[#92f5a4] text-[#007233]",
    iconBg: "bg-surface-container-high",
    iconColor: "text-primary",
    features: ["دخول يومي للمرافق", "حصة تدريبية واحدة"],
    featured: false,
  },
  {
    id: 2,
    title: "3 أشهر",
    price: "945",
    icon: CalendarRange,
    badge: "توفير 10%",
    badgeClass: "bg-[#ffddb8] text-[#653e00]",
    iconBg: "bg-primary",
    iconColor: "text-white",
    features: ["جميع مميزات الشهر", "تقييم بدني شهري"],
    featured: true,
  },
  {
    id: 3,
    title: "6 أشهر",
    price: "1,785",
    icon: CalendarRange,
    badge: "توفير 15%",
    badgeClass: "bg-surface-variant text-on-surface-variant",
    iconBg: "bg-surface-container-high",
    iconColor: "text-primary",
    features: ["دخول حصص جماعية", "برنامج غذائي مبدئي"],
    featured: false,
  },
  {
    id: 4,
    title: "12 شهر",
    price: "3,360",
    icon: Crown,
    badge: "الأفضل قيمة",
    badgeClass: "bg-[#ffddb8] text-[#2a1700]",
    iconBg: "bg-surface-container-high",
    iconColor: "text-primary",
    features: ["جميع المميزات السابقة", "تجميد الاشتراك (شهر)"],
    featured: false,
  },
];

// ─── Helpers ───────────────────────────────────────────────────────────────────
function PaymentIcon({ method }: { method: PaymentMethod }) {
  if (method === "بطاقة ائتمان" || method === "بطاقة مدى")
    return <CreditCard className="w-4 h-4" />;
  if (method === "تحويل بنكي") return <Building2 className="w-4 h-4" />;
  return <Banknote className="w-4 h-4" />;
}

function StatusBadge({ status }: { status: Status }) {
  const map: Record<Status, { cls: string; label: string }> = {
    نشط: {
      cls: "bg-[#92f5a4] text-[#007233]",
      label: "نشط",
    },
    منتهي: {
      cls: "bg-[#ffdad6] text-[#93000a]",
      label: "منتهي",
    },
    "قارب على الانتهاء": {
      cls: "bg-[#6b4200] text-[#ffa929]",
      label: "قارب على الانتهاء",
    },
  };
  const { cls, label } = map[status];
  return (
    <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${cls}`}>
      {label}
    </span>
  );
}

// ─── Component ─────────────────────────────────────────────────────────────────
export default function MembershipsPage() {
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [activeMenuId, setActiveMenuId] = useState<number | null>(null);

  const filtered = subscriptions.filter(
    (s) =>
      s.name.includes(search) ||
      s.package.includes(search) ||
      s.status.includes(search)
  );

  return (
    <div className="space-y-8 animate-fade-in" dir="rtl">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold text-foreground">إدارة الاشتراكات</h2>
          <p className="text-muted-foreground mt-1 text-sm">
            تجديد، متابعة، وإدارة الباقات المالية للاعبين.
          </p>
        </div>
        <button className="flex items-center gap-2 bg-primary text-white px-6 py-3 rounded-full text-sm font-semibold hover:bg-primary/90 transition-all shadow-md hover:shadow-lg hover:-translate-y-0.5">
          <PlusCircle className="w-5 h-5" />
          اشتراك جديد
        </button>
      </div>

      {/* Quick Renewal Package Cards */}
      <section>
        <h3 className="text-xl font-bold text-foreground mb-4">
          باقات التجديد السريع
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
          {packages.map((pkg) => {
            const Icon = pkg.icon;
            return (
              <div
                key={pkg.id}
                className={`relative rounded-2xl p-6 flex flex-col hover:-translate-y-1 transition-all duration-300 overflow-hidden
                  ${
                    pkg.featured
                      ? "bg-gradient-to-br from-primary to-primary/80 text-white shadow-xl shadow-primary/30"
                      : "bg-white/70 backdrop-blur-md border border-white/50 shadow-lg shadow-primary/5"
                  }`}
              >
                {pkg.featured && (
                  <div className="absolute -right-8 -top-8 w-28 h-28 bg-white/10 rounded-full blur-2xl pointer-events-none" />
                )}
                <div className="flex justify-between items-start mb-4 relative z-10">
                  <div
                    className={`p-2 rounded-lg ${
                      pkg.featured ? "bg-white/20" : pkg.iconBg
                    }`}
                  >
                    <Icon
                      className={`w-5 h-5 ${
                        pkg.featured ? "text-white" : pkg.iconColor
                      }`}
                    />
                  </div>
                  <span
                    className={`text-xs font-bold px-2 py-1 rounded-full ${
                      pkg.featured
                        ? "bg-white/20 text-white"
                        : pkg.badgeClass
                    }`}
                  >
                    {pkg.badge}
                  </span>
                </div>
                <h4
                  className={`text-lg font-bold relative z-10 ${
                    pkg.featured ? "text-white" : "text-foreground"
                  }`}
                >
                  {pkg.title}
                </h4>
                <div className="mt-2 mb-4 relative z-10">
                  <span
                    className={`text-3xl font-extrabold ${
                      pkg.featured ? "text-white" : "text-primary"
                    }`}
                  >
                    {pkg.price}
                  </span>
                  <span
                    className={`text-sm mr-1 ${
                      pkg.featured ? "text-white/80" : "text-muted-foreground"
                    }`}
                  >
                    ريال
                  </span>
                </div>
                <ul className="space-y-2 mb-5 flex-1 relative z-10">
                  {pkg.features.map((f, i) => (
                    <li
                      key={i}
                      className={`flex items-center gap-2 text-xs ${
                        pkg.featured ? "text-white/90" : "text-muted-foreground"
                      }`}
                    >
                      <CheckCircle2
                        className={`w-4 h-4 ${
                          pkg.featured ? "text-white" : "text-[#006d30]"
                        }`}
                      />
                      {f}
                    </li>
                  ))}
                </ul>
                <button
                  className={`w-full py-2.5 rounded-xl text-sm font-bold transition-all relative z-10 ${
                    pkg.featured
                      ? "bg-white text-primary hover:bg-white/90"
                      : "bg-surface-container border border-primary/20 text-primary hover:bg-primary hover:text-white"
                  }`}
                >
                  تجديد سريع
                </button>
              </div>
            );
          })}
        </div>
      </section>

      {/* Subscription History Table */}
      <section className="flex flex-col">
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center mb-4 gap-4">
          <h3 className="text-xl font-bold text-foreground">سجل الاشتراكات</h3>
          {/* Filters */}
          <div className="flex flex-wrap items-center gap-3 w-full lg:w-auto">
            {/* Search */}
            <div className="relative flex-1 lg:w-72">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
              <input
                id="subscription-search"
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="bg-surface-container-low border border-border/40 text-foreground text-sm rounded-xl focus:ring-2 focus:ring-primary focus:border-primary block w-full pr-10 p-2.5 outline-none transition-all"
                placeholder="بحث باسم اللاعب أو الباقة..."
              />
            </div>
            {/* Filter button */}
            <button className="flex items-center gap-2 bg-surface-container-low border border-border/40 rounded-xl px-3 py-2.5 text-sm text-muted-foreground hover:bg-surface-container transition-colors">
              <Filter className="w-4 h-4" />
              تصفية بالتاريخ
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white/70 backdrop-blur-md border border-white/50 rounded-2xl overflow-hidden shadow-lg shadow-primary/5">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="text-xs text-muted-foreground uppercase bg-surface-container/50 border-b border-border/30">
                <tr>
                  <th scope="col" className="px-6 py-4 font-bold">
                    اسم اللاعب
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    الباقة
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    تاريخ البدء
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    تاريخ الانتهاء
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    المبلغ
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    طريقة الدفع
                  </th>
                  <th scope="col" className="px-6 py-4 font-bold">
                    الحالة
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-4 font-bold text-center"
                  >
                    إجراءات
                  </th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr>
                    <td
                      colSpan={8}
                      className="px-6 py-12 text-center text-muted-foreground"
                    >
                      لا توجد نتائج مطابقة للبحث
                    </td>
                  </tr>
                ) : (
                  filtered.map((sub) => (
                    <tr
                      key={sub.id}
                      className="bg-transparent border-b border-border/20 hover:bg-surface-container-low/50 transition-colors"
                    >
                      {/* Name */}
                      <td className="px-6 py-4 font-medium text-foreground">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-surface-variant flex items-center justify-center text-primary font-bold text-xs shrink-0">
                            {sub.initials}
                          </div>
                          {sub.name}
                        </div>
                      </td>
                      {/* Package */}
                      <td className="px-6 py-4 text-muted-foreground">
                        {sub.package}
                      </td>
                      {/* Start date */}
                      <td className="px-6 py-4 text-muted-foreground">
                        {sub.startDate}
                      </td>
                      {/* End date */}
                      <td
                        className={`px-6 py-4 font-semibold ${
                          sub.status === "منتهي"
                            ? "text-[#ba1a1a]"
                            : sub.status === "قارب على الانتهاء"
                            ? "text-[#ffa929]"
                            : "text-muted-foreground"
                        }`}
                      >
                        {sub.endDate}
                      </td>
                      {/* Amount */}
                      <td className="px-6 py-4 font-bold text-foreground">
                        {sub.amount}
                      </td>
                      {/* Payment method */}
                      <td className="px-6 py-4 text-muted-foreground">
                        <span className="flex items-center gap-1.5">
                          <PaymentIcon method={sub.paymentMethod} />
                          {sub.paymentMethod}
                        </span>
                      </td>
                      {/* Status */}
                      <td className="px-6 py-4">
                        <StatusBadge status={sub.status} />
                      </td>
                      {/* Actions */}
                      <td className="px-6 py-4 text-center relative">
                        <button
                          id={`subscription-menu-${sub.id}`}
                          onClick={() =>
                            setActiveMenuId(
                              activeMenuId === sub.id ? null : sub.id
                            )
                          }
                          className="p-1 text-primary hover:text-primary/70 transition-colors rounded-lg hover:bg-surface-container"
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>
                        {activeMenuId === sub.id && (
                          <div className="absolute left-4 top-full z-50 mt-1 w-40 bg-white rounded-xl border border-border/40 shadow-xl py-1">
                            <button className="w-full text-right px-4 py-2 text-sm text-foreground hover:bg-surface-container transition-colors">
                              تجديد
                            </button>
                            <button className="w-full text-right px-4 py-2 text-sm text-foreground hover:bg-surface-container transition-colors">
                              تعديل
                            </button>
                            <button className="w-full text-right px-4 py-2 text-sm text-[#ba1a1a] hover:bg-[#ffdad6] transition-colors">
                              إلغاء
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="px-6 py-4 flex items-center justify-between border-t border-border/20 bg-white/50">
            <span className="text-xs text-muted-foreground">
              عرض 1-{filtered.length} من {subscriptions.length} اشتراك
            </span>
            <div className="flex gap-1">
              <button
                onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                className="p-1.5 rounded-md text-muted-foreground hover:bg-surface-container transition-colors"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
              {[1, 2, 3].map((p) => (
                <button
                  key={p}
                  onClick={() => setCurrentPage(p)}
                  className={`w-8 h-8 rounded-md text-sm font-semibold transition-colors ${
                    p === currentPage
                      ? "bg-primary text-white"
                      : "text-muted-foreground hover:bg-surface-container"
                  }`}
                >
                  {p}
                </button>
              ))}
              <button
                onClick={() => setCurrentPage(Math.min(3, currentPage + 1))}
                className="p-1.5 rounded-md text-muted-foreground hover:bg-surface-container transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
