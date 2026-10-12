import type { Port } from '../types'

// lsof -nP -iTCP -sTCP:LISTEN: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (LISTEN)
export function parsePorts(stdout: string): Port[] {
  const seen = new Map<string, Port>()
  for (const line of stdout.split('\n').slice(1)) {
    const cols = line.trim().split(/\s+/)
    if (cols.length < 9) continue
    const name = cols[cols.length - 2] ?? ''
    const port = name.slice(name.lastIndexOf(':') + 1)
    if (!/^\d+$/.test(port) || seen.has(port)) continue
    seen.set(port, { port, command: (cols[0] ?? '').replace(/\\x20/g, ' '), pid: cols[1] ?? '' })
  }
  return [...seen.values()].sort((a, b) => Number(a.port) - Number(b.port))
}

// The ### headings inside the first "## 🎯 真實剩餘" section.
export function parseBacklog(md: string): string[] {
  const lines = md.split('\n')
  const start = lines.findIndex(l => l.startsWith('## 🎯'))
  if (start < 0) return []
  const out: string[] = []
  for (const line of lines.slice(start + 1)) {
    if (line.startsWith('## ')) break
    if (!line.startsWith('### ')) continue
    out.push(line.slice(4).replace(/\*\*/g, '').replace(/[（(].*$/, '').trim() + count(line))
  }
  return out
}

function count(line: string): string {
  const m = line.match(/[（(](\d+)[，,）)]/)
  if (m) return ` (${m[1]})`
  const left = line.match(/剩\s*(\d+)\s*條/)
  return left ? ` (剩 ${left[1]})` : ''
}

// docker ps --format '{{.Label "com.docker.compose.service"}}\t{{.Ports}}'
// "nginx\t0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:8080->80/tcp"
export function parseDockerPorts(stdout: string): Port[] {
  const seen = new Map<string, Port>()
  for (const line of stdout.split('\n')) {
    const [service = '', ports = ''] = line.split('\t')
    for (const m of ports.matchAll(/:(\d+)->\d+\/tcp/g)) {
      const port = m[1] ?? ''
      if (!seen.has(port)) seen.set(port, { port, command: service, pid: '' })
    }
  }
  return [...seen.values()]
}

export function mergePorts(...lists: Port[][]): Port[] {
  const seen = new Map<string, Port>()
  for (const p of lists.flat()) if (!seen.has(p.port)) seen.set(p.port, p)
  return [...seen.values()].sort((a, b) => Number(a.port) - Number(b.port))
}
