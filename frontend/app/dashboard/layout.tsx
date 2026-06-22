"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  CreditCard,
  QrCode,
  Bell,
  BarChart3,
  Settings,
  LogOut,
  Search,
  Grid,
  TrendingUp,
} from "lucide-react";
import Image from "next/image";

interface DashboardLayoutProps {
  children: React.ReactNode;
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [userName, setUserName] = useState("المسؤول");
  
  // Set default theme: 'ahly' or 'aws'
  const [academyTheme, setAcademyTheme] = useState<"ahly" | "aws">("ahly");

  useEffect(() => {
    // Read local storage info
    const storedName = localStorage.getItem("user_name");
    if (storedName) {
      setUserName(storedName);
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("user_token");
    localStorage.removeItem("user_role");
    localStorage.removeItem("user_name");
    router.push("/login");
  };

  const toggleTheme = () => {
    setAcademyTheme((prev) => (prev === "ahly" ? "aws" : "ahly"));
  };

  // Menu items config with RTL flows
  const menuItems = [
    { name: "لوحة القيادة", path: "/dashboard", icon: LayoutDashboard },
    { name: "اللاعبين", path: "/dashboard/athletes", icon: Users },
    { name: "الاشتراكات", path: "/dashboard/memberships", icon: CreditCard },
    { name: "الفحص السريع", path: "/dashboard/verify", icon: QrCode },
    { name: "التنبيهات", path: "/dashboard/notifications", icon: Bell, badge: 3 },
    { name: "التقارير", path: "/dashboard/reports", icon: BarChart3 },
  ];

  return (
    <div className={`min-h-screen bg-background text-foreground flex flex-col transition-colors duration-300 ${academyTheme === "aws" ? "theme-aws" : "theme-ahly"}`}>
      {/* Top Header */}
      <header className="fixed top-0 left-0 right-0 h-16 z-40 bg-white/70 dark:bg-card/70 backdrop-blur-md border-b border-border/40 flex justify-between items-center px-8 w-full pr-[288px] rtl">
        <div className="flex items-center gap-4">
          {/* Search bar */}
          <div className="relative hidden sm:block">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground w-4 h-4" />
            <input
              className="bg-surface-container-low border-none rounded-full py-2 pr-9 pl-4 w-64 text-sm text-foreground placeholder:text-muted-foreground focus:ring-2 focus:ring-primary focus:bg-white transition-all outline-none"
              placeholder="بحث..."
              type="text"
            />
          </div>
        </div>

        <div className="flex items-center gap-6">
          <span className={`font-bold text-lg transition-colors ${academyTheme === 'aws' ? 'text-[#1E7A43]' : 'text-primary'}`}>
            إدارة الرياضة
          </span>
          <div className="flex items-center gap-3 border-r border-border/40 pr-6 mr-2">
            <button className="w-10 h-10 rounded-full flex items-center justify-center text-muted-foreground hover:bg-surface-container hover:text-foreground transition-colors relative">
              <Bell className="w-5 h-5" />
              <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-error rounded-full"></span>
            </button>
            <button className="w-10 h-10 rounded-full flex items-center justify-center text-muted-foreground hover:bg-surface-container hover:text-foreground transition-colors">
              <Grid className="w-5 h-5" />
            </button>
            {/* User Profile Avatar */}
            <div className="w-10 h-10 rounded-full overflow-hidden border-2 border-primary-container shrink-0 relative">
              <Image
                alt="صورة المستخدم"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuDGGWjdYMNAuEUlX3_EM-M5C_X614HuhQqcHXtUnmVNwOn2aqxNwXRB09c0OeQ6gxeSE7UazvUXA4Gjgy2hJUp-LfKNqbbVPm_77o2WuyzuqdCBpU67sTF3-J2D7CVq9ETiX9l2QMxRML3H4n3sWfSJ8UZh-NCco85SYTmIrveHsRx-2i0JNzQP02SdZEiVY4uN60EbtggO81P4E0E4wIf6-9zJbKHTkJTPMAVktn1AIXIK5XQTfDJZQz5oHgfIhNJ-rt9bOUbosws"
                fill
                sizes="40px"
                className="object-cover"
              />
            </div>
          </div>
        </div>
      </header>

      {/* Right Sidebar Navigation */}
      <nav className="h-screen w-72 fixed right-0 top-0 border-l border-border/40 bg-white/80 dark:bg-card/85 backdrop-blur-xl flex flex-col p-6 space-y-8 rtl z-50 shadow-md">
        {/* Brand / Header */}
        <div className="flex flex-col items-start gap-4">
          <div className="w-16 h-16 rounded-xl bg-primary-container text-on-primary-container flex items-center justify-center shadow-md relative overflow-hidden">
            <Image
              alt="شعار النادي"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDzd-Fz8J0E-KmHaxFHJtcTAs2IbV7LjcEWBB0VFr9qsMife67LAhnwqm0EUiJQf550FSNCPzLJapxFXxNc-m67jHNnqVpAeav8A0qExgnHtMdVPdP1_NgVXu0yXKlbLYfzoPAsPFCwOczVyS_MnYe9hN5JRjoavwDTRwaAvDICgjb_LgGjnZ4N9atlApWPKYZ5zZxe_H_3NcZpR3h1lRHTUF-ftHnSruOZJChFQVzddBoNWeVYijUDreEVARSbOH6Igx4h_32q1_0"
              width={48}
              height={48}
              className="object-contain"
            />
          </div>
          <div>
            <h1 className="text-lg font-bold text-foreground">
              {academyTheme === "aws" ? "أكاديمية العوز" : "الأهلي للياقة البدنية"}
            </h1>
            <p className="text-xs text-muted-foreground mt-1">نظام إدارة الأداء الرياضي</p>
          </div>
          <button
            onClick={toggleTheme}
            className="w-full py-2 px-4 mt-2 bg-muted/60 border border-primary/10 rounded-lg text-primary hover:bg-primary-container/20 transition-all flex items-center justify-center gap-2 text-xs font-semibold"
          >
            <TrendingUp className="w-4 h-4" />
            تبديل الأكاديمية (الفرع)
          </button>
        </div>

        {/* Main Links */}
        <div className="flex-1 overflow-y-auto space-y-2">
          {menuItems.map((item) => {
            const isActive = pathname === item.path;
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                href={item.path}
                className={`flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 group hover:translate-x-[-4px] ${
                  isActive
                    ? "bg-primary text-primary-foreground font-semibold"
                    : "text-muted-foreground hover:bg-surface-container hover:text-foreground"
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className="w-5 h-5" />
                  <span className="text-sm">{item.name}</span>
                </div>
                {item.badge && (
                  <span className="bg-error text-white text-xxs font-bold px-2 py-0.5 rounded-full">
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </div>

        {/* Footer Settings/Logout */}
        <div className="pt-4 border-t border-border/40 space-y-2">
          <Link
            href="/dashboard/settings"
            className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-colors ${
              pathname === "/dashboard/settings"
                ? "bg-primary text-primary-foreground font-semibold"
                : "text-muted-foreground hover:bg-surface-container hover:text-foreground"
            }`}
          >
            <Settings className="w-5 h-5" />
            <span className="text-sm">الإعدادات</span>
          </Link>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 text-error hover:bg-error/10 transition-colors rounded-xl text-right"
          >
            <LogOut className="w-5 h-5" />
            <span className="text-sm">تسجيل الخروج</span>
          </button>
        </div>
      </nav>

      {/* Main Content Area */}
      <main className="pt-24 pr-[288px] pb-10 pl-8 min-h-screen">
        <div className="max-w-7xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
