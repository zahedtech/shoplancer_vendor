// User profile (name/email/default note) stored locally per-device.
// Phone is stored separately via cartSync.ts (PHONE_KEY).
const KEY = "shoplanser_profile_v1";

export interface UserProfile {
  name: string;
  email?: string;
  notes?: string;
}

export function getProfile(): UserProfile {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return { name: "", email: "", notes: "" };
    return JSON.parse(raw) as UserProfile;
  } catch {
    return { name: "", email: "", notes: "" };
  }
}

export function saveProfile(profile: UserProfile) {
  try {
    localStorage.setItem(KEY, JSON.stringify(profile));
  } catch {
    /* ignore */
  }
}
