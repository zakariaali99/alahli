"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Plus, Search, Filter, ArrowDown, LayoutGrid, TableProperties, Eye, Edit2, MoreVertical, Dumbbell, Shield, HelpCircle, ChevronRight, ChevronLeft } from "lucide-react";
import Image from "next/image";

interface Athlete {
  id: string;
  name: string;
  phone: string;
  department: string;
  sportIcon: any;
  status: "active" | "expired" | "pending";
  statusText: string;
  joinDate: string;
  image: string | null;
}

const initialAthletes: Athlete[] = [
  {
    id: "ATH-2026-001",
    name: "أحمد محمود عبدلله",
    phone: "+218 91 123 4567",
    department: "الأهلي للياقة",
    sportIcon: Dumbbell,
    status: "active",
    statusText: "نشط",
    joinDate: "12 مارس 2026",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuDsqtCKxgWs47HSxRaTdyipL4ixU6NCwVjgvcdowN_X76uloSQTdjgs7XDFLt4rAyK3icxoHc9CDpQ-ADN6BtSUHA-JYx7knzraeNfb-0XJ72aFRe0v1A-T9X0-hI_3OpfSeEC81FCi-VxQKcdar5M-v-LBA3HchxjLCsBINBTB9Ngb3cIfyy1uYeM_G2Tqurm_9yMN_HfeF35WnrJQdEhU8ygdaKi5nXQoEg_CTPN_hJVUSNKI8tHI2eaRSkCqkEGGb0gGrCdkTaU",
  },
  {
    id: "ATH-2026-042",
    name: "خالد سعد الدوسري",
    phone: "+218 92 987 6543",
    department: "أكاديمية كرة القدم",
    sportIcon: Shield,
    status: "expired",
    statusText: "منتهي",
    joinDate: "05 يناير 2026",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBj22s7K_7hu8aGg_iUjcNPGsraMr2OIQMRMSjlqrOmsRyjpSZb_uUP51QW494uSj13xfihQ6jskBEBJLBCLhOmjOFWIj967ctdo-E074F3GyaQcjeyEFP7LVB3a2JH0vh5841fjkBvuQ_cuqv2sRE4vzeUD69ujfTcn0fsUCEUBEdBqd1S7CZSlJ2f078YqZwfXWM1JbCg1KWcJZVZp0-7oGPcc2xGB8Uop0AX-RiQjkgNCIktkTcka8zZLw0vT1RBKcq-YlDZxXI",
  },
  {
    id: "ATH-2026-118",
    name: "عمر سليمان الفيتوري",
    phone: "+218 91 444 5555",
    department: "الأهلي للياقة",
    sportIcon: Dumbbell,
    status: "active",
    statusText: "نشط",
    joinDate: "22 نوفمبر 2025",
    image: null,
  },
  {
    id: "ATH-2026-089",
    name: "سارة عبدالله الورفلي",
    phone: "+218 91 111 2222",
    department: "السباحة",
    sportIcon: HelpCircle,
    status: "pending",
    statusText: "قيد المراجعة",
    joinDate: "اليوم",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuB0capdRBrCRayUgaDqZjOZ8U6NAkaxghunlE-H3Z9ZF8TDDDIp3b0rYNYHYAorwVSOiSmTUx465mYzIKrV341jxdUt3KkmDMxXxr01aHCwVARieL7jeXiuDDoC8adi0Nw3hngQfxWuSV1az5yjsRCbJVNyO31cUVoEpGdoSBAKnNE_Cao_6mURIjRfYJlAFcQDaNVTblif3jYpVp_x5PTGh_VridhUG5tzn7xUu0Po3mgZsEQK5KEldWFlu2d2ubmcvfKl8D30oRE",
  },
];

export default function AthletesPage() {
  const [athletes, setAthletes] = useState<Athlete[]>(initialAthletes);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [deptFilter, setDeptFilter] = useState("all");
  const [viewMode, setViewMode] = useState<"table" | "grid">("table");

  // Filtering Logic
  const filteredAthletes = athletes.filter((a) => {
    const matchesSearch =
      a.name.includes(searchQuery) ||
      a.phone.includes(searchQuery) ||
      a.id.includes(searchQuery);
    const matchesStatus = statusFilter === "all" || a.status === statusFilter;
    const matchesDept =
      deptFilter === "all" ||
      (deptFilter === "fitness" && a.department.includes("لياقة")) ||
      (deptFilter === "football" && a.department.includes("كرة")) ||
      (deptFilter === "swimming" && a.department.includes("سباحة"));

    return matchesSearch && matchesStatus && matchesDept;
  });

  return (
    <div className="space-y-8 select-none">
      {/* Background Blurs */}
      <div className="fixed top-[-20%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-primary-container/10 blur-[120px] -z-10 pointer-events-none"></div>

      {/* Header Area */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-foreground">إدارة اللاعبين</h1>
          <p className="text-sm text-muted-foreground mt-2">
            عرض وإدارة بيانات جميع الرياضيين المسجلين في النظام.
          </p>
        </div>
        <Link href="/dashboard/athletes/add">
          <button className="bg-primary text-primary-foreground font-semibold px-5 py-2.5 rounded-xl shadow-lg shadow-primary/20 hover:bg-primary/95 transition-all flex items-center gap-2 text-sm">
            <Plus className="w-4 h-4" />
            إضافة رياضي جديد
          </button>
        </Link>
      </div>

      {/* Search & Filter bar container */}
      <div className="glass-card rounded-2xl p-4 flex flex-col md:flex-row gap-4 items-center justify-between shadow-sm">
        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto flex-1">
          {/* Search bar inside header/filter area */}
          <div className="relative w-full max-w-sm">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
            <input
              type="text"
              placeholder="ابحث بالاسم، رقم الهاتف أو المعرّف..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary focus:bg-white outline-none transition-all"
            />
          </div>

          {/* Status Select */}
          <div className="relative w-full sm:w-44">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary outline-none cursor-pointer appearance-none"
            >
              <option value="all">حالة الاشتراك: الكل</option>
              <option value="active">نشط</option>
              <option value="expired">منتهي</option>
              <option value="pending">قيد المراجعة</option>
            </select>
            <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
          </div>

          {/* Department Select */}
          <div className="relative w-full sm:w-44">
            <select
              value={deptFilter}
              onChange={(e) => setDeptFilter(e.target.value)}
              className="w-full bg-surface-container-low text-sm text-foreground rounded-lg py-2.5 pr-10 pl-4 border border-border/40 focus:ring-2 focus:ring-primary outline-none cursor-pointer appearance-none"
            >
              <option value="all">القسم: الكل</option>
              <option value="fitness">الأهلي للياقة</option>
              <option value="football">أكاديمية كرة القدم</option>
              <option value="swimming">السباحة</option>
            </select>
            <Filter className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
          </div>
        </div>

        {/* View Switching */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-muted-foreground hidden lg:inline">ترتيب حسب الاسم:</span>
          <button className="flex items-center gap-1 text-primary text-xs font-semibold bg-primary-container/20 px-3 py-1.5 rounded-lg hover:bg-primary-container/40 transition-colors">
            الاسم <ArrowDown className="w-3.5 h-3.5" />
          </button>
          <div className="h-6 w-px bg-border/50 mx-2"></div>
          <button
            onClick={() => setViewMode("table")}
            className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
              viewMode === "table" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
            }`}
          >
            <TableProperties className="w-4 h-4" />
          </button>
          <button
            onClick={() => setViewMode("grid")}
            className={`w-9 h-9 rounded-lg flex items-center justify-center transition-all ${
              viewMode === "grid" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
            }`}
          >
            <LayoutGrid className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Grid or Table canvas */}
      {viewMode === "table" ? (
        <div className="glass-card rounded-2xl overflow-hidden shadow-sm flex flex-col border border-border/20">
          <div className="overflow-x-auto w-full">
            <table className="w-full text-right border-collapse min-w-[800px]">
              <thead>
                <tr className="bg-surface-container-lowest/50 border-b border-border/40 text-muted-foreground text-xs font-semibold">
                  <th className="py-4 px-6 w-16 text-center">
                    <input type="checkbox" className="rounded border-border text-primary focus:ring-primary w-4 h-4 cursor-pointer" />
                  </th>
                  <th className="py-4 px-4">الرياضي</th>
                  <th className="py-4 px-4">رقم الهاتف</th>
                  <th className="py-4 px-4">القسم</th>
                  <th className="py-4 px-4">حالة الاشتراك</th>
                  <th className="py-4 px-4">تاريخ الانضمام</th>
                  <th className="py-4 px-6 text-left">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="text-sm divide-y divide-border/20">
                {filteredAthletes.map((athlete) => {
                  const Icon = athlete.sportIcon;
                  return (
                    <tr key={athlete.id} className="hover:bg-surface-container-lowest/80 transition-colors group">
                      <td className="py-3 px-6 text-center">
                        <input type="checkbox" className="rounded border-border text-primary focus:ring-primary w-4 h-4 cursor-pointer" />
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full overflow-hidden bg-muted border border-border/50 shrink-0 relative">
                            {athlete.image ? (
                              <Image
                                alt={athlete.name}
                                src={athlete.image}
                                fill
                                sizes="40px"
                                className="object-cover"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center text-primary bg-primary-container/20 font-bold">
                                {athlete.name[0]}
                              </div>
                            )}
                          </div>
                          <div>
                            <p className="font-semibold text-foreground">{athlete.name}</p>
                            <p className="text-xs text-muted-foreground">ID: {athlete.id}</p>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-foreground font-medium" dir="ltr">
                        {athlete.phone}
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded bg-primary-container/20 flex items-center justify-center shrink-0 text-primary">
                            <Icon className="w-3.5 h-3.5" />
                          </div>
                          <span className="text-foreground">{athlete.department}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <span
                          className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold gap-1 ${
                            athlete.status === "active"
                              ? "bg-secondary/15 text-secondary"
                              : athlete.status === "expired"
                              ? "bg-error/15 text-error"
                              : "bg-amber-500/15 text-amber-600"
                          }`}
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${
                              athlete.status === "active"
                                ? "bg-secondary"
                                : athlete.status === "expired"
                                ? "bg-error"
                                : "bg-amber-500"
                            }`}
                          ></span>
                          {athlete.statusText}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-muted-foreground">{athlete.joinDate}</td>
                      <td className="py-3 px-6 text-left">
                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <Link href={`/dashboard/athletes/${athlete.id}`}>
                            <button className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors" title="عرض التفاصيل">
                              <Eye className="w-4 h-4" />
                            </button>
                          </Link>
                          <button className="p-2 rounded-lg text-muted-foreground hover:text-primary hover:bg-primary-container/20 transition-colors" title="تعديل">
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button className="p-2 rounded-lg text-muted-foreground hover:text-error hover:bg-error-container/50 transition-colors" title="المزيد">
                            <MoreVertical className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination bar */}
          <div className="bg-white/50 border-t border-border/20 p-4 flex items-center justify-between text-xs text-muted-foreground">
            <span>عرض 1 إلى {filteredAthletes.length} من أصل {athletes.length} رياضيين</span>
            <div className="flex items-center gap-1.5">
              <button className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted disabled:opacity-40 transition-colors" disabled>
                <ChevronRight className="w-4 h-4" />
              </button>
              <button className="w-8 h-8 rounded-lg flex items-center justify-center bg-primary text-primary-foreground font-semibold">1</button>
              <button className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted font-semibold transition-colors">2</button>
              <button className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted transition-colors">
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* Grid layout */
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredAthletes.map((athlete) => {
            const Icon = athlete.sportIcon;
            return (
              <div key={athlete.id} className="glass-card p-6 rounded-2xl flex flex-col justify-between gap-4 hover:shadow-md transition-all group">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full overflow-hidden bg-muted border border-border/50 shrink-0 relative">
                      {athlete.image ? (
                        <Image
                          alt={athlete.name}
                          src={athlete.image}
                          fill
                          sizes="48px"
                          className="object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-primary bg-primary-container/20 font-bold text-lg">
                          {athlete.name[0]}
                        </div>
                      )}
                    </div>
                    <div>
                      <h4 className="font-bold text-foreground text-sm">{athlete.name}</h4>
                      <p className="text-xs text-muted-foreground">ID: {athlete.id}</p>
                    </div>
                  </div>
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-xxs font-bold ${
                      athlete.status === "active"
                        ? "bg-secondary/15 text-secondary"
                        : athlete.status === "expired"
                        ? "bg-error/15 text-error"
                        : "bg-amber-500/15 text-amber-600"
                    }`}
                  >
                    {athlete.statusText}
                  </span>
                </div>
                <div className="space-y-2 text-xs text-muted-foreground border-t border-border/20 pt-4">
                  <div className="flex justify-between">
                    <span>الهاتف:</span>
                    <span className="text-foreground font-medium" dir="ltr">{athlete.phone}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>الفرع / القسم:</span>
                    <span className="text-foreground font-semibold flex items-center gap-1">
                      <Icon className="w-3.5 h-3.5" /> {athlete.department}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span>تاريخ الانضمام:</span>
                    <span className="text-foreground">{athlete.joinDate}</span>
                  </div>
                </div>
                <div className="flex gap-2 mt-2">
                  <Link href={`/dashboard/athletes/${athlete.id}`} className="flex-1">
                    <button className="w-full py-2 bg-primary-container/20 text-primary hover:bg-primary-container/40 text-xs font-semibold rounded-lg transition-colors flex items-center justify-center gap-1">
                      <Eye className="w-3.5 h-3.5" /> التفاصيل
                    </button>
                  </Link>
                  <button className="py-2 px-3 border border-border/60 hover:bg-muted text-muted-foreground hover:text-foreground rounded-lg transition-all">
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
