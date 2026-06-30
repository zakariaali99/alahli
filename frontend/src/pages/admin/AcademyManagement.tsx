import { useEffect, useMemo, useState, type FormEvent } from "react"
import { AnimatePresence, motion } from "framer-motion"
import { Building2, ChevronLeft, Layers3, Pencil, Plus, Trash2, Users, X } from "lucide-react"
import { Button } from "@/components/ui/button"
import { LoadingSpinner } from "@/components/ui/loading-spinner"
import { api } from "@/lib/api"
import { extractResults } from "@/lib/response"
import type { Department, Group, Sport } from "@/lib/types"

const WEEK_DAYS = [
  { value: "saturday", label: "السبت" },
  { value: "sunday", label: "الأحد" },
  { value: "monday", label: "الإثنين" },
  { value: "tuesday", label: "الثلاثاء" },
  { value: "wednesday", label: "الأربعاء" },
  { value: "thursday", label: "الخميس" },
  { value: "friday", label: "الجمعة" },
]

type Stage = "academies" | "sports" | "groups"

type AcademyForm = { nameAr: string; name: string; color: string; bankAccountNumber: string; iban: string }
type SportForm = { nameAr: string; name: string }
type GroupForm = { nameAr: string; name: string; coach: string; startTime: string; endTime: string; days: string[] }

export default function AcademyManagement() {
  const [stage, setStage] = useState<Stage>("academies")
  const [academies, setAcademies] = useState<Department[]>([])
  const [sportsByAcademy, setSportsByAcademy] = useState<Record<number, Sport[]>>({})
  const [groupsBySport, setGroupsBySport] = useState<Record<number, Group[]>>({})
  const [coaches, setCoaches] = useState<Array<{ id: number; full_name_ar: string; photo: string | null }>>([])

  const [selectedAcademyId, setSelectedAcademyId] = useState<number | null>(null)
  const [selectedSportId, setSelectedSportId] = useState<number | null>(null)

  const [loading, setLoading] = useState(true)
  const [pageError, setPageError] = useState<string | null>(null)
  const [flash, setFlash] = useState<string | null>(null)

  const [modalType, setModalType] = useState<"academy" | "sport" | "group" | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [modalError, setModalError] = useState<string | null>(null)

  const [academyForm, setAcademyForm] = useState<AcademyForm>({ nameAr: "", name: "", color: "#1570EF", bankAccountNumber: "", iban: "" })
  const [editingAcademy, setEditingAcademy] = useState<Department | null>(null)
  const [editingSport, setEditingSport] = useState<Sport | null>(null)
  const [sportForm, setSportForm] = useState<SportForm>({ nameAr: "", name: "" })
  const [groupForm, setGroupForm] = useState<GroupForm>({ nameAr: "", name: "", coach: "", startTime: "16:00", endTime: "17:00", days: [] })
  const [editingGroup, setEditingGroup] = useState<Group | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<{ type: "academy" | "sport" | "group"; id: number; name: string } | null>(null)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => { void fetchAcademies() }, [])
  useEffect(() => { if (flash) { const t = setTimeout(() => setFlash(null), 2800); return () => clearTimeout(t) } }, [flash])

  const selectedAcademy = academies.find((a) => a.id === selectedAcademyId) ?? null
  const academySports = selectedAcademyId ? sportsByAcademy[selectedAcademyId] || [] : []
  const selectedSport = academySports.find((s) => s.id === selectedSportId) ?? null
  const sportGroups = selectedSportId ? groupsBySport[selectedSportId] || [] : []

  const totalSports = useMemo(() => Object.values(sportsByAcademy).reduce((a, l) => a + l.length, 0), [sportsByAcademy])
  const totalGroups = useMemo(() => Object.values(groupsBySport).reduce((a, l) => a + l.length, 0), [groupsBySport])

  const fetchAcademies = async () => {
    setLoading(true); setPageError(null)
    try {
      const data = await api.get<{ results: Department[] } | Department[]>("/departments/")
      setAcademies(extractResults(data))
    } catch { setPageError("تعذر تحميل الأكاديميات") }
    finally { setLoading(false) }
  }

  const fetchSports = async (academyId: number) => {
    try {
      const data = await api.get<{ results: Sport[] } | Sport[]>(`/sports/?department=${academyId}`)
      setSportsByAcademy((p) => ({ ...p, [academyId]: extractResults(data) }))
    } catch { setPageError("تعذر تحميل الرياضات") }
  }

  const fetchGroups = async (sportId: number) => {
    try {
      const data = await api.get<{ results: Group[] } | Group[]>(`/groups/?sport=${sportId}`)
      setGroupsBySport((p) => ({ ...p, [sportId]: extractResults(data) }))
    } catch { setPageError("تعذر تحميل المجموعات") }
  }

  const loadCoaches = async () => {
    if (coaches.length > 0) return
    try {
      const data = await api.get<{ results: Array<{ id: number; full_name_ar: string; photo: string | null }> } | Array<{ id: number; full_name_ar: string; photo: string | null }>>("/auth/users/?role=trainer")
      setCoaches(extractResults(data))
    } catch { setModalError("تعذر تح المدربين") }
  }

  const openAcademyCard = async (academy: Department) => {
    setSelectedAcademyId(academy.id)
    setSelectedSportId(null)
    setStage("sports")
    if (!sportsByAcademy[academy.id]) await fetchSports(academy.id)
  }

  const openSportCard = async (sport: Sport) => {
    setSelectedSportId(sport.id)
    setStage("groups")
    if (!groupsBySport[sport.id]) await fetchGroups(sport.id)
  }

  const openEditGroupModal = async (group: Group) => {
    setEditingGroup(group)
    setGroupForm({
      nameAr: group.name_ar,
      name: group.name,
      coach: group.coach ? String(group.coach) : "",
      startTime: group.start_time,
      endTime: group.end_time,
      days: Array.isArray(group.days) ? group.days : [],
    })
    setModalError(null)
    setModalType("group")
    await loadCoaches()
  }

  const openEditSportModal = async (sport: Sport) => {
    setEditingSport(sport)
    setSportForm({ nameAr: sport.name_ar, name: sport.name })
    setModalError(null)
    setModalType("sport")
  }

  const openEditAcademyModal = (academy: Department) => {
    setEditingAcademy(academy)
    setAcademyForm({ nameAr: academy.name_ar, name: academy.name, color: academy.color, bankAccountNumber: academy.bank_account_number || "", iban: academy.iban || "" })
    setModalError(null)
    setModalType("academy")
  }

  const openModal = async (type: "academy" | "sport" | "group") => {
    setEditingAcademy(null)
    setEditingSport(null)
    setEditingGroup(null)
    setModalError(null)
    setModalType(type)
    if (type === "academy") setAcademyForm({ nameAr: "", name: "", color: "#1570EF", bankAccountNumber: "", iban: "" })
    if (type === "sport") setSportForm({ nameAr: "", name: "" })
    if (type === "group") {
      setGroupForm({ nameAr: "", name: "", coach: "", startTime: "16:00", endTime: "17:00", days: [] })
      await loadCoaches()
    }
  }

  const closeModal = () => { if (!submitting) { setModalType(null); setModalError(null); setEditingAcademy(null); setEditingSport(null); setEditingGroup(null) } }

  const submitAcademy = async (e: FormEvent) => {
    e.preventDefault()
    if (!academyForm.nameAr.trim() || !academyForm.name.trim()) { setModalError("يرجى تعبئة الاسم بالعربية والإنجليزية"); return }
    try {
      setSubmitting(true); setModalError(null)
      const payload = {
        name_ar: academyForm.nameAr.trim(), name: academyForm.name.trim(),
        color: academyForm.color, is_active: true,
        bank_account_number: academyForm.bankAccountNumber.trim(),
        iban: academyForm.iban.trim(),
      }
      if (editingAcademy) {
        await api.put(`/departments/${editingAcademy.id}/`, payload)
        setFlash("تم تحديث الأكاديمية بنجاح")
      } else {
        await api.post("/departments/", payload)
        setFlash("تمت إضافة الأكاديمية بنجاح")
      }
      closeModal(); await fetchAcademies()
    } catch (err: any) { setModalError(err?.message || "فشل الحفظ") }
    finally { setSubmitting(false) }
  }

  const submitSport = async (e: FormEvent) => {
    e.preventDefault()
    if (!selectedAcademyId) return
    if (!sportForm.nameAr.trim() || !sportForm.name.trim()) { setModalError("يرجى تعبئة الاسم بالعربية والإنجليزية"); return }
    try {
      setSubmitting(true); setModalError(null)
      const payload = { department: selectedAcademyId, name_ar: sportForm.nameAr.trim(), name: sportForm.name.trim(), is_active: true }
      if (editingSport) {
        await api.put(`/sports/${editingSport.id}/`, payload)
        setFlash("تم تحديث الرياضة بنجاح")
      } else {
        await api.post("/sports/", payload)
        setFlash("تمت إضافة الرياضة بنجاح")
      }
      closeModal(); await fetchSports(selectedAcademyId)
    } catch (err: any) { setModalError(err?.message || "فشل الحفظ") }
    finally { setSubmitting(false) }
  }

  const submitGroup = async (e: FormEvent) => {
    e.preventDefault()
    if (!selectedSportId) return
    if (!groupForm.nameAr.trim() || !groupForm.name.trim()) { setModalError("يرجى تعبئة الاسم بالعربية والإنجليزية"); return }
    if (groupForm.days.length === 0) { setModalError("اختر يوم واحد على الأقل"); return }
    if (groupForm.startTime >= groupForm.endTime) { setModalError("وقت النهاية يجب أن يكون بعد البداية"); return }
    try {
      setSubmitting(true); setModalError(null)
      const payload = {
        sport: selectedSportId, name_ar: groupForm.nameAr.trim(), name: groupForm.name.trim(),
        coach: groupForm.coach ? Number(groupForm.coach) : null,
        days: groupForm.days, start_time: groupForm.startTime, end_time: groupForm.endTime, is_active: true,
      }
      if (editingGroup) {
        await api.put(`/groups/${editingGroup.id}/`, payload)
        setFlash("تم تحديث المجموعة بنجاح")
      } else {
        await api.post("/groups/", payload)
        setFlash("تمت إضافة المجموعة بنجاح")
      }
      closeModal(); await fetchGroups(selectedSportId)
    } catch (err: any) { setModalError(err?.message || "فشل الحفظ") }
    finally { setSubmitting(false) }
  }

  const confirmDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      const endpoints: Record<string, string> = {
        academy: `/departments/${deleteTarget.id}/`,
        sport: `/sports/${deleteTarget.id}/`,
        group: `/groups/${deleteTarget.id}/`,
      }
      await api.delete(endpoints[deleteTarget.type])
      setFlash(`تم حذف ${deleteTarget.name} بنجاح`)
      setDeleteTarget(null)
      if (deleteTarget.type === "academy") await fetchAcademies()
      if (deleteTarget.type === "sport" && selectedAcademyId) await fetchSports(selectedAcademyId)
      if (deleteTarget.type === "group" && selectedSportId) await fetchGroups(selectedSportId)
    } catch (err: any) {
      setPageError(err?.message || "فشل الحذف")
    } finally {
      setDeleting(false)
    }
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="space-y-5">
      {flash && <div className="fixed left-4 right-4 top-4 z-[80] rounded-xl border border-secondary/30 bg-secondary/15 px-4 py-3 text-sm text-secondary shadow-lg md:left-auto md:max-w-sm">{flash}</div>}

      {/* Header */}
      <div className="rounded-2xl border border-border bg-card p-5">
        <h2 className="text-xl font-bold">إدارة الأكاديميات</h2>
        <p className="mt-1 text-xs text-muted-foreground">تصفح الأكاديميات والرياضات والمجموعات عبر بطاقات تفاعلية.</p>
      </div>

      {/* Stats */}
      <div className="grid gap-3 sm:grid-cols-3">
        <StatCard label="الأكاديميات" value={academies.length} />
        <StatCard label="الرياضات" value={totalSports} />
        <StatCard label="المجموعات" value={totalGroups} />
      </div>

      {pageError && <div className="rounded-xl border border-error/30 bg-error/10 p-3 text-xs text-error">{pageError}</div>}

      {/* Breadcrumb */}
      {stage !== "academies" && (
        <div className="flex flex-wrap items-center gap-1 text-sm">
          <button className="font-semibold text-primary hover:underline" onClick={() => setStage("academies")}>الأكاديميات</button>
          {selectedAcademy && (<><ChevronLeft className="h-4 w-4" /><button className="font-semibold text-primary hover:underline" onClick={() => setStage("sports")}>{selectedAcademy.name_ar}</button></>)}
          {stage === "groups" && selectedSport && (<><ChevronLeft className="h-4 w-4" /><span className="font-bold">{selectedSport.name_ar}</span></>)}
        </div>
      )}

      {/* Stage: Academies */}
      {stage === "academies" && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="inline-flex items-center gap-2 text-sm font-bold"><Building2 className="h-4 w-4" /> الأكاديميات</h3>
            <Button size="sm" variant="outline" onClick={() => void openModal("academy")}><Plus className="h-4 w-4" /> إضافة أكاديمية</Button>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {academies.length === 0 && <EmptyState message="لا توجد أكاديميات. ابدأ بإضافة واحدة جديدة." />}
            {academies.map((academy) => (
              <motion.div key={academy.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} whileHover={{ y: -4 }} className="group relative cursor-pointer rounded-2xl border-2 border-border bg-card p-5 transition hover:border-primary" onClick={() => void openAcademyCard(academy)}>
                <div className="absolute left-2 top-2 z-10 flex gap-1 opacity-0 transition group-hover:opacity-100">
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-primary/10 text-primary hover:bg-primary/20" onClick={(e) => { e.stopPropagation(); openEditAcademyModal(academy) }}><Pencil className="h-3.5 w-3.5" /></button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-error/10 text-error hover:bg-error/20" onClick={(e) => { e.stopPropagation(); setDeleteTarget({ type: "academy", id: academy.id, name: academy.name_ar }) }}><Trash2 className="h-3.5 w-3.5" /></button>
                </div>
                <div className="flex items-start gap-3">
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl text-lg font-bold text-white shadow" style={{ backgroundColor: academy.color }}>
                    {(academy.name_ar || "?").charAt(0)}
                  </div>
                  <div className="flex-1">
                    <p className="font-bold">{academy.name_ar}</p>
                    <p className="text-xs text-muted-foreground" dir="ltr">{academy.name}</p>
                  </div>
                </div>
                <div className="mt-3 flex items-center gap-1 text-xs text-muted-foreground">
                  <Layers3 className="h-3.5 w-3.5" />
                  {(sportsByAcademy[academy.id] || []).length} رياضة
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      )}

      {/* Stage: Sports */}
      {stage === "sports" && selectedAcademy && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="inline-flex items-center gap-2 text-sm font-bold"><Layers3 className="h-4 w-4" /> رياضات {selectedAcademy.name_ar}</h3>
            <Button size="sm" variant="outline" onClick={() => void openModal("sport")}><Plus className="h-4 w-4" /> إضافة رياضة</Button>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {academySports.length === 0 && <EmptyState message="لا توجد رياضات في هذه الأكاديمية." />}
            {academySports.map((sport) => (
              <motion.div key={sport.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} whileHover={{ y: -4 }} className="group relative cursor-pointer rounded-2xl border-2 border-border bg-card p-5 transition hover:border-primary" onClick={() => void openSportCard(sport)}>
                <div className="absolute left-2 top-2 z-10 flex gap-1 opacity-0 transition group-hover:opacity-100">
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-primary/10 text-primary hover:bg-primary/20" onClick={(e) => { e.stopPropagation(); openEditSportModal(sport) }}><Pencil className="h-3.5 w-3.5" /></button>
                  <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-error/10 text-error hover:bg-error/20" onClick={(e) => { e.stopPropagation(); setDeleteTarget({ type: "sport", id: sport.id, name: sport.name_ar }) }}><Trash2 className="h-3.5 w-3.5" /></button>
                </div>
                <div className="flex items-start gap-3">
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-lg font-bold text-primary">
                    {(sport.name_ar || "?").charAt(0)}
                  </div>
                  <div className="flex-1">
                    <p className="font-bold">{sport.name_ar}</p>
                    <p className="text-xs text-muted-foreground" dir="ltr">{sport.name}</p>
                  </div>
                </div>
                <div className="mt-3 flex items-center gap-1 text-xs text-muted-foreground">
                  <Users className="h-3.5 w-3.5" />
                  {(groupsBySport[sport.id] || []).length} مجموعة
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      )}

      {/* Stage: Groups */}
      {stage === "groups" && selectedSport && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="inline-flex items-center gap-2 text-sm font-bold"><Users className="h-4 w-4" /> مجموعات {selectedSport.name_ar}</h3>
            <Button size="sm" variant="outline" onClick={() => void openModal("group")}><Plus className="h-4 w-4" /> إضافة مجموعة</Button>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {sportGroups.length === 0 && <EmptyState message="لا توجد مجموعات في هذه الرياضة." />}
            {sportGroups.map((group) => {
              const coach = coaches.find((c) => c.id === group.coach)
              return (
                <motion.div key={group.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} whileHover={{ y: -4 }} className="group relative cursor-pointer rounded-2xl border-2 border-border bg-card p-5 transition hover:border-primary" onClick={() => void openEditGroupModal(group)}>
                  <div className="absolute left-2 top-2 z-10 flex gap-1 opacity-0 transition group-hover:opacity-100">
                    <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-primary/10 text-primary hover:bg-primary/20" onClick={(e) => { e.stopPropagation(); void openEditGroupModal(group) }}><Pencil className="h-3.5 w-3.5" /></button>
                    <button className="flex h-7 w-7 items-center justify-center rounded-lg bg-error/10 text-error hover:bg-error/20" onClick={(e) => { e.stopPropagation(); setDeleteTarget({ type: "group", id: group.id, name: group.name_ar }) }}><Trash2 className="h-3.5 w-3.5" /></button>
                  </div>
                  <p className="font-bold">{group.name_ar}</p>
                  <p className="text-xs text-muted-foreground" dir="ltr">{group.name}</p>

                  <div className="mt-3 flex items-center gap-2">
                    {coach?.photo ? <img src={coach.photo} alt={coach.full_name_ar} className="h-7 w-7 rounded-full object-cover" /> : <div className="flex h-7 w-7 items-center justify-center rounded-full bg-muted text-xs"><Users className="h-3.5 w-3.5" /></div>}
                    <span className="text-xs text-muted-foreground">{group.coach_name || "بدون مدرب"}</span>
                  </div>

                  <div className="mt-2 flex flex-wrap gap-1">
                    {(Array.isArray(group.days) ? group.days : []).map((d) => {
                      const label = WEEK_DAYS.find((w) => w.value === d)?.label || d
                      return <span key={d} className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] text-primary">{label}</span>
                    })}
                  </div>

                  <p className="mt-2 text-xs text-muted-foreground" dir="ltr">{group.start_time} - {group.end_time}</p>
                </motion.div>
              )
            })}
          </div>
        </div>
      )}

      {/* Modals */}
      <AnimatePresence>
        {modalType && (
          <Modal title={modalType === "academy" ? (editingAcademy ? "تعديل الأكاديمية" : "إضافة أكاديمية") : modalType === "sport" ? (editingSport ? "تعديل الرياضة" : "إضافة رياضة") : editingGroup ? "تعديل المجموعة" : "إضافة مجموعة"} onClose={closeModal}>
            {modalType === "academy" && (
              <form className="space-y-3" onSubmit={submitAcademy}>
                <ModalField label="الاسم (عربي)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={academyForm.nameAr} onChange={(e) => setAcademyForm((p) => ({ ...p, nameAr: e.target.value }))} /></ModalField>
                <ModalField label="الاسم (English)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={academyForm.name} onChange={(e) => setAcademyForm((p) => ({ ...p, name: e.target.value }))} /></ModalField>
                <ModalField label="اللون"><input className="h-10 w-full rounded-xl border border-border p-1" type="color" value={academyForm.color} onChange={(e) => setAcademyForm((p) => ({ ...p, color: e.target.value }))} /></ModalField>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <ModalField label="رقم الحساب المصرفي">
                    <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={academyForm.bankAccountNumber} onChange={(e) => setAcademyForm((p) => ({ ...p, bankAccountNumber: e.target.value }))} />
                  </ModalField>
                  <ModalField label="الآيبان (IBAN)">
                    <input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={academyForm.iban} onChange={(e) => setAcademyForm((p) => ({ ...p, iban: e.target.value }))} />
                  </ModalField>
                </div>
                {modalError && <p className="text-xs text-error">{modalError}</p>}
                <div className="flex justify-end gap-2"><Button type="button" variant="ghost" onClick={closeModal}>إلغاء</Button><Button type="submit" disabled={submitting}>{submitting ? "جارٍ..." : "حفظ"}</Button></div>
              </form>
            )}
            {modalType === "sport" && (
              <form className="space-y-3" onSubmit={submitSport}>
                <ModalField label="الأكاديمية"><p className="rounded-xl border border-border bg-surface-container-low px-3 py-2 text-sm">{selectedAcademy?.name_ar}</p></ModalField>
                <ModalField label="اسم الرياضة (عربي)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={sportForm.nameAr} onChange={(e) => setSportForm((p) => ({ ...p, nameAr: e.target.value }))} /></ModalField>
                <ModalField label="اسم الرياضة (English)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={sportForm.name} onChange={(e) => setSportForm((p) => ({ ...p, name: e.target.value }))} /></ModalField>
                {modalError && <p className="text-xs text-error">{modalError}</p>}
                <div className="flex justify-end gap-2"><Button type="button" variant="ghost" onClick={closeModal}>إلغاء</Button><Button type="submit" disabled={submitting}>{submitting ? "جارٍ..." : "حفظ"}</Button></div>
              </form>
            )}
            {modalType === "group" && (
              <form className="space-y-3" onSubmit={submitGroup}>
                <ModalField label="الرياضة"><p className="rounded-xl border border-border bg-surface-container-low px-3 py-2 text-sm">{selectedSport?.name_ar}</p></ModalField>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <ModalField label="اسم المجموعة (عربي)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={groupForm.nameAr} onChange={(e) => setGroupForm((p) => ({ ...p, nameAr: e.target.value }))} /></ModalField>
                  <ModalField label="اسم المجموعة (English)"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" dir="ltr" value={groupForm.name} onChange={(e) => setGroupForm((p) => ({ ...p, name: e.target.value }))} /></ModalField>
                </div>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                  <ModalField label="المدرب">
                    <select className="w-full appearance-none cursor-pointer bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" value={groupForm.coach} onChange={(e) => setGroupForm((p) => ({ ...p, coach: e.target.value }))}>
                      <option value="">بدون مدرب</option>
                      {coaches.map((c) => <option key={c.id} value={c.id}>{c.full_name_ar}</option>)}
                    </select>
                  </ModalField>
                  <ModalField label="وقت البداية"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="time" value={groupForm.startTime} onChange={(e) => setGroupForm((p) => ({ ...p, startTime: e.target.value }))} /></ModalField>
                  <ModalField label="وقت النهاية"><input className="w-full bg-surface-container-low border border-border rounded-xl px-3 py-2.5 text-sm text-foreground outline-none focus:ring-2 focus:ring-primary focus:border-primary transition-colors" type="time" value={groupForm.endTime} onChange={(e) => setGroupForm((p) => ({ ...p, endTime: e.target.value }))} /></ModalField>
                </div>
                <div>
                  <p className="mb-1 text-xs text-muted-foreground">أيام التدريب</p>
                  <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                    {WEEK_DAYS.map((day) => (
                      <label key={day.value} className="flex items-center gap-2 rounded-lg border border-border px-2 py-1.5 text-xs">
                        <input type="checkbox" checked={groupForm.days.includes(day.value)} onChange={() => setGroupForm((p) => ({ ...p, days: p.days.includes(day.value) ? p.days.filter((d) => d !== day.value) : [...p.days, day.value] }))} />
                        {day.label}
                      </label>
                    ))}
                  </div>
                </div>
                {modalError && <p className="text-xs text-error">{modalError}</p>}
                <div className="flex justify-end gap-2"><Button type="button" variant="ghost" onClick={closeModal}>إلغاء</Button><Button type="submit" disabled={submitting}>{submitting ? "جارٍ..." : "حفظ"}</Button></div>
              </form>
            )}
          </Modal>
        )}
      </AnimatePresence>

      {deleteTarget && (
        <div className="fixed inset-0 z-50 bg-black/50 p-4 flex items-center justify-center" onClick={() => { if (!deleting) setDeleteTarget(null) }}>
          <div className="w-full max-w-md rounded-2xl border border-border bg-card p-5 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold">تأكيد الحذف</h3>
            <p className="text-sm text-muted-foreground">
              هل أنت متأكد من حذف <span className="font-semibold text-foreground">{deleteTarget.name}</span>؟ لا يمكن التراجع عن هذا الإجراء.
            </p>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" disabled={deleting} onClick={() => setDeleteTarget(null)}>إلغاء</Button>
              <Button type="button" variant="destructive" disabled={deleting} onClick={confirmDelete}>
                {deleting ? "جاري الحذف..." : "حذف"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="mt-1 text-2xl font-extrabold">{value.toLocaleString("ar-SA-u-nu-latn")}</p>
    </div>
  )
}

function EmptyState({ message }: { message: string }) {
  return <div className="col-span-full rounded-xl border border-border bg-surface-container-low p-6 text-center text-sm text-muted-foreground">{message}</div>
}

function ModalField({ label, children }: { label: string; children: React.ReactNode }) {
  return (<div><label className="mb-1 block text-xs text-muted-foreground">{label}</label>{children}</div>)
}

function Modal({ title, children, onClose }: { title: string; children: React.ReactNode; onClose: () => void }) {
  return (
    <motion.div animate={{ opacity: 1 }} className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" exit={{ opacity: 0 }} initial={{ opacity: 0 }} onClick={onClose}>
      <motion.div animate={{ opacity: 1, scale: 1 }} className="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-2xl border border-border bg-card p-5" exit={{ opacity: 0, scale: 0.96 }} initial={{ opacity: 0, scale: 0.96 }} onClick={(e) => e.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-bold">{title}</h3>
          <button aria-label="close" className="text-muted-foreground hover:text-foreground" onClick={onClose} type="button"><X className="h-5 w-5" /></button>
        </div>
        {children}
      </motion.div>
    </motion.div>
  )
}