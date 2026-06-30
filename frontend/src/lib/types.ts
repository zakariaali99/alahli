export interface PaginatedResponse<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}

export interface Department {
  id: number
  name: string
  name_ar: string
  color: string
  logo: string | null
  bank_account_number: string
  iban: string
  is_active: boolean
  created_at: string
}

export interface Sport {
  id: number
  name: string
  name_ar: string
  department: number
  department_name: string
  is_active: boolean
  created_at: string
}

export interface Group {
  id: number
  name: string
  name_ar: string
  sport: number
  sport_name: string
  coach: number | null
  coach_name: string
  days: string[]
  start_time: string
  end_time: string
  is_active: boolean
  created_at: string
}

export interface Package {
  id: number
  name: string
  description: string
  price: string
  duration_type: "weeks" | "months"
  duration_value: number
  max_athletes: number
  tag: "discount" | "special" | "normal"
  features: string[]
  icon_name: string
  color_class: string
  is_active: boolean
  order: number
}

export interface RegistrationRequest {
  id: number
  user: number
  user_name: string
  user_phone: string
  athlete_id: number | null
  athlete_name: string | null
  athlete_photo: string | null
  athlete_membership_number: string | null
  athlete_department_name: string | null
  has_parent: boolean
  parent_name: string | null
  parent_phone: string | null
  role_choice: "athlete" | "parent"
  status: "pending" | "approved" | "rejected"
  reviewed_by: number | null
  reviewed_at: string | null
  created_at: string
}

export interface ParentAthlete {
  id: number
  parent: number
  athlete: number
  athlete_name: string
  athlete_membership: string
  relationship: string
  created_at: string
}

export interface Subscription {
  id: number
  athlete: number
  athlete_name: string
  membership_number: string
  package_name: string
  department_name: string | null
  start_date: string
  end_date: string
  amount: string
  payment_method: "cash" | "bank_transfer"
  invoice_pdf: string | null
  invoice_pdf_url: string | null
  group: number | null
  group_name: string
  status: "active" | "expired" | "pending" | "rejected"
  approved_by: number | null
  approved_at: string | null
  created_at: string
  updated_at: string
  renewals?: Renewal[]
}

export interface Renewal {
  id: number
  subscription: number
  amount: string
  months: number
  renewal_date: string
  created_by: number | null
  created_at: string
}
