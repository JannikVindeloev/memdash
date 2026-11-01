import { useState } from "react";
import {
  AppBar,
  Box,
  Button,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemText,
  Stack,
  TextField,
  Toolbar,
  Tooltip,
  Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import BoltIcon from "@mui/icons-material/Bolt";
import LogoutIcon from "@mui/icons-material/Logout";
import MenuIcon from "@mui/icons-material/Menu";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import ScienceIcon from "@mui/icons-material/Science";
import { useDashboard } from "../store";
import { seedDemoData } from "../lib/memgraph";
import CardGrid from "./CardGrid";
import CardEditor from "./CardEditor";
import { runCard } from "../lib/runner";

const SIDEBAR_WIDTH = 240;

export default function DashboardShell() {
  const {
    connection,
    cards,
    selectedCardId,
    sidebarOpen,
    toggleSidebar,
    addCard,
    selectCard,
    logout,
  } = useDashboard();
  const [seeding, setSeeding] = useState(false);
  const [seedMsg, setSeedMsg] = useState<string | null>(null);

  const runAll = async () => {
    for (const card of cards) {
      if (card.cypher.trim()) await runCard(card.id);
    }
  };

  const seed = async () => {
    setSeeding(true);
    setSeedMsg(null);
    try {
      const msg = await seedDemoData(connection.database);
      setSeedMsg(msg);
    } catch (e) {
      setSeedMsg(`Seed failed: ${e instanceof Error ? e.message : String(e)}`);
    } finally {
      setSeeding(false);
    }
  };

  return (
    <Box sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <AppBar position="static" color="transparent" elevation={0}>
        <Toolbar sx={{ gap: 1, borderBottom: "1px solid", borderColor: "divider" }}>
          <IconButton onClick={toggleSidebar} edge="start">
            <MenuIcon />
          </IconButton>
          <BoltIcon color="primary" />
          <Typography variant="h6" fontWeight={700} sx={{ flexGrow: 1 }}>
            memdash
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ display: { xs: "none", sm: "block" } }}>
            {connection.uri}
          </Typography>
          <Button
            size="small"
            variant="outlined"
            startIcon={<PlayArrowIcon />}
            onClick={runAll}
            disabled={cards.length === 0}
          >
            Run all
          </Button>
          <Button size="small" variant="outlined" startIcon={<AddIcon />} onClick={addCard}>
            Add card
          </Button>
          <Button
            size="small"
            variant="outlined"
            color="secondary"
            startIcon={<ScienceIcon />}
            onClick={seed}
            disabled={seeding}
          >
            {seeding ? "Seeding…" : "Load demo data"}
          </Button>
          <Tooltip title="Disconnect">
            <IconButton onClick={logout}>
              <LogoutIcon />
            </IconButton>
          </Tooltip>
        </Toolbar>
      </AppBar>

      <Box sx={{ flexGrow: 1, display: "flex", minHeight: 0 }}>
        <Drawer
          variant="persistent"
          open={sidebarOpen}
          sx={{
            width: sidebarOpen ? SIDEBAR_WIDTH : 0,
            flexShrink: 0,
            "& .MuiDrawer-paper": {
              width: SIDEBAR_WIDTH,
              boxSizing: "border-box",
              position: "relative",
              borderRight: "1px solid",
              borderColor: "divider",
            },
          }}
        >
          <Box sx={{ p: 2 }}>
            <Typography variant="overline" color="text.secondary">
              Cards ({cards.length})
            </Typography>
            <List dense>
              {cards.map((c) => (
                <ListItemButton
                  key={c.id}
                  selected={c.id === selectedCardId}
                  onClick={() => selectCard(c.id)}
                >
                  <ListItemText
                    primary={c.title}
                    secondary={c.visualization}
                    primaryTypographyProps={{ noWrap: true }}
                    secondaryTypographyProps={{ noWrap: true }}
                  />
                </ListItemButton>
              ))}
              {cards.length === 0 && (
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  No cards yet — add one to run your first Cypher query.
                </Typography>
              )}
            </List>
            <Divider sx={{ my: 2 }} />
            {seedMsg && (
              <TextField value={seedMsg} multiline minRows={2} fullWidth size="small" InputProps={{ readOnly: true }} />
            )}
          </Box>
        </Drawer>

        <Box sx={{ flexGrow: 1, minWidth: 0, p: 2, overflow: "auto" }}>
          <CardGrid />
        </Box>
      </Box>

      <CardEditor
        open={selectedCardId !== null}
        cardId={selectedCardId}
        onClose={() => selectCard(null)}
      />
    </Box>
  );
}
