import { useDashboard } from "./store";
import ConnectionScreen from "./components/ConnectionScreen";
import DashboardShell from "./components/DashboardShell";

export default function App() {
  const connected = useDashboard((s) => s.connected);
  return connected ? <DashboardShell /> : <ConnectionScreen />;
}
