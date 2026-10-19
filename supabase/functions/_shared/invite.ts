export function inviteLink(base: string, code: string): string {
  return `${base.replace(/\/+$/, '')}/${encodeURIComponent(code)}`;
}
