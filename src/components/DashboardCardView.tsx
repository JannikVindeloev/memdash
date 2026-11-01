import { useEffect, useRef } from "react";
import {
  Box,
  Chip,
  IconButton,
  Paper,
  Tooltip,
  Typography,
} from "@mui/material";
import DragIndicatorIcon from "@mui/icons-material/DragIndicator";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import SettingsIcon from "@mui/icons-material/Settings";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import type { DashboardCard } from "../lib/types";
import { useDashboard } from "../store";
import { runCard } from "../lib/runner";
import Visualization from "./visualizations/Visualization";

export default function DashboardCardView({ card }: { card: DashboardCard }) {
  const selectCard = useDashboard((s) => s.selectCard);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (intervalRef.current) clearInterval(intervalRef.current);
    if (card.refreshRate > 0) {
      intervalRef.current = setInterval(() => runCard(card.id), card.refreshRate * 1000);
    }
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [card.id, card.refreshRate]);

  useEffect(() => {
    runCard(card.id);
  }, [card.id, card.cypher]);

  const records = (card.cachedRecords ?? []) as Record<string, unknown>[];
  const fields = card.cachedFields ?? [];

  return (
    <Paper
      sx={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
        border: "1px solid",
        borderColor: "divider",
      }}
    >
      <Box
        className="card-drag-handle"
        sx={{
          display: "flex",
          alignItems: "center",
          gap: 1,
          px: 1,
          py: 0.5,
          cursor: "move",
          borderBottom: "1px solid",
          borderColor: "divider",
          bgcolor: "rgba(255,255,255,0.03)",
        }}
      >
        <DragIndicatorIcon fontSize="small" sx={{ color: "text.secondary" }} />
        <Typography variant="subtitle2" noWrap sx={{ flexGrow: 1, fontWeight: 600 }}>
          {card.title}
        </Typography>
        {card.lastError && (
          <Tooltip title={card.lastError}>
            <ErrorOutlineIcon color="error" fontSize="small" />
          </Tooltip>
        )}
        <Chip label={card.visualization} size="small" variant="outlined" sx={{ height: 20, fontSize: 11 }} />
        <Tooltip title="Run query">
          <IconButton size="small" onClick={() => runCard(card.id)}>
            <PlayArrowIcon fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Edit card">
          <IconButton size="small" onClick={() => selectCard(card.id)}>
            <SettingsIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>
      <Box sx={{ flexGrow: 1, minHeight: 0, p: 1 }}>
        <Visualization card={card} records={records} fields={fields} />
      </Box>
      <Box sx={{ px: 1, py: 0.25, borderTop: "1px solid", borderColor: "divider" }}>
        <Typography variant="caption" color="text.secondary">
          {card.lastError
            ? "Query failed"
            : `${records.length} row${records.length === 1 ? "" : "s"}`}
          {card.lastRunAt ? ` · ${new Date(card.lastRunAt).toLocaleTimeString()}` : ""}
          {card.refreshRate > 0 ? ` · refresh ${card.refreshRate}s` : ""}
        </Typography>
      </Box>
    </Paper>
  );
}
