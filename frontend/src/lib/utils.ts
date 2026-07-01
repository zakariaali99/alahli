import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export const LIBYAN_PHONE_REGEX = /^09[1-5]\d{7}$/

export function validateLibyanPhone(phone: string): string | null {
  if (!phone) return "يرجى إدخال رقم الهاتف"
  if (!LIBYAN_PHONE_REGEX.test(phone.trim()))
    return "رقم هاتف ليبي غير صالح. يجب أن يبدأ بـ 091-095 ويتكون من 10 أرقام"
  return null
}
