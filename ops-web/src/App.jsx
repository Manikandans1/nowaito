import React, { useEffect, useState } from "react";
import axios from "axios";
import { LayoutGrid, Gauge, Users as UsersIcon, AlertTriangle, ShieldAlert, Flag, BarChart3, RefreshCw } from "lucide-react";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";
const api = axios.create({ baseURL: API_BASE });

const C = { primary: "#00FF29", secondary: "#000000", surface: "#1C1C1C", muted: "#666666", white: "#FFFFFF" };

function Card({ children, style }) {
  return <div style={{ background: C.surface, border: `1px solid ${C.muted}33`, borderRadius: 16, padding: 16, ...style }}>{children}</div>;
}
function Pill({ children, tone = "muted" }) {
  const styles = tone === "primary"
    ? { background: C.primary + "1a", color: C.primary, border: `1px solid ${C.primary}55` }
    : { background: C.muted + "22", color: C.white, border: `1px solid ${C.muted}44` };
  return <span style={{ ...styles, fontSize: 11, padding: "4px 10px", borderRadius: 999, fontWeight: 500 }}>{children}</span>;
}
function NavItem({ icon: Icon, label, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", alignItems: "center", gap: 10, width: "100%", textAlign: "left",
      padding: "10px 12px", borderRadius: 10, marginBottom: 4, border: "none", cursor: "pointer",
      background: active ? C.primary + "1a" : "transparent", color: active ? C.primary : C.white,
    }}>
      <Icon size={15} />
      <span style={{ fontSize: 13 }}>{label}</span>
    </button>
  );
}

function ZoneHealthPage() {
  const [zones, setZones] = useState(null);
  const [error, setError] = useState(null);
  const [loadedAt, setLoadedAt] = useState(null);

  const load = async () => {
    try {
      const { data } = await api.get("/api/zones/health");
      setZones(data);
      setError(null);
      setLoadedAt(new Date());
    } catch (e) {
      setError("Could not reach the backend at " + API_BASE + " — is it running? (see README)");
    }
  };

  useEffect(() => {
    load();
    const interval = setInterval(load, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 20 }}>
        <div>
          <div style={{ color: C.white, fontSize: 20, fontWeight: 600 }}>Zone health monitor</div>
          <div style={{ color: C.muted, fontSize: 13, marginTop: 4 }}>Live from {API_BASE}/api/zones/health · auto-refreshes every 5s</div>
        </div>
        <button onClick={load} style={{ display: "flex", alignItems: "center", gap: 6, background: "transparent", border: `1px solid ${C.muted}55`, color: C.muted, borderRadius: 8, padding: "6px 10px", cursor: "pointer" }}>
          <RefreshCw size={13} /> Refresh
        </button>
      </div>

      {error && <Card style={{ borderColor: C.primary }}><span style={{ color: C.white, fontSize: 13 }}>{error}</span></Card>}

      {zones && (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 16 }}>
          {zones.map((z) => (
            <Card key={z.zoneId} style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <div style={{ color: C.white, fontSize: 14, fontWeight: 500 }}>{z.name}</div>
                <div style={{ color: z.healthy ? C.primary : C.white, fontFamily: "monospace", fontSize: 28, marginTop: 6 }}>{z.activeDrivers}</div>
                <div style={{ color: C.muted, fontSize: 12 }}>active drivers</div>
              </div>
              {!z.healthy && <Pill>Below floor</Pill>}
              {z.healthy && !z.readyToLaunch && <Pill tone="primary">Healthy</Pill>}
              {z.readyToLaunch && <Pill tone="primary">Ready to launch</Pill>}
            </Card>
          ))}
          {zones.length === 0 && <Card><span style={{ color: C.muted, fontSize: 13 }}>No zones yet — the backend seeds Koramangala + T. Nagar on first boot.</span></Card>}
        </div>
      )}
      {loadedAt && <div style={{ color: C.muted, fontSize: 11, marginTop: 16 }}>Last updated {loadedAt.toLocaleTimeString()}</div>}
    </div>
  );
}

function PlaceholderPage({ title, note }) {
  return (
    <div>
      <div style={{ color: C.white, fontSize: 20, fontWeight: 600, marginBottom: 8 }}>{title}</div>
      <Card>
        <span style={{ color: C.muted, fontSize: 13 }}>{note} This screen is a UI placeholder from the design prototype — wire it to a real backend endpoint the same way Zone Health is wired (see ZoneHealthPage in this file for the pattern).</span>
      </Card>
    </div>
  );
}

const NAV = [
  { id: "zones", label: "Zone health", icon: Gauge },
  { id: "verify", label: "Driver verification", icon: UsersIcon },
  { id: "reviews", label: "Reviews & incidents", icon: ShieldAlert },
  { id: "revenue", label: "Revenue & analytics", icon: BarChart3 },
];

export default function App() {
  const [page, setPage] = useState("zones");

  return (
    <div style={{ minHeight: "100vh", background: C.secondary, fontFamily: "Inter, system-ui, sans-serif" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "16px 24px", borderBottom: `1px solid ${C.muted}22` }}>
        <LayoutGrid size={18} color={C.primary} />
        <span style={{ color: C.white, fontWeight: 600, fontSize: 14 }}>NoWaito Ops Console</span>
        <span style={{ marginLeft: "auto" }}><Pill tone="primary">Bangalore + Chennai</Pill></span>
      </div>
      <div style={{ display: "flex" }}>
        <div style={{ width: 220, borderRight: `1px solid ${C.muted}22`, padding: 16, minHeight: "calc(100vh - 57px)" }}>
          {NAV.map((n) => <NavItem key={n.id} icon={n.icon} label={n.label} active={page === n.id} onClick={() => setPage(n.id)} />)}
        </div>
        <div style={{ flex: 1, padding: 28 }}>
          {page === "zones" && <ZoneHealthPage />}
          {page === "verify" && <PlaceholderPage title="Driver verification queue" note="Backend endpoint not yet built —" />}
          {page === "reviews" && <PlaceholderPage title="Reviews & incidents" note="Backend endpoint not yet built —" />}
          {page === "revenue" && <PlaceholderPage title="Revenue & analytics" note="Backend endpoint not yet built —" />}
        </div>
      </div>
    </div>
  );
}
