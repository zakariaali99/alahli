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
  is_active: boolean
  created_at: string
}
