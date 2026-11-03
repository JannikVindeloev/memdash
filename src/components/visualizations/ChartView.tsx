import { useMemo } from "react";
import { Box, Typography } from "@mui/material";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { chartRows } from "../../lib/format";

const PIE_COLORS = ["#3d7bfd", "#19c37d", "#f5a524", "#e5534b", "#a371f7", "#2bb3c0", "#ec6aa8", "#8bc34a"];

export default function ChartView({
  kind,
  records,
  fields,
}: {
  kind: "bar" | "line" | "pie";
  records: Record<string, unknown>[];
  fields: string[];
}) {
  const data = useMemo(() => chartRows(records).slice(0, 200), [records]);
  const xKey = fields[0] ?? "x";
  const valueKeys = fields.slice(1);

  if (data.length === 0 || valueKeys.length === 0) {
    return (
      <Box sx={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Typography color="text.secondary">No data — needs at least 2 columns</Typography>
      </Box>
    );
  }

  if (kind === "pie") {
    const nameKey = xKey;
    return (
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie data={data} dataKey={valueKeys[0]} nameKey={nameKey} outerRadius="80%" label>
            {data.map((_, i) => (
              <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
            ))}
          </Pie>
          <Tooltip />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    );
  }

  const series = valueKeys.map((k, i) => ({ key: k, color: PIE_COLORS[i % PIE_COLORS.length] }));
  return (
    <ResponsiveContainer width="100%" height="100%">
      {kind === "bar" ? (
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis dataKey={xKey} stroke="#9aa3b2" fontSize={12} />
          <YAxis stroke="#9aa3b2" fontSize={12} />
          <Tooltip contentStyle={{ background: "#181c26", border: "1px solid rgba(255,255,255,0.1)" }} />
          <Legend />
          {series.map((s) => (
            <Bar key={s.key} dataKey={s.key} fill={s.color} />
          ))}
        </BarChart>
      ) : (
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis dataKey={xKey} stroke="#9aa3b2" fontSize={12} />
          <YAxis stroke="#9aa3b2" fontSize={12} />
          <Tooltip contentStyle={{ background: "#181c26", border: "1px solid rgba(255,255,255,0.1)" }} />
          <Legend />
          {series.map((s) => (
            <Line key={s.key} dataKey={s.key} stroke={s.color} dot={false} />
          ))}
        </LineChart>
      )}
    </ResponsiveContainer>
  );
}
