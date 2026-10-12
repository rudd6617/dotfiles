import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Snapshot } from '../types'
import { mergePorts, parseBacklog, parseDockerPorts, parsePorts } from './parse'

const PANE = 'ports-backlog'
const BACKLOG = '.claude/open-todo-backlog.md'
// Local dev servers of this project: vite, sa-doc preview (serve.sh).
const DEV_PORTS: Record<string, string> = { '5173': 'vite', '8123': 'sa-doc' }
const snapshot = atom({ plugin: 'ports-backlog', key: 'snapshot' } as const, {
  ports: [],
  backlog: [],
  at: '',
} as Snapshot)

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'ports-backlog',
      description: 'Show listening ports and backlog summary in a right pane',
    })
    void $.ui.open({ id: PANE, title: 'Ports · Backlog' })
    void refresh($)
    $.clock.every(10_000, () => refresh($))

    return next(e)
  })

  on('command.run', { command: 'ports-backlog' }, async $ => {
    await refresh($)
    await $.ui.open({ id: PANE, title: 'Ports · Backlog' })

    return { text: 'Ports · Backlog pane opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const snap = await read($, snapshot)

    return (
      <Box flexDirection="column">
        <Text bold>Ports</Text>
        {snap.error && <Text color="red">{snap.error}</Text>}
        {snap.ports.length === 0 && !snap.error && <Text dimColor>none</Text>}
        {snap.ports.map(p => (
          <Text>
            {p.port.padStart(5)} <Text dimColor>{p.command}</Text>
          </Text>
        ))}
        <Text> </Text>
        <Text bold>Backlog</Text>
        {snap.backlog.length === 0 && <Text dimColor>none</Text>}
        {snap.backlog.map(item => (
          <Text wrap="truncate-end">· {item}</Text>
        ))}
        <Text> </Text>
        <Text dimColor>updated {snap.at}</Text>
      </Box>
    )
  })
}

async function refresh($: EngineInterface) {
  const cwd = await $.session.cwd()
  const project = cwd.slice(cwd.lastIndexOf('/') + 1)
  const failed = (err: Error) => ({ exitCode: -1, stdout: '', stderr: String(err) })
  const lsof = await $.process
    .run(['lsof', '-nP', '-iTCP', '-sTCP:LISTEN'], { timeoutMs: 8000 })
    .catch(failed)
  const docker = await $.process
    .run(
      ['docker', 'ps', '--filter', `label=com.docker.compose.project=${project}`,
        '--format', '{{.Label "com.docker.compose.service"}}\t{{.Ports}}'],
      { timeoutMs: 8000 },
    )
    .catch(failed)
  const dev = parsePorts(lsof.stdout)
    .filter(p => p.port in DEV_PORTS)
    .map(p => ({ ...p, command: DEV_PORTS[p.port] ?? p.command }))
  const md = await $.fs.read(`${cwd}/${BACKLOG}`).catch(() => '')
  const now = new Date(await $.clock.now())
  await update($, snapshot, () => ({
    ports: mergePorts(parseDockerPorts(docker.stdout), dev),
    backlog: parseBacklog(typeof md === 'string' ? md : ''),
    at: now.toTimeString().slice(0, 8),
    error: docker.exitCode !== 0 ? `docker ps failed: ${docker.stderr.trim().slice(0, 60)}` : undefined,
  }))
}
