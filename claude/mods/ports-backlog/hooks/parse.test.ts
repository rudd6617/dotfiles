import { test, expect } from 'claude-code/testing'
import { mergePorts, parseBacklog, parseDockerPorts, parsePorts } from './parse'

test('parsePorts dedupes and sorts listening ports', async () => {
  const out = [
    'COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME',
    'com.docke 812 rudolf 120u IPv6 0x1 0t0 TCP *:8080 (LISTEN)',
    'com.docke 812 rudolf 121u IPv4 0x2 0t0 TCP *:8080 (LISTEN)',
    'node     4410 rudolf  22u IPv4 0x3 0t0 TCP 127.0.0.1:5173 (LISTEN)',
  ].join('\n')
  expect(parsePorts(out)).toEqual([
    { port: '5173', command: 'node', pid: '4410' },
    { port: '8080', command: 'com.docke', pid: '812' },
  ])
})

test('parseBacklog takes ### headings of the first 🎯 section only', async () => {
  const md = [
    '# t',
    '## 🎯 真實剩餘（x）',
    '### 阻擋第一階段上線（3）',
    'body',
    '### 🆕 Deepen 第十四輪候選 11 條（2026-09-22；**①②⑦ 已收，剩 8 條等你挑**）',
    '## 🔴 other',
    '### ignored',
  ].join('\n')
  expect(parseBacklog(md)).toEqual(['阻擋第一階段上線 (3)', '🆕 Deepen 第十四輪候選 11 條 (剩 8)'])
})

test('parseDockerPorts takes host ports per compose service, ipv4/ipv6 deduped', async () => {
  const out = [
    'mysql\t0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp, 33060/tcp',
    'nginx\t0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:8080->80/tcp',
    'php\t9000/tcp',
  ].join('\n')
  expect(mergePorts(parseDockerPorts(out)).map(p => `${p.port} ${p.command}`)).toEqual([
    '80 nginx', '3306 mysql', '8080 nginx',
  ])
})
