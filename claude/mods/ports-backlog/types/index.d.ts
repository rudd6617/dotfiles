export type Port = { port: string; command: string; pid: string }
export type Snapshot = { ports: Port[]; backlog: string[]; at: string; error?: string }

declare module 'claude-code' {
  interface PluginState {
    'ports-backlog': { snapshot: Snapshot }
  }
}
