import { useState } from "react";
import {
  Box,
  Button,
  CircularProgress,
  Paper,
  TextField,
  Typography,
  Alert,
  Stack,
  Link,
} from "@mui/material";
import BoltIcon from "@mui/icons-material/Bolt";
import { useDashboard } from "../store";
import type { ConnectionConfig } from "../lib/types";

export default function ConnectionScreen() {
  const { connection, connecting, connectionError, connect } = useDashboard();
  const [form, setForm] = useState<ConnectionConfig>(connection);

  const set = (patch: Partial<ConnectionConfig>) => setForm((f) => ({ ...f, ...patch }));

  return (
    <Box
      sx={{
        height: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background:
          "radial-gradient(1200px 600px at 20% -10%, rgba(61,123,253,0.25), transparent), radial-gradient(900px 500px at 90% 110%, rgba(25,195,125,0.18), transparent), #10131a",
      }}
    >
      <Paper elevation={6} sx={{ p: 4, width: 420, borderRadius: 3 }}>
        <Stack spacing={2}>
          <Stack direction="row" spacing={1.5} alignItems="center">
            <BoltIcon color="primary" sx={{ fontSize: 40 }} />
            <Box>
              <Typography variant="h5" fontWeight={700}>
                memdash
              </Typography>
              <Typography variant="body2" color="text.secondary">
                A shiny NeoDash-style dashboard for Memgraph
              </Typography>
            </Box>
          </Stack>

          {connectionError && (
            <Alert severity="error" sx={{ wordBreak: "break-word" }}>
              {connectionError}
            </Alert>
          )}

          <TextField
            label="Bolt URI"
            value={form.uri}
            onChange={(e) => set({ uri: e.target.value })}
            placeholder="bolt://localhost:7687"
            fullWidth
            size="small"
          />
          <TextField
            label="Username (optional)"
            value={form.username}
            onChange={(e) => set({ username: e.target.value })}
            fullWidth
            size="small"
          />
          <TextField
            label="Password (optional)"
            type="password"
            value={form.password}
            onChange={(e) => set({ password: e.target.value })}
            fullWidth
            size="small"
          />
          <TextField
            label="Database (optional)"
            value={form.database}
            onChange={(e) => set({ database: e.target.value })}
            placeholder="memgraph"
            fullWidth
            size="small"
          />

          <Button
            variant="contained"
            size="large"
            disabled={connecting || !form.uri}
            onClick={() => connect(form)}
            startIcon={connecting ? <CircularProgress size={18} color="inherit" /> : undefined}
          >
            {connecting ? "Connecting…" : "Connect"}
          </Button>

          <Typography variant="caption" color="text.secondary">
            Memgraph speaks Bolt and openCypher, so any Cypher query works here.{" "}
            <Link
              href="https://memgraph.com/docs"
              target="_blank"
              rel="noreferrer"
              color="primary"
            >
              Memgraph docs
            </Link>{" "}
            ·{" "}
            <Link
              href="https://github.com/neo4j-contrib/neodash"
              target="_blank"
              rel="noreferrer"
              color="primary"
            >
              inspired by NeoDash
            </Link>
          </Typography>
        </Stack>
      </Paper>
    </Box>
  );
}
