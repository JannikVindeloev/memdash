import { Box } from "@mui/material";

export default function JsonView({
  records,
}: {
  records: Record<string, unknown>[];
  fields: string[];
}) {
  return (
    <Box
      component="pre"
      sx={{
        height: "100%",
        overflow: "auto",
        m: 0,
        p: 1,
        fontSize: 12,
        fontFamily: "monospace",
        whiteSpace: "pre-wrap",
        wordBreak: "break-word",
        color: "text.primary",
      }}
    >
      {JSON.stringify(records.slice(0, 100), null, 2) || "[]"}
    </Box>
  );
}
