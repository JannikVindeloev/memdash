import {
  Box,
  Button,
  Drawer,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
  Typography,
  IconButton,
} from "@mui/material";
import DeleteIcon from "@mui/icons-material/Delete";
import CloseIcon from "@mui/icons-material/Close";
import { useDashboard } from "../store";
import { VISUALIZATION_OPTIONS, type VisualizationType } from "../lib/types";
import { runCard } from "../lib/runner";

export default function CardEditor({
  open,
  cardId,
  onClose,
}: {
  open: boolean;
  cardId: string | null;
  onClose: () => void;
}) {
  const cards = useDashboard((s) => s.cards);
  const updateCard = useDashboard((s) => s.updateCard);
  const removeCard = useDashboard((s) => s.removeCard);
  const card = cards.find((c) => c.id === cardId) ?? null;

  return (
    <Drawer anchor="right" open={open && card !== null} onClose={onClose}>
      <Box sx={{ width: 420, p: 3, display: "flex", flexDirection: "column", gap: 2, height: "100%" }}>
        <Stack direction="row" alignItems="center" justifyContent="space-between">
          <Typography variant="h6">Edit card</Typography>
          <Stack direction="row" spacing={1}>
            {card && (
              <IconButton color="error" onClick={() => { removeCard(card.id); onClose(); }}>
                <DeleteIcon />
              </IconButton>
            )}
            <IconButton onClick={onClose}>
              <CloseIcon />
            </IconButton>
          </Stack>
        </Stack>

        {card && (
          <>
            <TextField
              label="Title"
              value={card.title}
              onChange={(e) => updateCard(card.id, { title: e.target.value })}
              fullWidth
              size="small"
            />
            <TextField
              label="Cypher query"
              value={card.cypher}
              onChange={(e) => updateCard(card.id, { cypher: e.target.value })}
              fullWidth
              multiline
              minRows={8}
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
              placeholder="MATCH (n) RETURN n LIMIT 25"
            />
            <FormControl fullWidth size="small">
              <InputLabel>Visualization</InputLabel>
              <Select
                label="Visualization"
                value={card.visualization}
                onChange={(e) => updateCard(card.id, { visualization: e.target.value as VisualizationType })}
              >
                {VISUALIZATION_OPTIONS.map((o) => (
                  <MenuItem key={o.value} value={o.value}>
                    {o.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="Auto-refresh (seconds, 0 = off)"
              type="number"
              value={card.refreshRate}
              onChange={(e) => updateCard(card.id, { refreshRate: Math.max(0, Number(e.target.value) || 0) })}
              fullWidth
              size="small"
              inputProps={{ min: 0 }}
            />
            <TextField
              label="Parameters ($key in query, one per line: key=value)"
              value={Object.entries(card.parameters).map(([k, v]) => `${k}=${v}`).join("\n")}
              onChange={(e) => {
                const parameters: Record<string, string> = {};
                for (const line of e.target.value.split("\n")) {
                  const idx = line.indexOf("=");
                  if (idx > 0) parameters[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
                }
                updateCard(card.id, { parameters });
              }}
              fullWidth
              multiline
              minRows={2}
              size="small"
              InputProps={{ sx: { fontFamily: "monospace", fontSize: 13 } }}
            />
            <Button variant="contained" onClick={() => runCard(card.id)}>
              Run query
            </Button>
            {card.lastError && (
              <Typography variant="body2" color="error" sx={{ wordBreak: "break-word" }}>
                {card.lastError}
              </Typography>
            )}
          </>
        )}
      </Box>
    </Drawer>
  );
}
