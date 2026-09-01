import { useState, useEffect, useRef } from "react";

const FONTS = `@import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700;900&family=Syne:wght@400;600;700;800&family=DM+Sans:ital,wght@0,300;0,400;0,500;1,400&family=JetBrains+Mono:wght@400;500;600&display=swap');`;

const C = {
  bg:    "#0C0B0A",
  s1:    "#171614",
  s2:    "#222120",
  s3:    "#2D2C2A",
  s4:    "#3A3836",
  fg:    "#F0EDE8",
  fgm:   "#A09890",
  fgd:   "#605850",
  ember: "#E96A12",
  neural:"#00C2DC",
  gold:  "#F49E12",
  sacred:"#CE3012",
  green: "#3DB87A",
  red:   "#E24B4A",
};

const T = {
  display: "'Cinzel', Georgia, serif",
  head:    "'Syne', system-ui, sans-serif",
  body:    "'DM Sans', system-ui, sans-serif",
  mono:    "'JetBrains Mono', monospace",
};

const AGENTS = [
  { id: 1, name: "ssr-frontend-agent", task: "Auditing TanStack Router config across 14 route files", status: "running", runtime: "UAR", progress: 62, model: "claude-sonnet-4-6", elapsed: "2m 14s", files: 14, tokens: 18400 },
  { id: 2, name: "doc-generation-agent", task: "Generating mineral acquisition document templates", status: "complete", runtime: "UAR", progress: 100, model: "claude-sonnet-4-6", elapsed: "4m 02s", files: 6, tokens: 31200 },
  { id: 3, name: "mcp-config-agent", task: "Resolving surreal-memory-server connection paths", status: "queued", runtime: "UAR", progress: 0, model: "claude-sonnet-4-6", elapsed: "—", files: 0, tokens: 0 },
  { id: 4, name: "mineral-sync-scheduler", task: "Nightly GIS data ingestion — RRC Texas feed", status: "scheduled", runtime: "BossFang", progress: 0, model: "gemini-3.5-flash", elapsed: "Next: 02:00 AM", files: 0, tokens: 0 },
  { id: 5, name: "hotseaters-refactor", task: "Migrating Radix UI to Base UI across 23 components", status: "running", runtime: "BossFang", progress: 38, model: "claude-opus-4-6", elapsed: "11m 47s", files: 23, tokens: 64100 },
];

const CONVOS = [
  { id: 1, label: "SSR BDD Scenario Gaps", age: "2h" },
  { id: 2, label: "PMPO Evolution Loop Cedar", age: "5h" },
  { id: 3, label: "turboquant-rs SIMD bench", age: "1d" },
  { id: 4, label: "UAR Cedar governance spec", age: "2d" },
  { id: 5, label: "HotSeaters schema v2", age: "3d" },
];

const SCHEDULED = [
  { id: 1, label: "Mineral data sync", cron: "0 2 * * *", next: "02:00 AM" },
  { id: 2, label: "SSR report digest", cron: "0 8 * * 1", next: "Mon 08:00" },
];

const STATUS_META = {
  running:   { color: C.neural,  label: "Running",   dot: true  },
  complete:  { color: C.green,   label: "Complete",  dot: false },
  queued:    { color: C.fgm,     label: "Queued",    dot: false },
  scheduled: { color: C.gold,    label: "Scheduled", dot: false },
  error:     { color: C.red,     label: "Error",     dot: false },
};

const RUNTIME_META = {
  UAR:      { color: C.ember,  desc: "Ephemeral · Fast" },
  BossFang: { color: C.neural, desc: "Persistent · Scheduled" },
};

const MODELS = [
  { id: "claude-sonnet-4-6", label: "Claude Sonnet 4.6",  provider: "Anthropic" },
  { id: "claude-opus-4-6",   label: "Claude Opus 4.6",    provider: "Anthropic" },
  { id: "gemini-3.5-flash",  label: "Gemini 3.5 Flash",   provider: "Google"    },
  { id: "llama-local",       label: "Llama 3.3 70B · L4", provider: "Local"     },
  { id: "deepseek-v4-pro",   label: "DeepSeek V4 Pro",    provider: "DeepSeek"  },
];

const RUNTIMES = ["UAR", "BossFang"];

function Dot({ color, pulse }) {
  return (
    <span style={{ position:"relative", display:"inline-block", width:8, height:8 }}>
      <span style={{
        display:"block", width:8, height:8, borderRadius:"50%",
        background: color,
        ...(pulse ? { animation: "pulse-dot 1.8s ease-in-out infinite" } : {})
      }}/>
    </span>
  );
}

function ProgressBar({ value, color }) {
  return (
    <div style={{ height:3, background:C.s4, borderRadius:99, overflow:"hidden" }}>
      <div style={{
        height:"100%", width:`${value}%`, background: color,
        borderRadius:99, transition:"width 0.6s ease"
      }}/>
    </div>
  );
}

function Badge({ label, color, bg }) {
  return (
    <span style={{
      fontSize:10, fontFamily:T.mono, fontWeight:600,
      color: color || C.fgm,
      background: bg || C.s3,
      padding:"2px 7px", borderRadius:4,
      letterSpacing:"0.04em", textTransform:"uppercase"
    }}>{label}</span>
  );
}

function AgentCard({ agent, selected, onClick }) {
  const sm = STATUS_META[agent.status];
  const rm = RUNTIME_META[agent.runtime];
  const isActive = agent.status === "running";

  return (
    <div onClick={onClick} style={{
      background: selected ? C.s3 : C.s2,
      borderRadius:10, padding:"14px 16px",
      cursor:"pointer", transition:"background 0.15s",
      position:"relative", overflow:"hidden",
    }}>
      {selected && (
        <div style={{ position:"absolute", left:0, top:0, bottom:0, width:3, background:C.ember, borderRadius:"3px 0 0 3px" }}/>
      )}
      <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:8 }}>
        <div style={{ display:"flex", alignItems:"center", gap:7 }}>
          <Dot color={sm.color} pulse={isActive && sm.dot} />
          <span style={{ fontFamily:T.mono, fontSize:12, color:C.fg, fontWeight:500 }}>{agent.name}</span>
        </div>
        <div style={{ display:"flex", gap:6, alignItems:"center" }}>
          <Badge label={agent.runtime} color={rm.color} bg={C.s4}/>
          <Badge label={sm.label} color={sm.color} bg={C.s4}/>
        </div>
      </div>
      <p style={{ fontFamily:T.body, fontSize:12, color:C.fgm, margin:"0 0 10px", lineHeight:1.5 }}>{agent.task}</p>
      {agent.status === "running" && (
        <ProgressBar value={agent.progress} color={C.neural}/>
      )}
      {agent.status === "complete" && (
        <ProgressBar value={100} color={C.green}/>
      )}
      <div style={{ display:"flex", gap:12, marginTop:8, flexWrap:"wrap" }}>
        <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>⏱ {agent.elapsed}</span>
        {agent.files > 0 && <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>📄 {agent.files} files</span>}
        {agent.tokens > 0 && <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>◈ {agent.tokens.toLocaleString()} tok</span>}
        <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd, marginLeft:"auto" }}>{agent.model}</span>
      </div>
    </div>
  );
}

function AgentInspector({ agent }) {
  const sm = STATUS_META[agent.status];
  const rm = RUNTIME_META[agent.runtime];
  const logs = [
    { t:"00:00", msg:"Agent initialized — loading Cedar policy context" },
    { t:"00:02", msg:"Tool: filesystem.read_directory → /prometheus/ssr-frontend" },
    { t:"00:14", msg:"Tool: filesystem.read_file → src/routes/index.tsx" },
    { t:"00:31", msg:"Planning phase complete — 14 files flagged for review" },
    { t:"01:04", msg:"Tool: filesystem.read_file → src/routes/dashboard.tsx" },
    { t:"01:47", msg:"Tool: filesystem.read_file → src/routes/documents.tsx" },
    { t:"02:14", msg:"Analyzing TanStack Router config patterns…" },
  ];
  return (
    <div style={{ width:280, background:C.s1, overflowY:"auto", padding:"20px 16px", borderLeft:`1px solid ${C.s3}` }}>
      <div style={{ marginBottom:16 }}>
        <div style={{ fontFamily:T.head, fontSize:13, fontWeight:700, color:C.fg, marginBottom:4 }}>{agent.name}</div>
        <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
          <Badge label={agent.runtime} color={rm.color} bg={C.s3}/>
          <Badge label={sm.label} color={sm.color} bg={C.s3}/>
        </div>
      </div>
      <div style={{ marginBottom:16 }}>
        <div style={{ fontFamily:T.mono, fontSize:10, color:C.fgd, marginBottom:6, textTransform:"uppercase", letterSpacing:"0.06em" }}>Task</div>
        <p style={{ fontFamily:T.body, fontSize:12, color:C.fgm, lineHeight:1.55, margin:0 }}>{agent.task}</p>
      </div>
      {agent.status === "running" && (
        <div style={{ marginBottom:16 }}>
          <div style={{ display:"flex", justifyContent:"space-between", marginBottom:4 }}>
            <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>Progress</span>
            <span style={{ fontFamily:T.mono, fontSize:10, color:C.neural }}>{agent.progress}%</span>
          </div>
          <ProgressBar value={agent.progress} color={C.neural}/>
        </div>
      )}
      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8, marginBottom:16 }}>
        {[
          { label:"Elapsed", val:agent.elapsed },
          { label:"Model", val:agent.model.split("-").slice(0,2).join("-") },
          { label:"Files", val:agent.files || "—" },
          { label:"Tokens", val:agent.tokens ? agent.tokens.toLocaleString() : "—" },
        ].map(m => (
          <div key={m.label} style={{ background:C.s2, borderRadius:6, padding:"8px 10px" }}>
            <div style={{ fontFamily:T.mono, fontSize:9, color:C.fgd, marginBottom:2, textTransform:"uppercase" }}>{m.label}</div>
            <div style={{ fontFamily:T.mono, fontSize:11, color:C.fg }}>{m.val}</div>
          </div>
        ))}
      </div>
      <div>
        <div style={{ fontFamily:T.mono, fontSize:10, color:C.fgd, marginBottom:8, textTransform:"uppercase", letterSpacing:"0.06em" }}>Activity Log</div>
        <div style={{ display:"flex", flexDirection:"column", gap:4 }}>
          {logs.map((l,i) => (
            <div key={i} style={{ display:"flex", gap:8, alignItems:"flex-start" }}>
              <span style={{ fontFamily:T.mono, fontSize:9, color:C.fgd, whiteSpace:"nowrap", paddingTop:2 }}>{l.t}</span>
              <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgm, lineHeight:1.5 }}>{l.msg}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{ marginTop:16, display:"flex", gap:8 }}>
        <button style={{
          flex:1, background:C.s3, color:C.fg, fontFamily:T.body,
          fontSize:11, padding:"7px 0", borderRadius:6, border:"none", cursor:"pointer"
        }}>Pause</button>
        <button style={{
          flex:1, background:C.sacred, color:C.fg, fontFamily:T.body,
          fontSize:11, padding:"7px 0", borderRadius:6, border:"none", cursor:"pointer"
        }}>Terminate</button>
      </div>
    </div>
  );
}

function ManagerView({ agents, selectedAgent, setSelectedAgent }) {
  return (
    <div style={{ display:"flex", flex:1, overflow:"hidden", gap:0 }}>
      <div style={{ flex:1, overflowY:"auto", padding:"20px 16px", display:"flex", flexDirection:"column", gap:10 }}>
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:4 }}>
          <span style={{ fontFamily:T.head, fontSize:12, color:C.fgd, textTransform:"uppercase", letterSpacing:"0.08em" }}>
            Active Agents ({agents.filter(a=>a.status==="running").length} running)
          </span>
          <button style={{
            background:C.ember, color:C.fg, fontFamily:T.body, fontSize:12,
            fontWeight:500, padding:"5px 12px", borderRadius:6, border:"none", cursor:"pointer"
          }}>+ New Agent</button>
        </div>
        {agents.map(a => (
          <AgentCard key={a.id} agent={a} selected={selectedAgent?.id === a.id} onClick={() => setSelectedAgent(a)} />
        ))}
      </div>
      {selectedAgent && <AgentInspector agent={selectedAgent} />}
    </div>
  );
}

const CHAT_MSGS = [
  { role:"user",      text:"Audit the ssr-frontend TanStack Router config and flag any route files missing loader patterns." },
  { role:"assistant", text:"Scanning 14 route files across the ssr-frontend workspace. I'll identify any routes missing loader definitions, error boundaries, or pending states required by the TanStack Router spec.\n\nStarting with the index routes…" },
  { role:"tool",      text:"filesystem.read_directory → /prometheus/ssr-frontend/src/routes\n→ 14 files found" },
  { role:"assistant", text:"Found 14 route files. 3 are missing loader patterns:\n\n• dashboard.tsx — no loader defined\n• documents/new.tsx — no pendingComponent\n• admin/users.tsx — error boundary missing\n\nShall I generate the missing patterns for each?" },
];

function ChatBubble({ msg }) {
  const isUser = msg.role === "user";
  const isTool = msg.role === "tool";
  return (
    <div style={{
      display:"flex", flexDirection: isUser ? "row-reverse" : "row",
      gap:10, alignItems:"flex-start",
    }}>
      {!isUser && !isTool && (
        <div style={{
          width:28, height:28, borderRadius:6, background:C.ember,
          display:"flex", alignItems:"center", justifyContent:"center",
          fontFamily:T.display, fontSize:10, color:C.fg, flexShrink:0, marginTop:2
        }}>B</div>
      )}
      <div style={{
        maxWidth:"78%",
        background: isUser ? C.s3 : isTool ? "transparent" : C.s2,
        borderRadius: isUser ? "12px 12px 4px 12px" : isTool ? 0 : "12px 12px 12px 4px",
        padding: isTool ? "0 0 0 4px" : "10px 14px",
        borderLeft: isTool ? `2px solid ${C.neural}` : "none",
      }}>
        {isTool ? (
          <pre style={{ fontFamily:T.mono, fontSize:10, color:C.neural, margin:0, lineHeight:1.6, padding:"4px 10px", whiteSpace:"pre-wrap" }}>{msg.text}</pre>
        ) : (
          <p style={{ fontFamily:T.body, fontSize:13, color:C.fg, margin:0, lineHeight:1.65, whiteSpace:"pre-wrap" }}>{msg.text}</p>
        )}
      </div>
    </div>
  );
}

function EditorView() {
  return (
    <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden" }}>
      <div style={{ flex:1, overflowY:"auto", padding:"24px 20px", display:"flex", flexDirection:"column", gap:14 }}>
        {CHAT_MSGS.map((m,i) => <ChatBubble key={i} msg={m}/>)}
        <div style={{ display:"flex", alignItems:"center", gap:8, marginTop:4 }}>
          <Dot color={C.neural} pulse/>
          <span style={{ fontFamily:T.mono, fontSize:11, color:C.neural }}>ssr-frontend-agent is working…</span>
        </div>
      </div>
    </div>
  );
}

export default function BossGravity() {
  const [view, setView] = useState("manager");
  const [runtime, setRuntime] = useState("UAR");
  const [model, setModel] = useState("claude-sonnet-4-6");
  const [selectedAgent, setSelectedAgent] = useState(AGENTS[0]);
  const [input, setInput] = useState("");
  const [sideSection, setSideSection] = useState("convos");

  useEffect(() => {
    const style = document.createElement("style");
    style.textContent = FONTS + `
      @keyframes pulse-dot {
        0%,100%{opacity:1;transform:scale(1)}
        50%{opacity:0.4;transform:scale(0.85)}
      }
      ::-webkit-scrollbar{width:4px;height:4px}
      ::-webkit-scrollbar-track{background:transparent}
      ::-webkit-scrollbar-thumb{background:${C.s4};border-radius:99px}
      textarea:focus{outline:none}
      button:focus{outline:none}
      select:focus{outline:none}
    `;
    document.head.appendChild(style);
    return () => document.head.removeChild(style);
  }, []);

  return (
    <div style={{
      display:"flex", flexDirection:"column", height:640,
      background:C.bg, color:C.fg, fontFamily:T.body,
      borderRadius:12, overflow:"hidden",
      fontSize:13,
    }}>
      <div style={{
        height:44, background:C.s1, display:"flex", alignItems:"center",
        padding:"0 16px", justifyContent:"space-between", flexShrink:0,
      }}>
        <div style={{ display:"flex", alignItems:"center", gap:10 }}>
          <span style={{ fontFamily:T.display, fontSize:15, fontWeight:700, color:C.ember, letterSpacing:"0.05em" }}>BOSS</span>
          <span style={{ fontFamily:T.display, fontSize:15, fontWeight:400, color:C.fg, letterSpacing:"0.08em" }}>GRAVITY</span>
          <div style={{ width:1, height:16, background:C.s4, margin:"0 6px" }}/>
          <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>Powered by UAR · BossFang</span>
        </div>
        <div style={{ display:"flex", gap:2, background:C.s2, borderRadius:8, padding:3 }}>
          {["manager","editor"].map(v => (
            <button key={v} onClick={() => setView(v)} style={{
              padding:"4px 14px", borderRadius:6, fontFamily:T.body, fontSize:12,
              fontWeight:500, border:"none", cursor:"pointer", transition:"all 0.15s",
              background: view===v ? C.s4 : "transparent",
              color: view===v ? C.fg : C.fgm,
            }}>
              {v === "manager" ? "Manager" : "Editor"}
            </button>
          ))}
        </div>
        <div style={{ display:"flex", gap:8, alignItems:"center" }}>
          <div style={{ width:8, height:8, borderRadius:"50%", background:C.green }}/>
          <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgm }}>UAR · Connected</span>
        </div>
      </div>

      <div style={{ display:"flex", flex:1, overflow:"hidden" }}>
        <div style={{ width:220, background:C.s1, display:"flex", flexDirection:"column", flexShrink:0, padding:"12px 0" }}>
          <div style={{ padding:"0 12px 12px" }}>
            <button style={{
              width:"100%", background:C.ember, color:C.fg,
              fontFamily:T.body, fontSize:12, fontWeight:500,
              padding:"8px 0", borderRadius:8, border:"none", cursor:"pointer",
            }}>+ New Conversation</button>
          </div>
          {[
            { id:"convos", label:"Conversations" },
            { id:"scheduled", label:"Scheduled Tasks" },
          ].map(s => (
            <button key={s.id} onClick={() => setSideSection(s.id)} style={{
              width:"100%", textAlign:"left", padding:"6px 16px",
              fontFamily:T.body, fontSize:12,
              color: sideSection===s.id ? C.fg : C.fgm,
              background: sideSection===s.id ? C.s2 : "transparent",
              border:"none", cursor:"pointer",
              fontWeight: sideSection===s.id ? 500 : 400,
            }}>{s.label}</button>
          ))}
          <div style={{ flex:1, overflowY:"auto", padding:"8px 0", marginTop:4 }}>
            {sideSection === "convos" && CONVOS.map(c => (
              <button key={c.id} style={{
                width:"100%", textAlign:"left", padding:"6px 16px",
                fontFamily:T.body, fontSize:12, color:C.fgm,
                background:"transparent", border:"none", cursor:"pointer",
                display:"flex", justifyContent:"space-between", alignItems:"center",
              }}>
                <span style={{ overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap", flex:1 }}>{c.label}</span>
                <span style={{ fontFamily:T.mono, fontSize:9, color:C.fgd, marginLeft:8, flexShrink:0 }}>{c.age}</span>
              </button>
            ))}
            {sideSection === "scheduled" && SCHEDULED.map(s => (
              <div key={s.id} style={{ padding:"8px 14px" }}>
                <div style={{ fontFamily:T.body, fontSize:12, color:C.fg, marginBottom:2 }}>{s.label}</div>
                <div style={{ fontFamily:T.mono, fontSize:9, color:C.gold }}>{s.cron}</div>
                <div style={{ fontFamily:T.mono, fontSize:9, color:C.fgd }}>Next: {s.next}</div>
              </div>
            ))}
          </div>
          <div style={{ padding:"12px 14px", borderTop:`1px solid ${C.s3}` }}>
            <div style={{ display:"flex", alignItems:"center", gap:8 }}>
              <div style={{ width:26, height:26, borderRadius:6, background:C.ember, display:"flex", alignItems:"center", justifyContent:"center", fontFamily:T.display, fontSize:10, fontWeight:700, color:C.fg }}>TJ</div>
              <div>
                <div style={{ fontFamily:T.body, fontSize:11, fontWeight:500, color:C.fg }}>Travis James</div>
                <div style={{ fontFamily:T.mono, fontSize:9, color:C.fgd }}>AI Application Architect</div>
              </div>
            </div>
          </div>
        </div>

        <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden" }}>
          {view === "manager"
            ? <ManagerView agents={AGENTS} selectedAgent={selectedAgent} setSelectedAgent={setSelectedAgent}/>
            : <EditorView />
          }
          <div style={{ background:C.s1, padding:"12px 16px", flexShrink:0 }}>
            <div style={{ display:"flex", gap:8, marginBottom:10, alignItems:"center" }}>
              <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>Runtime</span>
              <div style={{ display:"flex", gap:2, background:C.s2, borderRadius:6, padding:2 }}>
                {RUNTIMES.map(r => (
                  <button key={r} onClick={() => setRuntime(r)} style={{
                    padding:"3px 10px", borderRadius:5, fontFamily:T.mono, fontSize:10,
                    fontWeight:600, border:"none", cursor:"pointer", transition:"all 0.15s",
                    background: runtime===r ? RUNTIME_META[r].color : "transparent",
                    color: runtime===r ? "#000" : C.fgm,
                  }}>{r}</button>
                ))}
              </div>
              <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd, marginLeft:8 }}>Model</span>
              <select value={model} onChange={e=>setModel(e.target.value)} style={{
                background:C.s2, color:C.fg, border:"none", borderRadius:6,
                fontFamily:T.mono, fontSize:10, padding:"4px 8px", cursor:"pointer",
                flex:1, maxWidth:220,
              }}>
                {MODELS.map(m => (
                  <option key={m.id} value={m.id}>{m.label} · {m.provider}</option>
                ))}
              </select>
              {runtime === "BossFang" && (
                <div style={{ display:"flex", alignItems:"center", gap:6, background:C.s2, padding:"4px 10px", borderRadius:6 }}>
                  <Dot color={C.neural}/>
                  <span style={{ fontFamily:T.mono, fontSize:10, color:C.neural }}>Persistent mode</span>
                </div>
              )}
            </div>
            <div style={{ display:"flex", gap:10, alignItems:"flex-end" }}>
              <textarea
                value={input}
                onChange={e=>setInput(e.target.value)}
                placeholder={view==="manager"
                  ? "Describe a task to spawn a new agent… @mention to assign to existing"
                  : "Ask anything, @ to mention, / for actions"
                }
                rows={2}
                style={{
                  flex:1, background:C.s2, color:C.fg, border:"none",
                  borderRadius:8, padding:"10px 14px", fontFamily:T.body,
                  fontSize:13, resize:"none", lineHeight:1.5,
                }}
              />
              <button style={{
                background:C.ember, color:C.fg, border:"none",
                borderRadius:8, padding:"10px 18px", fontFamily:T.body,
                fontSize:13, fontWeight:500, cursor:"pointer", flexShrink:0,
                height:60, alignSelf:"stretch",
              }}>
                {runtime === "BossFang" ? "Schedule" : "Send"}
              </button>
            </div>
            <div style={{ display:"flex", gap:16, marginTop:8 }}>
              {[
                { label:"@ Mention agent" },
                { label:"/ Actions" },
                { label:"⌘K Command" },
              ].map(h => (
                <span key={h.label} style={{ fontFamily:T.mono, fontSize:10, color:C.fgd }}>{h.label}</span>
              ))}
              {runtime === "UAR" && (
                <span style={{ fontFamily:T.mono, fontSize:10, color:C.fgd, marginLeft:"auto" }}>
                  UAR · ephemeral · Cedar policy active
                </span>
              )}
              {runtime === "BossFang" && (
                <span style={{ fontFamily:T.mono, fontSize:10, color:C.neural, marginLeft:"auto" }}>
                  BossFang · persistent · cron-eligible
                </span>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
